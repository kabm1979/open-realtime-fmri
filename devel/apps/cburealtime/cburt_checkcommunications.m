function [cburt]=cburt_checkcommunications(cburt)

fprintf('Checking stimulus delivery\n');
nosuccess=true;
while (nosuccess)
    try
        % Update IP address
        fid=fopen(fullfile(cburt.directory_conventions.incomingmetapath,'stim_ip.txt'),'r');
        cburt.communication.tostimulus.ip=fgetl(fid);
        fclose(fid);

        cmd=sprintf('nc -w 2 -z -v %s %d',cburt.communication.tostimulus.ip,cburt.communication.tostimulus.port);
        fprintf('Attempting %s\n',cmd);
        [nosuccess w]=unix(cmd);
        if (nosuccess)
            fprintf('Stimulus delivery machine not found, awaiting handshake from someone\n  %s',w);
            pause(1.0);
        end;
    catch
        fprintf('Stimulus delivery machine not found, awaiting handshake from someone\n');
        pause(1.0);
    end;
end;
fprintf('Stimulus delivery communication established\n');