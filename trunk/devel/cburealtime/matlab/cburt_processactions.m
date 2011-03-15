function [cburt]= cburt_processactions(cburt,seriesnum,eventtype,varargin)

imgtype=cburt.incoming.series(seriesnum).imgtype;
protocolname=cburt.incoming.series(seriesnum).protocolname;

% Find out if any actions associated with this event


findaction=[strcmp({cburt.actions.imgtype},imgtype)];

if (any(findaction))
    action=cburt.actions(findaction);
    if(~isempty(regexp(protocolname,action.protocolname)))
        cburt.benchmarking.series(seriesnum).(eventtype).start=clock;
        if (isfield(action,eventtype))
            for i=1:length(action.(eventtype))
                if (~strcmp(eventtype,'onreceived') || mod(varargin{1},20)==0)
                    fprintf('Running action %s for series %d imgtype %s\n',action.(eventtype){i},seriesnum,imgtype);
                end;
                starttime=clock;
                try
                    cburt.benchmarking.series(seriesnum).(eventtype).(action.(eventtype){i}).start(end+1,:)=starttime;
                catch
                    cburt.benchmarking.series(seriesnum).(eventtype).(action.(eventtype){i}).start=starttime;
                end;
                cburt=feval(action.(eventtype){i},cburt,seriesnum,varargin{:});
                endtime=clock;
                try
                    cburt.benchmarking.series(seriesnum).(eventtype).(action.(eventtype){i}).stop(end+1,:)=endtime;
                catch
                    cburt.benchmarking.series(seriesnum).(eventtype).(action.(eventtype){i}).stop=endtime;
                end;
                try
                    cburt.benchmarking.series(seriesnum).(eventtype).(action.(eventtype){i}).duration(end+1)=etime(starttime,endtime);
                catch
                    cburt.benchmarking.series(seriesnum).(eventtype).(action.(eventtype){i}).duration=etime(starttime,endtime);
                end;
            end;
        end;
        cburt.benchmarking.series(seriesnum).(eventtype).stop=clock;
    end;
end;
