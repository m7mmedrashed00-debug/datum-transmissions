function x0 = rd03_ic(p)
%RD03_IC  Consistent initial condition for the AS-BUILT (penalty-stop) model.
%   Static mechanical balance at V=0, P=0: k(xp+xpre) = -Kstop*min(xp,0)
%   => xp_eq = -k*xpre/(k+Kstop)  (NEGATIVE: about -23 um with [Repr] values).
%   The negative seated equilibrium DOCUMENTS defect D4: a penalty seat admits
%   penetration by construction. v0.3b replaces this with event/complementarity
%   contact whose seated equilibrium is exactly xp = 0.
%   Temperatures start at ambient (cold start), NOT at thermal equilibrium.
xp_eq = -p.k*p.xpre/(p.k + p.Kstop);
x0 = [0; xp_eq; 0; 0; p.Tamb; p.Tamb; 0; 0];
end
