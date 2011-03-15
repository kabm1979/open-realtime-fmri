% Run watchport.py first

incomingmetapath='/realtime/scratch/incomingmeta';
nextseries=1;

while(1)
    fn=fullfile(incomingmetapath,sprintf('series%04d.txt',nextseries));
    if (exist(fn,'file'))
        fprintf('Data series %s\n',fn);
        process_series(fn);
        nextseries=nextseries+1;
    end;
end;