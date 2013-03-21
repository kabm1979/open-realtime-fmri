function [cburt]=cburt_roi_labelled_extract(cburt,seriesnum,imgnum)

V=spm_vol(cburt_getimages(cburt,seriesnum,imgnum,'r'));
Y=spm_read_vols(V);

cburt.incoming.series(seriesnum).timeseries.global(imgnum)=mean(Y(:));

if (cburt.model.globalrescale)
    globmean=cburt.incoming.series(seriesnum).timeseries.global(imgnum)/100;
else
    globmean=1;
end
if (imgnum==1)
    cburt=cburt_roi_labelled_inversenormalise_epi(cburt,seriesnum,V);
end

allvox=[];
for i=1:length(cburt.incoming.series(seriesnum).rois)
    lablist=setdiff(unique(cburt.incoming.series(seriesnum).rois(i).Y(:)),0);
    for labind=1:length(lablist)
        allvox=[allvox mean(Y(cburt.incoming.series(seriesnum).rois(i).Y(:)==lablist(labind)))];
    end;
end
cburt.incoming.series(seriesnum).timeseries.raw(imgnum,:)=allvox./globmean;

% Scale by mean through time series
if (cburt.options.scalebymeanoftimeseries)
    cburt.incoming.series(seriesnum).timeseries.norm=100*cburt.incoming.series(seriesnum).timeseries.raw./repmat(mean(cburt.incoming.series(seriesnum).timeseries.raw,1),[size(cburt.incoming.series(seriesnum).timeseries.raw,1) 1]);
else
    cburt.incoming.series(seriesnum).timeseries.norm=cburt.incoming.series(seriesnum).timeseries.raw;
end

if (cburt.options.filtereveryscan)
    % Filter, if sufficient data available
    nvol=size(cburt.incoming.series(seriesnum).timeseries.norm,1);
    if (nvol<=3*(length(cburt.model.filter.hpf_b)-1))
        cburt.incoming.series(seriesnum).timeseries.filtered=cburt.incoming.series(seriesnum).timeseries.norm;
    else
        cburt.incoming.series(seriesnum).timeseries.filtered=filtfilt(cburt.model.filter.hpf_b,cburt.model.filter.hpf_a,cburt.incoming.series(seriesnum).timeseries.norm);
    end
end

cburt=cburt_graphics_incoming(cburt,seriesnum);

drawnow;