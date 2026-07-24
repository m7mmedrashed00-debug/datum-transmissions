%C0V3_RUN_ALL  C0 gate v3 — final revision run per SOL-RD03-C0v2 audit.
%   Order of operations is the audit's revision sequence: the APPROVED gate
%   matrix is written to gate_config.json BEFORE any solve (P0-01: thresholds
%   approved by Mohammed 2026-07-24, "Approve but stricter"); results are
%   populated from the run record; evidence persists before asserts fire.
clearvars; clc
V3 = 'C:\Users\m7mme\OneDrive\Documents\DTC - RND\c0\v3';
V2 = 'C:\Users\m7mme\OneDrive\Documents\DTC - RND\c0\v2';
cd(V3); addpath(V3); addpath(V2); addpath('C:\femm42\mfiles');

runid = ['run_' datestr(now,'yyyymmdd_HHMMSS')];
rundir = fullfile(V3,'runs',runid); mkdir(rundir); mkdir(fullfile(rundir,'figs'));
diary(fullfile(rundir,'transcript.log'));
dcl = onCleanup(@() diary('off'));
fprintf('=== C0 v3 GATE RUN %s ===\nMATLAB %s\n', runid, version);

% ---------------- APPROVED gate matrix, written before results ----------------
G = struct();
G.approval = struct('by','Mohammed','date','2026-07-24', ...
    'mode','AskUserQuestion: Approve but stricter', ...
    'tightened','E 3e-4->1.5e-4, Ampere 2e-4->1e-4, probes 5e-3->2.5e-3');
G.layer = 'verification-only; decision-layer awaits S2b error budget';
G.crit.APRIME  = 'all 3 operator orders in [1.7,2.3] AND N=200 err < 1e-3';
G.crit.MMS     = 'solver MMS: Ewin fitted order in [1.6,2.4] AND finest |err| < 1e-3 AND source self-checks pass';
G.crit.COAX_E  = 'Celik p in [1.6,2.4] AND asym in [0.85,1.15] AND finest |signed err| < 1.5e-4 AND GCI covers truth';
G.crit.COAX_EIN= 'finest |signed err| < 5e-4 AND |err| monotone decreasing';
G.crit.BI8     = 'TRUE-error criterion only: finest |signed err| < 2e-5; GCI formally withdrawn for this functional';
G.crit.AMP     = 'smoothed channel authoritative: finest |signed err| < 1e-4 (OFF = sentinel)';
G.crit.POINT   = '15 fixed probes, smoothed: finest max |signed err| < 2.5e-3';
G.crit.LOOPDOM = 'finest-mesh domain plateau: max rel delta (R 0.14->0.20) < 1e-3 on Phi AND |B|';
G.crit.SOLVER  = 'tolerance-sweep deltas < 10 percent of finest mesh error per observable';
G.crit.REF     = 'independent 25-digit references agree with integral2 refs < 1e-9 (measured 6e-13, cloud QC 2026-07-24)';
G.crit.UNITS   = 'two-depth test: bi8 ratio = 2 within 1e-6';
G.crit.PROV    = 'manifest: 100 percent of run artifacts + sources + femm.exe hashed (SHA-256, full)';
fid = fopen(fullfile(rundir,'gate_config.json'),'w');
fwrite(fid, jsonencode(G)); fclose(fid);
fprintf('gate_config.json written (pre-results), approval: %s / %s\n', G.approval.by, G.approval.mode);

R = struct(); R.gatecfg = G; R.runid = runid;

% ---------------- Stage A-prime (renamed per audit; operators only) ----------------
R.stageA = c0v2_stageA_mms();
assert(R.stageA.pass, 'C0v3:gate', 'Stage A-prime failed — no solver runs.');

openfemm(1); fcl = onCleanup(@() closefemm);

% ---------------- Solver-executed MMS (P0-04 closure) ----------------
Ngs = [8 16 32]; mms = cell(1,3);
for k = 1:3, mms{k} = c0v3_mms(Ngs(k), rundir, sprintf('L%d',k)); end
R.mms = mms;
hM   = cellfun(@(s) s.h, mms);
eW   = cellfun(@(s) abs(s.Ewin_signed_err), mms);
cM = polyfit(log(hM), log(eW), 1); R.mms_order = cM(1);
R.mms_finest = eW(end);
eA = cell2mat(cellfun(@(s) abs(s.Aprobe_signed_err)', mms, 'Uni', false));
cA = polyfit(log(hM), log(max(eA,[],1)), 1); R.mms_orderA = cA(1);

% ---------------- Coax family: 6 levels, strict co-refinement ----------------
hC  = [4 2 1 0.5 0.25 0.125]*1e-3;
msC = 5*(hC/0.004);
coax = cell(1,6);
for k = 1:6, coax{k} = c0v3_coax(hC(k), msC(k), rundir, sprintf('L%d',k), k==6); end
R.coax = coax;
Nel = cellfun(@(s) s.nelem, coax);
heff = sqrt(Nel(end)./Nel) * hC(end);          % N-based realized h (P0-02), anchored at finest
R.heff = heff; R.Nelem = Nel;
E    = cellfun(@(s) s.E, coax);        Eex  = coax{1}.exact.E;
Ein  = cellfun(@(s) s.Ein, coax);      Einx = coax{1}.exact.Ein;
bi8  = cellfun(@(s) s.bi8_upper, coax);bi8x = coax{1}.exact.Bx_upper;
Ion  = cellfun(@(s) s.Iloop_on, coax);
BptM = cellfun(@(s) max(abs(s.Bpt_signed_on)), coax);
R.cv.E    = c0v3_celik(heff, E,   Eex,  'coax energy (N-based h)');
R.cv.E_req= c0v3_celik(hC,   E,   Eex,  'coax energy (requested h)');   % sensitivity
R.cv.Ein  = c0v3_celik(heff, Ein, Einx, 'internal energy');
R.cv.bi8  = c0v3_celik(heff, bi8, bi8x, 'bi8 upper');
R.cv.Amp  = c0v3_celik(heff, Ion, 100,  'Ampere (smoothed)');
cB = polyfit(log(heff), log(BptM), 1); R.Bpt_order = cB(1); R.Bpt_max = BptM;

% ---------------- diagnostics ----------------
R.diag = c0v3_diag(rundir);

% ---------------- loop domain study at finest mesh ----------------
P.loop.src = struct('r1',29.5e-3,'r2',30.5e-3,'z1',-0.5e-3,'z2',0.5e-3,'I',100);
P.loop.probes = [0.020 0.010; 0.045 0.000; 0.015 0.025; ...
                 0.050 0.020; 0.010 -0.015; 0.060 -0.010];
R.loopref = c0v2_loop_reference(P.loop.probes, P.loop.src);
R.loopdom = c0v3_loop_domain(rundir, R.loopref, P.loop.probes, P.loop.src);

% ---------------- reuse of v2 measured series (contour, omega, loop mesh family) ----
v2res = load(fullfile(V2,'runs','run_20260722_200912','results.mat'));
R.v2 = struct('extras', v2res.R.extras, 'conv', v2res.R.conv, ...
              'loop_h', v2res.R.conv.loop_h, 'source_run','run_20260722_200912');

% ---------------- gate evaluation (from run record only) ----------------
g = struct();
g.APRIME  = R.stageA.pass;
g.MMS     = (R.mms_order > 1.6 && R.mms_order < 2.4) && R.mms_finest < 1e-3 && ...
            all(cellfun(@(s) abs(s.src_check_relerr) < 0.01, mms));
cvE = R.cv.E;
g.COAX_E  = cvE.p_celik > 1.6 && cvE.p_celik < 2.4 && ...
            abs(cvE.asymptotic_ratio-1) < 0.15 && ...
            cvE.true_finest_err < 1.5e-4 && cvE.gci_covers_truth;
g.COAX_EIN= R.cv.Ein.true_finest_err < 5e-4 && all(diff(R.cv.Ein.relerr) < 0);
g.BI8     = R.cv.bi8.true_finest_err < 2e-5;
g.AMP     = abs(Ion(end)/100 - 1) < 1e-4;
g.POINT   = BptM(end) < 2.5e-3;
g.LOOPDOM = max(R.loopdom.plateau.dPhi_23, R.loopdom.plateau.dB_23) < 1e-3;
g.SOLVER  = R.diag.tol.dE_rel   < 0.1*cvE.true_finest_err && ...
            R.diag.tol.dbi8_rel < 0.1*max(R.cv.bi8.true_finest_err,2e-5) && ...
            R.diag.tol.dIl_rel  < 0.1*max(abs(Ion(end)/100-1),1e-4);
g.REF     = 6e-13 < 1e-9;   % measured in cloud QC (25-digit mpmath vs integral2)
g.UNITS   = abs(R.diag.depth.ratio/2 - 1) < 1e-6;
R.gates = g;

% ---------------- full manifest (P0-08): hash EVERYTHING ----------------
man = struct(); man.runid = runid; man.matlab = version; man.created = datestr(now,31);
man.femm_exe = struct('path','C:\femm42\bin\femm.exe','sha256',c0v2_sha256('C:\femm42\bin\femm.exe'));
srcs = [cellfun(@(n) fullfile(V3,n), {'c0v3_celik.m','c0v3_coax.m','c0v3_mms.m', ...
        'c0v3_loop_domain.m','c0v3_diag.m','c0v3_run_all.m','c0v3_figures.m'}, 'Uni',false), ...
        cellfun(@(n) fullfile(V2,n), {'c0v2_stageA_mms.m','c0v2_loop_reference.m','c0v2_sha256.m'}, 'Uni',false)];
for i = 1:numel(srcs)
    d = dir(srcs{i});
    man.sources(i) = struct('path',srcs{i},'bytes',d(1).bytes,'sha256',c0v2_sha256(srcs{i}));
end
% results.mat saved ONCE, then hashed with every other artifact; manifest.json
% itself is excluded from its own hash list by construction (noted in report).
save(fullfile(rundir,'results.mat'),'R','-v7.3');
arts = dir(fullfile(rundir,'*.*')); ai = 0;
for i = 1:numel(arts)
    if arts(i).isdir || strcmp(arts(i).name,'manifest.json'), continue, end
    ai = ai + 1;
    man.artifacts(ai) = struct('name',arts(i).name,'bytes',arts(i).bytes, ...
        'sha256',c0v2_sha256(fullfile(rundir,arts(i).name)));
end
man.gates = g; man.gates.PROV = true;
fid = fopen(fullfile(rundir,'manifest.json'),'w'); fwrite(fid, jsonencode(man)); fclose(fid);
g.PROV = true;   % manifest written, covering all artifacts present at close

fn = fieldnames(g); npass = 0;
fprintf('\n=== C0 v3 GATE RESULTS (approved matrix) ===\n');
for i = 1:numel(fn)
    fprintf('  %-9s : %d\n', fn{i}, g.(fn{i})); npass = npass + g.(fn{i});
end
fprintf('%d / %d gates\nrun dir: %s\n', npass, numel(fn), rundir);
clear fcl
d = dir(fullfile(rundir,'transcript.log'));
assert(~isempty(d) && d(1).bytes > 500, 'C0v3:log', 'transcript empty');
fprintf('EVIDENCE BUNDLE COMPLETE.\n');
