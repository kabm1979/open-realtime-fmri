function [cburt]=cburt_roi_inversenormalise_epi(cburt,seriesnum,V)

% Check we're up to date, by retrieving required ROI from stim
if (cburt.communication.tostimulus.on)
    roifilename=cburt_getparameterfromstim(cburt,'roifilename',240);
    cburt.rois=[];
    cburt=cburt_addroi(cburt,'itmask',roifilename,cburt.options.nvox); 
end;

% Find normalisation parameters
invsnfn=dir(fullfile(cburt.incoming.processeddata,'*_seg_inv_sn.mat'));
if (length(invsnfn)~=1)
    fprintf('Expected only one inv_sn file but trying to continue anyway\n');
end;

figure(15);
cburt.incoming.series(seriesnum).rois=[];

% Make roifilelist to be normalised
needxyz=false;
filelist={};
for i=1:length(cburt.rois)
    if (isstr(cburt.rois(i).filename))
        filelist=[filelist cburt.rois(i).filename];
    else
        needxyz=true;
    end;
end;
if (needxyz)
    filelist=[filelist 'coordsX.nii' 'coordsY.nii' 'coordsZ.nii'];
end;
cburt.roifilelist=filelist;

invsnfn=dir(fullfile(cburt.incoming.processeddata,'*_seg_inv_sn.mat'));
if (length(invsnfn)~=1)
    fprintf('Expected only one inv_sn file but trying to continue anyway\n');
end;

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
    spm_write_sn(fullfile(cburt.incoming.processeddata,'rois',filelist{i}),fullfile(cburt.incoming.processeddata,invsnfn(1).name));
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
    spm_reslice(imgs);
end

% and go through ROIs doing inverse normalising and reslicing
loadedcoords=false;
for i=1:length(cburt.rois)
    if (isstr(cburt.rois(i).filename))
        [pth fle ext]=fileparts(cburt.rois(i).filename);
        seriesroifn=fullfile(cburt.incoming.processeddata,'rois',sprintf('rw%s_forseries_%03d%s',fle,seriesnum,ext));
        cburt.incoming.series(seriesnum).rois(i).inversenormalised=seriesroifn;
        V=spm_vol(cburt.incoming.series(seriesnum).rois(i).inversenormalised);
        Y=spm_read_vols(V);
        
        % It is now possible to choose the top "numvox" values from Y
        % (typically applied to function ROIs)
        if (isfield(cburt.rois(i),'numvox'))
            sz=size(Y);
            Y=Y(:);
            Y(isnan(Y))=0;
            [junk ind]=sort(Y,1,'descend');
            Y(ind((cburt.rois(i).numvox+1):end))=0;
            Y=reshape(Y,sz);
            spm_write_vol(V,Y);
            fprintf('!!Writing %s\n',V.fname);
        end;
        cburt.incoming.series(seriesnum).rois(i).V=V;
        cburt.incoming.series(seriesnum).rois(i).Y=find(Y);
    else
        if (~loadedcoords)
            dimensions={'X','Y','Z'};
            for j=1:3
                Vcoords{j}=spm_vol(fullfile(cburt.incoming.processeddata,'rois',sprintf('rwcoords%s_forseries_%03d.nii',dimensions{j},seriesnum)));
                Ycoords{j}=spm_read_vols(Vcoords{j});
            end;
            loadedcoords=true;
        end;
        filename=cburt.rois(i).filename;
        
        switch filename{1}
            case 'sphere'
                centre=filename{2};
                radius=filename{3};
                d=(Ycoords{1}-centre(1)).^2+(Ycoords{2}-centre(2)).^2+(Ycoords{3}-centre(3)).^2;
                d(d>(radius.^2))=0;
                d=d~=0;
                d(isnan(d))=0;
                cburt.incoming.series(seriesnum).rois(i).Y=find(d);
                V=Vcoords{j};
                V.fname=['rwsphere_' cburt.rois(i).name '.nii'];
                spm_write_vol(V,d);
            case 'sphere-bilateral'
                centre=filename{2};
                radius=filename{3};
                d1=(Ycoords{1}-centre(1)).^2+(Ycoords{2}-centre(2)).^2+(Ycoords{3}-centre(3)).^2;
                d2=(Ycoords{1}+centre(1)).^2+(Ycoords{2}-centre(2)).^2+(Ycoords{3}-centre(3)).^2;
                d=min(d1,d2);
                d(d>(radius.^2))=0;
                d=d~=0;
                d(isnan(d))=0;
                cburt.incoming.series(seriesnum).rois(i).Y=find(d);
                V=Vcoords{j};
                V.fname=fullfile(cburt.incoming.processeddata,'rois',['rwsphere_' cburt.rois(i).name '.nii']);
                spm_write_vol(V,d);
        end;
    end;
    cburt.incoming.series(seriesnum).rois(i).nvox=length(cburt.incoming.series(seriesnum).rois(i).Y(:));
    
end;