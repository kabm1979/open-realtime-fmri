function [cburt]=cburt_processseries(cburt,incomingmetafn)

status='...waiting';
seekpos=0;
try
    cburt.internal.livedata;
catch
    cburt.internal.livedata=false;
end;
seriesfound=[];
while(~strcmp(status,'MEAS_FINISHED'));
    fid=fopen(incomingmetafn,'r');
    fseek(fid,seekpos,-1); % start where we left off!
    while(~feof(fid))
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
        %         if (~feof(fid))
        %             fprintf('Line is %s\n',lne);
        %         end;
        switch(cmd)
            case {'MEAS_START'}
                status=cmd;
                fprintf('Got command %s\n',cmd);
                seriesfound=[];
                figure(14); clf;
                figure(15); clf;
                figure(12); clf
            case {'MEAS_FINISHED'}
                status=cmd;
                fprintf('Got command %s\n',cmd);
                for i=1:length(seriesfound)
                    cburt=cburt_processactions(cburt,seriesfound(i),'onend');
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
                            fprintf('Convert find dicom file, retry %d',i);
                            pause(0.5);
                        end;
                        H=spm_dicom_headers(imgpth);

                        seriesnum=H{1}.SeriesNumber;
                        if (~isempty(seriesnum))
                            if (isempty(intersect(seriesfound,seriesnum)))
                                seriesfound=union(seriesfound,seriesnum);
                                H=spm_dicom_headers(imgpth);
                                cburt.incoming.processeddata=fullfile(cburt.directory_conventions.processeddata,strtrim(H{1}.PatientsName));
                                try
                                    for fld=fields(cburt.benchmarking.series(seriesnum))
                                        cburt.benchmarking.series(seriesnum).(fld)=[];
                                    end;
                                catch
                                end;
                                cburt.benchmarking.series(seriesnum).start=clock;
                                cburt.incoming.series(seriesnum).imgtype=strtrim(H{1}.ImageType);
                                cburt.incoming.series(seriesnum).protocolname=strtrim(H{1}.ProtocolName);
                                cburt.incoming.series(seriesnum).receivedvolumes={imgpth};
                                cburt.incoming.series(seriesnum).timeseries=[];
                                cburt.incoming.series(seriesnum).model=[];
                                cburt.incoming.series(seriesnum).realignmentparms=[];
                                cburt.incoming.series(seriesnum).model=cburt.model;
                                cburt.incoming.series(seriesnum).firstvalidimage=nan;
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
    end;
    fclose(fid);
end;

if (exist('seriesnum','var'))
    cburt.benchmarking.series(seriesnum).stop=clock;
end;

fprintf('Finished processing series\n');
drawnow;
try
    fprintf('Saving cburt structure...');
    cburt=cburt_savecburt(cburt,seriesnum);
    fprintf('all done.\n');
catch
    fprintf('\nFailed to save cburt structure. All done.\n')
end;