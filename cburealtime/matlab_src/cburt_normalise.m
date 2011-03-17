function [cburt]=cburt_normalise(cburt,seriesnum)
tic
niifilter=sprintf('s*-%04d-00001-%06d-01.nii',seriesnum,length(cburt.incoming.series(seriesnum).receivedvolumes));
fn=dir(fullfile(cburt.incoming.processeddata, niifilter));
if (length(fn)~=1)
    fprintf('Normalise expected just one nii file but proceeding with first anyway (%s).\n',fn(1).name);
end;
infile=fullfile(cburt.incoming.processeddata,fn(1).name);

% single pass normalisation - restrict field of view to start with!

estopts.regtype='mni';    % turn on affine again
out = spm_preproc(infile,estopts);
[sn,isn]   = spm_prep2sn(out);
fprintf('Normalisation estimation %f\n',toc);

% columns are   [modulated normalised, unmodulated normalised, native]
writeopts.biascor = 1;
writeopts.GM  = [0 1 0];
writeopts.WM  = [0 0 0];
writeopts.CSF = [0 0 0];
writeopts.cleanup = [0];
spm_preproc_write(sn,writeopts);

[pth nme ext]=fileparts(infile);

subj.matname = fullfile(pth,[spm_str_manip(nme,'sd') '_seg_sn.mat']);
subj.invmatname = fullfile(pth,[spm_str_manip(nme,'sd') '_seg_inv_sn.mat']);
savefields(subj.matname,sn);
savefields(subj.invmatname,isn);

fprintf('Normalisation and write took %f\n',toc);
%------------------------------------------------------------------------
function savefields(fnam,p)
if length(p)>1, error('Can''t save fields.'); end;
fn = fieldnames(p);
if numel(fn)==0, return; end;
for i=1:length(fn),
    eval([fn{i} '= p.' fn{i} ';']);
end;
if str2double(version('-release'))>=14,
    save(fnam,'-V6',fn{:});
else
    save(fnam,fn{:});
end;

return;
%------------------------------------------------------------------------



