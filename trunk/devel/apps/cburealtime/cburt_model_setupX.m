function [cburt]=cburt_model_setupX(cburt)

clear SPM
% non condition specific bf stuff
SPM.xBF.T          = 16;                % number of time bins per scan
SPM.xBF.T0         = 8;                 % bin for model (here middle)
SPM.xBF.UNITS      = 'scans';           % OPTIONS: 'scans'|'secs' for onsets
SPM.xBF.Volterra   = 1;                 % OPTIONS: 1|2 = order of convolution
SPM.xBF.name       = 'hrf';
SPM.xBF.length     = 32;              % length in seconds
SPM.xBF.order      = 1;                 % order of basis set
SPM.xY.RT = cburt.model.TR;
SPM.xBF.dt = SPM.xY.RT/SPM.xBF.T;
try
    bf      = SPM.xBF.bf;
catch
    SPM.xBF = spm_get_bf(SPM.xBF);
    bf      = SPM.xBF.bf;
end
SPM.xGX.iGXcalc = 'None';
SPM.xVi.form = 'AR(1)';

% max number of scans
SPM.nscan(1) = cburt.model.maxscans;

for i=1:length(cburt.model.conds)
    ons=cburt.model.conds(i).ons;
    dur=cburt.model.conds(i).dur;
    if (length(ons)==0)
        ons=-1;
        dur=0;
    end;
    SPM.Sess(1).U(i) = struct(...
        'ons',ons,...
        'dur',dur,...
        'name',{cburt.model.conds(i).name},...
        'P',struct('name','none'));
end;

cburt.model.SPM=SPM;


% recreate unfiltered design matrix
U=spm_get_ons(cburt.model.SPM,1);
fMRI_T     = cburt.model.SPM.xBF.T;
fMRI_T0    = cburt.model.SPM.xBF.T0;
bf      = cburt.model.SPM.xBF.bf;
k   = cburt.model.SPM.nscan(1);

% only really need to do the convolution separately for scans with distinct
% durations and offsets relative to the scans, so lets get a list of these
offsets=mod([U.ons],cburt.model.SPM.xY.RT);
offsetsT=round(offsets*cburt.model.SPM.xBF.T);
singleevents=[[offsetsT]',[U.dur]'];
[durb duri durj]=unique(singleevents,'rows');

winlen=round(32/cburt.model.SPM.xY.RT);

% do convolution to create models of these single unique events
sSPM=cburt.model.SPM;
sSPM.nscan=winlen;
sSPM.Sess=[];
for i=1:size(durb,1)
    sSPM.Sess.U(i).name={sprintf('ons_%d_dur_%f',durb(i,:))};
    sSPM.Sess.U(i).ons=durb(i,1);
    sSPM.Sess.U(i).dur=durb(i,2);    
    sSPM.Sess.U(i).P=struct('name','none');
end;
sU=spm_get_ons(sSPM,1);
sX=spm_Volterra(sU,bf,1); % 1st order Volterra
sX = sX([0:(winlen - 1)]*fMRI_T + fMRI_T0 + 32,:);

% now drop them down at the appropriate times
X=zeros(cburt.model.SPM.nscan(1)+winlen,length(U));

ind=1;
for i=1:length(U)
    for j=1:length(U(i).ons)
        eoffsetT=mod(U(i).ons(j),cburt.model.SPM.xY.RT)*cburt.model.SPM.xBF.T;
        edur=U(i).dur(j);
        bind=find(all(repmat([eoffsetT edur],[size(durb,1) 1])==durb,2));
        starttime=1+floor(U(i).ons(j));
        X(starttime:(starttime+winlen-1),i)=X(starttime:(starttime+winlen-1),i)+sX(:,bind);
    end;
end;
X=X(1:cburt.model.SPM.nscan(1),:);

% old style SPM - too slow
%X2=spm_Volterra(U,bf,1); % 1st order Volterra
%X2 = X2([0:(k- 1)]*fMRI_T + fMRI_T0 + 32,:);

% this adds on the session mean
X=[X, ones(size(X,1),1)];

% specify which columns are of interest
cburt.model.X.columnofinterest=[true(1,length(cburt.model.conds)) false];

% now filter the model
cburt.model.X.unfiltered=X;

try
    nofiltering=cburt.options.nofitering;
catch
    nofiltering=false;
end;

if (nofiltering)
    cburt.model.X.filtered=cburt.model.X.unfiltered;
else
    cburt.model.X.filtered=filtfilt(cburt.model.filter.hpf_b,cburt.model.filter.hpf_a,X);
end;

cburt.model.X.filtered(:,end)=1;
% options for later % 0=none; 1=realign parms; 2=spikes+moves
cburt.model.addrealignmentparms=2;

% figure(16); 
% subplot(211);
% imagesc(cburt.model.X.filtered); colormap('gray');


