function [cburt]=cburt_convert_multipledcm_doit(cburt,seriesnum)
cwd=pwd;
if (~exist(cburt.incoming.processeddata,'file'))
    [pth fle ext]=fileparts(cburt.incoming.processeddata);
    mkdir(pth,[fle ext]);
end;
cd (cburt.incoming.processeddata);
spm_dicom_convert(cburt.incoming.series(seriesnum).dcmheaders);
cd(pwd);