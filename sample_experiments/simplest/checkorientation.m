siemenspath='/home/stefanh/realtime/scratch/processed/Phantom20110324a';
siemensseriesoffset=25;
siemensdicompath='/local/sambashare/20110324.Phantom20110324a.11.03.24_17_16_48_STD_1.3.12.2.1107.5.2.32.35435/';
siemensdicomseriesoffset=0;
llpth='/home/stefanh/realtime/scratch/processed/2.0.34902';
llseriesoffset=31;
for orient=1:1
    siemensfn=dir(fullfile(siemenspath,sprintf('*-%04d-00001-*.nii',siemensseriesoffset+orient)));
    siemensV(orient)=spm_vol(fullfile(siemenspath,siemensfn.name));
    siemensdicomfn=dir(fullfile(siemensdicompath,sprintf('*_%06d_*000001.dcm',siemensdicomseriesoffset+orient)));
    siemensD(orient)=spm_dicom_headers(fullfile(siemensdicompath,siemensdicomfn.name));
    siemensorient{orient}=reshape( siemensD{1}.ImageOrientationPatient,[3 2]);
    siemensorient{orient}(:,3)=null(siemensorient{orient}');
    
    llfn=dir(fullfile(llpth,sprintf('*_%04d-00001-*.nii',llseriesoffset+orient)));
    llV(orient)=spm_vol(fullfile(llpth,llfn.name));
    llcburt{orient}=load(fullfile(llpth,sprintf('cburt_series%02d.mat',llseriesoffset+orient)));
    llhdr{orient}=llcburt{orient}.cburt.incoming.series(llseriesoffset+orient).hdr;
end;
    