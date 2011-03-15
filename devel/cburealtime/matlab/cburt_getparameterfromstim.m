function [parmvalue]=cburt_getparameterfromstim(cburt,parmname,maximumageinsecs)

fn=fullfile(cburt.directory_conventions.incomingmetapath,['parameterfromstim_' parmname '.txt']);
tic;
oldtime=toc;
while(1)
    fnd=dir(fn);

    if (~isempty(fnd))
        agesecs=3600*24*(now-datenum(fnd(1).date));
        if (agesecs<maximumageinsecs)
            fid=fopen(fn);
            parmvalue=fgetl(fid);
            blank=fgetl(fid);
            term=fgetl(fid);
            fclose(fid);
            if (strcmp(term,'==END=='))
                break;
            end;
        else
            if (round(toc)~=oldtime)
                fprintf('parameter from stim %s is stale, with age %f s - try restarting stimulus delivery\n',parmname,agesecs);
                oldtime=round(toc);
            end;
        end;
    else
        if (round(toc)~=oldtime)
                fprintf('no parameter from stim %s found- try restarting stimulus delivery\n',parmname);
                oldtime=round(toc);
        end;
    end;
    pause(0.1);

end;


fprintf('Got parameter from stim %s with age %d seconds, value %s\n',parmname,round(agesecs),parmvalue);