function [cburt]=cburt_roi_inversenormalise(cburt,seriesnum)

invsnfn=dir(fullfile(cburt.incoming.processeddata,'*_seg_inv_sn.mat'));
if (length(invsnfn)~=1)
    fprintf('Expected only one inv_sn file but trying to continue anyway\n');
end;

% First copy ROIS into the subject directory
if ~exist(fullfile(cburt.incoming.processeddata,'rois'),'file')
    mkdir(cburt.incoming.processeddata,'rois');
end;


needxyz=false;
filelist={};
for i=1:length(cburt.roistonormalise)
    if (isstr(cburt.roistonormalise(i).filename))
        filelist=[filelist cburt.roistonormalise(i).filename];
    else
        needxyz=true;
    end;
end;
if (needxyz)
    filelist=[filelist 'coordsX.nii' 'coordsY.nii' 'coordsZ.nii'];
end;

cburt.roifilelist=filelist;


for i=1:length(filelist)
    cmd=['cp ' fullfile(cburt.directory_conventions.rois,filelist{i}) ' ' fullfile(cburt.incoming.processeddata,'rois')];
    [s w]=unix(cmd);
    if (s)
        fprintf('Error while copying file with %s\n',cmd);
    end;
    spm_write_sn(fullfile(cburt.incoming.processeddata,'rois',filelist{i}),fullfile(cburt.incoming.processeddata,invsnfn(1).name));
    cburt.roistonormalise(i).inversenormalised=fullfile(cburt.incoming.processeddata,'rois',['w' filelist{i}]);
end;