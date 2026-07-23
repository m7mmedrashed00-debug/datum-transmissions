function tests = test_rd03_spine
%TEST_RD03_SPINE  v0.2.1 suite: component checks + invariants + XFAIL defect ledger.
%   CONVENTION: testXFAIL_* ASSERT THAT A KNOWN DEFECT IS PRESENT. They pass while
%   the defect exists and FAIL when a fix ships - the failure is the signal to
%   promote them to positive tests. Every model-card defect has a test here.
tests = functiontests(localfunctions);
end

% ---------- component checks (selected equations vs independent yardsticks) ----------
function testAnalyticRLBenchmark(tc)
p = rd03_params(); p.kf = 0;
[t,X] = ode15s(@(t,x)rd03_rhs(t,x,5,p),[0 0.05],rd03_ic(p),rd03_solveropts('fast'));
R = p.R20*(1+p.alpha*(p.Tamb-20));
ia = (5/R)*(1-exp(-t*R/p.L));
verifyLessThan(tc, max(abs(X(:,1)-ia))/max(ia), 2e-3);
end

function testElectricalOnlyEnergyBalance(tc)
% Component check ONLY (kf=0). The COUPLED ledger lives in testXFAIL_EMEnergyLedgerOpen.
p = rd03_params(); p.kf = 0; L = rd03_lib(p);
[t,X] = ode15s(@(t,x)rd03_rhs(t,x,5,p),[0 0.05],rd03_ic(p),rd03_solveropts('fast'));
Ein = trapz(t, 5*X(:,1)); Eloss = trapz(t, X(:,1).^2 .* L.R(X(:,5)));
verifyLessThan(tc, abs(Ein-Eloss-0.5*p.L*X(end,1)^2)/Ein, 2e-3);
end

function testCdLimitsAndLeakOrdering(tc)
p = rd03_params(); L = rd03_lib(p);
verifyLessThan(tc, L.cd(10), 0.3*p.CdInf);
verifyGreaterThan(tc, L.cd(1e5), 0.95*p.CdInf);
verifyGreaterThan(tc, L.qleak(4e5,100), 2*L.qleak(4e5,25));
end

function testRegimeLabels(tc)
p = rd03_params(); L = rd03_lib(p);
verifyEqual(tc, L.regime(1e5,25), 0);
verifyEqual(tc, L.regime(-5e3,25), 1);
verifyEqual(tc, L.regime(L.pvap(25)-p.Patm-100,25), 2);
end

% ---------- solution verification: FULL-TRAJECTORY + event time on fixed grid ----------
function testTrajectoryToleranceConvergence(tc)
p = rd03_params();
sc = [1;1e-3;0.1;4e5;100;100;4e5;4e7];
% SOLUTION VERIFICATION at production tolerance: 1e-6 vs 1e-7 must agree on the
% FULL trajectory (fixed deval grid) and on event time. Build finding F-NUM
% (2026-07-18): RelTol 1e-4 is OUTSIDE the convergence regime for the ~12 ms
% underdamped mech-hydraulic swing (scaled errors up to ~377) - documented in
% testXFAIL_D7 below. Minimum production tolerance: RelTol 1e-6.
sol_b = ode15s(@(t,x)rd03_rhs(t,x,5,p),[0 0.4],rd03_ic(p),rd03_solveropts('fast',1e-6));
sol_c = ode15s(@(t,x)rd03_rhs(t,x,5,p),[0 0.4],rd03_ic(p),rd03_solveropts('fast',1e-7));
tg = linspace(5e-3,0.4,400);
Xb = deval(sol_b,tg); Xc = deval(sol_c,tg);
verifyLessThan(tc, max(max(abs(Xb(1:7,:)-Xc(1:7,:))./sc(1:7),[],2)), 1e-2);
verifyLessThan(tc, max(abs(Xb(8,:)-Xc(8,:))/sc(8)), 5e-2);   % derivative state, looser
tge = linspace(1e-5,0.05,2000);
tb = local_t63(deval(sol_b,tge,4), tge); tcx = local_t63(deval(sol_c,tge,4), tge);
verifyLessThan(tc, abs(tb-tcx), 2e-4);
end

function testXFAIL_D7_CoarseToleranceOutsideConvergence(tc)
% FINDING F-NUM: RelTol 1e-4 does not track the converged transient trajectory
% (phase error in the underdamped swing near t~12 ms). This test DOCUMENTS the
% inadequacy; if future smoothing (event-based contact/floor) brings 1e-4 into
% the convergence regime, this fails -> revisit the tolerance policy.
p = rd03_params(); sc = [1;1e-3;0.1;4e5;100;100;4e5;4e7];
sol_a = ode15s(@(t,x)rd03_rhs(t,x,5,p),[0 0.4],rd03_ic(p),rd03_solveropts('fast',1e-4));
sol_b = ode15s(@(t,x)rd03_rhs(t,x,5,p),[0 0.4],rd03_ic(p),rd03_solveropts('fast',1e-6));
tg = linspace(5e-3,0.4,400);
err = max(max(abs(deval(sol_a,tg)-deval(sol_b,tg))./sc,[],2));
verifyGreaterThan(tc, err, 1);
end

function t63 = local_t63(pv, tg)
tgt = 0.63*pv(end); k = find(pv >= tgt, 1);
t63 = tg(k-1) + (tgt-pv(k-1))/(pv(k)-pv(k-1))*(tg(k)-tg(k-1));
end

% ---------- invariants ----------
function testEnergizeInvariants(tc)
p = rd03_params(); L = rd03_lib(p);
[~,X] = ode15s(@(t,x)rd03_rhs(t,x,5,p),[0 0.4],rd03_ic(p),rd03_solveropts('fast'));
verifyGreaterThan(tc, X(end,2), 0); verifyLessThan(tc, X(end,2), p.gmax);
verifyLessThanOrEqual(tc, X(end,1), 5/L.R(X(end,5)) + 1e-3);
verifyGreaterThan(tc, X(end,5), p.Tamb);
end

function testVoltageOffDecay(tc)
p = rd03_params();
[~,X] = ode15s(@(t,x)rd03_rhs(t,x,5,p),[0 0.4],rd03_ic(p),rd03_solveropts('fast'));
x0 = X(end,:).'; x0(1) = 1;
[~,Xo] = ode15s(@(t,x)rd03_rhs(t,x,0,p),[0 0.3],x0,rd03_solveropts('fast'));
verifyLessThan(tc, Xo(end,1), 0.05);
end

function testSensorTracksSteadyLagsTransient(tc)
p = rd03_params();
[~,X] = ode15s(@(t,x)rd03_rhs(t,x,5,p),[0 0.4],rd03_ic(p),rd03_solveropts('fast'));
verifyLessThan(tc, abs(X(end,7)-X(end,4)), 1e3);
verifyGreaterThan(tc, max(abs(X(:,7)-X(:,4))), 10*max(abs(X(end,7)-X(end,4)),1));
end

% ---------- cross-implementation regression (Sol 5.6 SciPy/BDF counterfactual) ----------
function testPheatZeroCounterfactualMatchesSol(tc)
% Sol 5.6 independent SciPy run, Pheat=0, 180 s: Tw 38.1 C, i 0.934 A,
% xp 1.307 mm, P 359 kPa. MATLAB must reproduce within cross-impl tolerance.
p = rd03_params(); p.Pheat = 0;
[~,X] = ode15s(@(t,x)rd03_rhs(t,x,5,p),[0 180],rd03_ic(p),rd03_solveropts('slow'));
verifyEqual(tc, X(end,5), 38.1,  "AbsTol", 0.6);
verifyEqual(tc, X(end,1), 0.934, "AbsTol", 0.01);
verifyEqual(tc, X(end,2)*1e3, 1.307, "AbsTol", 0.04);
verifyEqual(tc, X(end,4)/1e3, 359,  "AbsTol", 6);
end

% ================== XFAIL DEFECT LEDGER (assert defect PRESENT) ==================
function testXFAIL_D1_EMEnergyLedgerOpenWithForceActive(tc)
% DEFECT D1: magnetic force does mechanical work never drawn from the circuit.
p = rd03_params(); L = rd03_lib(p);
[t,X] = ode15s(@(t,x)rd03_rhs(t,x,5,p),[0 0.1],rd03_ic(p),rd03_solveropts('fast'));
Ein  = trapz(t, 5*X(:,1));
Eht  = trapz(t, X(:,1).^2 .* L.R(X(:,5)));
Est  = 0.5*p.L*X(end,1)^2;
Wmech= trapz(t, (p.kf*X(:,1).^2).*X(:,3));          % work done by Fmag
verifyLessThan(tc, abs(Ein-Eht-Est)/Ein, 5e-3);      % electrical side closes alone...
verifyGreaterThan(tc, Wmech, 1e-3);                  % ...while >1 mJ appears from nowhere
end

function testXFAIL_D4a_SeatedEquilibriumPenetrates(tc)
% DEFECT D4: penalty seat's own equilibrium is negative (~-23 um).
p = rd03_params(); x0 = rd03_ic(p);
verifyLessThan(tc, x0(2), -5e-6);
end

function testXFAIL_D4b_AllTimeSeatPenetration(tc)
% DEFECT D4: trajectory penetrates the seat beyond tolerance (all-time check).
p = rd03_params();
[~,X] = ode15s(@(t,x)rd03_rhs(t,x,5,p),[0 0.4],rd03_ic(p),rd03_solveropts('fast'));
verifyLessThan(tc, min(X(:,2)), -5e-6);
end

function testXFAIL_D5_MovingVaporFloorViolated(tc)
% DEFECT D5: derivative-only clamp cannot follow a temperature-driven floor rise.
p = rd03_params(); p.cr = 0;                          % isolate: no leak path
L = rd03_lib(p); x0 = rd03_ic(p);
x0(2) = -p.k*p.xpre/(p.k+p.Kstop);                    % seated, no inflow
x0(4) = L.pvap(p.Tamb) - p.Patm;                      % start ON the floor at 25 C
[~,X] = ode15s(@(t,x)rd03_rhs(t,x,0,p),[0 60],x0,rd03_solveropts('slow'));
viol = max(L.pvap(X(:,6)) - (X(:,4)+p.Patm));         % floor above P_abs
verifyGreaterThan(tc, viol, 500);                     % violation grows as Tf warms
end

function testXFAIL_D6_ReverseFlowUnsupported(tc)
% DEFECT D6: P > Ps demands backflow through the metering path; model gives zero.
p = rd03_params(); L = rd03_lib(p);
P = 6e5; xp = 1e-3; Tf = 25;                          % P above 5e5 supply
vjet = sqrt(2*max(p.Ps-P,0)/p.rho);
Qin  = L.cd(p.rho*vjet*2*xp/L.mu(Tf)) * p.wArea*xp * vjet;
verifyEqual(tc, Qin, 0);                              % no reverse flow representable
verifyLessThan(tc, p.Ps - P, 0);                      % though physics demands it
end
