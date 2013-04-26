%% Load up data
pth='/media/DE-Data/pruebas_Realigment_for_RealTime_DTI/all_patients/P016_11_02_13_run1';

series=41;

% Finds images for this series, following realignment rf*
fn=dir(fullfile(pth,sprintf('rf*-%04d-*.nii',series)));

V={};
Y=[];
for fnind=1:length(fn)
    V{fnind}=spm_vol(fullfile(pth,fn(fnind).name));
    Y(fnind,:,:,:)=spm_read_vols(V{fnind});   
end;

%% New index - 90 percentile of global intensity

pctiles = zeros(1,size(Y,1));

for fnind = 1:size(Y,1)
    pctiles(fnind) = prctile(reshape(Y(fnind,:,:,:),1,prod(size(Y))/size(Y,1)),90);   
end

pctiles = pctiles(2:end);

[sortpc sortpcidx] = sort(pctiles);

% call the second one ind and the bottom will work
%% Now display and calculate diagnostics

% Mean of each slice for 64 images with b=700
%Ymn=squeeze(mean(mean(Y,2),3));
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
%OddEven=sqrt(mean((Ydiff(:,11:2:67)-Ydiff(:,10:2:67)).^2,2));
%figure(300+series); barh(OddEven);
%xlim([0 5]);
%ylabel('Diffusion direction');
%title('Error indicator');

% Sort by this measure
%[junk ind]=sort(OddEven);

%% Best and worst
% Plot 4 best
%figure(400+series);
%for bestind=1:4
   % subplot(2,2,bestind)
  %  cburt_get_mosaic(squeeze(Y(1+ind(bestind),:,:,:)),true);
 %   title(sprintf('Best, img %d',1+ind(bestind)));
%end;

% Plot 4 worst
%figure(500+series);
%for worstind=1:4
   % subplot(2,2,worstind)
  %  cburt_get_mosaic(squeeze(Y(1+ind(end+1-worstind),:,:,:)),true);
 %   title(sprintf('Worst, img %d',1+ind(end+1-worstind)));
%end;


%% Best and worst for new index
% Plot 4 best (they are arranged in the opposite order than the other
% index)
figure(400+series);
for worstind=1:10
    subplot(2,5,worstind)
    cburt_get_mosaic(squeeze(Y(1+sortpcidx(worstind),:,:,:)),true);
    title(sprintf('Worst, img %d',1+sortpcidx(worstind)));
end;

% Plot 4 worst
figure(500+series);
for bestind=1:4
    subplot(2,2,bestind)
    cburt_get_mosaic(squeeze(Y(1+sortpcidx(end+1-bestind),:,:,:)),true);
    title(sprintf('Best, img %d',1+sortpcidx(end+1-bestind)));
end;

