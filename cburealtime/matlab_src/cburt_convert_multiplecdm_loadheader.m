function [cburt]=cburt_convert_multipledcm_loadheader(cburt,seriesnum,imgnum)
H=spm_dicom_headers(cburt.incoming.series(seriesnum).receivedvolumes{imgnum});
cburt.incoming.series(seriesnum).dcmheaders{imgnum}=H{1};