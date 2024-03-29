/*
 * Copyright (C) 2010, Stefan Klanke
 * Donders Institute for Donders Institute for Brain, Cognition and Behaviour,
 * Centre for Cognitive Neuroimaging, Radboud University Nijmegen,
 * Kapittelweg 29, 6525 EN Nijmegen, The Netherlands
 */
#include <PixelDataGrabber.h>
#include <stdio.h>
#include <math.h>
#include <FolderWatcher.h>

PixelDataGrabber::PixelDataGrabber() : lastName(10) { // keep 10 file names for comparision
	ftbSocket = -1;
	FW = NULL;
	
	phaseFOV = readoutFOV = 0.0;
	samplesWritten = 0;
	lastSampleReported =0;
	readResolution = 0;
	numSlices = 0;
	numEchos = 1;
	curFileIndex = 0;
	filesPerEcho = 1;
	TR = 0;
	lastAction = Nothing;
	protInfo = NULL;
	fwActive = false;
	headerWritten = false;
	verbosity = 1;
	lastNamePos = 0;
	tCreateFirstFile.QuadPart = tCreateLastFile.QuadPart = -1;

	// Queues of files that have changed
	gotprotocol=false;
	gotprotocolthisseries=false;

	
	// Control of which files to use for protocol and whether they must alternate
	protocolFormat=ShadowDataUseLast;
	
	currentSeriesDirectory="";

	char logname[128];
	SYSTEMTIME LT;
	
	GetLocalTime(&LT);
	snprintf(logname, 128, "PixGrabberLog_%04i_%02i_%02i_%02i_%02i_%02i.txt", 
		LT.wYear, LT.wMonth, LT.wDay, LT.wHour, LT.wMinute, LT.wSecond);
		
	logFile = fopen(logname, "w");	
}

PixelDataGrabber::~PixelDataGrabber() {
	fprintf(logFile,"Destroying\n");

	if (FW) delete FW;

	if (ftbSocket > 0) close_connection(ftbSocket);
	sap_destroy(protInfo);
	if (logFile != NULL) fclose(logFile);
}
	
bool PixelDataGrabber::monitorDirectory(const char *directory) {
	if (protInfo) {
		sap_destroy(protInfo);
		protInfo = NULL;
	}
	
	curFileIndex = 0;
	
	if (FW) {
		FW->stopListenForChanges();
		delete FW;
		FW = NULL;
		fwActive = false;
	}
	if (directory == NULL) return false;

	sourceDir = directory;
	int n = sourceDir.size();
	if (n>0) {
		if (sourceDir[n-1]!='\\' && sourceDir[n-1]!='/') sourceDir += '\\';

		FW = new FolderWatcher(directory);
		fwActive = FW->startListenForChanges();
	}

	return fwActive;
}

bool PixelDataGrabber::connectToFieldTrip(const char *hostname, int port) {
	if (ftbSocket > 0) close_connection(ftbSocket);
	if (hostname != NULL) {
		ftbSocket = open_connection(hostname, port);
	} else {
		ftbSocket = -1;
	}
	headerWritten = false;		
	return (ftbSocket > 0);
}
	
int PixelDataGrabber::run(unsigned int ms) {
	lastAction = Nothing;
	if (FW==NULL || !FW->isValid()) {
		if (verbosity>3) fprintf(stderr, "No directory is being monitored.\n");
		return -1;
	}
	
	int numChg = FW->checkHasChanged(ms);

	if (numChg > 0) {
		tryFolderToBuffer();
	}
	return 1;
}


int PixelDataGrabber::getNumWrittenSinceLastReport()
{ 
	int tmp=samplesWritten-lastSampleReported;
	lastSampleReported=samplesWritten;
	return tmp;
}
	
	
bool PixelDataGrabber::writeHeader() {
	FtBufferResponse resp;
	UINT32_T nchans = numSlices*readResolution*phaseResolution;
	float    fsamp  = 1.0e6 / (float) TR;
	
	headerWritten = false;
	
	int otherinfo[4];

	// Record sample number in nifti header
	nifti.toffset= samplesWritten+1;

	if (ftReq.prepPutHeader(nchans, DATATYPE_INT16, fsamp) &&
		ftReq.prepPutHeaderAddChunk(FT_CHUNK_SIEMENS_AP, protBuffer.size(), protBuffer.data()) &&
		ftReq.prepPutHeaderAddChunk(FT_CHUNK_NIFTI1, sizeof(nifti), &nifti)) {
		
		// write the request, read the response
		int result = tcprequest(ftbSocket, ftReq.out(), resp.in());		
	
		if (result < 0) {
			if (verbosity>0) fprintf(stderr, "Communication error when sending header to fieldtrip buffer\n");
			lastAction = TransmissionError;
			return false;
		}
	
		if (!resp.checkPut()) {
			if (verbosity>0) fprintf(stderr, "PUT_HDR: error from buffer server\n");
			lastAction = TransmissionError;
			return false;
		}
		fprintf(logFile,"header written\n");
		headerWritten = true;
		return true;
	} else {
		// one of the prepPutHeader* calls failed
		lastAction = OutOfMemory;
		return false;
	}
}
	
bool PixelDataGrabber::writePixelData() {
	FtBufferResponse resp;
	UINT32_T nchans = numSlices*readResolution*phaseResolution;
	
	if (!ftReq.prepPutData(nchans, 1, DATATYPE_INT16, sliceBuffer.data())) {
		if (verbosity > 0) fprintf(stderr, "Out of memory!\n");
		lastAction = OutOfMemory;
		return false;
	}
	
	/* write the request, read the response */
	int result = tcprequest(ftbSocket, ftReq.out(), resp.in());
		
	if (result < 0) {
		if (verbosity>0) fprintf(stderr, "Communication error when sending pixel data to fieldtrip buffer\n");
		lastAction = TransmissionError;
		return false;
	}
	if (!resp.checkPut()) {
		if (verbosity>0) fprintf(stderr, "PUT_DAT: error from buffer server\n");
		lastAction = TransmissionError;
		return false;
	}
	fprintf(logFile,"pixel data written\n");
	
	// Reset headerWritten field, as we need another before writing any more pixel data
	headerWritten=false;
	return true;
}	
	
bool PixelDataGrabber::writeTimestampEvent(const struct timeval &tv) {
	FtBufferResponse resp;
	char ts[20];
	
	sprintf(ts, "%11li.%06li", tv.tv_sec, tv.tv_usec);
	
	if (!ftReq.prepPutEvent(samplesWritten-1, 0, 0, "unixtime", ts)) {
		if (verbosity>0) fprintf(stderr, "Out of memory!\n");
		lastAction = OutOfMemory;
		return false;
	}

	int result = tcprequest(ftbSocket, ftReq.out(), resp.in());
	
	if (result < 0) {
		if (verbosity>0) fprintf(stderr, "Communication error when sending pixel data to fieldtrip buffer\n");
		lastAction = TransmissionError;
		return false;
	}
	if (!resp.checkPut()) {
		if (verbosity>0) fprintf(stderr, "PUT_EVT: error from buffer server\n");
		lastAction = TransmissionError;
		return false;
	}
	return true;
}

bool PixelDataGrabber::sendFrameToBuffer(const struct timeval &tv) {

// Rhodri: strict alternation of writing headers and data now, so don't allow this
//	if (!headerWritten) {
//		if (!writeHeader()) return false;
//	}
	if (!writePixelData()) return false;
	
	if (logFile != NULL) writeLogMessage(true);
	samplesWritten++;
	lastAction = PixelsTransmitted;
	// if (!writeTimestampEvent(tv)) return false;
	return true;
}

bool PixelDataGrabber::handleProtocol(const char *info, unsigned int sizeInBytes) {
	const sap_item_t *item, *slice0;
	double slicePos[3] = {0, 0, 0};
	double sliceNormal[3] = {0, 0, 0};
	double inPlaneRotation = 0.0;
	double distFactor = 1.0;
	bool haveTrafo = false;
	long ucMode = 1;	
	
	fprintf(logFile,"Ready for sap_parse.\n");
	sap_item_t *PI = sap_parse(info, sizeInBytes);
	fprintf(logFile,"Back from sap_parse.\n");
	
	
	if (PI == NULL) return(false);
	
	tCreateFirstFile.QuadPart = -1;
	
	phaseResolution = readResolution = numSlices = 0;
	phaseFOV = readoutFOV = 0.0;
	
	// new info? replace the old one, if present
	if (protInfo != NULL) {
		sap_destroy(protInfo);
	}
	protInfo = PI;	

	// Prepare NIFTI-1 header by setting everything to zero, and then 
	// filling in some constants (for acquiring pixel data this way)
	memset(&nifti, 0, sizeof(nifti));
	nifti.sizeof_hdr = 348;
	nifti.datatype = DT_INT16;
	nifti.bitpix = 16;
	nifti.scl_slope = 1.0f;
	nifti.xyzt_units = NIFTI_UNITS_MM | NIFTI_UNITS_SEC;
	nifti.magic[0] = 'n';
	nifti.magic[1] = 'i';
	nifti.magic[2] = '1';

	
	// alTR --> repetition time
	item = sap_search_deep(PI, "alTR");
	if (item!=NULL && item->type == SAP_LONG) {
		TR = ((long *) item->value)[0];
		if (logFile != NULL) fprintf(logFile, "TR: %i microsec.\n", TR);
	} else {
		TR = 2000000;
	}
	TR_in_ms = TR * 0.001;
	// TODO: Does the following make sense?
	nifti.pixdim[4] = TR*1e-6f;	// repetition time in seconds 

	// lContrasts --> number of echos
	item = sap_search_deep(PI, "lContrasts");
	if (item!=NULL && item->type == SAP_LONG) {
		numEchos = ((long *) item->value)[0];
		if (logFile != NULL) fprintf(logFile, "Multi-echo: %i\n", numEchos);
	} else {
		numEchos = 1;
	}		
	
	// ucReconstructionMode --> single or two files per echo?
	// From the IDEA documentation:
	//  1 -> Single magnitude image
	//  2 -> Single phase image
	//  4 -> Real part only (single image)
	//  8 -> Magnitude+phase image (we need to skip the phase)
	// 10 -> Real part+phase (we need to skip the phase)
	// 20 -> PSIR (also need to skip every second image)
	item = sap_search_deep(PI, "ucReconstructionMode");
	if (item!=NULL && item->type == SAP_LONG) {
		long reconMode = ((long *) item->value)[0];
		filesPerEcho = (reconMode >= 8) ? 2 : 1;
		if (logFile != NULL) fprintf(logFile, "Reconstruction mode: %i\n", (int) reconMode);
	} else {
		filesPerEcho = 1;
	}			
	
	// sKSpace.lBaseResolution => number of pixels in readout direction
	item = sap_search_deep(PI, "sKSpace.lBaseResolution");
	if (item!=NULL && item->type == SAP_LONG) {
		long res = *((long *) item->value);
		readResolution = (res > 0) ? res : 0;
	}
	
	// sSliceArray.lSize => number of slices
	item = sap_search_deep(PI, "sSliceArray.lSize");
	if (item!=NULL && item->type == SAP_LONG) {
		long slices = *((long *) item->value);
		numSlices = (slices > 0) ? slices : 0;
	}
	
	// Set NIFTI fields depending on #slices and TR
	if (numSlices > 0) {
		nifti.dim[3] = (short) numSlices;
		nifti.slice_start = 0;
		nifti.slice_end = (short) numSlices-1;
		nifti.slice_duration = (TR/numSlices)*1e-6f;	// in seconds
	}
	
	// sGroupArray.asGroup[0].dDistFact => distance factor (gap between slices)
	item = sap_search_deep(PI, "sGroupArray.asGroup[0].dDistFact");
	if (item!=NULL && item->type == SAP_DOUBLE) {
		// Siemens stores this as the factor between gap size + slice thickness
		// "distFactor" here is the factor between slice distance + slice thickness
		// 1.0 = default = no gap
		distFactor = 1.0 + *((double *) item->value);
	}
		
	// sSliceArray.ucMode => ordering of slices
	item = sap_search_deep(PI, "sSliceArray.ucMode");
	if (item!=NULL && item->type == SAP_LONG) {
		ucMode = *((long *) item->value);
	}
	// Convert ucMode to NIFTI field
	switch(ucMode) {
		case 1:
			nifti.slice_code = NIFTI_SLICE_SEQ_INC;
			break;
		case 2:
			nifti.slice_code = NIFTI_SLICE_SEQ_DEC;
			break;
		case 4:
			// in case of an odd number of slices, start at zero (ALT), 
			// otherwise slice[1] (=second!) has been acquired first (ALT2)
			nifti.slice_code = (numSlices & 1) ? NIFTI_SLICE_ALT_INC : NIFTI_SLICE_ALT_INC2;
			break;
	}
		
	// Have slice0 point to sub-structure encoding the first slice
	slice0 = sap_search_deep(PI, "sSliceArray.asSlice");
	// Not found, or not a struct - we can't do anything more
	if (slice0 == NULL || slice0->type != SAP_STRUCT) return(false);

	// -------------------------------------------------------------------------------------
	// From here on it's specific to info from sliceArray.asSlice[0] 
	// -------------------------------------------------------------------------------------	
	slice0 = ((const sap_item_t **) slice0->value)[0];
	
	// sSliceArray.asSlice[0].dPhaseFOV => field of view in phase (Y) direction
	item = sap_search_deep(slice0, "dPhaseFOV");
	if (item!=NULL && item->type == SAP_DOUBLE) {
		phaseFOV = *((double *) item->value);
		if (logFile != NULL) fprintf(logFile, "PhaseFOV: %f\n", phaseFOV);
	}

	// sSliceArray.asSlice[0].dPhaseFOV => field of view in readout (X) direction
	item = sap_search_deep(slice0, "dReadoutFOV");
	if (item!=NULL && item->type == SAP_DOUBLE) {
		readoutFOV = *((double *) item->value);
		if (logFile != NULL) fprintf(logFile, "ReadoutFOV: %f\n", readoutFOV);
	}

	if (phaseFOV > 0.0 && readoutFOV > 0.0) {
		phaseResolution = (unsigned int) round(readResolution * phaseFOV / readoutFOV);
	}
	if (logFile != NULL) fprintf(logFile, "Resolution: %i x %i x %i\n", readResolution, phaseResolution, numSlices);
	item = sap_search_deep(slice0, "lRepetitions");
	if (item!=NULL && logFile != NULL) fprintf(logFile, "Repetition: %d\n",*((int*) item->value));

	// Fill in the resolution- and FOV-dependent NIFTI fields
	nifti.dim[0] = 3;
	nifti.dim[1] = (short) readResolution;
	nifti.dim[2] = (short) phaseResolution;
	nifti.pixdim[0] = -1.0f; // this is qfac
	nifti.pixdim[1] = (float) (readoutFOV / readResolution);
	nifti.pixdim[2] = (float) (phaseFOV / phaseResolution);

	item = sap_search_deep(slice0, "dThickness");
	if (item!=NULL && item->type == SAP_DOUBLE) {
		double thick = *((double *) item->value);
		nifti.pixdim[3] = (float) (thick * distFactor);
	}

	// sSliceArray.asSlice[0].sPosition.d[Sag|Cor|Tra] encode slice position X/Y/Z
	item = sap_search_deep(slice0, "sPosition.dSag");
	if (item!=NULL && item->type == SAP_DOUBLE) {
		slicePos[0] = *((double *) item->value);
	}	
	item = sap_search_deep(slice0, "sPosition.dCor");
	if (item!=NULL && item->type == SAP_DOUBLE) {
		slicePos[1] = (float) *((double *) item->value);
	}	
	item = sap_search_deep(slice0, "sPosition.dTra");
	if (item!=NULL && item->type == SAP_DOUBLE) {
		slicePos[2] = (float) *((double *) item->value);
	}	

	// sSliceArray.asSlice[0].sNormal.d[Sag|Cor|Tra] encode slice normal vector X/Y/Z
	item = sap_search_deep(slice0, "sNormal.dSag");
	if (item!=NULL && item->type == SAP_DOUBLE) {
		sliceNormal[0] = *((double *) item->value);
		haveTrafo = true;
	}	
	item = sap_search_deep(slice0, "sNormal.dCor");
	if (item!=NULL && item->type == SAP_DOUBLE) {
		sliceNormal[1] = *((double *) item->value);
		haveTrafo = true;
	}	
	item = sap_search_deep(slice0, "sNormal.dTra");
	if (item!=NULL && item->type == SAP_DOUBLE) {
		sliceNormal[2] = *((double *) item->value);
		haveTrafo = true;
	}	
	// sSliceArray.asSlice[0].dInPlaneRot => in-plane-rotation of slice (around normal)
	item = sap_search_deep(slice0, "dInPlaneRot");
	if (item!=NULL && item->type == SAP_DOUBLE) {
		inPlaneRotation = *((double *) item->value);
	}	
	
	if (haveTrafo) fillXFormFromSAP(slicePos, sliceNormal, inPlaneRotation);
	return(true);
}

void PixelDataGrabber::fillXFormFromSAP(const double *pos, const double *norm, double inPlane) {
	double ax = fabs(norm[0]);
	double ay = fabs(norm[1]);
	double az = fabs(norm[2]);
	double Rx[3], Ry[3], Rz[3], Vx[3], Vy[3];
	const char *letters = "XXX";
	double angA, angB;
	
	// Note subtle differences between usage of > and >=
	// this was reverse-engineered from Siemens POET behaviour
	if (az >= ay) {
		if (ay >= ax) {
			// az >= ay >= ax
			letters = "TCS";
			// look at smallest element in normal to determine rot. angle B
			angB = asin(norm[0]);
			// look at other two elements to get the other rotation angle
			angA = atan2(norm[1], norm[2]);
	
			double ca = cos(angA);
			double sa = sin(angA);
			double cb = cos(angB);
			double sb = sin(angB);	// == norm[0]
			
			Rx[0] = cb;		Ry[0] = 0;		Rz[0] = sb;
			Rx[1] = -sa*sb;	Ry[1] = ca;		Rz[1] = sa*cb;
			Rx[2] = -ca*sb;	Ry[2] = -sa;	Rz[2] = ca*cb;
		} else if (az>=ax) {
			// az >= ax > ay
			letters = "TSC";
			angB = asin(norm[1]);
			angA = atan2(norm[0], norm[2]);
			
			double ca = cos(angA);
			double sa = sin(angA);
			double cb = cos(angB);
			double sb = sin(angB);	// == norm[1]
		
			Rx[0] = ca;		Ry[0] = -sa*sb;	Rz[0] = sa*cb;
			Rx[1] = 0;		Ry[1] = cb;		Rz[1] = sb;
			Rx[2] = -sa;	Ry[2] = -ca*sb;	Rz[2] = ca*cb;
		} else {
			// ax > az >= ay
			letters = "STC";
			angB = asin(norm[1]);
			angA = atan2(norm[2], norm[0]);
	
			double ca = cos(angA);
			double sa = sin(angA);
			double cb = cos(angB);
			double sb = sin(angB);

			Rx[0] = -sb; Ry[0] = sa*cb;		Rz[0] = ca*cb;
			Rx[1] = -cb;     Ry[1] = -sa*sb;  Rz[1] = sb*ca;
			Rx[2] = 0;      Ry[2] = ca;    Rz[2] = -sa;

//			Rx[0] = sa;		Ry[0] = -ca*sb;	Rz[0] = cb*ca;
//			Rx[1] = 0;		Ry[1] = cb;		Rz[1] = sb;
//			Rx[2] = -ca;	Ry[2] = -sa*sb;	Rz[2] = sa*cb;		
		}
	} else {
		if (ax > ay) {
			// ax > ay > az
			letters = "SCT";
			angB = asin(norm[2]);
			angA = atan2(norm[1], norm[0]);
			
			double ca = cos(angA);
			double sa = sin(angA);
			double cb = cos(angB);
			double sb = sin(angB);
			
			Rx[0] = ca*sb;	Ry[0] = -sa;	Rz[0] = ca*cb;
			Rx[1] = sa*sb;	Ry[1] = ca;		Rz[1] = sa*cb;
			Rx[2] = -cb;	Ry[2] = 0;		Rz[2] = sb;
		} else if (ax > az) {
			// ay > ax > az)
			letters = "CST";
			angB = asin(norm[2]);
			angA = atan2(norm[0], norm[1]);
			
			double ca = cos(angA);
			double sa = sin(angA);
			double cb = cos(angB);
			double sb = sin(angB);
 
			Rx[0] = -sa*sb;	Ry[0] = ca;		Rz[0] = sa*cb;
			Rx[1] = -ca*sb;	Ry[1] = -sa;	Rz[1] = ca*cb;
			Rx[2] = cb;		Ry[2] = 0;		Rz[2] = sb;
		} else {
			// ay > az >= ax
			letters = "CTS";
			angB = asin(norm[0]);
			angA = atan2(norm[2], norm[1]);
			
			double ca = cos(angA);
			double sa = sin(angA);
			double cb = cos(angB);
			double sb = sin(angB);
			
			Rx[0] = 0;		Ry[0] = cb;		Rz[0] = sb;
			Rx[1] = -sa;	Ry[1] = -sb*ca;	Rz[1] = cb*ca;
			Rx[2] = cb;		Ry[2] = -sb*sa;	Rz[2] = cb*sa;
		}
	}
	
	if (inPlane == 0.0) {
		for (int i=0;i<3;i++) {
			Vx[i] = Rx[i];
			Vy[i] = Ry[i];
		}
	} else {
		double cip = cos(inPlane);
		double sip = sin(inPlane);
		
		for (int i=0;i<3;i++) {
			Vx[i] = cip*Rx[i] - sip*Ry[i];
			Vy[i] = sip*Rx[i] + cip*Ry[i];
		}
	}
	
	if (logFile != NULL) {
		double pex = fabs(Vy[0]);
		double pey = fabs(Vy[1]);
		double pez = fabs(Vy[2]);
		
		if (pez >= pey && pez >= pex) {
			// z is dominant
			if (Vy[2] > 0) {
				fprintf(logFile, "F >> H\n");
			} else {
				fprintf(logFile, "H >> F\n");
			}
		} else if (pey > pez && pey >= pex) {
			// y is dominant
			if (Vy[1] > 0) {
				fprintf(logFile, "A >> P\n");
			} else {
				fprintf(logFile, "P >> A\n");
			}
		} else {
			// x is dominant
			if (Vy[0] > 0) {
				fprintf(logFile, "R >> L\n");
			} else {
				fprintf(logFile, "L >> R\n");
			}
		}
		
		// this should print something similar to the way the slice orientation is defined in POET
		fprintf(logFile, "POET definition:\n%c > %c %.1f > %c %.1f\n", letters[0], letters[1], -angA*180.0/M_PI, letters[2], -angB*180.0/M_PI);
		fprintf(logFile, "\nParsed normal vector versus calculated version (should be equal):\n");
		fprintf(logFile, "%f  %f\n%f  %f\n%f  %f\n", norm[0], Rz[0], norm[1], Rz[1], norm[2], Rz[2]);
	
		fprintf(logFile, "\nReadout direction and phase encoding direction:\n");
		fprintf(logFile, "%f  %f\n%f  %f\n%f  %f\n", Vx[0], Vy[0], Vx[1], Vy[1], Vx[2], Vy[2]);
	}
	
	double Pos0[3];
	// Calculate position of voxel (0,0,0)
	// Input 'pos' is center of slice 0, so we need to 
	// subtract half readoutFOV + phaseFOV along proper directions 
	for (int i=0;i<3;i++) {
		Pos0[i] = pos[i] - 0.5*readoutFOV*Vx[i] - 0.5*phaseFOV*Vy[i];
	}
	// Slice orientation + position matrix in DICOM format:
	// (Vx Vy Rz Vp)      -- Vz=Rz (same axis)
	// (0  0  0  1 )
	
	// In NIFTI-1 format, a different convention is used
	// The rotation part of the above matrix becomes
	// -Vx[0]  Vy[0] -Rz[0]
	// -Vx[1]  Vy[1] -Rz[1]
	//  Vx[2] -Vy[2]  Rz[2]
	
	// A bit unclear from the NIFTI standard: Should only one of these two methods be used?
	nifti.sform_code = NIFTI_XFORM_SCANNER_ANAT;
	nifti.qform_code = 0; // NIFTI_XFORM_SCANNER_ANAT; -- TODO: think about this again
	
	// NIFTI standard says the SFORM matrix should include pixdim scaling
	nifti.srow_x[0] = -Vx[0]*nifti.pixdim[1];
	nifti.srow_y[0] = -Vx[1]*nifti.pixdim[1];
	nifti.srow_z[0] =  Vx[2]*nifti.pixdim[1];
	
	nifti.srow_x[1] =  Vy[0]*nifti.pixdim[2];
	nifti.srow_y[1] =  Vy[1]*nifti.pixdim[2];
	nifti.srow_z[1] = -Vy[2]*nifti.pixdim[2];
	
	nifti.srow_x[2] = -Rz[0]*nifti.pixdim[3];
	nifti.srow_y[2] = -Rz[1]*nifti.pixdim[3];
	nifti.srow_z[2] =  Rz[2]*nifti.pixdim[3];
	
	double offY = phaseFOV - nifti.pixdim[2];  // ==phaseResolution*pixdim[2]
	nifti.srow_x[3] = -Vy[0]*offY - Pos0[0];
	nifti.srow_y[3] = -Vy[1]*offY - Pos0[1];
	nifti.srow_z[3] =  Vy[2]*offY + Pos0[2];
	
	/*
	// Quaternion from matrix -- see nifti1.h
	// Rotation matrix is composed from columns, R=(Vx Vy Rz)
    // a = 0.5  * sqrt(1+R11+R22+R33)    (not stored)
	double a = 0.5 * sqrt(1.0 + Vx[0] + Vy[1] + Rz[2]);
	// b = 0.25 * (R32-R23) / a       => quatern_b
	nifti.quatern_b = 0.25 * (Vy[2] - Rz[1]) / a;
	// c = 0.25 * (R13-R31) / a       => quatern_c
	nifti.quatern_c = 0.25 * (Rz[0] - Vx[2]) / a;
    // d = 0.25 * (R21-R12) / a       => quatern_d
	nifti.quatern_c = 0.25 * (Vx[1] - Vy[0]) / a;
	*/
}

bool PixelDataGrabber::tryReadFile(const char *filename, SimpleStorage &sBuf, bool checkAge) {
	HANDLE fHandle;
	LARGE_INTEGER creationThisFile;
	
	// Wait if the file can't be opened- it may be in the middle of being written
	for(int i=0; i<200; i++)
	{
		fHandle = CreateFile(filename, GENERIC_READ, 0 , NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
		if (fHandle != INVALID_HANDLE_VALUE)
			break;
		Sleep(5);
	};
	
	// 
	if (fHandle != INVALID_HANDLE_VALUE) {
		DWORD read, size;
		FILETIME fileTime;
		
		GetFileTime(fHandle, &fileTime, NULL, NULL);
		creationThisFile.LowPart  = fileTime.dwLowDateTime;
		creationThisFile.HighPart = fileTime.dwHighDateTime;
		
		if (checkAge && (creationThisFile.QuadPart <= tCreateLastFile.QuadPart)) {
			if (logFile!=NULL) fprintf(logFile,"Warning: file %s is older than another we've read - ignoring\n", filename);
			CloseHandle(fHandle);
			return false;
		}
			
		size = GetFileSize(fHandle, NULL);  // ignore higher DWORD - our files are not that big
		
		if (!sBuf.resize(size)) {
			if (logFile!=NULL) fprintf(logFile, "Out of memory in tryReadFile !!!\n"); 
			if (verbosity>0) fprintf(stderr, "Out of memory in tryReadFile !!!\n");
			CloseHandle(fHandle);
			return false;
		}
			
		ReadFile(fHandle, sBuf.data(), size, &read, NULL);
		CloseHandle(fHandle);
				
		if (size==read) {
			tCreateLastFile = creationThisFile;
			
			GetSystemTimeAsFileTime(&fileTime);
			tAccessLastFile.LowPart  = fileTime.dwLowDateTime;
			tAccessLastFile.HighPart = fileTime.dwHighDateTime;	
			if (logFile!=NULL) fprintf(logFile, "Got data from disk.\n"); 
			return true;
		}

		if (logFile!=NULL) fprintf(logFile, "Error reading file contents from disk.\n"); 
		if (verbosity>0) fprintf(stderr, "Error reading file contents from disk.\n");
		sBuf.resize(read);
	}
	else
		if (logFile!=NULL) fprintf(logFile, "Invalid file handle for %s.\n",filename); 
	return false;
}


bool PixelDataGrabber::tryReadProtocol() {
	std::string defProtFile = sourceDir + "mrprot.txt";
	
	if (!tryReadFile(defProtFile.c_str(), protBuffer, false)) return false;
	
	return(handleProtocol((char *) protBuffer.data(), protBuffer.size()));
}


void PixelDataGrabber::tryFolderToBuffer() {
	const std::vector<std::string>& vfn = FW->getFilenames();
	
	// Major chages by Rhodri Cusack March 2011
	// Do the following
	//  (1) Scan for pixeldata, shadowdata (and myprot.txt) files and add them to queues protocolq and pixeldataq
	//  (2) When item in both queues, pull one from each and send data through

	
	fprintf(logFile,"Protocol q size %d and pixel data q size %d, waiting files %d\n",protocolq.size(),pixeldataq.size(),vfn.size());

	for (unsigned int i=0;i<vfn.size();i++) {
	
		
		fullName = sourceDir + vfn[i];
		fprintf(logFile,"Iteration %d got %s\n",i,fullName.c_str());

		// New series? Get from directory
		std::string thisSeriesDirectory=vfn[i].substr( 0,vfn[i].rfind( "\\" ) );
		std::string currentSeriesDirectory_Parent=currentSeriesDirectory.substr( 0, currentSeriesDirectory.rfind( "\\" ) );
		if ((thisSeriesDirectory.compare(currentSeriesDirectory)!=0) && (thisSeriesDirectory.compare(currentSeriesDirectory_Parent)!=0))
		{
			currentSeriesDirectory=thisSeriesDirectory;
			if (logFile!=NULL) { fprintf(logFile,"New series directory %s\n",thisSeriesDirectory.c_str()); fflush(logFile);};
			
			// No protocol so far this series
			gotprotocol=false;
			gotprotocolthisseries=false;
			writtenheaderthisseries=false;

			samplesWritten = 0;
			lastSampleReported =0;
			protocolFormatThisSeries=protocolFormat;
			// If auto mode, start by trying for one protocol file per image. If this fails and the images pile up it will switch strategy
			if (protocolFormatThisSeries==ShadowDataAuto) {
				protocolFormatThisSeries=ShadowDataUseOnce;
				if (logFile!=NULL) { fprintf(logFile,"Mode ShadowDataAuto\n"); fflush(logFile);};
			};
		};

		// Now process, depending on kind of data
		// both .PixelData and "mrprot.txt" are at least 10 characters long
		if (vfn[i].size() < 10) continue;

		if (((protocolFormatThisSeries!=MrProtUseLast) && !((protocolFormatThisSeries==ShadowDataUseLast) && gotprotocolthisseries) && (vfn[i].compare(vfn[i].size()-10,10, "ShadowData") == 0)) || 
			((protocolFormatThisSeries==MrProtUseLast) && (vfn[i].compare(vfn[i].size()-10,10, "mrprot.txt") == 0))) {
			// first, check if this modification in the monitored directory
			// really corresponds to a new file
			boolean newFile = true;
			for (unsigned int k=0;k<lastName.size();k++) {
				if (lastName[k] == fullName) {
					printf("Warning: another change on file %s detected - ignoring\n", fullName.c_str());
					newFile = false;
					break;
				}
			}

			if (newFile) {
				if (logFile != NULL) {
					fprintf(logFile,"Queuing protocol %s\n",fullName.c_str());
					fflush(logFile);
				};

				// Add to a queue of waiting protocol files
				protocolq.push_back(fullName);
				// add current file name to ring buffer of processed names
				// just overwrite old entries if buffer wraps around
				lastName[lastNamePos] = fullName;
				if (++lastNamePos == lastName.size()) lastNamePos = 0;

			}
		
		} 
		else if (vfn[i].compare(vfn[i].size()-10,10, ".PixelData") == 0) {
			
			// first, check if this modification in the monitored directory
			// really corresponds to a new file
			boolean newFile = true;
			for (unsigned int k=0;k<lastName.size();k++) {
				if (lastName[k] == fullName) {
					printf("Warning: another change on file %s detected - ignoring\n", fullName.c_str());
					newFile = false;
					break;
				}
			}
			if (newFile) {
				if (logFile != NULL) {
					fprintf(logFile,"Queuing pixel data %s\n",fullName.c_str());
					fflush(logFile);
				};

				// Add to a queue of waiting pixeldata files
				pixeldataq.push_back(fullName);
				// add current file name to ring buffer of processed names
				// just overwrite old entries if buffer wraps around
				lastName[lastNamePos] = fullName;
				if (++lastNamePos == lastName.size()) lastNamePos = 0;
			}
		};
	};

	// 
	// (2) Process, if something in both pixel and protocol queues
	//
	struct timeval tv;
	gettimeofday(&tv, NULL);
	
	// Carry on trying protocol files until we get one that contains a valid header
	while(protocolq.size()) {
		if (logFile != NULL) {
			fprintf(logFile,"Now attempting to parse protocol\n");
			fflush(logFile);
		};
		if (!tryReadFile(protocolq.front().c_str(), protBuffer, false)) {
			fprintf(logFile,"Error reading protocol\n");
			fflush(logFile);
			break;
		};

		protocolq.pop_front();
		
		if (handleProtocol((char *) protBuffer.data(), protBuffer.size())) {
			if (logFile != NULL) {
				fprintf(logFile,"Target protocol found\n");
				fflush(logFile);
			};
			gotprotocol=true;
			gotprotocolthisseries=true;
			strcpy(nifti.descrip,currentSeriesDirectory.c_str());
			break;
		};
	};

	// If we're in auto mode, then as soon as the number of pixeldatas goes larger than 1, switch to ShadowDataUseLast
	//   where it doesn't need a separate protocol for every image (e.g., MPRAGE)
	if ((protocolFormat==ShadowDataAuto) && (protocolFormatThisSeries!=ShadowDataUseLast)) {
		if (pixeldataq.size()>1) {
			if (logFile!=NULL) { fprintf(logFile,"ShadowDataAuto - change mode to ShadowDataUseLast\n"); fflush(logFile);};
			protocolFormatThisSeries=ShadowDataUseLast;
			gotprotocol=gotprotocolthisseries;
		};
	};

	// Check for pixeldata if we have a valid protocol
	while(gotprotocol && pixeldataq.size()) 
	{
		if (logFile != NULL) {
			fprintf(logFile,"Parsing pixel data %s\n",pixeldataq.front().c_str());
			fflush(logFile);
		};
		bool goterror=false;
		if (!writtenheaderthisseries) {
			// Write header to fieldtrip buffer
			if (ftbSocket != -1) writeHeader();
			curFileIndex = 0;
			writtenheaderthisseries=true;
		}

		// Read in pixeldata
		if (!tryReadFile(pixeldataq.front().c_str(), pixBuffer, false)) {
			fprintf(logFile,"Error reading pixeldata\n");
			fflush(logFile);
			goterror=true;
		};

		pixeldataq.pop_front();
		
		if (!goterror) {
			if (curFileIndex == 0) 
				reshapeToSlices();
			else if (filesPerEcho==1 || (curFileIndex & 1) == 0) 
					addEchoToSlices();
			if (sliceBuffer.size()!=0)
			{
				if  (tCreateFirstFile.QuadPart == -1) 
					tCreateFirstFile = tCreateLastFile;
			
				if (logFile != NULL) writeLogMessage(false);
				curFileIndex++;

				if (curFileIndex == filesPerEcho * numEchos) {
					if (ftbSocket != -1) sendFrameToBuffer(tv);
					curFileIndex = 0;
				};
			};
		};
		// If only using each protocol file once, then don't accept any more pixeldatas
		if (protocolFormatThisSeries==ShadowDataUseOnce)
			gotprotocol=false;
	};
}


void PixelDataGrabber::writeLogMessage(bool sentOut) {
	
	int dt_file = (int) ((tCreateLastFile.QuadPart - tCreateFirstFile.QuadPart)/10000L);
	double dt_file_in_TR = (double) dt_file / TR_in_ms;
	int dt_fileproc = (int) ((tAccessLastFile.QuadPart - tCreateLastFile.QuadPart)/10000L);
	
	if (sentOut) {
		FILETIME fileTime;
		LARGE_INTEGER tDone;
	
		GetSystemTimeAsFileTime(&fileTime);
		tDone.LowPart  = fileTime.dwLowDateTime;
		tDone.HighPart = fileTime.dwHighDateTime;	
	
		int dt_stream = (int) ((tDone.QuadPart - tCreateLastFile.QuadPart)/10000L);
		
		// sample index, dt_file_creation, dt_fileproc, dt_file_creation in TR, dt_stream, dt_streamproc, dt_stream_in_TR
		fprintf(logFile, "%4i %2i  %8i %6i %8.3f  # streaming took %i ms\n", 
					samplesWritten, -1,
					dt_file, dt_fileproc, dt_file_in_TR, 
					dt_stream);
	} else {
		// sample index, dt_file_creation, dt_fileproc, dt_file_creation in TR, curFileIndex, file name
		fprintf(logFile, "%4i %2i  %8i %6i %8.3f  # %s\n", 
					samplesWritten, curFileIndex,
					dt_file, dt_fileproc, dt_file_in_TR, 
					fullName.c_str());
	}
	fflush(logFile);
}


void PixelDataGrabber::reshapeToSlices() {
	unsigned int pixels = pixBuffer.size() >> 1;
	unsigned int root   = (unsigned int) round(sqrt(pixels));
	
	if (readResolution == 0 || phaseResolution == 0 || numSlices == 0) {
		// if for some reason we don't have proper protocol information,
		// we just spit out square images (one slice)
		if (root*root != pixels) {
			// source image not square? don't know what to do
			sliceBuffer.resize(0);
			lastAction = BadPixelData;
		} else	{
			readResolution = phaseResolution = root;
			numSlices = 1;
			if (sliceBuffer.resize(pixels*sizeof(INT16_T))) {
				memcpy(sliceBuffer.data(), pixBuffer.data(), pixels*sizeof(INT16_T));
			} else {
				if (verbosity>0) fprintf(stderr, "Out of memory in reshapeToSlices !!!\n");
				sliceBuffer.resize(0);
				lastAction = OutOfMemory;
			}
		}
	} else {
		unsigned int tiles  = pixels / (readResolution * phaseResolution);
		unsigned int mosw = (unsigned int) round(sqrt(tiles));
		fprintf(logFile,"Pixels %d tiles %d  mosw %d  read res %d  phase res %d  numSlices %d\n",pixels,tiles,mosw,readResolution,phaseResolution,numSlices);
		fflush(logFile);
		if ((pixels != readResolution * phaseResolution * tiles) || (mosw*mosw != tiles) || (numSlices > tiles)) {
			// mosaic does not match readResolution, or is too small - do nothing...
			if (verbosity>0) fprintf(stderr, "PixelData (%i) does not match protocol information (%i x %i x %i)\n",pixels,readResolution,phaseResolution,numSlices);
			sliceBuffer.resize(0);
			lastAction = BadPixelData;
		} else if (!sliceBuffer.resize(readResolution*phaseResolution*numSlices*sizeof(INT16_T))) {
			if (verbosity>0) fprintf(stderr, "Out of memory in reshapeToSlices !!!\n");
			sliceBuffer.resize(0);
			lastAction = OutOfMemory;
		} else {
			const int16_t *src	= (const int16_t *) pixBuffer.data();
			int16_t *dest   	= (int16_t *) sliceBuffer.data();
			
			// row and column in source mosaic
			unsigned int i = 0, j = 0;
			
			for (unsigned int n=0; n<numSlices; n++) {
				int16_t *dest_n = dest + readResolution*phaseResolution*n;
				const int16_t *src_n = src + readResolution*(phaseResolution*mosw*i + j);
				
				// copy one line (=readResolution pixels) at a time
				for (unsigned int m=0; m<phaseResolution; m++) {
					int off_m = readResolution*(phaseResolution-1-m);	// flip along phase direction !
					memcpy(dest_n + off_m, src_n + mosw*readResolution*m, sizeof(INT16_T) * readResolution);
				}
				
				// increase source column index
				if (++j == mosw) {
					// and shift to next row eventually
					++i;
					j = 0;
				}
			}
		}
	}
}


void PixelDataGrabber::addEchoToSlices() {
	// In contrast to reshapeToSlices, this is only called when 
	// a) we have protocol information (otherwise we wouldn't know about echos and
	// b) the sliceBuffer is already big enough
	unsigned int pixels = pixBuffer.size() >> 1;
	unsigned int tiles  = pixels / (readResolution * phaseResolution);
	unsigned int mosw   = (unsigned int) round(sqrt(tiles));
		
	if ((pixels != readResolution * phaseResolution * tiles) || (mosw*mosw != tiles) || (numSlices > tiles)) {
		// mosaic does not match readResolution, or is too small - do nothing...
		if (verbosity>0) fprintf(stderr, "PixelData (%i) does not match protocol information (%i x %i x %i)\n",pixels,readResolution,phaseResolution,numSlices);
		sliceBuffer.resize(0);
		lastAction = BadPixelData;
	} else {
		const int16_t *src	= (const int16_t *) pixBuffer.data();
		int16_t *dest   	= (int16_t *) sliceBuffer.data();
			
		// row and column in source mosaic
		unsigned int i = 0, j = 0;
			
		for (unsigned int n=0; n<numSlices; n++) {
			int16_t *dest_n = dest + readResolution*phaseResolution*n;
			const int16_t *src_n = src + readResolution*(phaseResolution*mosw*i + j);
				
			// add one line (=readResolution pixels) at a time
			for (unsigned int m=0; m<phaseResolution; m++) {
				int16_t      *dest_mn = dest_n + readResolution*(phaseResolution-1-m);	// flip along phase direction !
				const int16_t *src_mn = src_n  + m*mosw*readResolution;
			
				for (unsigned int v=0; v<readResolution; v++) {
					dest_mn[v] += src_mn[v];
				}
			}
				
			// increase source column index
			if (++j == mosw) {
				// and shift to next row eventually
				++i;
				j = 0;
			}
		}
	}
}
