function [value] = dcmparser(file,name)

% Here some of the relevant variables in the DICOM header ...
% sTXSPEC.asNucleusInfo[0].lFrequency      = 123251959
% sTXSPEC.asNucleusInfo[0].flReferenceAmplitude = 371.02
% sTXSPEC.aRFPULSE[0].flAmplitude          = 326.496
% asCoilSelectMeas[0].asList[11].lRxChannelConnected = 12
% alTE[0]                                  = 30000
% alTR[0]                                  = 2000000
% adFlipAngleDegree[0]                     = 78

fid = fopen(file,'r');

%% Loop through all the lines:

b_name = false;
while ~(b_name)
  tline = fgetl(fid);
  if ~ischar(tline) % it will read a -1 at the end-of-file
    break
  end
%   disp(tline); % for debugging
  k = strfind(tline, name);
  if k>0
    value = tline(k+length(name):end);
    b_name = true;
  end
end

if ~b_name
  value = '0';
end

fclose(fid);

end