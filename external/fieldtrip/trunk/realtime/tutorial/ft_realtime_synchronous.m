function cmd = ft_realtime_synchronous(cfg)

% FT_REALTIME_SYNCHRONOUS is an example realtime application for
% synchronous (trigger-based) brain-computer interfaces
%
% Use as
%
%   cmd = ft_realtime_synchronous(cfg)
%
% where cmd is the last processed command and cfg has the following configuration options
%   cfg.bcifun     = the BCI function that is called
%   cfg.trigger    = the trigger values that should be processed (default = 'all')
%   cfg.blocksize  = number, size of the blocks/chuncks that are processed in seconds (default = 1)
%   cfg.offset     = offset relative to the trigger (default = 0)
%   cfg.channel    = cell-array, see FT_CHANNELSELECTION (default = 'all')
%   cfg.bufferdata = whether to start on the 'first or 'last' data that is
%                    available when the function _starts_ (default = 'last')
%   cfg.jumptoeof  = whether to start on the 'first or 'last' data that is
%                    available when the function _starts_ (default = 'last')
%
%   cfg.ostream    = the output stream that is used to send a command via
%                     write_event (default = []
%
% The source of the data is configured as
%   cfg.dataset       = string
% or alternatively to obtain more low-level control as
%   cfg.datafile      = string
%   cfg.headerfile    = string
%   cfg.eventfile     = string
%   cfg.dataformat    = string, default is determined automatic
%   cfg.headerformat  = string, default is determined automatic
%   cfg.eventformat   = string, default is determined automatic
%
% trials that correspond to any of the triggers in the vector cfg.trigger will be
% processed. By default all trigger values will be processed (cfg.trigger =
% 'all') and may be of any type (cfg.type = 'all'). The condition to which a 
% data segment belongs is passed to bcifun using cfg.condition.
%
% The bcifun must be of the form
%   
%   cmd = bcifun(cfg,data)
%
% where cfg is the configuration passed by this function and data is the
% new data segment. Cmd is the command which is generated by the bcifun.
% This command will be send to an external device via cfg.ostream. Check
% bcifun_latidx for an example.
%
% Some notes about skipping data and catching up with the data stream:
%
% cfg.jumptoeof='yes' causes the realtime function to jump to the end
% when the function _starts_. It causes all data acquired prior to
% starting the RT function to be skipped.
% 
% cfg.bufferdata=last causes the realtime function to jump to the last
% available data while _running_. If the RT loop is not fast enough,
% it causes some data to be dropped.
% 
% If you want to skip all data that was acquired before you start the
% RT function, but don't want to miss any data that was acquired while
% the realtime function is started, then you should use jumptoeof=yes and
% bufferdata=first. If you want to analyse data from a file, then you
% should use jumptoeof=no and bufferdata=first.
%
% To stop the realtime function, you have to press Ctrl-C

% Copyright (C) 2010, Marcel van Gerven, Robert Oostenveld

% set the default configuration options

if ~isfield(cfg, 'bcifun'),         cfg.bcifun = @bcifun_latidx; end % example function computes lateralization index
if ~isfield(cfg, 'trigger'),        cfg.trigger = 'all';         end % trigger values to process
if ~isfield(cfg, 'type'),           cfg.type = 'all';            end % trigger type to process
if ~isfield(cfg, 'nsamples'),       cfg.nsamples = inf;          end % number of samples to process
if ~isfield(cfg, 'blocksize'),      cfg.blocksize = 1;           end % in seconds
if ~isfield(cfg, 'offset'),         cfg.offset = 0;              end % in seconds
if ~isfield(cfg, 'channel'),        cfg.channel = 'all';         end % processed channels
if ~isfield(cfg, 'bufferdata'),     cfg.bufferdata = 'last';     end % first or last
if ~isfield(cfg, 'jumptoeof'),      cfg.jumptoeof = 'yes';       end % jump to end of file at initialization
if ~isfield(cfg, 'dataformat'),     cfg.dataformat = [];         end % default is detected automatically
if ~isfield(cfg, 'headerformat'),   cfg.headerformat = [];       end % default is detected automatically
if ~isfield(cfg, 'eventformat'),    cfg.eventformat = [];        end % default is detected automatically
if ~isfield(cfg, 'dataset') && ~isfield(cfg, 'header') && ~isfield(cfg, 'datafile')
  cfg.dataset = 'buffer://localhost:1972';
end
if ~isfield(cfg, 'ostream'),        cfg.ostream = [];            end % no output by default

% translate dataset into datafile+headerfile
cfg = ft_checkconfig(cfg, 'dataset2files', 'yes');
cfg = ft_checkconfig(cfg, 'required', {'datafile' 'headerfile'});

% ensure that the persistent variables related to caching are cleared
clear ft_read_header
% start by reading the header from the realtime buffer
hdr = ft_read_header(cfg.headerfile, 'headerformat', cfg.headerformat, 'cache', true, 'retry', true);

% define a subset of channels for reading
cfg.channel = ft_channelselection(cfg.channel, hdr.label);
chanindx    = match_str(hdr.label, cfg.channel);
nchan       = length(chanindx);
if nchan==0, error('no channels were selected'); end

% determine the size of blocks to process
blocksize = round(cfg.blocksize * hdr.Fs);
offset    = round(cfg.offset*hdr.Fs);

if strcmp(cfg.jumptoeof, 'yes')
  prevSample = hdr.nSamples * hdr.nTrials;
else
  prevSample  = 0;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is the general BCI loop where realtime incoming data is handled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cfg.count = 0; % current segment; can be used in bcifun
minsample = 0; % only consider events that are later than the data processed sofar
while cfg.count < cfg.nsamples

  % determine number of samples available in buffer
  hdr = ft_read_header(cfg.headerfile, 'headerformat', cfg.headerformat, 'cache', true);

  % read new events
  event = ft_read_event(cfg.dataset, 'minsample', minsample+1);  

  if ~isempty(event)
    fprintf('found %d events\n',length(event));
  end
  
  for j=1:length(event)
      
     bprocess = (strcmp(cfg.type,'all') | strcmp(event(j).type,cfg.type)) & ...
                (strcmp(cfg.trigger,'all') | ismember(event(j).value,cfg.trigger));
        
     if bprocess % catched a trigger of interest
          
       cfg.condition = event(j).value;
       
       % we do not consider samples < 1
       begsample = max(1,event(j).sample + offset);
       endsample = max(1,begsample + blocksize);
       
       % keep reading until we acquired enough samples
       while hdr.nSamples<endsample
         hdr = ft_read_header(cfg.headerfile, 'headerformat', cfg.headerformat,'cache', true);
       end
       
       % remember up to where the data was read
       minsample = endsample;
       cfg.count = cfg.count + 1;
       fprintf('processing segment %d from sample %d to %d, trigger = %d\n', cfg.count, begsample, endsample, cfg.condition);
       
       % read data segment from buffer
       dat = double(ft_read_data(cfg.datafile, 'header', hdr, 'dataformat', cfg.dataformat, 'begsample', begsample,...
         'endsample', endsample, 'chanindx', chanindx, 'checkboundary', false));

       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       % from here onward it is specific to the display of the data
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       
       % put the data in a fieldtrip-like raw structure
       data.trial{1} = dat;
       data.time{1}  = offset2time(0, hdr.Fs, endsample-begsample+1);
       data.label    = hdr.label(chanindx);
       data.hdr      = hdr;
       data.fsample  = hdr.Fs;
       data.grad     = [];
       
       % apply BCI function
       cmd = cfg.bcifun(cfg,data);
       
       if ~isempty(cfg.ostream)
         
         fprintf('writing command %s to %s\n',num2str(cmd),cfg.ostream);
         
         % send command
         evt.type = 'uint';
         evt.offset = [];
         evt.duration = [];
         evt.sample = abs(data.time{1}(1)*hdr.Fs);
         evt.timestamp = data.time{1}(1);
         evt.value = cmd;
         
         ft_write_event(cfg.ostream,evt);
         
       else
         fprintf('generated command %s\n',num2str(cmd));
       end
       
       cfg.count = cfg.count +  1;
       
       if cfg.count == cfg.nsamples
         break;
       end
       
     end % trigger of interest
  end % if event
end % while true
