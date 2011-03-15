function [cburt]=cburt_convert(cburt,seriesnum,imgnum)

H=spm_dicom_headers(cburt.incoming.series(seriesnum).receivedvolumes{imgnum});
cwd=pwd;
if (~exist(cburt.incoming.processeddata,'file'))
    [pth fle ext]=fileparts(cburt.incoming.processeddata);
    mkdir(pth,[fle ext]);
end;
cd (cburt.incoming.processeddata);
spm_dicom_convert(H,'all','flat','nii');
cd(pwd);