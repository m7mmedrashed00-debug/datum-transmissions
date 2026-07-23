function dx = rd03_rhs(t, x, Vcmd, p, L)
%RD03_RHS  Eight-state RD-03 spine v0.2.
%   x = [ i ; xp ; v ; P ; Tw ; Tf ; ps1 ; ps2 ]
%   P is GAUGE pressure. Floor applied in ABSOLUTE: P_abs = P + Patm >= Pvap(Tf).
%   ps1/ps2: second-order pressure-sensor states (observation layer,
%   y_p = ps1 + noise) per [NBS67]/[Eichstadt2010] cards.
if nargin < 5, L = rd03_lib(p); end
i=x(1); xp=x(2); v=x(3); P=x(4); Tw=x(5); Tf=x(6); ps1=x(7); ps2=x(8);

R   = L.R(Tw);
Fm  = p.kf*i^2;                                   % flat placeholder [Wang2020]
Fsp = p.k*(xp + p.xpre);
Ffr = p.Fc*tanh(v/p.vs) + L.cvisc(Tf)*v;          % Coulomb + c(T)*v [Rundo2021]
Fstop = -p.Kstop*( max(xp - p.gmax,0) + min(xp,0) );

% metering inflow with Cd(Re) [Wu2002-Cd structure]; non-iterative Re from ideal jet
dpin  = max(p.Ps - P, 0);
vjet  = sqrt(2*dpin/p.rho);
Dh    = 2*max(xp, 1e-6);                          % slot hydraulic-diameter proxy
Re    = p.rho*vjet*Dh / L.mu(Tf);
Qin   = L.cd(Re) * p.wArea*max(xp,0) * vjet;

Qout  = p.CdOut*p.Aout*sqrt(2*max(P,0)/p.rho);    % fixed outlet orifice [Repr]
                                                  % KNOWN DEFECT: no signed/reverse
                                                  % flow on any path (xfail-covered)
Qlk   = L.qleak(P, Tf);                           % annular leak to sump [Dziubak2023]

dP = p.beta/p.Vch * (Qin - Qout - Qlk - p.Ap*v);
floorP = L.pvap(Tf) - p.Patm;                     % vapor floor in gauge terms
if P <= floorP && dP < 0, dP = 0; end

dx = [ (Vcmd - R*i)/p.L ; ...
       v ; ...
       (Fm - Fsp - Ffr - p.Ap*P + Fstop)/p.m ; ...
       dP ; ...
       (i^2*R - p.hw*(Tw - Tf))/p.Cw ; ...
       (p.Pheat + p.hw*(Tw - Tf) - p.hf*(Tf - p.Tamb))/p.Cf ; ...
       ps2 ; ...
       p.wn_s^2*(P - ps1) - 2*p.zeta_s*p.wn_s*ps2 ];
end
