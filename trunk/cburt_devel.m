spmpth='/open-realtime-fmri/spm8';
global cburealtime_defaults
cburealtime_defaults=[];
cburealtime_defaults.path_data='/home/rcusack/realtime';
cburealtime_defaults.path_code='/open-realtime-fmri';
cburealtime_defaults.path_sambashare=fullfile(cburealtime_defaults.path_data,'rawdata');

% Names of your protocols as seen on the Siemens console. Use regular
% expressions for wildcards
cburealtime_defaults.protocol.localiser.protocolname='.*localiser.*';
cburealtime_defaults.protocol.anatomical.protocolname='.*MPRAGE.*';
cburealtime_defaults.protocol.functional.protocolname='.*ep2d.*';

% Set paths
%  Recursively add subdirectories of cburealtime/matlab_src too
addpath(genpath(fullfile(cburealtime_defaults.path_code,'cburealtime','matlab_src')));
addpath(genpath(fullfile(cburealtime_defaults.path_code,'external','fieldtrip')))
addpath(spmpth);

spm('fmri');
