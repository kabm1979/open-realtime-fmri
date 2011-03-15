function [cburt]=cburt_watcher_posthoc(processedpath,rerunnormalisation,dosendstim,ndummies)

posthocpath='/realtime/scratch/posthoc';

if (~exist('rerunnormalisation','var'))
    rerunnormalisation=true;
end;

if ~iscell(processedpath)
    processedpath={processedpath};
end;

for k=1:length(processedpath)
    % Load up previous cburt path
    if (isstruct(processedpath{k}))
        cburt=processedpath{k};
    else
        load(fullfile(processedpath{k},'cburt.mat'))
    end;
    %Don't load up stimuli
    if (exist('dosendstim','var') && dosendstim)
        cburt.model.adaptstimuli=1;
        cburt.communication.tostimulus.on=true;
    else
        cburt.model.adaptstimuli=0;
        cburt.communication.tostimulus.on=false;
        cburt.model.loadstimuli=0;
    end;
    cburt.incoming.dealtwith=[];

    if (exist('ndummies','var'))
        cburt.model.ndummies=ndummies;
    end;
    % Extra options

    [pth subj ext]=fileparts(cburt.incoming.processeddata);

    posthoc_subj=fullfile(posthocpath,subj);

    if (~exist(posthoc_subj,'dir'))
        mkdir(posthocpath,subj);
    end;
    ind=0;
    for i=1:length(cburt.incoming.series)
        if (~isempty(strfind(cburt.incoming.series(i).protocolname,'CBU_EPI')) || (rerunnormalisation && ~isempty(strfind(cburt.incoming.series(i).protocolname,'CBU_MPRAGE'))))
            fprintf('Adding %d which has protocol %s\n', i,cburt.incoming.series(i).protocolname);
            ind=ind+1;
            fid=fopen(fullfile(posthoc_subj,sprintf('series99%04d.txt',ind)),'w');
            fprintf(fid,'MEAS_START%c%c',[13 10]);
            for j=1:length(cburt.incoming.series(i).receivedvolumes)
                [pth1 fle1 ext1]=fileparts(cburt.incoming.series(i).receivedvolumes{j});
                [pth2 fle2 ext2]=fileparts(pth1);
                fprintf(fid,'DATAFILE DICOMIMA %s%c%c',fullfile([fle2 ext2],[fle1 ext1]),[13 10]);
            end;
            fprintf(fid,'MEAS_FINISHED%c%c',[13 10]);
            fclose(fid)
            cburt.directory_conventions.incomingmetapath=posthoc_subj;
        end;
    end;
    cburt_watcher(cburt,false);

end;
