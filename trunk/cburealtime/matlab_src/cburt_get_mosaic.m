function [img]=cburt_get_mosaic(Y,plotit)
if ~exist('plotit','var')
    plotit=false;
end;

gap=0;
w=ceil(sqrt(size(Y,3)));
xpos=1; ypos=1;
img=[];
width=size(Y,1); height=size(Y,2);
for zpos=1:size(Y,3)
    img(xpos:(xpos+width-1),ypos:(ypos+height-1))=Y(:,:,zpos);
    xpos=xpos+width+gap;
    if (mod(zpos,w)==0)
        xpos=1;
        ypos=ypos+height+gap;
    end;
end;

if plotit
    imagesc(img',[0 6*mean2(img)]);
    colormap('gray');
end;