function [cburt]=cburt_realign(cburt,seriesnum,imgnum)

if (size(cburt.incoming.series(seriesnum).realignmentparms,1)<imgnum)
    if (~cburt.incoming.series(seriesnum).timeseries.hasnogradients(imgnum))
        first=cburt_getimages(cburt,seriesnum,cburt.incoming.series(seriesnum).firstvalidimage);
        current=cburt_getimages(cburt,seriesnum,imgnum);
        if (imgnum>1)
            flags.graphics=0;
            M=spm_realign(strvcat(first,current),flags);
            qq = spm_imatrix(M(2).mat/M(1).mat);
            cburt.incoming.series(seriesnum).realignmentparms(imgnum,:)=qq(1:6);
            clear flags;
            flags.which=1;
            flags.mean=0; % djm: don't write mean image. 30/11/09
            %    flags.interp=inf; % non-finite for fourier
            spm_reslice(strvcat(first,current),flags);
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
