%C0V2_RUN_ALL  C0 verification-gate v2 — full run with the SOL-RD03-C0e-R P0
%   repairs landed:
%   P0-1 fail-closed: gates computed, saved, then ASSERTED (a failed gate still
%        leaves a complete evidence bundle; downstream must read gate_manifest).
%   P0-2 provenance: cache key over source hashes + femm.exe hash + MATLAB
%        version + parameters; recorded in manifest and gate JSON.
%   P0-3 evidence: unique immutable run directory; diary via onCleanup with a
%        nonzero-size assert; .fem/.ans retained; results.mat + gate JSON.
%   P0-4 Stage A' manufactured solution with enforced accuracy AND order.
%   P0-5 explicit smoothing states, smartmesh off, co-refined arc maxseg,
%        realized mesh metrics (node/element counts) recorded.
clearvars; clc
V2DIR = 'C:\Users\m7mme\OneDrive\Documents\DTC - RND\c0\v2';
cd(V2DIR); addpath(V2DIR); addpath('C:\femm42\mfiles');

runid = ['run_' datestr(now,'yyyymmdd_HHMMSS')];
rundir = fullfile(V2DIR,'runs',runid); mkdir(rundir); mkdir(fullfile(rundir,'figs'));
diary(fullfile(rundir,'transcript.log'));
dcl = onCleanup(@() diary('off'));                      % P0-3: guaranteed close
fprintf('=== C0 v2 GATE RUN %s ===\nMATLAB %s\n', runid, version);

% ---------------- manifest + cache key (P0-2) ----------------
M = struct(); M.runid = runid; M.matlab = version; M.started = datestr(now,31);
srcs = {'c0v2_sha256.m','c0v2_stageA_mms.m','c0v2_coax_bench.m', ...
        'c0v2_loop_reference.m','c0v2_loop_bench.m','c0v2_convergence.m', ...
        'c0v2_extras.m','c0v2_run_all.m','c0v2_figures.m'};
for i = 1:numel(srcs)
    M.src.(matlab.lang.makeValidName(srcs{i})) = c0v2_sha256(fullfile(V2DIR,srcs{i}));
end
femmexe = 'C:\femm42\bin\femm.exe';
M.femm_exe_sha256 = c0v2_sha256(femmexe);
M.femm_exe_sha256_expected_solC0eR = '5e83cf0899cabae2017868ddcce338e3ba4ac25d1bf8e511eac77eda2bc92a21';
M.femm_exe_matches_audit = strcmp(M.femm_exe_sha256, M.femm_exe_sha256_expected_solC0eR);
% parameters
P = struct();
P.coax.h  = [4 2 1 0.5 0.25]*1e-3;          % requested annulus mesh sizes
P.coax.ms = max(5*(P.coax.h/0.004), 0.3125);% co-refined arc maxseg [deg]
P.loop.h  = [8 4 2 1]*1e-3;                 % air mesh sizes
P.loop.Rdom = 0.12; P.loop.Rdom_check = 0.18;
P.loop.src = struct('r1',29.5e-3,'r2',30.5e-3,'z1',-0.5e-3,'z2',0.5e-3,'I',100);
P.loop.probes = [0.020 0.010; 0.045 0.000; 0.015 0.025; ...
                 0.050 0.020; 0.010 -0.015; 0.060 -0.010];
M.params = P;
allh = ''; fn = fieldnames(M.src);
for i = 1:numel(fn), allh = [allh M.src.(fn{i})]; end %#ok<AGROW>
tmp = fullfile(tempdir,'c0v2_key.bin'); fid = fopen(tmp,'w');
fwrite(fid,[allh M.femm_exe_sha256 M.matlab jsonencode(P)]); fclose(fid);
M.cachekey = c0v2_sha256(tmp);
fprintf('cache key %s | femm.exe matches C0e-R record: %d\n', M.cachekey(1:16), M.femm_exe_matches_audit);

R = struct(); R.manifest = M;

% ---------------- Stage A' (no solver until it passes) ----------------
R.stageA = c0v2_stageA_mms();
assert(R.stageA.pass, 'C0v2:gate', 'Stage A'' FAILED — solver runs forbidden.');

% ---------------- Stage B1: coax mesh family ----------------
openfemm(1); fcl = onCleanup(@() closefemm);
nl = numel(P.coax.h);
coax = cell(1,nl);
for k = 1:nl
    coax{k} = c0v2_coax_bench(P.coax.h(k), P.coax.ms(k), rundir, ...
                              sprintf('L%d',k), k==nl);
end
R.coax = coax;
hE   = cellfun(@(s) s.h, coax);
E    = cellfun(@(s) s.E, coax);            Eex  = coax{1}.exact.E;
bi8  = cellfun(@(s) s.bi8_upper, coax);    bi8x = coax{1}.exact.Bx_upper;
Ilo  = cellfun(@(s) s.Iloop_off, coax);
Bpt  = cellfun(@(s) s.err_Bpt_off, coax);
Nel  = cellfun(@(s) s.nelem, coax);
R.conv.E     = c0v2_convergence(hE, E,   Eex,  'coax energy');
R.conv.bi8   = c0v2_convergence(hE, bi8, bi8x, 'coax bi8 upper');
R.conv.Iloop = c0v2_convergence(hE, Ilo, 100,  'coax Ampere (off)');
cc = polyfit(log(hE), log(Bpt), 1);
R.conv.Bpt_order = cc(1); R.conv.Bpt_err = Bpt; R.conv.Nelem = Nel;
% realized refinement ratios from element counts (2-D: r = sqrt(N2/N1))
R.conv.r_realized = sqrt(Nel(2:end)./Nel(1:end-1));

% VERIFICATION-layer gate criteria (declared; NOT application adequacy —
% decision-layer thresholds await the S2b error budget per C0e-R Q3):
gate.coax_order    = R.conv.E.p_fit_last3 > 1.5 && R.conv.E.p_fit_last3 < 2.6;
gate.coax_asym     = abs(R.conv.E.asymptotic_ratio - 1) < 0.25;
gate.coax_finest   = R.conv.E.relerr(end) < 3e-4;
gate.coax_monotone = all(diff(R.conv.E.relerr) < 0);
R.gate.coax = gate.coax_order && gate.coax_asym && gate.coax_finest && gate.coax_monotone;
fprintf('coax gate: order %d asym %d finest %d monotone %d -> %d\n', ...
    gate.coax_order, gate.coax_asym, gate.coax_finest, gate.coax_monotone, R.gate.coax);

% ---------------- Stage B2: axisym loop family ----------------
fprintf('computing quadrature references (integral2, tol 1e-11)...\n');
R.loopref = c0v2_loop_reference(P.loop.probes, P.loop.src);
nll = numel(P.loop.h);
loop = cell(1,nll);
for k = 1:nll
    loop{k} = c0v2_loop_bench(P.loop.h(k), rundir, sprintf('L%d',k), ...
                              P.loop.Rdom, R.loopref, P.loop.probes, P.loop.src, k==nll);
end
R.loop = loop;
% truncation check at mid mesh, larger ABC radius
R.loop_trunc = c0v2_loop_bench(P.loop.h(2), rundir, 'TRUNC', P.loop.Rdom_check, ...
                               R.loopref, P.loop.probes, P.loop.src, false);
R.trunc_delta_Phi  = abs(R.loop_trunc.err.Phi  - loop{2}.err.Phi);
R.trunc_delta_Bmag = abs(R.loop_trunc.err.Bmag - loop{2}.err.Bmag);
hL   = cellfun(@(s) s.h, loop);
ePhi = cellfun(@(s) s.err.Phi,  loop);
eB   = cellfun(@(s) s.err.Bmag, loop);
cP = polyfit(log(hL), log(ePhi), 1); R.conv.loopPhi_order = cP(1);
cB = polyfit(log(hL), log(eB),   1); R.conv.loopB_order   = cB(1);
R.conv.loopPhi_err = ePhi; R.conv.loopB_err = eB; R.conv.loop_h = hL;
gate.loop_Phi = (R.conv.loopPhi_order > 1.2) || (ePhi(end) < 3e-3);
gate.loop_B   = (R.conv.loopB_order   > 1.2) || (eB(end)   < 3e-3);
R.gate.loop = gate.loop_Phi && gate.loop_B;
fprintf('loop gate: pPhi %.2f pB %.2f finest %.2e/%.2e trunc-delta %.1e/%.1e -> %d\n', ...
    R.conv.loopPhi_order, R.conv.loopB_order, ePhi(end), eB(end), ...
    R.trunc_delta_Phi, R.trunc_delta_Bmag, R.gate.loop);

% ---------------- extras: contour study, omega seq, P4 ----------------
R.extras = c0v2_extras(rundir);
R.gate.criteria = gate;

% ---------------- persist FIRST, assert AFTER (evidence survives failure) ----
save(fullfile(rundir,'results.mat'), 'R', '-v7.3');
G = struct('runid',runid,'cachekey',M.cachekey,'stageA',R.stageA.pass, ...
           'coax',R.gate.coax,'loop',R.gate.loop, ...
           'femm_exe_matches_audit',M.femm_exe_matches_audit, ...
           'finished',datestr(now,31));
fid = fopen(fullfile(rundir,'gate_manifest.json'),'w');
fwrite(fid, jsonencode(G)); fclose(fid);

fprintf('\n=== C0 v2 GATE SUMMARY ===\nStageA'' %d | coax %d | loop %d\n', ...
        R.stageA.pass, R.gate.coax, R.gate.loop);
fprintf('run dir: %s\n', rundir);
clear fcl                                       % close FEMM
d = dir(fullfile(rundir,'transcript.log'));
assert(~isempty(d) && d(1).bytes > 500, 'C0v2:log', 'transcript empty — P0-3 violated');
assert(R.gate.coax, 'C0v2:gate', 'coax verification gate FAILED — see results.mat');
assert(R.gate.loop, 'C0v2:gate', 'loop verification gate FAILED — see results.mat');
fprintf('ALL GATES PASS — evidence bundle complete at %s\n', rundir);
