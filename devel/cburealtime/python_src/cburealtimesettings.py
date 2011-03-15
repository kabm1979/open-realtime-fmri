import os
def inport_stim():
	return(6003);
def outport_stim():
	return(6001);
def incomingport_scanner():
	return(6000);
def realtimepath():
	return('/home/stefanh/realtime/scratch/');
def incomingmetapath():
	return(os.path.join(realtimepath(),'incomingmeta'));
	
