function [cburt]=cburt_streams_send(cburt,seriesnum,imgnum)

streamspath='/mnt/ibm_data/ActiveRT';

% Now send 
datatosend=cburt.incoming.series(seriesnum).timeseries.raw(imgnum,:);

[pth nme ext]=fileparts(cburt.incoming.processeddata);

% Create .csv string containing the data
datastr=sprintf('%f,',datatosend);
if length(datastr)>1
    datastr=datastr(1:end-1);
end;

% Now write out csv
%datafn=fullfile(cburt.incoming.processeddata,sprintf('data_%s_%04d_%04d.csv',nme,seriesnum,imgnum));
datafn=fullfile(streamspath,sprintf('data_%s_%04d_%04d.csv',nme,seriesnum,imgnum));
fid=fopen(datafn,'w');
fprintf(fid,'[%s]',datastr);
fclose(fid);

% Upload it

% cmd=sprintf('curl -T %s ftp://129.100.246.208/Test/ -u ''SSC-GoodaleLab9\streams'':''Daley1@b''',datafn);
% [status res]=system(cmd);
% if status
%     fprintf('Error uploading, %s\n',res);
% end;

