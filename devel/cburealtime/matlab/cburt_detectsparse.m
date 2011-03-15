function [cburt]=cburt_detectsparse(cburt,seriesnum,imgnum)

% A little heuristic to spot scans with the phase encode off
% What proportion of voxels have a brightness in the mid range (25-75%)
% versus in the top range (75-100%)
% For phase encode off very biased to top range, little in the middle


try
    cburt.options.detectsparse;
catch
    cburt.options.detectsparse=true;
end;

if (cburt.options.detectsparse)

    cutoff=4;

    current=cburt_getimages(cburt,seriesnum,imgnum);
    V=spm_vol(current);
    Y=spm_read_vols(V);
    H=hist(Y(:),4);
    SCORE=(H(2)+H(3))/H(4);
    ISNOGRADS=SCORE<cutoff;

    if (isnan(cburt.incoming.series(seriesnum).firstvalidimage) && ~ISNOGRADS)
        cburt.incoming.series(seriesnum).firstvalidimage=imgnum;
    end;

    cburt.incoming.series(seriesnum).timeseries.hasnogradients(imgnum)=ISNOGRADS;

    if (ISNOGRADS)
        fprintf('Img %d has no gradients, score %f cutoff %f\n',imgnum,SCORE,cutoff);
    else
        fprintf('Img %d does have gradients, score %f cutoff %f\n',imgnum,SCORE,cutoff);
    end;
else
    cburt.incoming.series(seriesnum).timeseries.hasnogradients(imgnum)=false;
    cburt.incoming.series(seriesnum).firstvalidimage=1;
end;