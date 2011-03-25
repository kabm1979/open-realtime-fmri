function [cburt]=cburt_convert_multipledcm_doit(cburt,seriesnum)
fprintf('Please change references to cburt_convert_multipledcm_doit to cburt_convert_fileperslice\nYou may not be able to use ...multipledcm in future releases.\n');
[cburt]=cburt_convert_fileperslice(cburt,seriesnum);