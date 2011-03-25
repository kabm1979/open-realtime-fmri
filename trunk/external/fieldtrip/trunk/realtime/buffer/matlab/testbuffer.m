
host='localhost';
port=1972;
buffer('tcpserver', 'init', host, port);
try    
    connstr=['buffer://' host ':' num2str(port)];
    
    while (1)
        hdr = read_header(connstr);
        begsample = hdr.nSamples - hdr.Fs + 1;
        endsample = hdr.nSamples;
        dat = read_data(connstr, 'header', hdr,  'begsample', begsample, 'endsample', endsample);
    end
    buffer('tcpserver', 'exit', host,port);    
catch exception
    buffer('tcpserver', 'exit', host,port);    
    rethrow(exception);
end;
