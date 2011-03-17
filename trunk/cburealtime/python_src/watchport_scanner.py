#!/usr/bin/python
import os
import cburealtimesettings

if (not os.path.exists(cburealtimesettings.realtimepath())):
	os.mkdir(cburealtimesettings.realtimepath());
if (not os.path.exists(cburealtimesettings.incomingmetapath())):
	os.mkdir(cburealtimesettings.incomingmetapath());

while (1):
	lastseriesfn=os.path.join(cburealtimesettings.incomingmetapath(),"lastseries.txt");
	try:
		f=open(lastseriesfn,"r");
		ind=int(f.readline());
		f.close();
	except:
		ind=1;
	
	fileexists=1;
	while(fileexists):
		fn=os.path.join(cburealtimesettings.incomingmetapath(),"series%06d.txt"%ind);
		if (os.path.exists(fn)):
			ind=ind+1;
		else:
			break;
				
	print "Next file %s"%fn
	
	firstwrite=1;
	nccmdfile=os.popen("nc -l -p %d"%cburealtimesettings.incomingport_scanner());
	while (1):
		ncresp=nccmdfile.readline();
		if (firstwrite):
			f=open(lastseriesfn,"w");
			f.write("%d"%ind);
			f.close();
			firstwrite=0;			
		outfile=open(fn,"a");
		if (len(ncresp)==0):
			break;
		outfile.write(ncresp),
		outfile.close();
		print "Received " + ncresp,
		

	
	
