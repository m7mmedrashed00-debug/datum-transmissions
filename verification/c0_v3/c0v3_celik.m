function cv = c0v3_celik(h, f, fexact, name)
%C0V3_CELIK  Discretization-uncertainty machinery per [Celik2008]/[NASA-GCI],
%   audit-corrected (C0v2 audit P0-02/P0-03/P1-01):
%   - SIGNED differences and signed errors throughout
%   - unequal realized ratios; apparent order from the Celik fixed point
%       p = |ln|e32/e21| + q(p)| / ln(r21),  q(p) = ln((r21^p - s)/(r32^p - s)),
%       s = sign(e32/e21)
%   - GCI computed ONLY if the finest triplet is monotone (s=+1) AND the
%     asymptotic-range ratio passes; otherwise GCI is REFUSED with a recorded
%     reason (never forced onto an unsuitable sequence).
%   - where fexact is known, GCI coverage vs truth is tested explicitly.
%   h: characteristic size per level (coarse..fine order irrelevant; sorted
%   internally), f: observable values aligned with h.
[hs, ix] = sort(h(:), 'descend');  fs = f(ix); fs = fs(:);
n = numel(hs);
cv = struct('name',name,'h',hs','f',fs','fexact',fexact);
serr = (fs - fexact)/abs(fexact);            % SIGNED relative error
cv.signed_relerr = serr';
cv.relerr = abs(serr)';

% exact-aware fitted order (all levels + last3)
c = polyfit(log(hs), log(abs(serr)), 1);              cv.p_fit_all  = c(1);
c3 = polyfit(log(hs(end-2:end)), log(abs(serr(end-2:end))), 1); cv.p_fit_last3 = c3(1);

% finest triplet, Celik fixed point
f1 = fs(n); f2 = fs(n-1); f3 = fs(n-2);
h1 = hs(n); h2 = hs(n-1); h3 = hs(n-2);
r21 = h2/h1; r32 = h3/h2;
e21 = f2 - f1; e32 = f3 - f2;
cv.r21 = r21; cv.r32 = r32; cv.e21 = e21; cv.e32 = e32;
s = sign(e32/e21);
cv.monotone_triplet = (s > 0);
cv.p_celik = NaN; cv.GCI12 = NaN; cv.GCI23 = NaN;
cv.asymptotic_ratio = NaN; cv.f_richardson = NaN; cv.rich_err_vs_exact = NaN;
cv.gci_status = 'REFUSED';
if cv.monotone_triplet
    F = @(p) p - abs(log(abs(e32/e21)) + log((r21.^p - s)./(r32.^p - s)))/log(r21);
    try
        cv.p_celik = fzero(F, 2);
    catch
        cv.p_celik = NaN;
    end
    if isfinite(cv.p_celik) && cv.p_celik > 0.1
        p = cv.p_celik;
        cv.f_richardson = f1 + (f1 - f2)/(r21^p - 1);
        cv.rich_err_vs_exact = abs(cv.f_richardson - fexact)/abs(fexact);
        Fs = 1.25;
        cv.GCI12 = Fs*abs((f1-f2)/f1)/(r21^p - 1);
        cv.GCI23 = Fs*abs((f2-f3)/f2)/(r32^p - 1);
        cv.asymptotic_ratio = cv.GCI23/(r21^p * cv.GCI12);
        cv.in_asymptotic_range = abs(cv.asymptotic_ratio - 1) < 0.15;
        if cv.in_asymptotic_range
            cv.gci_status = 'VALID';
        else
            cv.gci_status = 'REFUSED: not in asymptotic range';
        end
    else
        cv.gci_status = 'REFUSED: order solve failed';
    end
else
    cv.gci_status = 'REFUSED: non-monotone (oscillatory) triplet';
    cv.in_asymptotic_range = false;
end
% truth-coverage test (known-exact benchmarks only)
cv.true_finest_err = abs(serr(n));
if strcmp(cv.gci_status,'VALID')
    cv.gci_covers_truth = cv.GCI12 >= cv.true_finest_err;
    cv.coverage_factor = cv.GCI12 / cv.true_finest_err;
else
    cv.gci_covers_truth = false; cv.coverage_factor = NaN;
end
fprintf(['[celik %s] p_fit3=%.2f p_celik=%.3f r21=%.3f | GCI %s (%.3e, asym %.3f, cover %.2fx) | ' ...
         'true finest %.3e (signed %+.3e)\n'], name, cv.p_fit_last3, cv.p_celik, r21, ...
        cv.gci_status, cv.GCI12, cv.asymptotic_ratio, cv.coverage_factor, ...
        cv.true_finest_err, serr(n));
end
