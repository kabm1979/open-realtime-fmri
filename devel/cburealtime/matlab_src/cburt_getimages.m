function [imgs]=cburt_getimages(cburt,seriesnum,imgnums,prefix)

if (~exist('prefix','var'))
    prefix='';
end;
imgs=[];
for i=imgnums
    filefilter=sprintf('%s*%04d-%05d-%06d-01.nii',prefix,seriesnum,i,i);
    for j=1:30
        fn=dir(fullfile(cburt.incoming.processeddata,filefilter));
        if (length(fn)>0)
            break;
        end;
        fprintf('Awaiting retry to find %s\n',filefilter);
        pause(1.0);
    end;        
    imgs=strvcat(imgs,fullfile(cburt.incoming.processeddata,fn(1).name));
end;