% choose st, t or s - optimise stimulus selection to hone this parameter
optimise='t';

%underlying neurometric
srange=[0:0.2:4];
trange=[0:0.2:10];
ns=length(srange);
nt=length(trange);

% priors
sm=2; ss=20;
tm=5; ts=50;
Pst=normpdf(srange,sm,ss)'*normpdf(trange,tm,ts);

%stimulus values
xrange=[0:0.2:11];
nx=length(xrange);

%and for BOLD values
brange=[0:0.05:1];
nb=length(brange);

figure(10);


%now iterate

D=[];
for i=1:40
    % plot current s t estimates
    subplot(2,2,1);
    imagesc(trange,srange,Pst,[0 max(Pst(:))]);
    axis xy;
    colorbar;
    % Find ML estimate
    [tmp tind]=max(max(Pst));
    [tmp sind]=max(max(Pst'));
    MLs=srange(sind);
    MLt=trange(tind);
    xlabel('threshold (t)');
    ylabel('signal change (s)');
    title('Probability distribution function');
    
    % first find variability in expected B as function of s & t
    [svals xvals tvals]=meshgrid(srange,xrange,trange);
    Bxst=expectedB(xvals,svals,tvals);
    Pst=Pst/sum(Pst(:)); % normalise
    Bmean=sum(sum(Bxst.*repmat(reshape(Pst,[1 ns nt]),[nx 1 1]),2),3);

    switch optimise
        case 'st'
            Bstd=sqrt(sum(sum((Bxst-repmat(Bmean,[1 ns nt])).^2.*repmat(reshape(Pst,[1 ns nt]),[nx 1 1]),2),3));
        case 's'
            % aim to optimise s only
            Bstd=sqrt(sum((mean(Bxst,3)-repmat(Bmean,[1 ns 1])).^2.*repmat(reshape(sum(Pst,2),[1 ns 1]),[nx 1 1]),2));
        case 't'
            % aim to optimise t only
            Bstd=sqrt(sum((mean(Bxst,2)-repmat(Bmean,[1 1 nt])).^2.*repmat(reshape(sum(Pst,1),[1 1 nt]),[nx 1 1]),3));
    end;
    subplot(2,2,2);
    errorbar(xrange',Bmean,Bstd);
    axis tight
    title('Predictions given current estimates of s and t');
    xlabel('Stimulus strength')
    ylabel('Predicted BOLD response');
    
    % that t2lls us where to put next stimulus
    [Bstdmax ind]=max(Bstd);
    x0=xrange(ind);

    % simulate noisy measurement
    Bmeasured=expectedB(x0,2,7)+2*randn(1);
    D=[D;x0 Bmeasured];
    fprintf('Stimulus at %f gave signal %f\n',x0,Bmeasured);

    subplot(2,2,3);
    scatter(D(:,1),D(:,2),'+');
    xlim([min(xrange) max(xrange)])
    title('Actual data (simulated)');
    xlabel('Stimulus strength')
    ylabel('Predicted BOLD response');

    [tvals svals]=meshgrid(trange,srange);

    % and update estimates of s & t
    L=likelihood(Bmeasured,x0,svals,tvals);

    subplot(2,2,4);
    imagesc(trange,srange,L);
    axis xy;
    xlabel('threshold (t)');
    ylabel('signal change (s)');
    title('Likelihood given most recent data point')
    % calculate posterior
    Pst=Pst.*L;
    if (mod(i-1,10)==0)
        pause;
    end;

    refresh;

end;

figure(11);
subplot(2,1,1);
Pst=Pst/sum(Pst(:));
plot(srange,squeeze(mean(Pst,2)));
xlabel('Signal change (s)');
ylabel ('Probability');
subplot(2,1,2);
plot(trange,squeeze(mean(Pst,1)));
xlabel('Threshold (t)');
ylabel ('Probability');

