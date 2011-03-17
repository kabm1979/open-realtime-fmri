spmpth='/home/stefanh/realtime/spm8';
global cburealtime_defaults
cburealtime_defaults=[];
cburealtime_defaults.path_data='/home/stefanh/realtime/scratch';
cburealtime_defaults.path_code='/home/stefanh/realtime/svn/trunk/devel';
cburealtime_defaults.path_sambashare='/local/sambashare';

% Names of your protocols as seen on the Siemens console. Use regular
% expressions for wildcards
cburealtime_defaults.protocol.localiser.protocolname='^CBU_Localiser.*';
cburealtime_defaults.protocol.anatomical.protocolname='^CBU_MPRAGE.*';
cburealtime_defaults.protocol.functional.protocolname='.*ep2d.*';

% Set paths
addpath(fullfile(cburealtime_defaults.path_code,'cburealtime','matlab_src'));
addpath(spmpth);

spm('fmri');
