function [cburt]=cburt_dai_adaptive_setup(cburt,seriesnum)
%% DAI
% choose st, t or s - optimise stimulus selection to hone this parameter
clear dai
dai.optimise='t';

%underlying neurometric
dai.srange=[0:0.1:2.4];
dai.trange=linspace(1,8,64);
dai.ns=length(dai.srange);
dai.nt=length(dai.trange);

% priors
dai.sm=1; dai.ss=4;
dai.tm=5; dai.ts=50;
dai.priorPst=normpdf(dai.srange,dai.sm,dai.ss)'*normpdf(dai.trange,dai.tm,dai.ts);

% starting Pst=prior
dai.Pst=dai.priorPst;

%stimulus values
dai.xrange=linspace(1,8,64);
dai.nx=length(dai.xrange);

%and for BOLD values
dai.brange=[0:0.05:1];
dai.nb=length(dai.brange);

cburt.incoming.series(seriesnum).dai=dai;

