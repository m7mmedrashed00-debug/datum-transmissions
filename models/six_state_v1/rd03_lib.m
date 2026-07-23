function L = rd03_lib(p)
%RD03_LIB  Constitutive library for the RD-03 spine v0.2. Structure per shelf
%   cards; ALL coefficients [Repr] until bench-fit. Never family values.

% viscosity-temperature (exponential placeholder; Walther fit pending [McGuire2021]/[ASTM D341 acq])
L.mu = @(T) p.mu40 * exp(-p.kmu*(T - 40));                     % Pa.s   [Repr]

% discharge coefficient Cd(Re): sqrt(Re) laminar limit -> turbulent plateau.
% STRUCTURE per [Wu2002-Cd] card (closed-form Cd(sqrt Re)); exact fitted form
% pending paper read (row Inbox). Coefficients bench-owned.
L.cd = @(Re) p.CdInf * tanh( sqrt(max(Re,0)/p.ReT) );          % -      [Repr]

% annular clearance leakage with eccentricity + mu(T)  [Dziubak2023 card + Textbook h^3]
L.qleak = @(dp,T) pi*p.Dsp*p.cr^3 .* dp .* (1+1.5*p.ecc^2) ./ (12*L.mu(T)*p.Llg);  % m^3/s

% vapor pressure (absolute), exponential placeholder [Repr - VERIFY w/ Totten/ASTM]
L.pvap = @(T) p.Pvap25 * exp(p.kvap*(T - 25));                 % Pa abs [Repr]

% regime label: 0 normal | 1 sub-atmospheric (gauge<0, above vapor) | 2 vapor-floor
% Three-regime language per [Osterland2023] card: sub-atmospheric != aeration != vapor cavitation.
% Aeration (gas release) needs air-fraction data -> RESERVE [Shah2018-RP].
L.regime = @(P,T) 1*((P<0) & ((P+p.Patm) > L.pvap(T))) + 2*((P+p.Patm) <= L.pvap(T));

% viscous friction coefficient c(T) ~ mu(T) hypothesis [Rundo2021 card]
L.cvisc = @(T) p.cv40 * L.mu(T)/L.mu(40);                      % N.s/m  [Repr]

% copper resistance [Dellinger]
L.R = @(Tw) p.R20*(1 + p.alpha*(Tw - 20));                     % ohm
end
