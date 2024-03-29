/*
 * Real-time proxy between the Elekta Neuromag MEG system and FieldTrip real-time buffer
 *
 * (C)opyright Gustavo Sudre and Lauri Parkkonen, 2010
 *
 * This software comes without warranty of any kind, and it may not be fit for any particular
 * purpose. Use at your own risk. This software is NOT by Elekta Oy, and Elekta Oy does not endorse
 * its use.
 */

#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>

/* Elekta libraries */
#include <err.h>
#include <fiff.h>
#include <dacq.h>
#include <dacqcomm.h>

/* FieldTrip buffer library */
#include <buffer.h>

/* Local */
#include "neuromag2ft.h"

#define COLLECTOR_PORT    "collector"
#define COLLECTOR_PASS    "homunculus122"
#define COLLECTOR_BUFS    32768
#define COLLECTOR_GETVARS "vars"
#define COLLECTOR_SETVARS "vara"
#define COLLECTOR_DOSETUP "setu"
#define COLLECTOR_BUFVAR  "maxBuflen"

#define MIN_BUFLEN      28+1//2*28    /* DSP units send packets of 28 samples, which is the ultimate lower bound */

#define CLIENT_ID       14013   /* A unique ID for us as a shared memory client. Should be more than 10000 */ 
#define SOCKET_UMASK    0x000	/* Acquisition system UNIX domain socket file must be world-writable */

char *collector_host = "localhost";
int collector_sock = -1;

host_t fieldtrip_host;
int fieldtrip_sock = -1;

int shmem_sock = -1;
int shmem_id = CLIENT_ID;

pthread_t buffer_tid;
int originalMaxBuflen = -1;	
int (*dacq_client_process_tag)() = process_tag;


/* -----------------------------------------------------------------------------
 * Open the collector control connection
 */

int collector_open()
{
  if (collector_sock >= 0) {
    dacq_log("Note: Tried to re-open an open connection\n");
    return(0);
  }
  if ((collector_sock = dacq_server_connect_by_name(collector_host, COLLECTOR_PORT)) == -1) {
    dacq_log("Neuromag collector connection: %s\n", err_get_error());
    return(-1);
  }
  if (dacq_server_login(&collector_sock, COLLECTOR_PASS, "neuromag2ft") == -1) {
    dacq_log("Neuromag collector connection: %s\n", err_get_error());
    return(-1);
  }
  
  return(0);
}


/* -----------------------------------------------------------------------------
 * Close the collector connection
 */

int collector_close()
{
  if (collector_sock < 0)
    return(0);
  if (dacq_server_close(&collector_sock, NULL)) {
    dacq_log("Neuromag collector connection: %s\n", err_get_error());
    return(-1);
  }
  collector_sock = -1;
  return(0);
}


/* -----------------------------------------------------------------------------
 * Query the current buffer length of the Elekta acquisition system
 */

int collector_getMaxBuflen()
{
#define REPLYSIZ 65536

  char *line;
  char buf[REPLYSIZ];
  char var_name[BUFSIZ];
  char var_value[BUFSIZ];
  char var_type[BUFSIZ];
  int maxbuflen = -1;

  sprintf(buf, "%s\n", COLLECTOR_GETVARS);
  if (dacq_server_send(&collector_sock, buf, strlen(buf), DACQ_DRAIN_INPUT) == -1) {
    dacq_log("Neuromag collector connection: %s\n", err_get_error());
    return(-1);
  }

  if (dacq_server_recv(&collector_sock, buf, REPLYSIZ-1, DACQ_REPLY_ASCII | DACQ_REPLY_RFC) == -1) {
    dacq_log("Neuromag collector connection: %s\n", err_get_error());
    return(-1);
  }

  line = strtok(buf, "\n");
  while (line != NULL) {
    /* All lines start with a three-digit code and a space or minus sign. Skip them and parse the rest */
    if (sscanf(line+4, "%s %s %s", var_name, var_value, var_type) == 3) {
      if (!strcmp(var_name, COLLECTOR_BUFVAR)) {
	if (sscanf(var_value, "%d", &maxbuflen) != 1) {
	  dacq_log("Neuromag collector: Misformatted variable line '%s'\n", line);
	  return(-1);
	} else {
	  return(maxbuflen);
	}
      }
    }
    line = strtok(NULL, "\n");
  }
  return(-1);
}


/* --------------------------------------------------------------------
 * Set the desired maximum buffer length
 */

int collector_setMaxBuflen(int maxbuflen)
{
  if (maxbuflen < 1)
    return(0);

  if (dacq_server_command(&collector_sock, "%s %s %d\n", COLLECTOR_SETVARS, COLLECTOR_BUFVAR, maxbuflen) == -1 ||
      dacq_server_command(&collector_sock, "%s\n", COLLECTOR_DOSETUP) == -1) {
    dacq_log("Neuromag collector connection: %s\n", err_get_error());
    return(-1);
  }

  return(0);
}


/* --------------------------------------------------------------------
 * Quit function
 */

void clean_up()
{
  /* Disconnect from the shared memory */
#if defined(DACQ_OLD_CONNECTION_SCHEME)
  if (dacq_disconnect_client(shmem_sock, shmem_id) == -1) {
    dacq_log("Neuromag data server: Could not disconnect!\n");
    exit (1);
  }
  dacq_log("Neuromag data server: Disconnected\n");
#else
  if (dacq_disconnect_client(&shmem_sock, shmem_id) == -1) {
    dacq_log("Neuromag data server: Could not disconnect\n");
  }
#endif

  /* Restore the buffer length and disconnect from the control server */
  if (originalMaxBuflen > 0) {
    dacq_log("Setting maxBuflen back to its original value (%d)...\n", originalMaxBuflen);
    if (collector_setMaxBuflen(originalMaxBuflen))
      dacq_log("Failed to restore the original maxBuflen value\n");
  }
  collector_close();

  /* Disconnect from / terminate the FT buffer */ 
  if (fieldtrip_sock == 0) {
    pthread_cancel(buffer_tid);
    dacq_log("FieldTrip buffer thread cancelled\n");
  } else {
    close_connection(fieldtrip_sock);
    dacq_log("FieldTrip buffer connection closed\n");
  }

}


/* -----------------------------------------------------------------------
 * Handler for user termination
 */

void sigint_handler(int signum)
{
  dacq_log("Terminated by the user\n");
  clean_up();
  dacq_log("Exiting\n");
  exit(1);
}


/* -----------------------------------------------------------------------
 * Command line usage information
 */

void usage(const char *me)
{
  fprintf(stderr, "Usage: %s [--bufhost <hostname>] [--bufport <portnumber>] |--chunksize <#samples>]\n", me);
  exit(1);
}


/* -----------------------------------------------------------------------
 * The main
 */

int main (int argc, char **argv) 
{
  int old_umask;
  int newMaxBuflen = -1;
  struct sigaction sigint_action;
  sigset_t sigmask;
  int arg;
  int remote_buf = 0;

  fieldtrip_host.port = DEFAULT_PORT;

  /* Parse command line arguments */
  for (arg = 1; arg < argc; arg++) {
    if (!strcmp(argv[arg], "--bufhost")) {
      arg++;
      if (arg <= argc - 1) {
	strcpy(fieldtrip_host.name, argv[arg]);
	remote_buf = 1;
      } else {
	fprintf(stderr, "%s: Hostname missing\n", argv[0]);
	usage(argv[0]);
      }
    }
    else if (!strcmp(argv[arg], "--bufport")) {
      arg++;
      if (arg <= argc - 1)
	fieldtrip_host.port = atoi(argv[arg]);
      else {
	fprintf(stderr, "%s: Port number missing\n", argv[0]);
	usage(argv[0]);
      }
    }
    else if (!strcmp(argv[arg], "--chunksize")) {
      arg++;
      if (arg <= argc - 1)
	newMaxBuflen = atoi(argv[arg]);
      else {
	fprintf(stderr, "%s: Neuromag buffer length missing\n", argv[0]);
	usage(argv[0]);
      }
      if (newMaxBuflen < MIN_BUFLEN) {
	fprintf(stderr, "%s: Too small Neuromag buffer length requested, should be at least %d\n", argv[0], MIN_BUFLEN);
	return(1);
      }
    }
    else
      usage(argv[0]);
  }

  /* Initialize logging and error handling */
  err_init_single();
  dacq_log_set_name("neuromag2ft");
  dacq_log_set_time(1);
    
  /* Set up a signal handler to catch control-C presses */
  sigemptyset(&sigmask);
  sigint_action.sa_handler = sigint_handler;
  sigint_action.sa_mask = sigmask;
  sigint_action.sa_flags = 0;
  if (sigaction(SIGINT, &sigint_action, NULL)) {
    dacq_log("Failed to install a signal handler: %s\n", strerror(errno));
    return(1);
  }

  /* Connect to the Elekta Neuromag shared memory system */
  dacq_log("About to connect to the Neuromag DACQ shared memory on this workstation...\n");
  old_umask = umask(SOCKET_UMASK);
  if ((shmem_sock = dacq_connect_client(shmem_id)) == -1) {
    umask(old_umask);
    dacq_log("Could not connect!\n");
    return(2);
  }
  dacq_log("Connection ok\n");

  /* Connect to the Elekta Neuromag acquisition control server and
   * fiddle with the buffer length parameter */
  if (newMaxBuflen > 0) {
    if (collector_open()) {
      dacq_log("Cannot change the Neuromag buffer length: Could not open collector connection\n");
      return(3);
    }
    if ((originalMaxBuflen = collector_getMaxBuflen()) < 1) {
      dacq_log("Cannot change the Neuromag buffer length: Could not query the current value\n");
      collector_close();
      return(3);
    }
    dacq_log("Changing the Neuromag buffer length %d -> %d\n", originalMaxBuflen, newMaxBuflen);
    if (collector_setMaxBuflen(newMaxBuflen)) {
      dacq_log("Setting a new Neuromag buffer length failed\n");
      collector_close();
      return(3);
    }
  }

  /* Connect/create the FieldTrip real-time buffer */
  if (remote_buf) {
    /* The buffer is on a remote host */
    dacq_log("About to connect to a remote FieldTrip buffer on %s...\n", fieldtrip_host.name);
    if ((fieldtrip_sock = open_connection(fieldtrip_host.name, fieldtrip_host.port)) < 0) {
      dacq_log("Error connecting to the buffer. Have you started it? Is there a firewall? Bailing out\n");
      return(4);
    }
    dacq_log("Connection ok\n");
  } else {
    /* We shall be hosting the buffer */
    if (pthread_create(&buffer_tid, NULL, tcpserver, (void *)(&fieldtrip_host))) {
      dacq_log("Failed to start FieldTrip buffer server thread: %s\n", strerror(errno));
      return(4);
    } else
      dacq_log("FieldTrip buffer server thread started\n");
    fieldtrip_sock = 0;
  }
  
  /* Mainloop */
  dacq_log("Waiting for the measurement to start...\n");
  for (;;) {
#if defined(DACQ_OLD_CONNECTION_SCHEME)
    if (dacq_client_receive_tag(shmem_sock, shmem_id) == -1)
#else
    if (dacq_client_receive_tag(&shmem_sock, shmem_id) == -1)
#endif
      break;
  }
  dacq_log("\n");

  /* Clean up and exiting */
  clean_up();
  return(0);
}
