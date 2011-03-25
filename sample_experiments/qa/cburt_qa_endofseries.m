function cburt = cburt_qa_endofseries(cburt,seriesnum)

%close 12; close 14; close 15;

%% QA report folder
qadir = '/home/stefanh/realtime/scratch/processed/qareport/';

%% Collect Data from user & dicom header:

Humi = 'Heaven';
while ( (isempty(Humi)) || (~isfloat(Humi)) || Humi > 100 )
Humi = input('\nPlease enter Humidity [%]: '); % scanner room
end;

Temp = 'Heaven';
while ( (isempty(Temp)) || (~isfloat(Temp)) || Temp > 50 )
Temp = input('\nPlease enter Temperature [°C]: '); % scanner room
end;

Hell = 'Heaven';
while ( (isempty(Hell)) || (~isfloat(Hell)) || Hell > 100 )
Hell = input('\nPlease enter Helium level [%]: '); % System > Control > MrScanner > "Helium Fill Level"
end;

Chan = 0;
while ( ~xor((Chan == 12),(Chan == 32)) )
Chan = input('\nPlease enter number of coil elements [12/32]: '); % Standard 12-channel or 32-channel coil
end;

switch(cburt.incoming.series(seriesnum).receivedvolumesformat)
    case 'dcm'
        info = dicominfo(cburt.incoming.series(seriesnum).receivedvolumes{1});
        if ((info.FlipAngle ~= 78) || (info.EchoTime ~= 30) || (info.PixelBandwidth ~= 2232) || (info.RepetitionTime ~= 2000)), disp('Check sequence parameters!'), end;
        Freq = dcmparser(cburt.incoming.series(seriesnum).receivedvolumes{1},'sTXSPEC.asNucleusInfo[0].lFrequency      = ');
        Ampl = dcmparser(cburt.incoming.series(seriesnum).receivedvolumes{1},'sTXSPEC.asNucleusInfo[0].flReferenceAmplitude = ');
    case 'img'
        info=[];
        info.AcquisitionDate=num2str(now);
        info.AcquisitionTime=num2str(now);
        Freq=cburt.incoming.series(seriesnum).hdr.siemensap.sTXSPEC.asNucleusInfo{1}.lFrequency;
        Ampl=cburt.incoming.series(seriesnum).hdr.siemensap.sTXSPEC.asNucleusInfo{1}.flReferenceAmplitude;
        if ((cburt.incoming.series(seriesnum).hdr.siemensap.adFlipAngleDegree ~= 78) ...
                || ((cburt.incoming.series(seriesnum).hdr.siemensap.alTE/1000)~= 30) ...             
                || ((cburt.incoming.series(seriesnum).hdr.siemensap.alTR/1000) ~= 2000)), ...
                disp('Check sequence parameters!'), end;        
        % Haven't found this yet: || (info.PixelBandwidth ~= 2232) ...
       
end;
fprintf('\nDATE  = %s\n', info.AcquisitionDate);
fprintf('TIME  = %s\n', info.AcquisitionTime);
Freq = str2double(Freq); fprintf('FREQ  = %.6f\n', Freq);
Ampl = str2double(Ampl); fprintf('AMPL  = %.6f\n', Ampl);

% Coil = dcmparser(cburt.incoming.series(seriesnum).receivedvolumes{1},'asCoilSelectMeas[0].asList[11].lRxChannelConnected = ');
% Chan = str2double(Coil); fprintf('CHAN  = %.6f\n\n', Chan);
% 4 Marta: Replace upper line by this one...
%                        Coil = dcmparser(cburt.incoming.series(seriesnum).receivedvolumes{1},'asCoilSelectMeas[0].asList[0].sCoilElementID.tCoilID = ');

% 4 Marta: ... and then: Chan = 12; if upper Chan is filled with string: ""32Ch_Head""
%                   and  Chan = 32; if upper Chan is filled with string: ""HeadMatrix""

%% Read acquired QA time series data:
Z = cburt.incoming.series(seriesnum).qa.Z;
centrx = cburt.incoming.series(seriesnum).qa.centrx;
centry = cburt.incoming.series(seriesnum).qa.centry;
sl_mean = cburt.incoming.series(seriesnum).qa.sl_mean;
[xdim ydim zdim rep] = size(Z);

%% Definition of ROIs
ROI = zeros(ydim, xdim, zdim);
cph = 20; % edge length of central phantom ROI (20)
ROI_phantom = ROI; ROI_phantom(ydim/2-cph/2+1:ydim/2+cph/2,xdim/2-cph/2+1:xdim/2+cph/2,:) = 1;  % central phantom (20x20)
ROI_noise1  = ROI; ROI_noise1(1:ydim,1:8,:) = 1;                                                % left band (8)
ROI_noise2  = ROI; ROI_noise2(1:ydim,xdim-7:xdim,:) = 1;                                        % right band (8)
ROI_ghost0  = ROI; ROI_ghost0(xdim/2-7:xdim/2+8,1:ydim,:) = 1;                                  % central band (16)
ROI_ghost1  = ROI; ROI_ghost1(1:8,1:ydim,:) = 1;                                                % upper band (8)
ROI_ghost2  = ROI; ROI_ghost2(xdim-7:xdim,1:ydim,:) = 1;                                        % lower band (8)

%% Calculate QA parameters
warning off all;

avg = mean(Z,4);
%rSD = 100*std(Z,[],4)./avg;

% drift correction of time course within central phantom ROI for calculating standard deviation
Zf = Z;
[b,a] = butter(3,0.2,'high');
for y = ydim/2-cph/2-1:ydim/2+cph/2
    for x = xdim/2-cph/2-1:xdim/2+cph/2
        for z = 1:zdim
            Zf(y,x,z,:) = filtfilt(b,a,Z(y,x,z,:));
        end
    end
end
rSD = 100*std(Zf,[],4)./avg;

for k = 1:zdim
    %% centroid drift [px/TR]
    ty = centry(:,k);
    tx = [ones(rep,1) (1:rep)'];
    [b, bint] = regress(ty,tx,0.05);
    c_slope(k) = b(2);
    c_offset(k) = b(1);
    
    rSD_tmp = rSD(:,:,k);
    avg_tmp = avg(:,:,k);

    % Stability ROI (central 20x20)
    stab(k) = mean(rSD_tmp(isfinite( 1./ROI_phantom(:,:,k))));
    %stab(k) = mean(rSD_tmp(avg_tmp > max(max(avg_tmp))/3)); % image intensity based mask for in-vivo experiments
    %figure(1); imagesc(rSD_tmp.*( avg_tmp > max(max(avg_tmp))/3 ),[0 10]);axis image;axis off;colorbar;pause(0.1);

    
    % SNR0 (central 20x20 vs. two noise bands along PE direction) // alternatively use slice not covering the phantom for "real" noise!
    SNR0(k) = 0.66 * mean(avg_tmp(isfinite( 1./ROI_phantom(:,:,k)))) /std(avg_tmp(isfinite( 1./(ROI_noise1(:,:,k)+ROI_noise2(:,:,k)))));

    % Nyquist ghost level (one central band vs. two ghost bands within the averaged image)
    %ghost(k) = 100* mean(avg_tmp(isfinite( 1./(ROI_ghost1(:,:,k)+ROI_ghost2(:,:,k))))) /mean(avg_tmp(isfinite( 1./(ROI_ghost0(:,:,k)))));
    % Just for fun: subtract mean noise from phantom ROI and ghost ROI assuming homogeneous noise
     mnoise(k) = mean(avg_tmp(isfinite( 1./(ROI_noise1(:,:,k)+ROI_noise2(:,:,k)))));
     ghost(k) = 100* ( mean(avg_tmp(isfinite( 1./(ROI_ghost1(:,:,k)+ROI_ghost2(:,:,k))))) - mnoise(k)) / ( mean(avg_tmp(isfinite( 1./(ROI_ghost0(:,:,k))))) - mnoise(k) );
end;
stab_vol  = mean(stab);    stab_vol_sd  = std(stab);
SNR0_vol  = mean(SNR0);    SNR0_vol_sd  = std(SNR0);
ghost_vol = mean(ghost);   ghost_vol_sd = std(ghost);
CENTRYd   = mean(c_slope); CENTRYd_sd   = std(c_slope);
unifo     = 100*(1 - (max(avg(isfinite( 1./ROI_phantom))) - min(avg(isfinite( 1./ROI_phantom)))) / (max(avg(isfinite( 1./ROI_phantom))) + min(avg(isfinite( 1./ROI_phantom)))) );

%% Visualize QA results
fprintf('---- QA RESULTS ----\n');
fprintf('SNR_0   = %.6f', SNR0_vol); fprintf('\t+- %.6f \n', SNR0_vol_sd);
fprintf('FLUCT   = %.6f', stab_vol); fprintf('\t+- %.6f \t\t[%%]\n', stab_vol_sd);
fprintf('SGR     = %.6f', ghost_vol); fprintf('\t+- %.6f \t\t[%%]\n', ghost_vol_sd);
fprintf('CENTRYd = %E', CENTRYd); fprintf('\t+- %E \t[px/TR]\n', CENTRYd_sd);
fprintf('HOMOG   = %.6f \t[%%]\n', unifo);

figure(21);set(gcf,'Position',[50 50 1024 768]);
subplot(331)
    imagesc(([avg(:,:,1),avg(:,:,zdim)]));axis image; axis off;colormap(jet);title('averaged signal of first & last slice')
    text(18,26,['SNR0 = ',num2str(SNR0_vol,'%10.1f')],'FontSize',6')
    text(18,34,['Homog = ',num2str(unifo,'%10.1f'),'%'],'FontSize',6')
subplot(332)
    imagesc([rSD(:,:,1),rSD(:,:,zdim)],[0 50]);axis image; axis off;colormap(jet);title('temporal standard deviation [red=50%]')
    subplot(333)
    plot(stab,'.-');xlabel('slice #');title('phantom ROI standard deviation [%]')
    text(2,stab_vol,num2str(stab_vol),'FontSize',8');
subplot(334)
    hold on;set(gca,'YDir','reverse')
    plot(centrx(1,1),centry(1,1),'b*');text(centrx(1,1),centry(1,1),num2str('  first'),'FontSize',8');
    plot(centrx(1,zdim),centry(1,zdim),'r*');text(centrx(1,zdim),centry(1,zdim),num2str('  last'),'FontSize',8');
    plot(32.5,32.5,'k+');xlim([32.5-3.5 32.5+3.5]);ylim([32.5-3.5 32.5+3.5])
    xlabel('x [px]');ylabel('y [px]');title('centroid of first and last slice')
    hold off;
    % plot(centry(:,zdim/2),'.-');xlabel('repetition');title('centroid in PE direction [px] of central slice')
subplot(335)
    plot(mean(centry,1),'.-');xlabel('slice #');title('centroid in PE and RO (x) direction [px]');hold on;
    plot(mean(centrx,1),'x');xlabel('slice #');
subplot(336)
    plot(c_slope,'.-');xlabel('slice #');title('centroid drift in PE direction [px/TR]');
    text(2,mean(c_slope),num2str(mean(c_slope)),'FontSize',8');
subplot(337)
    plot(mean(sl_mean,2),'.-'); xlabel('repetition');title('mean(signal) of whole volume')
    b = regress(mean(sl_mean,2),[ones(rep,1) (1:rep)']);
    gsd = 100 * b(2)/b(1);  % global signal drift [%]
    text(2,mean(mean(sl_mean,2)),['drift = ',num2str(gsd),' %'],'FontSize',8');
subplot(338)
    plot(ghost,'.-');xlabel('slice #');title('Nyquist ghost level [%]')
    text(2,ghost_vol,num2str(ghost_vol),'FontSize',8');
subplot(339)
    % for r=1:rep 
    %         slice = Z(:,:,:,r) + 500*(ROI_phantom+ROI_noise1+ROI_noise2+ROI_ghost0+ROI_ghost1+ROI_ghost2);
    %         imagesc(log([slice(:,:,1),slice(:,:,zdim)]),[2 8]); colormap(jet), axis image, axis off; 
    %         text(20,36,['rep=',num2str(r)],'FontSize',6');title('log(signal)');
    %         pause(0.05);
    % end;
drawnow;

%% Spike detection
sens = -erfinv(1/(zdim*rep)-1)*sqrt(2)+1.0; % threshold in units of STD (+ offset [1.0])
% Scale with number of samples (reps*slices) to prevent false alarms = (1 - erf(sens/sqrt(2)))*slices*rep
% http://en.wikipedia.org/wiki/Standard_deviation#Rules_for_normally_distributed_data

% % % DETREND timecourse
%
% % (A) Subtract cubic fit:
%   t = linspace(0,1,rep)';
%   X = [ones(rep,1), t, t.^2]; % why exponential decay of overall signal?? (replacing t.^6 by exp(t) helps)
%   invX = pinv(X);
%   for s = 1:zdim
%       dsl_mean(:,s) = sl_mean(:,s) - X*(invX*sl_mean(:,s));
%   end;
%
% % (B) SET HIGH PASS FILTER  with butterworth order 3 / Have a look at this:
%   cburt.model.highpassperiod = 128; % filter out frequencies with period below
%   cburt.model.TR = 1; % seconds
%   nyquistfreq = 0.5/cburt.model.TR;
%   [cburt.model.filter.hpf_b cburt.model.filter.hpf_a] = butter(3,1/(cburt.model.highpassperiod*nyquistfreq),'high');
%   nvol = size(cburt.incoming.series(seriesnum).timeseries.norm,1);
%   if (nvol<=3*(length(cburt.model.filter.hpf_b)-1))
%       cburt.incoming.series(seriesnum).timeseries.filtered = cburt.incoming.series(seriesnum).timeseries.norm;
%   else
%       cburt.incoming.series(seriesnum).timeseries.filtered = filtfilt(cburt.model.filter.hpf_b,cburt.model.filter.hpf_a,cburt.incoming.series(seriesnum).timeseries.norm);
%   end
    
% % (C) Precisely zero-phase distortion with the "filtfilt" method (spike position not shifted! *but* filter effects in time steps around spike!!)
[b,a] = butter(3,0.2,'high');
for s = 1:zdim
    dsl_mean(:,s) = filtfilt(b,a,sl_mean(:,s));
end;
   
% Calculate mean and std of detrended timecourse 
% TODO: optimize for speed (for Rhodri) and beauty (for Marta)
M2 = mean(dsl_mean,1);
M3 = std(dsl_mean,0,1);
M4 = zeros(size(dsl_mean))';
n = 0;
for r=1:rep
    for s=1:zdim
        if ( abs(dsl_mean(r,s)-M2(s)) > sens*M3(s) ) % Are spikes with negative k-space energy possible at all? If not: remove 'abs'!
            M4(s,r)=dsl_mean(r,s); n=n+1;
            figure(22);
            subplot(221)
            imagesc(log(Z(:,:,s,r)),[2 8]);axis image;axis off;colormap(gray);title(['detected spikes (thres=',num2str(sens),'\sigma)'])
            text(22,28,['slc ',num2str(s),''],'FontSize',8')
            text(22,34,['rep ',num2str(r),''],'FontSize',8')
            subplot(222)
            plot(dsl_mean(:,s));hold on;plot(r,dsl_mean(r,s),'r*');hold off;title(['timecourse (spike# ',num2str(n),')']) %plot(sl_mean(:,s)-mean(sl_mean(:,s)),'r');
            subplot(223)
            imagesc(M4);ylabel('slice #');xlabel('repetition')
            pause(0.2)
        spikes(n)=figure(22);
        print(spikes(n),'-dpng', '-r90', fullfile(qadir,[sprintf('%s',info.AcquisitionDate) sprintf('%s',info.AcquisitionTime(1:6)) '_spike_' sprintf('%d',n) '.png'])  )  % spiky slices
        end;
    end;
end;
drawnow;
figure(21);subplot(339);
imagesc(M4);ylabel('slice #');xlabel('repetition')
title(['detected spikes = ',num2str(n),' (thres=',num2str(sens),'\sigma)'])
print(figure(21),'-dpng','-r130', fullfile(qadir,[sprintf('%s',info.AcquisitionDate) sprintf('%s',info.AcquisitionTime(1:6)) '_QA.png'])  )

%% Write results to QA.txt
info.AcquisitionDate = str2double(info.AcquisitionDate);
info.AcquisitionTime = str2double(info.AcquisitionTime);
QA = [info.AcquisitionDate, info.AcquisitionTime, Chan, Hell, Freq, Ampl, unifo, SNR0_vol, SNR0_vol_sd, stab_vol, stab_vol_sd, ghost_vol, ghost_vol_sd, CENTRYd, CENTRYd_sd, centry(1,1), centry(1,zdim), centrx(1,1), centrx(1,zdim), n, gsd, Humi, Temp];

Ch = Chan;

if Ch==12
    fid = fopen([qadir 'QA12.txt'], 'at');
end
if Ch==32
    fid = fopen([qadir 'QA32.txt'], 'at');
end
fprintf(fid, '%.9f %.9f %.9f %.9f %.9f %.9f %.9f %.9f %.9f %.9f %.9f %.9f %.9f %.9f %.9f %.9f %.9f %.9f %.9f %.9f %.9f %.9f %.9f\n', QA);
fclose(fid);

%% Show QA history
if Ch==12
    [Date, Time, Chan, Hell, Freq, Ampl, unifo, SNR0_vol, SNR0_vol_sd, stab_vol, stab_vol_sd, ghost_vol, ghost_vol_sd, CENTRYd, CENTRYd_sd, centryf, centryl, centrxf, centrxl, n, gsd, Humi, Temp] = ...
    textread([qadir 'QA12.txt'], '%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f');
end
if Ch==32
    [Date, Time, Chan, Hell, Freq, Ampl, unifo, SNR0_vol, SNR0_vol_sd, stab_vol, stab_vol_sd, ghost_vol, ghost_vol_sd, CENTRYd, CENTRYd_sd, centryf, centryl, centrxf, centrxl, n, gsd, Humi, Temp] = ...
    textread([qadir 'QA32.txt'], '%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f');
end

sDate = num2str(Date); yyyy = str2num(sDate(:,1:4)); mm = str2num(sDate(:,5:6)); dd = str2num(sDate(:,7:8)); AD = datenum([yyyy mm dd]) - datenum([2009 11 02]) + Time/240000; % Anno Domini

figure(23);set(gcf,'Position',[100 100 1024 768]);
subplot(331);plot(AD,unifo,'.-'),title('Uniformity [%]');
subplot(332);errorbar(AD,SNR0_vol,SNR0_vol_sd,'.-'),title('SNR0 [%]');
subplot(333);errorbar(AD,stab_vol,stab_vol_sd,'.-'),title('Fluctuations [%]');
subplot(334);errorbar(AD,ghost_vol,ghost_vol_sd,'.-'),title('Ghost Level [%]');
subplot(335);errorbar(AD,CENTRYd,CENTRYd_sd,'.-'),title('Drift in PE direction [px/TR]');
subplot(336);plot(AD,Freq,'.-'),title('Center Frequency [Hz]');
subplot(337);plot(AD,Ampl,'.-'),title('Reference Amplitude [V]');
subplot(338);plot(AD,Hell,'k.-', AD,Humi,'b.-', AD,Temp,'r.-'),title('Scanning Weather');legend('Helium level [%]','Humidity [%]','Temperature [°C]'),legend('boxoff') % Helium evaporation ~0.56 percent per day
subplot(339);plot(AD,n,'.--'),hold on,for i=1:numel(n), if n(i)>0, plot(AD(i),n(i),'r*'), end,end,title('Detected Spikes');

if Ch==12
    xlabel('12-channel coil')
    print(figure(23),'-dpng','-r130', fullfile(qadir,'QA-history12.png')  )
end
if Ch==32
    xlabel('32-channel coil')
    print(figure(23),'-dpng','-r130', fullfile(qadir,'QA-history32.png')  )
end


% input('\n*** FINISHED (Log off, please.) ***');


% Correlations between QA parameters?
% xx = [Date, Time, Chan, Hell, Freq, Ampl, unifo, SNR0_vol, SNR0_vol_sd, stab_vol, stab_vol_sd, ghost_vol, ghost_vol_sd, CENTRYd, CENTRYd_sd, centryf, centryl, centrxf, centrxl, n, gsd, Humi, Temp];
% [rx,px] = corrcoef(xx);
% figure; imagesc((px<0.05).*rx,[-1 1]); axis image; colorbar  % significant correlations

% RHODRI - removed these!
% pause (3)
% quit force