function [cburt]=cburt_estimate_noise(cburt,seriesnum,imgnum)

nits=20;

Xtrim=cburt.incoming.series(seriesnum).model.X.filtered;
nvol=size(Xtrim,1);
whichX=max(Xtrim,[],1)>0.1;
Xtrim=Xtrim(:,whichX);

% First estimate AR(1)
R=cburt.incoming.series(seriesnum).model.residuals*cburt.model.contrast;
A=corrcoef(R(1:(end-1)),R(2:end));
A=A(2,1);
A=0;
Ball=[];
Nall=[];
for i=1:nits
    % get noise with same AR(1)
    N=randn((nvol+1),1);
    N=N(1:(end-1))+N(2:end)*A;
    % fit betas
    B=inv(Xtrim'*Xtrim)*Xtrim'*N;
    Ball=[Ball B];
end;

sR=std(R);
sB=mean(std(Ball(:)))*sR;
fprintf('Residuals sd is %f, estimated beta sd %f\n',sR,sB);
cburt.incoming.series(seriesnum).model.stdev_residuals=sR;
cburt.incoming.series(seriesnum).model.stdev_beta=sB;
