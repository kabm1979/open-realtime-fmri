function [cburt tmes]=cburt_benchmark_series(cburt, seriesnumber)


switch(cburt.incoming.series(seriesnumber).receivedvolumesformat)
    case 'dcm'
        dcmhdr=spm_dicom_headers(cburt.incoming.series(seriesnumber).receivedvolumes{1});
        tr=dcmhdr{1}.RepetitionTime/1000;
    case 'img'
        tr=cburt.incoming.series(seriesnum).hdr.siemensap.alTR/1e6;
end;

onr=cburt.benchmarking.series(seriesnumber).onreceived;

global cburealtime_defaults
actions=cburt.actions([strcmp({cburt.actions.protocolname},cburealtime_defaults.protocol.functional.protocolname)]).onreceived;

titles={};
for actind=1:length(actions)
    if (actind==1)
        if (cburt.benchmarking.synchronized)
            tmes=[onr.(actions{1}).start];
            % Relative to end of acquisition
            tmes=tmes-([1:size(tmes,1)]')*tr;
            titles=[titles, 'transfer'];
        else
            tmes=[];
        end;
    end;
    tmes=[tmes, [onr.(actions{actind}).duration]'];
    titles=[titles, strrep(actions{actind},'_',' ')];
    
end;

figure(51);
bar(tmes,'stacked');
legend(titles,'Location','SouthWest');
xlabel('Scan number');
ylabel('Seconds');
if (cburt.benchmarking.synchronized)
    title('Real-time latencies relative to end of each acquisition');
else
    fprintf('Timing not synchronized\n');
    title('Real-time latencies (no synchronization to acqusition)');
end;
