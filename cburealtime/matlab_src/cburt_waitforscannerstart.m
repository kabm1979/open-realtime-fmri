function cburt=cburt_waitforscannerstart(cburt)
try
    close('waitingforkey');
catch
end;
h=waitingforkey;
while(true)
    mychar=get(h,'currentcharacter');
    if (strcmp(mychar,'5'))
        cburt.benchmarking.ticstart=tic;
        break;
    end;
    pause(0.001);
end;
close(h);