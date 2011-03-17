function [cburt]=cburt_roi_inversenormalise_extra(cburt,rois,destspace)

invsnfn=dir(fullfile(cburt.incoming.processeddata,'*_seg_inv_sn.mat'));
if (length(invsnfn)~=1)
    fprintf('Expected only one inv_sn file but trying to continue anyway\n');
end;

if (~iscell(rois))
    rois={rois};
end;

for i=1:length(rois)
    spm_write_sn(rois{i},fullfile(cburt.incoming.processeddata,invsnfn(1).name));
    [pth nme ext]=fileparts(rois{i});
    invnormfn=fullfile(pth,['w' nme ext]);


    if (exist('destspace','var'))
        spm_reslice(strvcat(destspace,invnormfn),struct('which',1,'mean',0));
    end;

end;


