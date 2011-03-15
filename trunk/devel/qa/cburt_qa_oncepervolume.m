function [cburt] = cburt_qa_oncepervolume(cburt,seriesnum,imgnum)

% Prevent air bubbles in the FOV (motion/marriages)
% Wait 5 minutes until start of scan (minimize residual flow)

dmy = 4; % dummy scans [4]

current = cburt_getimages(cburt,seriesnum,imgnum);
V = spm_vol(current);
Y = spm_read_vols(V);
Y = permute(Y,[2 1 3]);
Y = flipdim(Y,1);
Y = flipdim(Y,2);

[xdim,ydim,zdim] = size(Y);


    % centroid calculation / check out repmat for speed optimization!
    area = sum(sum(Y,1),2);
    [cy cx cz] = ndgrid(1:size(Y,1),1:size(Y,2),1:size(Y,3)); % each pixel set to its x coordinate
    centrx = sum(sum(Y.*cx,1),2)./area;
    centry = sum(sum(Y.*cy,1),2)./area;

    tol = 3.5; % [px] / we can detect position changes with a precision of some um!
    decent = (centrx < (xdim/2+0.5-tol)) + (centrx > (xdim/2+0.5+tol)) + (centry < (ydim/2+0.5-tol)) + (centry > (ydim/2+0.5+tol));
    if (mean(decent(:)) > 0),
        disp('The phantom is not centred ...')
    end

if imgnum > dmy

    cburt.incoming.series(seriesnum).qa.centrx(imgnum-dmy,:)=centrx;
    cburt.incoming.series(seriesnum).qa.centry(imgnum-dmy,:)=centry;
    cburt.incoming.series(seriesnum).qa.sl_mean(imgnum-dmy,:)=area/(xdim*ydim);
    cburt.incoming.series(seriesnum).qa.Z(:,:,:,imgnum-dmy) = Y;

else
    disp(['dummy scan # ',num2str(imgnum)])
end


%% This is for real-time phantom positioning ;-)
% figure(7);clf;set(gcf,'Position',[700 200 300 300]);set(gca,'YDir','reverse')
% hold on;
% plot(centrx(1,1),centry(1,1),'b*');text(centrx(1,1),centry(1,1),num2str('  first'),'FontSize',8');
% plot(centrx(1,zdim),centry(1,zdim),'r*');text(centrx(1,zdim),centry(1,zdim),num2str('  last'),'FontSize',8');
% plot(32.5,32.5,'k+');xlim([32.5-3.5 32.5+3.5]);ylim([32.5-3.5 32.5+3.5])
% xlabel('x [px]');ylabel('y [px]');title('centroid of first and last slice')
% hold off;