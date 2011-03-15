#!/usr/bin/python
import os
import cburealtimesettings

# Load up the last stim_ip received
fin=open(os.path.join(cburealtimesettings.incomingmetapath(),'stim_ip.txt'));
stim_ip=fin.readline();
fin.close();

# Communicates with stimulus delivery machine
while (1):
	nccmdfile=os.popen("nc -l -p %d"%cburealtimesettings.inport_stim());
	while (1):
		ncresp=nccmdfile.readline();
		if (len(ncresp)==0):
			break;
		f=ncresp.split(' ');

		print "Received " + ncresp,

		if (f[0]=="HELLO_REALTIME"):
			stim_ip=f[1].strip();

			if (stim_ip.find(".")==-1):
				stim_ip=stim_ip + ".mrc-cbu.cam.ac.uk";

			fout=open(os.path.join(cburealtimesettings.incomingmetapath(),'stim_ip.txt'),'w');
			fout.writelines(stim_ip);
			fout.close();		
				
			# Handshake!
			cmd="echo 'HELLO_STIM' | nc %s %d"%(stim_ip,cburealtimesettings.outport_stim());
			print "Received HELLO_REALTIME, responded with HELLO_STIM"
			os.system(cmd);	

		elif (f[0]=="PARAMETER"):
			if (f[2].strip()!="Number"):
				print "Parameter number absent"
			else:
				trialNumber=int(f[3]);
				
			if (f[4].strip()!="inputParameter"):
				print "Parameter inputParameter absent"
			else:
				inputParameter=float(f[5].strip());

			if (f[6].strip()!="filteredParameter"):
				print "Parameter filteredParameter absent"
			else:
				filteredParameter=float(f[7].strip());
				
				
			if (f[8].strip()!="Contrast"):
				print "Parameter contrast absent"
			else:		
				contrast=float(f[9].strip());
				
			print "Trial " + str(trialNumber) + " inputParameter " + str(inputParameter) + " filteredParameter " + str(filteredParameter) + " contrast " + str(contrast)
		
		
			fout=open(os.path.join(cburealtimesettings.incomingmetapath(),'stimlist.txt'),'a');
			fout.writelines(str(trialNumber) + "\t" + str(inputParameter) + "\t" + str(filteredParameter) + "\t" +str(contrast) +"\n");
			fout.close();
		elif (f[0]=="GOT"):
			fout=open(os.path.join(cburealtimesettings.incomingmetapath(),'whathaveyougot.txt'),'w');
			# a little header to help the watcher check its reading the fully written file... length and a magic number...			
			fout.writelines(str(len(f)+1) + "\n");			
			fout.writelines("1234\n");	
			for item in f[1:]:
				fout.writelines(item + "\n");
			fout.close();		
		elif (f[0]=="PARAMETERFROMSTIM"):
			fout=open(os.path.join(cburealtimesettings.incomingmetapath(),'parameterfromstim_' + f[1] + '.txt'),'w');
			
			fout.writelines(f[2] + "\n");
			fout.writelines('==END==');
			fout.close();	
			# Handshake!
			cmd="echo 'PARAMETERFROMSTIM_RECEIVED' | nc %s %d"%(stim_ip,cburealtimesettings.outport_stim());
			print "Received PARAMETERFROMSTIM, responded with PARAMETERFROMSTIM_RECEIVED"
			os.system(cmd);	
		
	
	
