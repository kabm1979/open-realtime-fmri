function [cburt]=cburt_addroi(cburt,name,fn,numvox)
if (~exist('filename','var'))
    filename=name;
end;
cburt.rois(end+1).filename=fn;
cburt.rois(end).name=name;
if(exist('numvox','var'))
    cburt.rois(end).numvox=numvox;
end;
 