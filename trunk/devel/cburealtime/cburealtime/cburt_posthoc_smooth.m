function [cburt]=cburt_posthoc_smooth(processedpath,sesses, fwhm)

try fwhm; catch fwhm=14; end

if ~iscell(processedpath)
    processedpath={processedpath};
end;

for k=1:length(processedpath)
    fprintf('Smoothing %s\n',processedpath{k});

    if (exist('sesses','var'))
        for sess=sesses
            % Load up previous cburt path
            load(fullfile(processedpath{k},sprintf('cburt_series%02d.mat',sess)))
            for j=1:length(cburt.incoming.series(sess).receivedvolumes)
                thisimg=cburt_getimages(cburt,sess,j,'r');
                [pth nme ext]=fileparts(thisimg);
                outfile=fullfile(pth,['s' nme ext]);
                if ~exist(outfile,'file'), spm_smooth(thisimg,outfile,fwhm); end
            end;
        end;
    end;
    for i=1:length(cburt.incoming.series)
        if (~isempty(strfind(cburt.incoming.series(i).protocolname,'CBU_EPI')) )
            for j=1:length(cburt.incoming.series(i).receivedvolumes)
                thisimg=cburt_getimages(cburt,i,j,'r');
                [pth nme ext]=fileparts(thisimg);
                outfile=fullfile(pth,['s' nme ext]);
                if ~exist(outfile,'file'), spm_smooth(thisimg,outfile,fwhm); end
            end;
        end;
    end;
end;
