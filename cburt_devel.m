spmpth='/home/stefanh/realtime/spm8';
global cburealtime_defaults
cburealtime_defaults=[];
cburealtime_defaults.path_data='/home/stefanh/realtime/scratch';
cburealtime_defaults.path_code='/home/stefanh/realtime/svn/trunk';
cburealtime_defaults.path_sambashare='/local/sambashare';

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
