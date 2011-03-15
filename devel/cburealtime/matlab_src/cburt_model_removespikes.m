function [cburt]=cburt_model_removespikes(cburt,seriesnum,imgnum)
if (cburt.model.addrealignmentparms==2)

    if (imgnum>1)
        tmlimit=0.015; % difference between images (proportion of (sum squared diff)/(globals squared))
        xyzlimit=0.5; %mm
        rotlimit=2*pi/360*1; % radians

        % Check whether spike in globals or moves
        gotspike=false;

        td=(cburt.incoming.series(seriesnum).timeseries.global(imgnum)-cburt.incoming.series(seriesnum).timeseries.global(imgnum-1)).^2;
        tm = (td/cburt.incoming.series(seriesnum).timeseries.global(imgnum)).^2;
        if (tm > tmlimit)
            gotspike=true;
        else

            rpdiff = cburt.incoming.series(seriesnum).realignmentparms(imgnum,:)-cburt.incoming.series(seriesnum).realignmentparms(imgnum-1,:);
            xyzdiff=max(rpdiff(1:3));
            rotdiff=max(rpdiff(4:6));
            
            xabsrpdiff = abs(rpdiff);
            if (xyzdiff > xyzlimit) || (rotdiff > rotlimit)
                gotspike=true;
            end;
            cburt.incoming.series(seriesnum).spikesmoves.xyzdiff(imgnum)=xyzdiff;
            cburt.incoming.series(seriesnum).spikesmoves.rotdiff(imgnum)=rotdiff;
            cburt.incoming.series(seriesnum).spikesmoves.globdiff(imgnum)=tm;
        end;

        % Now, regress out spike if there was one
        if (gotspike)
            tmpSPM=cburt.model.SPM;
            tmpSPM.Sess(1)=[];
            tmpSPM.Sess(1).U(1) = struct('ons',imgnum-1,'dur',0,'name',{{'spike'}},'P',struct('name','none'));


            %             U=spm_get_ons(tmpSPM,1);
            %             fMRI_T     = cburt.model.SPM.xBF.T;
            %             fMRI_T0    = cburt.model.SPM.xBF.T0;
            %             bf      = cburt.model.SPM.xBF.bf;
            %             k   = cburt.model.SPM.nscan(1);
            %             tmpX=spm_Volterra(U,bf,1); % 1st order Volterra
            %             tmpX = tmpX([0:(k - 1)]*fMRI_T + fMRI_T0 + 32,:);
            tmpX=zeros(size(cburt.incoming.series(seriesnum).model.X.filtered),1);
            tmpX(imgnum)=1;
            tmpX=filtfilt(cburt.model.filter.hpf_b,cburt.model.filter.hpf_a,tmpX);

            cburt.incoming.series(seriesnum).model.X.filtered=[cburt.incoming.series(seriesnum).model.X.filtered tmpX];
            cburt.incoming.series(seriesnum).model.X.columnofinterest=[cburt.incoming.series(seriesnum).model.X.columnofinterest false];

            if (~isfield(cburt.incoming.series(seriesnum).model.X,'spikesremoved'))
                cburt.incoming.series(seriesnum).model.X.spikesremoved=imgnum;
            else
                cburt.incoming.series(seriesnum).model.X.spikesremoved=[cburt.incoming.series(seriesnum).model.X.spikesremoved imgnum];
            end;
        end;
    end;
end;