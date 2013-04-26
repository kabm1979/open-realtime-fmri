function [cburt]=cburt_dtidiagnostics(cburt,seriesnum,imgnum)
current=cburt_getimages(cburt,seriesnum,imgnum);
V=spm_vol(current);
Ydiff=spm_read_vols(V);

% Calculate 90th percentile
datsort=sort(Ydiff(:));
perc90=datsort(round(length(datsort)*0.9));

% call the second one ind and the bottom will work
%% Now display and calculate diagnostics

% Mean of each slice for 64 images with b=700
%Ymn=squeeze(mean(mean(Y,1),2));
%Ymn=Ymn(2:end,:);
%figure(100+series); imagesc(Ymn)
%xlabel('Slice number');
%ylabel('Diffusion direction');
%title('Slice mean');


% Difference of each slice from typical mean for this slice with b=700
%Gmn=mean(Ymn,1);
%Ydiff=Ymn-repmat(Gmn,[size(Ymn,1) 1]);
%figure(200+series); imagesc(Ydiff,[-10 10]);
%xlabel('Slice number');
%ylabel('Diffusion direction');
%title('Difference relative to normal value for this slice');

% RMS difference between odd-even slices
Ysqdiff=(Ydiff(:,:,11:2:67)-Ydiff(:,:,10:2:67)).^2;
OddEven=sqrt(mean(Ysqdiff(:)));



Ysqdiff=(Ydiff(:,:,11:2:67)-Ydiff(:,:,10:2:67)).^2;
OddEven=sqrt(mean(Ysqdiff(:)));

% Record values
cburt.incoming.series(seriesnum).perc90(imgnum)=perc90;
cburt.incoming.series(seriesnum).oddeven(imgnum)=OddEven;

ctot=[];
for slice=11:67
    target=Ydiff(:,:,slice);
    neighbours=(Ydiff(:,:,slice-1)+Ydiff(:,:,slice+1))/2;
    c=corrcoef(target(:),neighbours);
    ctot=[ctot c(2,1)];
end;
cburt.incoming.series(seriesnum).oddeven_corr(imgnum)=mean(ctot);

figure(200);
subplot(311);
bar(cburt.incoming.series(seriesnum).perc90);
xlabel('DTI direction');
ylabel('90th percentile');

subplot(312);
bar(cburt.incoming.series(seriesnum).oddeven);
xlabel('DTI direction');
ylabel('Odd/even rms');

subplot(313);
h=bar(cburt.incoming.series(seriesnum).oddeven_corr);
% for barind=1:length(cburt.incoming.series(seriesnum).oddeven_corr)
%     if cburt.incoming.series(seriesnum).oddeven_corr(barind)<0.9
%         set(h(barind),'facecolor','red');
%     end;
% end;
xlabel('DTI direction');
ylabel('Odd/even correlation');
