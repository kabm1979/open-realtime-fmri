function [cburt]= cburt_processactions(cburt,seriesnum,eventtype,varargin)

protocolname=cburt.incoming.series(seriesnum).protocolname;

% Find out if any actions associated with this event
if (isfield(cburt.actions,'imgtype') )
    findaction=[strcmp({cburt.actions.imgtype},'*')] | [strcmp({cburt.actions.imgtype},cburt.incoming.series(seriesnum).imgtype)] | [strcmp({cburt.actions.imgtype},'*')];
    if (~any(findaction))
        fprintf('No action for data with protocol %s and image type %s\n',protocolname,cburt.incoming.series(seriesnum).imgtype);
    end;
else
    findaction=1:length(cburt.actions);
end;

if (any(findaction))
    action=cburt.actions(findaction);
    findaction_byprotocol=~[cellfun(@isempty,regexp(protocolname,{action.protocolname}))];
    if(any(findaction_byprotocol))
        action=action(findaction_byprotocol);
        cburt.benchmarking.series(seriesnum).(eventtype).start=toc(cburt.benchmarking.ticstart);
        if (isfield(action,eventtype))
            for i=1:length(action.(eventtype))
                if (~strcmp(eventtype,'onreceived') || mod(varargin{1},20)==0)
                    fprintf('Running action %s for series %d\n',action.(eventtype){i},seriesnum);
                end;
                starttime=toc(cburt.benchmarking.ticstart);
                try
                    cburt.benchmarking.series(seriesnum).(eventtype).(action.(eventtype){i}).start(end+1,:)=starttime;
                catch
                    cburt.benchmarking.series(seriesnum).(eventtype).(action.(eventtype){i}).start=starttime;
                end;
                cburt=feval(action.(eventtype){i},cburt,seriesnum,varargin{:});
                endtime=toc(cburt.benchmarking.ticstart);
                try
                    cburt.benchmarking.series(seriesnum).(eventtype).(action.(eventtype){i}).stop(end+1,:)=endtime;
                catch
                    cburt.benchmarking.series(seriesnum).(eventtype).(action.(eventtype){i}).stop=endtime;
                end;
                try
                    cburt.benchmarking.series(seriesnum).(eventtype).(action.(eventtype){i}).duration(end+1)=endtime-starttime;
                catch
                    cburt.benchmarking.series(seriesnum).(eventtype).(action.(eventtype){i}).duration=endtime-starttime;
                end;
            end;
        end;
        cburt.benchmarking.series(seriesnum).(eventtype).stop=toc(cburt.benchmarking.ticstart);
    end;
end;
