%RD03_IDENTIFIABILITY  C0-gate screen for spine v0.2 (G bucket, [Raue2009] posture).
% LOCAL normalized sensitivity + SVD conditioning of OBSERVABLE features w.r.t.
% candidate parameters, on synthetic truth. This is the cheap screen that runs
% BEFORE profile likelihood; it exposes parameter combinations the planned
% observables cannot separate. Not a calibration; not bench evidence.
p0 = rd03_params();
opt = odeset('RelTol',1e-6,'AbsTol',1e-9,'MaxStep',0.005);
names = {'kf','CdInf','cr','Fc','cv40','beta'};
th0   = [p0.kf p0.CdInf p0.cr p0.Fc p0.cv40 p0.beta];
f0 = rd03_feat(p0,opt); nf = numel(f0); np = numel(names);
S = zeros(nf,np); h = 0.02;
for k = 1:np
    pp = p0; pm = p0;
    pp.(names{k}) = th0(k)*(1+h);
    pm.(names{k}) = th0(k)*(1-h);
    S(:,k) = ((rd03_feat(pp,opt) - rd03_feat(pm,opt))/(2*h)) ./ max(abs(f0),1e-12);
end
[~,Sv,V] = svd(S,'econ'); sv = diag(Sv);
fprintf('=== C0 identifiability screen (local, synthetic, observables only) ===\n');
fprintf('features: [i_ss, p_sens_ss, t63_p, early di/dt]  |  drive: 5 V step, cold\n');
for k = 1:np, fprintf('  %-6s  column-norm %.4g\n', names{k}, norm(S(:,k))); end
fprintf('singular values: '); fprintf('%.3g  ', sv); fprintf('\n');
fprintf('condition number: %.3g\n', sv(1)/max(sv(end),eps));
[~,ix] = sort(abs(V(:,end)),'descend');
fprintf('weakest direction (least separable combo): ');
for j = 1:min(3,np), fprintf('%s(%+.2f) ', names{ix(j)}, V(ix(j),end)); end
fprintf('\nverdict: parameters in the weakest direction need a DEDICATED test\n');
fprintf('(temperature sweep / no-fluid force ramp / pressure-decay) before fitting.\n');

function f = rd03_feat(p,opt)
x0 = zeros(8,1); x0(5) = 25; x0(6) = 25;
[t,X] = ode15s(@(tt,x)rd03_rhs(tt,x,5,p),[0 0.4],x0,opt);
iss = X(end,1); pss = X(end,7);
i63 = find(X(:,7) >= 0.63*pss, 1); if isempty(i63), i63 = numel(t); end
t63 = t(i63);
k5 = find(t >= 0.002, 1); slope = X(k5,1)/t(k5);
f = [iss; pss; t63; slope];
end
