function cv = c0v2_convergence(h, f, fexact, name)
%C0V2_CONVERGENCE  Order / Richardson / GCI machinery per [NASA-GCI], run in
%   TWO modes and cross-checked (meta-verification, possible because exact
%   values exist for these benchmarks):
%     exact-aware : observed order = LSQ slope of log(|f-fexact|) vs log(h)
%     blind       : 3-grid observed order from solution DIFFERENCES via the
%                   generalized ratio equation (non-integer realized ratios):
%                   (f3-f2)/(f2-f1) = r21^p (r32^p - 1)/(r21^p - 1)
%   Richardson: f_ext = f1 + (f1-f2)/(r21^p - 1)  -> compared against fexact.
%   GCI (fine): GCI = Fs |e21| / (r21^p - 1), e21 = (f1-f2)/f1, Fs = 1.25
%   (>=3 grids). Asymptotic-range check: GCI23 / (r21^p GCI12) ~ 1.
%   Grids must be ordered coarse -> fine in h; f aligned with h.
[hs, ix] = sort(h(:), 'descend');  fs = f(ix); fs = fs(:);   % coarse..fine
n = numel(hs);
cv = struct('name',name,'h',hs','f',fs','fexact',fexact);
err = abs(fs - fexact)/abs(fexact);
cv.relerr = err';

% exact-aware fitted order (all levels; also last-3 for locality)
c = polyfit(log(hs), log(err), 1);       cv.p_fit_all  = c(1);
c3 = polyfit(log(hs(end-2:end)), log(err(end-2:end)), 1); cv.p_fit_last3 = c3(1);

% blind 3-grid order on the finest triplet: grids 1=fine,2=mid,3=coarse
f1 = fs(n); f2 = fs(n-1); f3 = fs(n-2);
h1 = hs(n); h2 = hs(n-1); h3 = hs(n-2);
r21 = h2/h1; r32 = h3/h2;
Fp = @(p) (f3-f2)/(f2-f1) - r21.^p .* (r32.^p - 1)./(r21.^p - 1);
try
    cv.p_blind = fzero(Fp, [0.2 6]);
catch
    cv.p_blind = NaN;   % non-monotone triplet — recorded, not hidden
end
% Richardson + GCI with the blind order (fallback: exact-aware last-3)
p_use = cv.p_blind; if ~isfinite(p_use), p_use = cv.p_fit_last3; end
cv.p_used = p_use;
cv.f_richardson = f1 + (f1 - f2)/(r21^p_use - 1);
cv.rich_err_vs_exact = abs(cv.f_richardson - fexact)/abs(fexact);
Fs = 1.25;
e21 = (f1 - f2)/f1;  e32 = (f2 - f3)/f2;
cv.GCI12 = Fs*abs(e21)/(r21^p_use - 1);          % fine-grid index (fraction)
cv.GCI23 = Fs*abs(e32)/(r32^p_use - 1);
cv.asymptotic_ratio = cv.GCI23/(r21^p_use * cv.GCI12);
cv.in_asymptotic_range = abs(cv.asymptotic_ratio - 1) < 0.15;

fprintf(['[conv %s] p_fit(all)=%.2f p_fit(3)=%.2f p_blind=%.2f | Rich err %.2e | ' ...
         'GCI_fine %.3e | asym ratio %.3f (%s)\n'], name, cv.p_fit_all, ...
        cv.p_fit_last3, cv.p_blind, cv.rich_err_vs_exact, cv.GCI12, ...
        cv.asymptotic_ratio, tern(cv.in_asymptotic_range,'IN range','NOT in range'));
end
function s = tern(c,a,b), if c, s=a; else, s=b; end, end
