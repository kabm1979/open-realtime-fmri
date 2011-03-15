% Run watchport.py before this script (Put it in the QA account's .bashrc incl. matlab -nosplash -nodesktop -r "addpath('/realtime/apps/matlab_tools/spm5','/realtime/apps/cburealtime'); addpath('/realtime/apps/matlab_tools/spm5_cbu_updates'); cd /realtime/apps/experiments/qa/;  cburt_watcher")
function [cburt]=cburt_watcher(cburt,waitforincoming)

try waitforincoming; catch waitforincoming=true; end;

%% add paths
cd(fileparts(mfilename('fullpath')));
addpath(pwd);
% for:
% cburt_roi_extract
% cburt_dai_estimate
% cburt_roi_adaptive_setup
% cburt_dai_newblock
% ...
addpath('../../cburealtime','-END')
% for:
% cburt_addroi
% ...

%% archive old series*.txt files, unless running posthoc analysis
% if waitforincoming
%     osf=spm_select('FPlist','/realtime/scratch/incomingmeta','series.*\.txt');
%     if ~isempty(osf)
%         fprintf('\nWarning: archiving old series*.txt files to series*.archived\n')
%         osf=cellstr(osf)
%         for f=1:length(osf)
%             [pth nam ext]=fileparts(osf{f});
%             try
%                 movefile(osf{f},fullfile(pth, ['old' nam '.archived' datestr(now,30)]));
%             catch
%                 error('\nPlease archive old series*.txt files.\n');
%             end
%         end
%     end
% end


%% Some options for diagnostic graphics
cburt.options.cburt_diagnostics.maximagesacross=16;
cburt.options.graphics_incoming='imagesc';
cburt.options.graphics.estimate.showmeanbeta=true;
cburt.options.drawgraphicsevery=8;

%% set up some defaults
rand('state',sum(100*clock))

% Directory conventions
try cburt.directory_conventions.incomingmetapath; catch cburt.directory_conventions.incomingmetapath='/realtime/scratch/incomingmeta'; end;
try cburt.directory_conventions.incomingdata; catch cburt.directory_conventions.incomingdata='/realtime/scratch/incoming'; end;
try cburt.directory_conventions.processeddata; catch cburt.directory_conventions.processeddata='/realtime/scratch/processed'; end;
try cburt.directory_conventions.rois; catch cburt.directory_conventions.rois='/realtime/scratch/rois'; end;

% % cburt.directory_conventions.incomingmetapath='/imaging/dm01/cbu_rt_appsOct1209/scratch/incomingmeta';
%try cburt.directory_conventions.incomingdata; catch cburt.directory_conventions.incomingdata='/imaging/dm01/cbu_rt_appsOct1209/scratch/incoming'; end
%try cburt.directory_conventions.processeddata; catch cburt.directory_conventions.processeddata='/imaging/dm01/cbu_rt_appsOct1209/scratch/processed'; end
%try cburt.directory_conventions.rois; catch
%cburt.directory_conventions.rois='/imaging/dm01/cbu_rt_appsOct1209/scratch/rois'; end

cburt.rois=[];
if (~isfield(cburt.options,'nvox'))
    %  IF THERE'S A DISASTER WITH THE ANT TEMP, CHANGE THE FOLLOWING LINE TO
    %   cburt.options.nvox=60000;
    cburt.options.nvox=800;
end;

if (~isfield(cburt.options,'corrmethod'))
    cburt.options.corrmethod='spearman';
end;

%% List of actions to be triggered by the arrival of different kinds of data
cburt.actions=[];
action.shortname='localiser';
action.protocolname='^CBU_Localiser.*';
action.imgtype='ORIGINAL\PRIMARY\M\ND';
action.onstart={};
action.onreceived={'cburt_convert'};
action.ontrigger={};
action.onend={};
cburt.actions=[cburt.actions action];

action.shortname='structural';
action.protocolname='^CBU_MPRAGE.*';
action.imgtype='ORIGINAL\PRIMARY\M\ND\NORM';
action.onstart={};
action.onreceived={'cburt_convert_multipledcm_loadheader'};
action.ontrigger={};
action.onend={'cburt_convert_multipledcm_doit','cburt_normalise'};
cburt.actions=[cburt.actions action];

action.shortname='epinomoco';
action.protocolname='^CBU_EPI.*';
action.imgtype='ORIGINAL\PRIMARY\M\ND\MOSAIC';
action.onstart={};
action.onreceived={'cburt_convert','cburt_qa_oncepervolume','cburt_diagnostics'};
action.ontrigger={};
action.onend={'cburt_qa_endofseries'};
cburt.actions=[cburt.actions action];

%% extraction options
cburt.options.scalebymeanoftimeseries=false;
cburt.options.filtereveryscan=false; % only need to do filtering when estimating model
cburt.options.nofitering=false;
% high pass filtering is probably a good idea; otherwise drift might bias
% selection of items towards the middle of the scan.

%% other options
cburt.options.detectsparse=false; % saves a tiny bit of time

cburt.model=[];

cburt.communication.tostimulus.on=false;

cburt.internal.livedata=true;

%% STIMULI - LOAD; ADAPT? - might be set in posthoc script
if (~isfield(cburt.model,'loadstimuli'))
    cburt.model.loadstimuli=0;
end;

if (~isfield(cburt.model,'adaptstimuli'))
    cburt.model.adaptstimuli=1;
    cburt.model.loadstimuli=0;
end;

cburt.rois=[];



%% TASK
try cburt.task % from stim deleivery
catch cburt.task='nothing';
end;

%% ROIs
addroi=false;
try
    if (isempty(cburt.rois)), addroi=true; end;
catch addroi=true;
end;
if addroi, cburt=cburt_addroi(cburt,'itmask','ots_both.nii');
end;


%% RESTART ANALYSIS
if (~isfield(cburt,'incoming') || ~isfield(cburt.incoming,'series'))
    cburt.incoming.series=[];
end;

if (~isfield(cburt.incoming,'dealtwith'))
    cburt.incoming.dealtwith=[];
end;


cburt.model.trigger=[];

%% WARNINGS
if (~cburt.model.adaptstimuli)
    fprintf('WARNING: not adapting stimuli\n');
end;
if (~cburt.communication.tostimulus.on)
    fprintf('WARNING: not communicating with stimulus delivery machine\n');
end;


%% Lets go!
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
