function [cburt]=cburt_convert_multipledcm_loadheader(cburt,seriesnum,imgnum)
switch (cburt.incoming.series(seriesnum).receivedvolumesformat)
    case 'dcm'
        H=spm_dicom_headers(cburt.incoming.series(seriesnum).receivedvolumes{imgnum});
        cburt.incoming.series(seriesnum).dcmheaders{imgnum}=H{1};
end;