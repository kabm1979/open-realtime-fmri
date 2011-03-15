function [cburt]=cburt_estimate_betas(cburt,seriesnum,imgnum,phaseshuffle)
% djm: add 'phaseshuffle' as final parameter, to scramble the data prior to estimating

if (~cburt.options.filtereveryscan)
    % Filter, if sufficient data available
    nvol=size(cburt.incoming.series(seriesnum).timeseries.norm,1);
    try
        nofiltering=cburt.options.nofitering;
    catch
        nofiltering=false;
    end;

    if (nvol<=3*(length(cburt.model.filter.hpf_b)-1) || nofiltering)
        cburt.incoming.series(seriesnum).timeseries.filtered=cburt.incoming.series(seriesnum).timeseries.norm;
    else
        cburt.incoming.series(seriesnum).timeseries.filtered=filtfilt(cburt.model.filter.hpf_b,cburt.model.filter.hpf_a,cburt.incoming.series(seriesnum).timeseries.norm);
    end
end

Xtrimextra=[];
X=cburt.incoming.series(seriesnum).model.X.filtered;

% Try adding on the spikes & moves
try
    X=[X cburt.incoming.series(seriesnum).model.X.filtered_movesspikes];
catch
end;

Y=cburt.incoming.series(seriesnum).timeseries.filtered(1:imgnum,:);
nvol=imgnum;
Xtrim=X(1:nvol,:);

if exist('phaseshuffle','var') && ischar(phaseshuffle) 
    if strcmp(phaseshuffle,'phaseshuffle')
        Y=spm_phase_shuffle(Y);
    else
        warning('Unknown argument %s passed to cburt_estimate_betas',phaseshuffle)
    end
end

% now lets add movement parameters
switch(cburt.model.addrealignmentparms)
    case 1
        cburt.incoming.series(seriesnum).model.realignmentparms.filtered=filtfilt(cburt.model.filter.hpf_b,cburt.model.filter.hpf_a,cburt.incoming.series(seriesnum).realignmentparms);
        % just to make figures better, rescale each columns so s.d. same as
        % first column of model
        std1=std(X(:,1));
        cburt.incoming.series(seriesnum).model.realignmentparms.filtered=cburt.incoming.series(seriesnum).model.realignmentparms.filtered./repmat(std(cburt.incoming.series(seriesnum).model.realignmentparms.filtered)/std1,[nvol 1]);
        Xtrimextra=cburt.incoming.series(seriesnum).model.realignmentparms.filtered;
end;


% Sometimes need to trim out scans from model
try
    hasnograds=cburt.incoming.series(seriesnum).timeseries.hasnogradients;
catch
    hasnograds=false(size(Y));
end;
figure(30);
subplot 221
imagesc(Y);
subplot 222
imagesc(Xtrim);
colormap('gray');

Y=Y(~hasnograds(1:imgnum),:);
Xtrim=Xtrim(~hasnograds(1:imgnum),:);

subplot 223
imagesc(Y);
subplot 224
imagesc(Xtrim);
colormap('gray');


% decide when to bring each beta into play
whichX=max(Xtrim,[],1)>0.1;
Xtrim=Xtrim(:,whichX);
Xtrim=[Xtrim Xtrimextra];


B=inv(Xtrim'*Xtrim)*Xtrim'*Y;
cburt.incoming.series(seriesnum).model.whichX=whichX;
cburt.incoming.series(seriesnum).model.Xtrim=Xtrim;
cburt.incoming.series(seriesnum).model.betas=B;
cburt.incoming.series(seriesnum).model.fit=Xtrim*cburt.incoming.series(seriesnum).model.betas;
cburt.incoming.series(seriesnum).model.residuals=Y-cburt.incoming.series(seriesnum).model.fit;

cburt=cburt_graphics_estimate(cburt,seriesnum);

