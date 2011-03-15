% This function works out where the next value should be
%

function [cburt]=cburt_dai_estimate(cburt,seriesnum,imgnum)

dai=cburt.incoming.series(seriesnum).dai;

% first find variability in expected B as function of s & t
[dai.svals dai.xvals dai.tvals]=meshgrid(dai.srange,dai.xrange,dai.trange);
Bxst=expectedB(dai.xvals,dai.svals,dai.tvals);
dai.Pst=dai.Pst/sum(dai.Pst(:)); % normalise
Bmean=sum(sum(Bxst.*repmat(reshape(dai.Pst,[1 dai.ns dai.nt]),[dai.nx 1 1]),2),3);

switch dai.optimise
    case 'st'
        Bstd=sqrt(sum(sum((Bxst-repmat(Bmean,[1 dai.ns dai.nt])).^2.*repmat(reshape(dai.Pst,[1 dai.ns dai.nt]),[dai.nx 1 1]),2),3));
    case 's'
        % aim to optimise s only
        Bstd=sqrt(sum((mean(Bxst,3)-repmat(Bmean,[1 dai.ns 1])).^2.*repmat(reshape(sum(dai.Pst,2),[1 dai.ns 1]),[dai.nx 1 1]),2));
    case 't'
        % aim to optimise t only
        Bstd=sqrt(sum((mean(Bxst,2)-repmat(Bmean,[1 1 dai.nt])).^2.*repmat(reshape(sum(dai.Pst,1),[1 1 dai.nt]),[dai.nx 1 1]),3));
end;

dai.Bmean=Bmean;
dai.Bstd=Bstd;
[Bstdmax ind]=max(Bstd);
x0=dai.xrange(ind);

if (cburt.model.adaptstimuli)
    fprintf('Optimal next stimulus is %f\n',x0);
else
    fprintf('If this were an adaptive block, the optimal next stimulus would be %f\n',x0);
end;

% That tells us where to put next stimulus
if (cburt.model.adaptstimuli)
    if (cburt.communication.tostimulus.on)
        cmd=sprintf('echo "PARAMETER 0 %f" | nc %s %d',x0,cburt.communication.tostimulus.ip,cburt.communication.tostimulus.port)
        [s w]=unix(cmd);
    end;
end;
if (~exist('imgnum','var'))
    cburt.model.series(seriesnum).stimuli=x0;
else
    trignum=sum(cburt.model.trigger<=imgnum);
    if (trignum>0)
        cburt.model.series(seriesnum).stimuli(trignum)=x0;
    end;
end;

cburt.incoming.series(seriesnum).dai=dai;

