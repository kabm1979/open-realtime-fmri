% Run watchport.py before this script
function [cburt]=cburt_watcher_posthoc_daionly_inner(cburt,waitforincoming)

% Directory conventions
try
    cburt.directory_conventions.incomingmetapath;
catch
    cburt.directory_conventions.incomingmetapath='/realtime/scratch/incomingmeta';
end;
try
    cburt.directory_conventions.incomingdata;
catch
    cburt.directory_conventions.incomingdata='/realtime/scratch/incoming';
end;

try
    cburt.directory_conventions.processeddata;
catch
    cburt.directory_conventions.processeddata='/realtime/scratch/processed';
end;

try
    cburt.directory_conventions.rois;
catch
    cburt.directory_conventions.rois='/realtime/scratch/rois';
end;

% Some options
cburt.options.cburt_diagnostics.maximagesacross=16;
try
    waitforincoming;
catch
    waitforincoming=true;
end;

% ROIs to be summarised
cburt.rois=[];
cburt=cburt_addroi(cburt,'left','V1_left.nii');
cburt=cburt_addroi(cburt,'right','V1_right.nii');
%cburt.rois(3).filename='ifs_left.nii';
%cburt.rois(4).filename='ifs_right.nii';
%
% List of actions to be trigger by the arrival of different kinds of data
cburt.actions=[];

action.shortname='epinomoco';
action.protocolname='^CBU_EPI.*';
action.imgtype='ORIGINAL\PRIMARY\M\ND\MOSAIC';
action.onstart={'cburt_dai_adaptive_setup','cburt_setseriesstimuli','cburt_dai_estimate'};
action.onreceived={};
action.ontrigger={'cburt_estimate_betas','cburt_estimate_noise','cburt_dai_adaptive_updatepdf','cburt_dai_estimate'};
action.onend={'cburt_dumpfigures'};
cburt.actions=[cburt.actions action];

% action.shortname='epimoco';
% action.protocolname='^CBU_EPI.*';
% action.imgtype='ORIGINAL\PRIMARY\M\ND\FILTERED\MOCO\MOSAIC';
% action.onstart={'cburt_dai_adaptive_setup'};
% action.onreceived={'cburt_convert','cburt_diagnostics','cburt_roi_summarise','cburt_dai_estimate'};
% action.onend={};
% cburt.actions=[cburt.actions action];

% try non-moco data
% action.shortname='epinomoco';
% action.protocolname='^CBU_EPI.*';
% action.imgtype='ORIGINAL\PRIMARY\M\ND\MOSAIC';
% action.onstart={};
% action.onreceived={'cburt_convert','cburt_diagnostics','cburt_roi_summarise'};
% action.onend={'cburt_savecburt'};
% cburt.actions=[cburt.actions action];

%% MODEL SETUP
cburt.model.highpassperiod=128; % filter out frequencies with period below
cburt.model.TR=1; % seconds
cburt.model.ndummies=7;
cburt.model.maxscans=780; %24*32+cburt.model.ndummies; % 32 trials of 24 s each
cburt.model.outliercutoff=0.5; % proportion of modal value
cburt.model.globalrescale=1; % rescale by global signal?

% Pre-prepared stimulus lists
%s=load('stim');
%cburt.model.stimuli=log(s.stim)/log(2);
cburt.model.stimuli=[ones(32,1)*log(255)/log(2)]; % these correspond to the ons, dur blocks
cburt.model.runspecificstimuli=false;

cburt.model.trigger=[3 24*[1:32]+cburt.model.ndummies-5 24*[1:32]+cburt.model.ndummies-4 24*[1:32]+cburt.model.ndummies-3]; % DAI

% A bit of a hack-factor at the moment, needs to be more accurately
% estimated
cburt.model.psychologicalbetastdev=0.5; %1;

cburt.model.contrast=[1 1 ]';
ind=1;
for i=24*[0:31]+cburt.model.ndummies
    cburt.model.conds(ind).ons=i;
    cburt.model.conds(ind).dur=12;
    cburt.model.conds(ind).name={sprintf('block%d',ind)};
    ind=ind+1;
end;



%
cburt=cburt_model_setupX(cburt);
cburt.model.stimlistfilename=fullfile(cburt.directory_conventions.incomingmetapath,'stimlist.txt');

%% STIMULI - LOAD; ADAPT?
if (~isfield(cburt.model,'loadstimuli'))
    cburt.model.loadstimuli=1;
end;

if (~isfield(cburt.model,'adaptstimuli'))
    cburt.model.adaptstimuli=1;
    cburt.model.loadstimuli=1;
end;

%% COMMUNICATION
if (~isfield(cburt,'communication') || ~isfield(cburt.communication,'tostimulus'))
    cburt.communication.tostimulus.on=true;
    cburt.communication.tostimulus.port=6001;
    cburt=cburt_checkcommunications(cburt);
end;


%% RESTART ANALYSIS
if (~isfield(cburt,'incoming') || ~isfield(cburt.incoming,'series'))
    cburt.incoming.series=[];
end;

if (~isfield(cburt.incoming,'dealtwith'))
    cburt.incoming.dealtwith=[];
end;

cburt.model.numstimulilistsused=0;



%% WARNINGS
if (~cburt.model.adaptstimuli)
    fprintf('WARNING: not adapting stimuli\n');
end;
if (~cburt.communication.tostimulus.on)
    fprintf('WARNING: not communicating with stimulus delivery machine\n');
end;


%% Lets go
process=true;
while(process)
    fn=dir(cburt.directory_conventions.incomingmetapath);
    for i=1:length(fn)
        if (length(fn(i).name)>6 && strcmp(fn(i).name(1:6),'series'))
            ind=str2num(fn(i).name(7:12));
            if (~any(cburt.incoming.dealtwith==ind))
                fprintf('Data series %s %06d\n',fn(i).name,ind);
                cburt=cburt_processseries(cburt,fullfile(cburt.directory_conventions.incomingmetapath,fn(i).name));
                cburt.incoming.dealtwith=[cburt.incoming.dealtwith ind];
            end;
        end;
    end;
    process=waitforincoming;
end;