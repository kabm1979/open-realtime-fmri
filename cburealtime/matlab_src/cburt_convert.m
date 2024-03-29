function [cburt]=cburt_convert(cburt,seriesnum,imgnum)

[pth nme ext]=fileparts(cburt.incoming.series(seriesnum).receivedvolumes{imgnum});
if (strcmp(ext,'.img'))
    V=spm_vol(cburt.incoming.series(seriesnum).receivedvolumes{imgnum});
    Y=spm_read_vols(V);
    V.fname=fullfile(pth,[nme '.nii']);
    spm_write_vol(V,Y);
elseif (~strcmp(ext,'.nii'))
    H=spm_dicom_headers(cburt.incoming.series(seriesnum).receivedvolumes{imgnum});
    cwd=pwd;
    if (~exist(cburt.incoming.processeddata,'file'))
        [pth fle ext]=fileparts(cburt.incoming.processeddata);
        mkdir(pth,[fle ext]);
    end;
    cd (cburt.incoming.processeddata);
    spm_dicom_convert(H,'all','flat','nii');
    cd(pwd);
else
    fprintf('Data received as .nii, no dicom conversion required for %s',cburt.incoming.series(seriesnum).receivedvolumes{imgnum});
end;