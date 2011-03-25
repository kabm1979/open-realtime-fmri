function [cburt]=cburt_convert_fileperslice(cburt,seriesnum)
switch (cburt.incoming.series(seriesnum).receivedvolumesformat)
    case 'dcm'
        cwd=pwd;
        if (~exist(cburt.incoming.processeddata,'file'))
            [pth fle ext]=fileparts(cburt.incoming.processeddata);
            mkdir(pth,[fle ext]);
        end;
        cd (cburt.incoming.processeddata);
        spm_dicom_convert(cburt.incoming.series(seriesnum).dcmheaders,'all','flat','nii');
        cd(pwd);
    case 'img'
        first_hdr=load(fullfile(cburt.incoming.processeddata,sprintf('first_hdr_%04d',seriesnum)));
        nfiles=length(cburt.incoming.series(seriesnum).receivedvolumes);
        for fnind=1:nfiles
            V=spm_vol(cburt.incoming.series(seriesnum).receivedvolumes{fnind});
            if (fnind==1)
                Y=zeros([V.dim(1:2) nfiles]);
            end;
            Y(:,:,fnind)=spm_read_vols(V);
        end;
        parms=spm_imatrix(V.mat);
        parms(9)=cburt.incoming.series(seriesnum).hdr.siemensap.sSliceArray.asSlice{1}.dThickness/nfiles;
        V.mat=spm_matrix(parms);
        V.dim(3)=nfiles;
        V.fname=fullfile(cburt.incoming.processeddata,sprintf('structural-%04d-00001-%06d-01.nii',seriesnum,nfiles));
        spm_write_vol(V,Y);
end;