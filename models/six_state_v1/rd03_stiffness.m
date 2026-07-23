function s = rd03_stiffness(p, x, Vcmd)
%RD03_STIFFNESS  Scripted, defined stiffness diagnostic (replaces withdrawn headlines).
%   DEFINITION (published with every reported value):
%   J = numerical Jacobian df/dx at state x, central differences with per-state
%   perturbation h_j = max(1e-6*scale_j, 1e-12). Diagnostics:
%     spread_raw    = max|Re(eig(J))| / min nonzero |Re(eig(J))|   [1/s ratio]
%     tau_fast/slow = 1/max|Re|, 1/min nonzero |Re|                 [s]
%   CAVEAT: both are OPERATING-POINT-, SCALING-, and REGIME-DEPENDENT (contact
%   active or not). They justify an implicit solver; they are NOT universal
%   constants of the model. Never quote without operating point + this script.
if nargin < 2 || isempty(x)
    [~,X] = ode15s(@(t,xx)rd03_rhs(t,xx,5,p),[0 0.4],rd03_ic(p),rd03_solveropts('fast'));
    x = X(end,:).';
end
if nargin < 3, Vcmd = 5; end
n = numel(x);
scale = [1; 1e-3; 0.1; 4e5; 100; 100; 4e5; 4e7];   % typical state magnitudes
J = zeros(n);
for j = 1:n
    h = max(1e-6*scale(j), 1e-12);
    xp_ = x; xm_ = x; xp_(j) = xp_(j)+h; xm_(j) = xm_(j)-h;
    J(:,j) = (rd03_rhs(0,xp_,Vcmd,p) - rd03_rhs(0,xm_,Vcmd,p))/(2*h);
end
lam = eig(J); re = abs(real(lam)); nz = re > 1e-9;
s.eigs = lam; s.operating_point = x; s.Vcmd = Vcmd;
s.tau_fast = 1/max(re); s.tau_slow = 1/min(re(nz));
s.spread_raw = max(re)/min(re(nz));
fprintf('stiffness diagnostic @ operating point (Vcmd=%g):\n', Vcmd);
fprintf('  tau_fast=%.3g s  tau_slow=%.3g s  spread=%.3g  (definition in header;\n', ...
    s.tau_fast, s.tau_slow, s.spread_raw);
fprintf('  point/scaling/regime-dependent - implicit solver justified, nothing more)\n');
end
