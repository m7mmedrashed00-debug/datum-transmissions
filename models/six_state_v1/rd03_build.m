function rpt = rd03_build()
%RD03_BUILD  One-command v0.2.1 build: tests + diagnostics + hashes + manifest.
%   Regenerates every metric from a clean state. Writes rd03_build_report.txt.
here = fileparts(mfilename('fullpath')); addpath(here);
p = rd03_params();
rpt.version = p.version; rpt.param_set = p.param_set; rpt.matlab = version;
rpt.date = char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd HH:mm'));

% 1) tests
res = runtests('test_rd03_spine');
rpt.tests_passed = nnz([res.Passed]); rpt.tests_failed = nnz([res.Failed]);
rpt.test_names = {res.Name}';

% 2) stiffness diagnostic (defined + scripted)
sdiag = rd03_stiffness(p);
rpt.tau_fast = sdiag.tau_fast; rpt.tau_slow = sdiag.tau_slow;
rpt.stiff_spread = sdiag.spread_raw;

% 3) reference runs on fixed grids + solver stats
sol = ode15s(@(t,x)rd03_rhs(t,x,5,p),[0 0.4],rd03_ic(p),rd03_solveropts('fast'));
rpt.ref_fast_end = deval(sol,0.4)'; rpt.ref_fast_steps = numel(sol.x);
p0 = p; p0.Pheat = 0;
sol2 = ode15s(@(t,x)rd03_rhs(t,x,5,p0),[0 180],rd03_ic(p0),rd03_solveropts('slow'));
rpt.ref_cf_end = deval(sol2,180)';

% 4) SHA-256 hashes of source files (config/file hashes for the manifest)
files = {'rd03_params.m','rd03_lib.m','rd03_rhs.m','rd03_observe.m','rd03_ic.m', ...
         'rd03_solveropts.m','rd03_stiffness.m','test_rd03_spine.m','rd03_build.m'};
md = java.security.MessageDigest.getInstance('SHA-256');
for k = 1:numel(files)
    fid = fopen(fullfile(here,files{k}),'r'); b = fread(fid,inf,'*uint8'); fclose(fid);
    md.reset(); h = typecast(md.digest(b),'uint8');
    rpt.hashes.(matlab.lang.makeValidName(files{k})) = lower(reshape(dec2hex(h)',1,[]));
end

% 5) write report
fid = fopen(fullfile(here,'rd03_build_report.txt'),'w');
fprintf(fid,'RD-03 v0.2.1 BUILD REPORT (%s UTC)\nmodel %s | params %s | MATLAB %s\n', ...
    rpt.date, rpt.version, rpt.param_set, rpt.matlab);
fprintf(fid,'tests: %d passed, %d failed (XFAIL convention: testXFAIL_* assert defects PRESENT)\n', ...
    rpt.tests_passed, rpt.tests_failed);
for k=1:numel(rpt.test_names), fprintf(fid,'  %s\n', rpt.test_names{k}); end
fprintf(fid,'stiffness diagnostic @0.4s point: tau_fast %.3g s, tau_slow %.3g s, spread %.3g (see rd03_stiffness.m for definition + caveats)\n', ...
    rpt.tau_fast, rpt.tau_slow, rpt.stiff_spread);
fprintf(fid,'ref fast end (0.4 s): i=%.4f A xp=%.4f mm P=%.1f kPa Tw=%.2f C | steps=%d\n', ...
    rpt.ref_fast_end(1), rpt.ref_fast_end(2)*1e3, rpt.ref_fast_end(4)/1e3, rpt.ref_fast_end(5), rpt.ref_fast_steps);
fprintf(fid,'counterfactual Pheat=0 end (180 s): i=%.4f A xp=%.4f mm P=%.1f kPa Tw=%.2f C Tf=%.2f C\n', ...
    rpt.ref_cf_end(1), rpt.ref_cf_end(2)*1e3, rpt.ref_cf_end(4)/1e3, rpt.ref_cf_end(5), rpt.ref_cf_end(6));
fn = fieldnames(rpt.hashes);
for k=1:numel(fn), fprintf(fid,'sha256 %s = %s\n', fn{k}, rpt.hashes.(fn{k})); end
fclose(fid);
fprintf('BUILD DONE: %d passed / %d failed. Report: rd03_build_report.txt\n', ...
    rpt.tests_passed, rpt.tests_failed);
end
