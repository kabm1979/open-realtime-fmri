% Run watchport.py before this script (Put it in the QA account's .bashrc incl. matlab -nosplash -nodesktop -r "addpath('/realtime/apps/matlab_tools/spm5','/realtime/apps/cburealtime'); addpath('/realtime/apps/matlab_tools/spm5_cbu_updates'); cd /realtime/apps/experiments/qa/;  cburt_watcher")
%  function [cburt]=cburt_watcher(cburt,waitforincoming,synchronizetopulse,moveoldseriesfiles)
% 
% set waitforincoming to false to just reprocess existing series files
% set synchronizetopulse to false to not wait for pulse at beginning
% set moveoldseriesfiles to false to stop it clearing out old series files
%
function [cburt]=cburt_watcher(cburt,waitforincoming,synchronizetopulse,moveoldseriesfiles)

cprintf([0 0 0.2],'WELCOME TO OPEN-REALTIME-FMRI\n');
fprintf('<a href="http://code.google.com/p/open-realtime-fmri/">wiki and code</a> - <a href="http://cusacklab.org/">cusacklab.org</a>\n');

if (~exist('waitforincoming','var'))
    waitforincoming=true;
end;
if (~exist('synchroizetopulse','var'))
    synchronizetopulse=false;
end;
if (~exist('moveoldseriesfiles','var'))
    moveoldseriesfiles=true;
end;


%% Use low latency?
cburt.lowlatency.enabled=false; 

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
if (~isfield(cburt,'benchmarking'))
    cburt.benchmarking=[];
end;

% Directory conventions
global cburealtime_defaults
try cburt.directory_conventions.incomingmetapath; catch cburt.directory_conventions.incomingmetapath=fullfile(cburealtime_defaults.path_data,'incomingmeta'); end;
try cburt.directory_conventions.incomingdata; catch cburt.directory_conventions.incomingdata=cburealtime_defaults.path_sambashare; end;
try cburt.directory_conventions.processeddata; catch cburt.directory_conventions.processeddata=fullfile(cburealtime_defaults.path_data,'processed'); end;
try cburt.directory_conventions.rois; catch cburt.directory_conventions.rois=fullfile(cburealtime_defaults.path_data,'rois'); end;
if (~exist(cburt.directory_conventions.incomingmetapath,'dir'))
    mkdir(cburt.directory_conventions.incomingmetapath);
end;
if (~exist(cburt.directory_conventions.processeddata,'dir'))
    mkdir(cburt.directory_conventions.processeddata);
end;


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
action=cburealtime_defaults.protocol.localiser;
action.onstart={};
action.onreceived={'cburt_convert'};
action.ontrigger={};
action.onend={};
cburt.actions=[cburt.actions action];


action=cburealtime_defaults.protocol.anatomical;
action.onstart={};
action.onreceived={'cburt_convert_multipledcm_loadheader'};
action.ontrigger={};
action.onend={'cburt_convert_fileperslice','cburt_normalise'};
cburt.actions=[cburt.actions action];

action=[];
action.protocolname='VSTM.*';
action.onstart={};
action.onreceived={'cburt_convert','cburt_detectsparse','cburt_realign','cburt_roi_labelled_extract','cburt_streams_send'};
action.ontrigger={};
action.onend={};
cburt.actions=[cburt.actions action];

%% extraction options
cburt.options.scalebymeanoftimeseries=false;
cburt.options.filtereveryscan=false; % only need to do filtering when estimating model
cburt.options.nofitering=false;
% high pass filtering is probably a good idea; otherwise drift might bias
% selection of items towards the middle of the scan.

%% other options
cburt.options.detectsparse=false; % saves a tiny bit of time


cburt.lowlatency.port=1972;
cburt.lowlatency.host='localhost';
cburt.lowlatency.connstr=['buffer://' cburt.lowlatency.host ':' num2str(cburt.lowlatency.port)];
cburt.lowlatency.buffer=[];
cburt.lowlatency.disablesiemensrealtime=cburt.lowlatency.enabled;

cburt.model=[];
cburt.model.globalrescale=false;

cburt.communication.tostimulus.on=true;

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
if addroi, cburt=cburt_addroi(cburt,'labelled_rtcorr','rtcorr05_2level_all_10.nii');
end;


%% RESTART ANALYSIS
if (~isfield(cburt,'incoming') || ~isfield(cburt.incoming,'series'))
    cburt.incoming.series=[];
end;

if (~isfield(cburt.incoming,'dealtwith'))
    cburt.incoming.dealtwith=[];
end;


%% MOVE OLD SERIES FILES
if (~cburt.lowlatency.disablesiemensrealtime)
    fprintf('Siemens realtime transfer\n');
end;

if (moveoldseriesfiles && ~cburt.lowlatency.disablesiemensrealtime)
    oldseriespth=fullfile(cburt.directory_conventions.incomingmetapath,'oldseries');
    if ~exist(oldseriespth,'dir')
        mkdir(oldseriespth);
    end;
    try
        movefile(fullfile(cburt.directory_conventions.incomingmetapath,'series*.txt'),oldseriespth);
        fprintf('Moved old series files to %s (as 4th argument to cburt_watcher is set)\n',oldseriespth);
    catch
    end;
end;


cburt.model.trigger=[];

%% WARNINGS
if (~cburt.model.adaptstimuli)
    fprintf('WARNING: not adapting stimuli\n');
end;
if (~cburt.communication.tostimulus.on)
    fprintf('WARNING: not communicating with stimulus delivery machine\n');
end;


% Launch low-latency data path
if (cburt.lowlatency.enabled)
    fprintf('Using low latency connection to %s\n',cburt.lowlatency.connstr);
    for retry=1:5
        try
            buffer('tcpserver','exit',cburt.lowlatency.host,cburt.lowlatency.port);
        catch
        end;
        try
            buffer('tcpserver','init',cburt.lowlatency.host,cburt.lowlatency.port);
            break;
        catch
        end;
    end;
    % Even following an init-exit cycle, the buffer isn't emptied. So, lets
    % do it manually
    try
        buffer('flush_hdr',cburt.lowlatency.connstr)
    catch
    end;
end;

%% Lets go!
process=true;

fprintf('Waiting...\n');
while(process)
    %% Synchronize to scanner
    if (waitforincoming && synchronizetopulse)
        cburt=cburt_waitforscannerstart(cburt);
    else
        cburt.benchmarking.synchronized=false;
        cburt.benchmarking.ticstart=tic;
    end;
    
    % low latency
    if (cburt.lowlatency.enabled)
        hdr=[];
        sample=0;
        prevsample=0;
        while(true)
            try
                hdr = ft_read_header(cburt.lowlatency.connstr, 'cache', true);
            catch
            end;
            
            if ~isempty(hdr)
                sample=hdr.nSamples;
                
                if (sample > prevsample)
                    if (sample==1)
                        cburt=cburt_processseries(cburt,'','MEAS_START');
                        
                    end;
                    for sampleind=(prevsample+1):sample
                        cburt=cburt_processseries(cburt,'','LOWLATENCY',hdr,sampleind);                
                    end;
                    if (isfield(hdr.siemensap,'lRepetitions'))
                            % EPI
                            expectedreps= 1+hdr.siemensap.lRepetitions;
                        else
                            % MPRAGE
                            expectedreps=hdr.siemensap.sKSpace.lImagesPerSlab;
                        end;
                        if (sample==expectedreps)
                            fprintf('Calling MEAS_FINISHED\n');
                            cburt=cburt_processseries(cburt,'','MEAS_FINISHED');
                            buffer('flush_hdr',cburt.lowlatency.connstr)
                            break;
                        end;
                    prevsample  = sample;
                end;
                
            end;
        end;
    end;
    
    % siemens real time
    if (~cburt.lowlatency.disablesiemensrealtime)
        fn=dir(fullfile(cburt.directory_conventions.incomingmetapath,'series*'));
        for i=1:length(fn)
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
% Flush buffer for tidiness
try
    buffer('flush_hdr',cburt.lowlatency.connstr)
catch
end;
buffer('tcpserver','exit',cburt.lowlatency.host,cburt.lowlatency.port);

end


