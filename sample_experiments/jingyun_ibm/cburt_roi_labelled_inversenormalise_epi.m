function [cburt]=cburt_roi_labelled_inversenormalise_epi(cburt,seriesnum,V)

% Find normalisation parameters
invsnfn=dir(fullfile(cburt.incoming.processeddata,'*_seg_inv_sn.mat'));
if (length(invsnfn)~=1)
    fprintf('Expected only one inv_sn file but trying to continue anyway\n');
end;

figure(15);
cburt.incoming.series(seriesnum).rois=[];

% Make roifilelist to be normalised

filelist={};
for i=1:length(cburt.rois)
    if ~isstr(cburt.rois(i).filename)
        fprintf('cburt_roi_labelled does not accept non-string filenames in cburt.rois');
    else
        filelist=[filelist cburt.rois(i).filename];
    end;
end;
cburt.roifilelist=filelist;

invsnfn=dir(fullfile(cburt.incoming.processeddata,'*_seg_inv_sn.mat'));
if (length(invsnfn)~=1)
    fprintf('Expected only one inv_sn file but trying to continue anyway\n');
end;

% Interp
flags=[];
flags.interp=0;

% Copy ROIS into the subject/roi directory
%   make roi directory
if ~exist(fullfile(cburt.incoming.processeddata,'rois'),'file')
    mkdir(cburt.incoming.processeddata,'rois');
end;
for i=1:length(filelist)
    cmd=['cp ' fullfile(cburt.directory_conventions.rois,filelist{i}) ' ' fullfile(cburt.incoming.processeddata,'rois')];
    [s w]=unix(cmd);
    if (s)
        fprintf('Error while copying file with %s\n',cmd);
    end;
    spm_write_sn(fullfile(cburt.incoming.processeddata,'rois',filelist{i}),fullfile(cburt.incoming.processeddata,invsnfn(1).name),flags);
    cburt.rois(i).inversenormalised=fullfile(cburt.incoming.processeddata,'rois',['w' filelist{i}]);
end;

% Now make a series specific copy
for i=1:length(cburt.roifilelist)
    [pth fle ext]=fileparts(cburt.roifilelist{i});
    seriesroifn=fullfile(cburt.incoming.processeddata,'rois',sprintf('w%s_forseries_%03d%s',fle,seriesnum,ext));
    cmd=['cp ' fullfile(cburt.incoming.processeddata,'rois',pth,['w' fle ext]) ' ' seriesroifn];
    [s w]=unix(cmd);
    if (s)
        fprintf('Error while copying file with %s\n',cmd);
    end;
    filefilter=sprintf('f*%04d-%05d-%06d-01.nii',seriesnum,1,1);
    fn=dir(fullfile(cburt.incoming.processeddata,filefilter));
    imgs=strvcat(fullfile(cburt.incoming.processeddata,fn(1).name),seriesroifn);
    spm_reslice(imgs,flags);
end

% and go through ROIs doing inverse normalising and reslicing
for i=1:length(cburt.rois)
        [pth fle ext]=fileparts(cburt.rois(i).filename);
        seriesroifn=fullfile(cburt.incoming.processeddata,'rois',sprintf('rw%s_forseries_%03d%s',fle,seriesnum,ext));
        cburt.incoming.series(seriesnum).rois(i).inversenormalised=seriesroifn;
        V=spm_vol(cburt.incoming.series(seriesnum).rois(i).inversenormalised);
        Y=spm_read_vols(V);        
        cburt.incoming.series(seriesnum).rois(i).V=V;
        cburt.incoming.series(seriesnum).rois(i).Y=Y;
    end;
    cburt.incoming.series(seriesnum).rois(i).nvox=length(cburt.incoming.series(seriesnum).rois(i).Y(:));
end