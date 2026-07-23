function p = rd03_params()
%RD03_PARAMS  Parameter set for RD-03 spine v0.2 (baseline proportional
%   pressure-control-solenoid topology). GENERIC [Repr] values unless tagged.
%   Nothing here is a product limit or family spec.
p.version   = 'v0.2.1';
p.param_set = 'RD03-P-0003';   % values identical to -0002; outlet magic numbers
                               % moved into parameters with provenance (v0.2.1)

% --- electrical ---
p.R20   = 5.0;      % ohm  [Repr]
p.alpha = 0.00393;  % 1/C  [Dellinger, Government]
p.L     = 0.012;    % H    [Repr] const; L(i,x) map pending FEMM

% --- magnetic (flat proportional force placeholder [Wang2020]; FEMM map next) ---
p.kf    = 4.0;      % N/A^2 [Repr]

% --- mechanical ---
p.m     = 0.010;    % kg    [Repr]
p.k     = 1200;     % N/m   [Repr]
p.xpre  = 0.001;    % m     [Repr]
p.gmax  = 0.004;    % m     [Repr]
p.Kstop = 5e4;      % N/m   [Textbook] seat + stroke penalty
p.Fc    = 0.4;      % N     [Repr] Coulomb (separate from viscous per [Rundo2021])
p.vs    = 0.01;     % m/s   [Textbook] smoothing
p.cv40  = 6.0;      % N.s/m [Repr] viscous coeff at 40 C; c(T) ~ mu(T) [Rundo2021]

% --- hydraulic ---
p.Ap    = 2e-6;     % m^2   [Repr]
p.rho   = 850;      % kg/m3 [Repr; refine w/ Totten]
p.CdInf = 0.70;     % -     [Repr] turbulent-limit Cd  [Wu2002-Cd structure]
p.ReT   = 1000;     % -     [Repr] transition scale    [Wu2002-Cd structure]
p.wArea = 2e-4;     % m^2/m [Repr] metering area gradient
p.CdOut = 0.60;     % -     [Repr] outlet-orifice discharge coeff (was hard-coded in rhs)
p.Aout  = 1.2e-7;   % m^2   [Repr] outlet-orifice area (was hard-coded in rhs)
p.Ps    = 5e5;      % Pa g  [Repr] supply
p.Vch   = 2e-6;     % m^3   [Repr]
p.beta  = 1.2e9;    % Pa    [Repr] aeration-free; beta(T,air) pending [Yuan2022]
% leakage geometry [Dziubak2023 structure]
p.Dsp   = 0.008;    % m     [Repr] spool/pintle land diameter
p.cr    = 8e-6;     % m     [Repr] radial clearance
p.Llg   = 0.010;    % m     [Repr] land length
p.ecc   = 0.5;      % -     [Repr] relative eccentricity (unknown state; swept in UQ)
% fluid properties
p.mu40  = 0.060;    % Pa.s  [Repr] at 40 C
p.kmu   = 0.020;    % 1/C   [Repr] exponential decay
% pressure reference + vapor floor (P state is GAUGE; floor applied in ABSOLUTE)
p.Patm  = 101325;   % Pa    [Textbook]
p.Pvap25= 2e3;      % Pa abs at 25 C [Repr - VERIFY]
p.kvap  = 0.030;    % 1/C   [Repr - VERIFY]

% --- thermal (two nodes) ---
p.Cw    = 20;  p.hw = 0.5;   % J/K, W/K [Repr; refine w/ Liu2023]
p.Cf    = 50;  p.hf = 0.8;   % J/K, W/K [Repr]
p.Pheat = 100; p.Tamb = 25;  % W, C     [Repr]

% --- observation layer: 2nd-order pressure channel [NBS67],[Eichstadt2010] ---
p.wn_s   = 2*pi*500; % rad/s [Repr] sensor natural frequency
p.zeta_s = 0.5;      % -     [Repr] sensor damping
p.sd_i   = 2e-3;     % A     [Repr] current-channel noise sd
p.sd_p   = 2e3;      % Pa    [Repr] pressure-channel noise sd
p.sd_T   = 0.2;      % C     [Repr] temperature-channel noise sd
end
