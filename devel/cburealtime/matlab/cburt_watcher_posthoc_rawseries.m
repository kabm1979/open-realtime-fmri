% function [cburt]=cburt_watcher_posthoc(processedpath,rawseriespath,rawseriesnumbers)
%  Reconstructs a realtime analysis run using dicom files in rawseriespath
%  for input data, and stimuli from cburt.model.series(XXX).actualstimuli 
%  processedpath: full path to processed folder
%  rawseriespath: full path to raw data
%  rawseriesnumbers: series numbers of EPIs

function [cburt]=cburt_watcher_posthoc_rawseries(processedpath,rawseriespath,rawseriesnumbers)


posthocpath='/realtime/scratch/posthoc';

if ~iscell(processedpath)
    processedpath={processedpath};
end;
if ~iscell(rawseriespath)
    rawseriespath={rawseriespath};
    rawseriesnumbers={rawseriesnumbers};
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

    for i=1:length(rawseriesnumbers{k})
        cburt.incoming.series(rawseriesnumbers{k}(i)).receivedvolumes=[];
        fn=dir(fullfile(rawseriespath{k},sprintf('001_%06d_*.dcm',rawseriesnumbers{k}(i))));
        fid=fopen(fullfile(posthoc_subj,sprintf('series99%04d.txt',i)),'w');
        fprintf(fid,'MEAS_START%c%c',[13 10]);
        [pth fle ext]=fileparts(rawseriespath{k});
        subjpath=[fle ext];
        for j=1:length(fn)
            cburt.incoming.series(rawseriesnumbers{k}(i)).receivedvolumes=fullfile(subjpath,fn(j).name);
            fprintf(fid,'DATAFILE DICOMIMA %s%c%c',cburt.incoming.series(rawseriesnumbers{k}(i)).receivedvolumes,[13 10]);
        end;
        fprintf(fid,'MEAS_FINISHED%c%c',[13 10]);
        fclose(fid)
        cburt.directory_conventions.incomingmetapath=posthoc_subj;
    end;
    cburt=cburt_watcher(cburt,false);
end;

end
