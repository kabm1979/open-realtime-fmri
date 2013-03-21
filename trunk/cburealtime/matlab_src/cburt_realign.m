function [cburt]=cburt_realign(cburt,seriesnum,imgnum)

if (size(cburt.incoming.series(seriesnum).realignmentparms,1)<imgnum)
    if (~isfield(cburt.incoming.series(seriesnum).timeseries,'hasnogradients') || ~cburt.incoming.series(seriesnum).timeseries.hasnogradients(imgnum))
        first=cburt_getimages(cburt,seriesnum,cburt.incoming.series(seriesnum).firstvalidimage);
        current=cburt_getimages(cburt,seriesnum,imgnum);
        if (imgnum>1)
            flags.graphics=0;
            spm_realign(strvcat(first,current),flags);
            M1=spm_vol(first);
            M2=spm_vol(current);
            qq = spm_imatrix(M2.mat/M1.mat);
            cburt.incoming.series(seriesnum).realignmentparms(imgnum,:)=qq(1:6);
            clear flags;
            flags.which=1;
            flags.mean=0; % djm: don't write mean image. 30/11/09
            %    flags.interp=inf; % non-finite for fourier
            spm_reslice(strvcat(first,current),flags);

            % This image and the last...
            lastscan=cburt_getimages(cburt,seriesnum,imgnum-1);
            [pth nme ext]=fileparts(lastscan);
            V1=spm_vol(fullfile(pth,['r' nme ext]));
            Y1=spm_read_vols(V1);
            [pth nme ext]=fileparts(current);
            V2=spm_vol(fullfile(pth,['r' nme ext]));
            Y2=spm_read_vols(V2);
            rmsdiff=sqrt(mean((Y2(:)-Y1(:)).^2));
            cburt.incoming.series(seriesnum).rmsdiff(imgnum)=rmsdiff;
            [pth nme ext]=fileparts(current);
            
        else
            [pth fle ext]=fileparts(first);
            copyfile(first,fullfile(pth,['r' fle ext]));
            cburt.incoming.series(seriesnum).realignmentparms(imgnum,:)=zeros(1,6);
        end;
    else
        cburt.incoming.series(seriesnum).realignmentparms(imgnum,:)=nan([1 6]);
    end;
end;

% [pth fle ext]=fileparts(current);
% spm_smooth(fullfile(pth,['r' fle ext]),fullfile(pth,['sr' fle ext]),[14 14 14]);
