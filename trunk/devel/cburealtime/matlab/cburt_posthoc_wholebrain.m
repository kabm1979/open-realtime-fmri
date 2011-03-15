function [cburt]=cburt_posthoc_wholebrain(processedpath)

firstgenonly=true;

hpf=40; % high pass filter (secs)
modelpath='/realtime/scratch/wholebrainmodels';
if ~iscell(processedpath)
    processedpath={processedpath};
end;

for k=1:length(processedpath)
    [pth subj ext]=fileparts(processedpath{k});
    fprintf('Subject %s\n',subj);
    cburt_posthoc_smooth(processedpath{k});
    % Load up previous cburt path
    load(fullfile(processedpath{k},'cburt'))

    nscan=[];
    ind=1;
    imgs=[];
    for i=1:length(cburt.incoming.series)
        if (~isempty(strfind(cburt.incoming.series(i).protocolname,'CBU_EPI')) )
            if (firstgenonly)
                thisimg=cburt_getimages(cburt,i,[1:725],'sr');
            else
                thisimg=cburt_getimages(cburt,i,[1:length(cburt.incoming.series(i).receivedvolumes)],'sr');
            end;
            fprintf('Session %d found %d images\n',ind,size(thisimg,1));
            imgs=strvcat(imgs,thisimg);
            nscan=[nscan size(thisimg,1)];
            cburt.incoming.series(i).model.SPM.Sess.C.C=[];
            cburt.incoming.series(i).model.SPM.Sess.C.name={};
            cburt.incoming.series(i).model.SPM.Sess.U=cburt.incoming.series(i).model.SPM.Sess.U(1:92);
            if (firstgenonly)
                for stim=1:92
                    cburt.incoming.series(i).model.SPM.Sess.U(stim).ons=cburt.incoming.series(i).model.SPM.Sess.U(stim).ons(1);
                    cburt.incoming.series(i).model.SPM.Sess.U(stim).dur=cburt.incoming.series(i).model.SPM.Sess.U(stim).dur(1);
                end;
            end;
            if (ind==1)
                SPM=cburt.incoming.series(i).model.SPM;
                SPM.xX.K.HParam = hpf;
                SPM.xY.RT=1;
            else
                SPM.Sess(ind)=cburt.incoming.series(i).model.SPM.Sess;
            end;
            ind=ind+1;
        end;
    end;
    if (~exist(fullfile(modelpath,subj),'dir'))
        mkdir(modelpath,subj);
    end;


    SPM.nscan=nscan;
    SPM.xY.P = imgs;
    cwd=pwd;
    cd(fullfile(modelpath,subj))
    SPMdes = spm_fmri_spm_ui(SPM);
    spm_unlink(fullfile('.', 'mask.img')); % avoid overwrite dialog
    SPMest = spm_spm(SPMdes);
    cd(cwd);
end;
