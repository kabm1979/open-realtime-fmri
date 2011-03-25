siemenspath='/home/stefanh/realtime/scratch/processed/Phantom20110325';
siemensseriesoffset=8;
siemensdicompath='/local/sambashare/20110325.Phantom20110325.11.03.25_09_26_08_STD_1.3.12.2.1107.5.2.32.35435/';
siemensdicomseriesoffset=8;
llpth='/home/stefanh/realtime/scratch/processed/2.0.34902';
llseriesoffset=50;
for orient=1:7
    siemensfn=dir(fullfile(siemenspath,sprintf('*-%04d-00001-*.nii',siemensseriesoffset+orient)));
    siemensV(orient)=spm_vol(fullfile(siemenspath,siemensfn.name));
    siemensdicomfn=dir(fullfile(siemensdicompath,sprintf('*_%06d_*000001.dcm',siemensdicomseriesoffset+orient)));
    siemensD(orient)=spm_dicom_headers(fullfile(siemensdicompath,siemensdicomfn.name));
    siemensorient{orient}=reshape( siemensD{orient}.ImageOrientationPatient,[3 2]);
    siemensorient{orient}(:,3)=null(siemensorient{orient}');
    
    
    llfn=dir(fullfile(llpth,sprintf('*_%04d-00001-*.nii',llseriesoffset+orient)));
    llV(orient)=spm_vol(fullfile(llpth,llfn.name));
    llcburt{orient}=load(fullfile(llpth,sprintf('cburt_series%02d.mat',llseriesoffset+orient)));
    llhdr{orient}=llcburt{orient}.cburt.incoming.series(llseriesoffset+orient).hdr;
    
    
    siemensParms(orient,:)=spm_imatrix(siemensV(orient).mat);
    scalebyvox{orient}=[1 1 1]'*siemensParms(orient,7:9);
    fliptonii=[-1 1 -1; -1 1 -1; 1 -1 1];
    siemensorient_scaled{orient}=siemensorient{orient}.*scalebyvox{orient}.*fliptonii;
    
    % Get normal from ll header
    n=[0 0 0];
    fields={'dSag','dCor','dTra'};
    for f=1:3
        if (isfield(llhdr{orient}.siemensap.sSliceArray.asSlice{1}.sNormal, fields{f}))
            n(f)=llhdr{orient}.siemensap.sSliceArray.asSlice{1}.sNormal.(fields{f});
        end;
    end;
    if (isfield(llhdr{orient}.siemensap.sSliceArray.asSlice{1},'dInPlane'))
        inplane=llhdr{orient}.siemensap.sSliceArray.asSlice{1}.dInPlane;
    else
        inplane=0;
    end;
    b=asin(n(2));
    a=atan2(n(3),n(1));
    
    % voxel sizes, cheat a little because these are easily available
    pixdim=abs(siemensParms(orient,7:9));

    ca=cos(a); sa=sin(a);
    cb=cos(b); sb=sin(b);
    ci=cos(inplane); si=sin(inplane);
    
    R1=[0 0 -1; 1 0 0; 0 -1 0];
    R2=[cb -sb 0; sb cb 0 ; 0 0 1]; % Right rule for sag_cor alone
    R3=[ca 0 -sa; 0 1 0; sa 0 ca]; % Right rule for sag_trans alone
    R4=[ci -si 0; si ci 0; 0 0 1];
    
    llmat{orient}=fliptonii.*(R2*R3*R1*R4).*abs(scalebyvox{orient});
    
    llmat{orient}/siemensV(orient).mat(1:3,1:3)
end;
