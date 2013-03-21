function [cburt]=cburt_diagnostics(cburt,seriesnum,imgnum)
% only run diagnostics if data is fresh and exciting
if (~cburt.internal.livedata)
    return;
end;

filefilter=sprintf('f*%04d-%05d-%06d-01.nii',seriesnum,imgnum,imgnum);
fn=dir(fullfile(cburt.incoming.processeddata,filefilter));
if (length(fn)~=1)
    fprintf('Confused - not 1 matching nii files for %s but %d\n',filefilter,length(fn));
else
    V=spm_vol(fullfile(cburt.incoming.processeddata,fn(1).name));
    Y=spm_read_vols(V);
    Y = flipdim(Y,1); %SH
    Y = flipdim(Y,2); %SH
    if (length(size(squeeze(Y)))==2)
        figure(20);
        subplot(111);
        imagesc(Y);
        colormap('gray');
        drawnow;
    else
        figure(20);%set(gcf,'Position',[100 300 500 200]);

        % Plot means
        subplot(1,2,1);
        img=cburt_get_mosaic(Y);
        imagesc(img',[0 6*mean2(img)]);
        axis off
        axis equal
        %colorbar;
        colormap('gray');
        title(['repetition ',num2str(imgnum)]);

        % and difference image
        if (isfield(cburt.incoming,'lastimage'))
            if (all(size(cburt.incoming.lastimage)==size(Y)))
                Ydiff=Y-cburt.incoming.lastimage;
                % Plot differences
                subplot(1,2,2);
                xpos=1; ypos=1;
                img=[];
                for zpos=1:size(Ydiff,3)
                    img(xpos:(xpos+width-1),ypos:(ypos+height-1))=Ydiff(:,:,zpos);
                    xpos=xpos+width+gap;
                    if (mod(zpos,w)==0)
                        xpos=1;
                        ypos=ypos+height+gap;
                    end;
                end;
                imagesc(img',[-6*std2(img) 6*std2(img)]);
                axis off
                axis equal
                %colorbar;
                colormap('gray');
                title('difference');
            end;
        end;
        cburt.incoming.lastimage=Y;
        drawnow;
    end;
end;