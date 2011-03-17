function [cburt]=cburt_watcher_posthoc_daionly(processedpath)

posthocpath='/realtime/scratch/posthoc';

if ~iscell(processedpath)
    processedpath={processedpath};
end;

for k=1:length(processedpath)
    % Load up previous cburt path
    load(fullfile(processedpath{k},'cburt'))
    % Don't load up stimuli
    cburt.model.adaptstimuli=0;
    cburt.model.loadstimuli=0;
    cburt.communication.tostimulus.on=false;
    cburt.incoming.dealtwith=[];

    % Extra options

    [pth subj ext]=fileparts(processedpath{k});

    posthoc_subj=fullfile(posthocpath,subj);

    if (~exist(posthoc_subj,'dir'))
        mkdir(posthocpath,subj);
    end;
    ind=0;
    for i=1:length(cburt.incoming.series)
        if (strfind(cburt.incoming.series(i).protocolname,'CBU_EPI'))
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
    cburt=cburt_watcher_posthoc_daionly_inner(cburt,false);

end;
