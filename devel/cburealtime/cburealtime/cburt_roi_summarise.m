function [cburt]=cburt_roi_summarise(cburt,seriesnum,imgnum)

V=spm_vol(cburt_getimages(cburt,seriesnum,imgnum,'r'));
Y=spm_read_vols(V);

cburt.incoming.series(seriesnum).timeseries.global(imgnum)=mean(Y(:));

if (cburt.model.globalrescale)
    globmean=cburt.incoming.series(seriesnum).timeseries.global(imgnum)/100;
else
    globmean=1;
end;
if (imgnum==1)
    cburt=cburt_roi_inversenormalise_epi(cburt,seriesnum,V);
end;

for i=1:length(cburt.incoming.series(seriesnum).rois)
    if (cburt.model.outliercutoff~=0)
        selectedfromEPI=Y(cburt.incoming.series(seriesnum).rois(i).Y);
        selectedfromEPI=selectedfromEPI(:);
        [n x]=hist(selectedfromEPI(:),50);
        [val ind]=max(n);
        cutoff=x(ind)*cburt.model.outliercutoff;
        selectedfromEPI=selectedfromEPI(selectedfromEPI>cutoff);
        cburt.incoming.series(seriesnum).timeseries.raw(imgnum,i)=mean(selectedfromEPI)/globmean;
    else
        cburt.incoming.series(seriesnum).timeseries.raw(imgnum,i)=sum(sum(sum(Y(cburt.incoming.series(seriesnum).rois(i).Y))))/cburt.incoming.series(seriesnum).rois(i).nvox/globmean;
    end;
end;

% Scale by mean through time series
cburt.incoming.series(seriesnum).timeseries.norm=100*cburt.incoming.series(seriesnum).timeseries.raw./repmat(mean(cburt.incoming.series(seriesnum).timeseries.raw,1),[size(cburt.incoming.series(seriesnum).timeseries.raw,1) 1]);

% Filter, if sufficient data available
nvol=size(cburt.incoming.series(seriesnum).timeseries.norm,1);
if (nvol<=3*(length(cburt.model.filter.hpf_b)-1))
    cburt.incoming.series(seriesnum).timeseries.filtered=cburt.incoming.series(seriesnum).timeseries.norm;
else
    cburt.incoming.series(seriesnum).timeseries.filtered=filtfilt(cburt.model.filter.hpf_b,cburt.model.filter.hpf_a,cburt.incoming.series(seriesnum).timeseries.norm);
end

cburt=cburt_graphics_incoming(cburt,seriesnum);

drawnow;
