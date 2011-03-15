function [cburt,desc,ML,MLlowerbound,MLupperbound]=cburt_dai_findML(cburt,pdfrange,logpdf)

[valmax indmax]=max(logpdf);
ML=pdfrange(indmax);
desc=sprintf('ML: %.2f',ML);
chiratio=2.51; % This corresponds to one half of alpha 0.05 (0.975 chi value) two tailed - Watson & Pelli (1983)
MLlowerbound=find(logpdf(1:indmax)<(valmax-chiratio));
if (isempty(MLlowerbound))
    desc=[desc ' (?-'];
else
    MLlowerbound=pdfrange(MLlowerbound(end));
    desc=sprintf('%s (%.2f-',desc,MLlowerbound);
end;
MLupperbound=find(logpdf(indmax:end)<(valmax-chiratio));
if (isempty(MLupperbound))
    desc=[desc '?)'];
else
    MLupperbound=pdfrange(indmax-1+MLupperbound(1));
    desc=sprintf('%s%.2f)',desc,MLupperbound);
end;
