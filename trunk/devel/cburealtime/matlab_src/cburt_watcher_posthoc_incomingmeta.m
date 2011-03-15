% For posthoc processing of data, when you have a set of series*txt files.
% Doesn't communicate with the stimulus delivery in either direction.

function [cburt]=cburt_watcher_posthoc_incomingmeta(incomingmetapath)


if ~iscell(incomingmetapath)
    incomingmetapath={incomingmetapath};
end;

% Don't load up stimuli
cburt.model.adaptstimuli=0;
cburt.model.loadstimuli=1;
cburt.communication.tostimulus.on=false;
cburt.incoming.dealtwith=[];

for k=1:length(incomingmetapath)
    cburt.directory_conventions.incomingmetapath=incomingmetapath{k};
    cburt=cburt_watcher(cburt,false);
end;


