function [cburt]=cburt_processseries(cburt,incomingmetafn,status,hdr,sample)

if (~exist('status','var'))
    status='...waiting';
    readfromfile=true;
else
    readfromfile=false;
end;
seekpos=0;
try
    cburt.internal.livedata;
catch
    cburt.internal.livedata=false;
end;
seriesfound=[];
while(~strcmp(status,'MEAS_FINISHED') || ~readfromfile);
    if (readfromfile)
        fid=fopen(incomingmetafn,'r');
        fseek(fid,seekpos,-1); % start where we left off!
    end;
    while(~readfromfile || ~feof(fid))
        if (readfromfile)
            % if we skip partial lines want to read them from the beginning
            % again...
            lne=fgets(fid);
            if (length(lne)<=2 || ~all(lne((end-1):end)==[13 10]))
                % its a partial line, so skip it...
                break;
            else
                seekpos=ftell(fid);
            end;
            lne=lne(1:(end-2));
            if (ischar(lne))
                fprintf(':[%d] %s\n',seekpos,lne)
            else
                fprintf(':[%d] [empty]\n',seekpos);
            end;
            [cmd rem]=strtok(lne);
        else
            cmd=status;
        end;
        
        
        switch(cmd)
            case {'MEAS_START'}
                status=cmd;
                fprintf('Got command %s\n',cmd);
                seriesfound=[];
            case {'MEAS_FINISHED'}
                seriesnum=length(cburt.incoming.series);
                if (~readfromfile)
                    seriesfound=seriesnum;
                end;
                status=cmd;
                fprintf('Got command %s\n',cmd);
                for i=1:length(seriesfound)
                    cburt=cburt_processactions(cburt,seriesfound(i),'onend');
                end;
                
                if (exist('seriesnum','var') && seriesnum>0)
                    cburt.benchmarking.series(seriesnum).stoptime=clock;
                    cburt.benchmarking.series(seriesnum).stop=toc(cburt.benchmarking.ticstart);
                    try
                        fprintf('Saving cburt structure...');
                        cburt=cburt_savecburt(cburt,seriesnum);
                        fprintf('all done.\n');
                    catch
                        fprintf('\nFailed to save cburt structure to %s\nAll done.\n',cburt.incoming.processeddata)
                    end;
                end;
                
                fprintf('Finished processing series\n');
                drawnow;
                
            case 'LOWLATENCY'
                % Wait for 2 seconds max for data to arrive
                tic
                success=false;
                while(toc<5 && ~success)
                    try
                        dat = ft_read_data(cburt.lowlatency.connstr, 'header', hdr, 'begsample', sample, 'endsample', sample);
                        success=true;
                    catch
                    end;
                    % 10 ms delay
                    pause(0.01)
                end;
                
                if (~success)
                    fprintf('Failed to load data - serious problem\n');
                end;
                
                if (sample==1)
                    descrip=strrep(hdr.nifti_1.descrip(:)','\','/');
                    [pth nme ext]=fileparts(descrip);
                    cburt.incoming.processeddata=fullfile(cburt.directory_conventions.processeddata,pth);
                    
                    % Check tag files in processed data directory to see if
                    %  series with this nme preexists
                    seriespreexists=false;
                    if (exist(cburt.incoming.processeddata,'dir'))
                        fn=dir(fullfile(cburt.incoming.processeddata,'received_series_*'));
                        for fnind=1:length(fn)
                            fnnme=fn(fnind).name(22:end);
                            if (strcmp(fnnme,nme))
                                seriesnum=str2num(fn(fnind).name(17:20));
                                seriespreexists=true;
                            end;
                        end;
                        if (~seriespreexists)
                            seriesnum=length(fn)+1;
                        end;
                    else
                        mkdir(cburt.incoming.processeddata);
                        seriesnum=1;
                    end;
                    fprintf('New series %d\n',seriesnum);
                    if (~seriespreexists)
                        for retry=1:10
                            try
                                fid=fopen(fullfile(cburt.incoming.processeddata,sprintf('received_series_%04d_%s',seriesnum,nme)),'w');
                                if (fid)
                                    break;
                                end;
                            catch
                                pause(0.025);
                            end;
                        end;
                        fprintf(fid,'%d',datestr(now,30));
                        fclose(fid);
                    end;
                    
                    cburt.incoming.series(seriesnum).hdr=hdr;
                    imgpth=fullfile(cburt.incoming.processeddata,sprintf('frawdata_%04d-%05d-%06d-01',seriesnum,sample,sample));
                    cburt.benchmarking.series(seriesnum).start=toc(cburt.benchmarking.ticstart);
                    cburt.benchmarking.series(seriesnum).start_time=clock;
                    cburt.incoming.series(seriesnum).imgtype='lowlatency';
                    cburt.incoming.series(seriesnum).protocolname=strtrim(hdr.siemensap.tProtocolName);
                    cburt.incoming.series(seriesnum).receivedvolumes={[imgpth '.img']};
                    cburt.incoming.series(seriesnum).timeseries=[];
                    cburt.incoming.series(seriesnum).model=[];
                    cburt.incoming.series(seriesnum).realignmentparms=[];
                    cburt.incoming.series(seriesnum).model=cburt.model;
                    cburt.incoming.series(seriesnum).firstvalidimage=nan;
                    cburt.incoming.series(seriesnum).receivedvolumesformat='img';
                    cburt=cburt_processactions(cburt,seriesnum,'onstart');
                else
                    seriesnum=length(cburt.incoming.series);
                    imgpth=fullfile(cburt.incoming.processeddata,sprintf('frawdata_%04d-%05d-%06d-01',seriesnum,sample,sample));
                    cburt.incoming.series(seriesnum).receivedvolumes{end+1}=[imgpth '.img'];
                end;
                imgnum=sample;
                
                if (length(dat)~= prod(double(hdr.nifti_1.dim)))
                    fprintf('Serious error - incorrect length %d of incoming data, expected %d\n',length(dat),prod(double(hdr.nifti_1.dim)))
                end;
                fprintf('image path is %s\n',imgpth);
                fid=fopen([imgpth '.hdr'],'wb');
                fwrite(fid,hdr.orig.nifti_1,'uint8');   % Header
                fclose(fid);
                fid=fopen([imgpth '.img'],'wb');
                fwrite(fid,dat,'int16');    % Data
                fclose(fid);
                
                % Process associated actions
                cburt=cburt_processactions(cburt,seriesnum,'onreceived',imgnum);
                
                if (any(imgnum==cburt.model.trigger))
                    cburt=cburt_processactions(cburt,seriesnum,'ontrigger',imgnum);
                end;
                
                
            case 'DATAFILE'
                [filetype imgfn]=strtok(rem);
                if (strcmp(imgfn(end-3:end),'.dcm'))
                    imgfn=strtrim(imgfn);
                    imgfn(imgfn=='\')='/';
                    if (strcmp(filetype,'DICOMIMA'))
                        imgpth=fullfile(cburt.directory_conventions.incomingdata,imgfn);
                        [pth fle ext]=fileparts(imgfn);
                        % now get series number
                        pos=find(fle=='_');
                        
                        % check dicom file has arrived
                        for i=1:60
                            if (exist(imgpth,'file'))
                                break;
                            end;
                            fprintf('Retry %d cannot find dicom file %s\n',i,imgpth);
                            pause(0.1);
                        end;
                        H=spm_dicom_headers(imgpth);
                        
                        seriesnum=H{1}.SeriesNumber;
                        if (~isempty(seriesnum))
                            if (isempty(intersect(seriesfound,seriesnum)))
                                seriesfound=union(seriesfound,seriesnum);
                                H=spm_dicom_headers(imgpth);
                                cburt.incoming.processeddata=fullfile(cburt.directory_conventions.processeddata,strtrim(H{1}.PatientsName));
                                if (~exist(cburt.incoming.processeddata,'dir'))
                                    mkdir(cburt.incoming.processeddata);
                                end;
                                try
                                    for fld=fields(cburt.benchmarking.series(seriesnum))
                                        cburt.benchmarking.series(seriesnum).(fld)=[];
                                    end;
                                catch
                                end;
                                cburt.benchmarking.series(seriesnum).start=toc(cburt.benchmarking.ticstart);
                                cburt.benchmarking.series(seriesnum).start_time=clock;
                                cburt.incoming.series(seriesnum).imgtype=strtrim(H{1}.ImageType);
                                cburt.incoming.series(seriesnum).protocolname=strtrim(H{1}.ProtocolName);
                                cburt.incoming.series(seriesnum).receivedvolumes={imgpth};
                                cburt.incoming.series(seriesnum).timeseries=[];
                                cburt.incoming.series(seriesnum).model=[];
                                cburt.incoming.series(seriesnum).realignmentparms=[];
                                cburt.incoming.series(seriesnum).model=cburt.model;
                                cburt.incoming.series(seriesnum).firstvalidimage=nan;
                                cburt.incoming.series(seriesnum).receivedvolumesformat='dcm';
                                cburt=cburt_processactions(cburt,seriesnum,'onstart');
                            else
                                cburt.incoming.series(seriesnum).receivedvolumes{end+1}=imgpth;
                            end;
                            imgnum=length(cburt.incoming.series(seriesnum).receivedvolumes);
                            
                            if (mod(imgnum,20)==0)
                                fprintf('Incoming DICOM type %s series %d volume %d fn %s\n',cburt.incoming.series(seriesnum).imgtype,seriesnum,length(cburt.incoming.series(seriesnum).receivedvolumes),imgfn);
                            end;
                            
                            cburt=cburt_processactions(cburt,seriesnum,'onreceived',imgnum);
                            
                            if (any(imgnum==cburt.model.trigger))
                                cburt=cburt_processactions(cburt,seriesnum,'ontrigger',imgnum);
                            end;
                        end;
                        
                    else
                        fprintf('Non-DICOM image received, ignored');
                    end;
                end;
        end;
        if (~readfromfile)
            break;
        end;
    end;
    if (readfromfile)
        fclose(fid);
    else
        break;
    end;
end;
