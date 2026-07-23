function c0v2_figures(rundir)
%C0V2_FIGURES  All report figures from a completed run's results.mat.
%   PNG at ~2300 px wide (Notion-legible) + SVG for 2-D plots (vector, crisp).
%   Also dumps report_numbers.json (results minus bulky grids) for the report
%   builder and the sample-calculation appendix.
S = load(fullfile(rundir,'results.mat')); R = S.R;
fd = fullfile(rundir,'figs');
CO = [242  84  27]/255;   % Torque Orange
CG = [ 28  31  38]/255;   % Graphite
CS = [138 146 155]/255;   % Steel
CB = [ 30 110 190]/255;   % supporting blue

% ---------- F1: Stage A' convergence ----------
f = nf();
loglog(R.stageA.Ns, R.stageA.relerr(:,1),'-o','Color',CO,'MarkerFaceColor',CO); hold on
loglog(R.stageA.Ns, R.stageA.relerr(:,2),'-s','Color',CG,'MarkerFaceColor',CG);
loglog(R.stageA.Ns, R.stageA.relerr(:,3),'-^','Color',CB,'MarkerFaceColor',CB);
Ng = R.stageA.Ns; guide = R.stageA.relerr(end,2)*(Ng/Ng(end)).^(-2);
loglog(Ng, guide,'--','Color',CS);
grid on; xlabel('grid cells per direction N'); ylabel('relative error');
title(sprintf('Stage A'' — manufactured-solution self-test (orders %.2f / %.2f / %.2f)', ...
      R.stageA.observed_order));
legend({'T1  \int B_x dA','T2  energy','T3  circulation','slope -2 guide'},'Location','southwest');
sv(f, fd, 'F1_stageA_convergence', true);

% ---------- F2: coax mesh convergence ----------
hE  = cellfun(@(s) s.h,  R.coax);
eE  = R.conv.E.relerr; e8 = R.conv.bi8.relerr; eI = R.conv.Iloop.relerr;
eBp = R.conv.Bpt_err;  Nel = R.conv.Nelem;
f = nf();
loglog(hE*1e3, eE,'-o','Color',CO,'MarkerFaceColor',CO); hold on
loglog(hE*1e3, e8,'-s','Color',CG,'MarkerFaceColor',CG);
loglog(hE*1e3, eI,'-^','Color',CB,'MarkerFaceColor',CB);
loglog(hE*1e3, eBp,'-d','Color',CS,'MarkerFaceColor',CS);
loglog(hE*1e3, eE(end)*(hE/hE(end)).^2,'--','Color',CS);
grid on; xlabel('requested annulus mesh size h  (mm)'); ylabel('relative error');
title(sprintf('Coax known-answer family — 5 meshes, co-refined arcs (N_{el} %d \\rightarrow %d)', ...
      Nel(1), Nel(end)));
legend({'energy (bi2)','\int B_x upper half (bi8)','Ampere loop (H\cdott)', ...
        'pointwise |B| (off)','slope 2 guide'},'Location','northwest');
sv(f, fd, 'F2_coax_convergence', true);

% ---------- F3: observed orders + asymptotic check ----------
f = nf();
labs = {'E fit(all)','E fit(3)','E blind','bi8 fit(all)','Ampere fit(all)','B_{pt} fit'};
vals = [R.conv.E.p_fit_all, R.conv.E.p_fit_last3, R.conv.E.p_blind, ...
        R.conv.bi8.p_fit_all, R.conv.Iloop.p_fit_all, R.conv.Bpt_order];
b = bar(vals,'FaceColor',CO,'EdgeColor','none'); %#ok<NASGU>
hold on; yline(2,'--','Color',CG,'LineWidth',2);
set(gca,'XTickLabel',labs,'XTickLabelRotation',20); ylabel('observed order p');
title(sprintf('Observed orders — GCI_{fine}(E) = %.2e, asymptotic ratio = %.3f', ...
      R.conv.E.GCI12, R.conv.E.asymptotic_ratio));
grid on
sv(f, fd, 'F3_orders_asymptotic', true);

% ---------- F4: Richardson meta-verification ----------
f = nf();
v1 = abs(R.conv.E.f(end)-R.conv.E.fexact)/abs(R.conv.E.fexact);
v2 = R.conv.E.rich_err_vs_exact;
bh = bar([v1 v2 R.conv.E.GCI12],'FaceColor',CO,'EdgeColor','none'); %#ok<NASGU>
set(gca,'YScale','log','XTickLabel',{'finest-mesh error','Richardson error','GCI_{fine} (claimed U_{num})'});
ylabel('relative error / index');
title('Richardson extrapolation meta-verification (exact solution known)');
grid on
sv(f, fd, 'F4_richardson_meta', true);

% ---------- F5: contour study ----------
cs = R.extras.contour;
f = nf();
mk = {'-o','-s','-^'}; hold on
for ri = 1:numel(cs.radii)
    eOff = squeeze(max(cs.relerr(:,ri,:,1),[],3));   % max over offsets, smoothing off
    eOn  = squeeze(max(cs.relerr(:,ri,:,2),[],3));
    plot(cs.steps, eOff, mk{ri},'Color',CO,'MarkerFaceColor',CO);
    plot(cs.steps, eOn,  mk{ri},'Color',CG,'MarkerFaceColor',CG);
end
set(gca,'XScale','log','YScale','log','XDir','reverse'); grid on
xlabel('contour anglestep (deg)  \rightarrow finer'); ylabel('|I_{loop}/I - 1|');
title('Ampere-contour discretization study (orange = smoothing off, graphite = on; markers = radii)');
sv(f, fd, 'F5_contour_study', true);

% ---------- F6a/F6b: coax 3-D surfaces ----------
gc = R.coax{end}.grid;
[RG,TG] = ndgrid(gc.r, gc.th);
X = RG.*cos(TG); Y = RG.*sin(TG);
f = nf3();
surf([X X(:,1)]*1e3, [Y Y(:,1)]*1e3, [gc.Bexact gc.Bexact(:,1)]*1e3, 'EdgeColor','none');
colormap(f, turbo); colorbar; view(40,32); lighting gouraud; camlight headlight
xlabel('x (mm)'); ylabel('y (mm)'); zlabel('|B| (mT)');
title('Coax annulus — analytic |B| = \mu_0 I / (2\pi r)   (exact reference surface)');
sv(f, fd, 'F6a_coax_B_analytic_3d', false);
f = nf3();
surf([X X(:,1)]*1e3, [Y Y(:,1)]*1e3, [gc.relerr gc.relerr(:,1)]*100, 'EdgeColor','none');
colormap(f, turbo); colorbar; view(40,32);
xlabel('x (mm)'); ylabel('y (mm)'); zlabel('pointwise |B| error (%)');
title(sprintf('FEMM finest mesh (h = %.2g mm) — pointwise |B| relative error surface', R.coax{end}.h*1e3));
sv(f, fd, 'F6b_coax_error_3d', false);

% ---------- F7a/F7b: loop 3-D surfaces ----------
gl = R.loop{end}.grid;
[RG2,ZG2] = ndgrid(gl.r, gl.z);
f = nf3();
surf(RG2*1e3, ZG2*1e3, gl.geta*1e6, 'EdgeColor','none');
colormap(f, turbo); colorbar; view(45,30);
xlabel('r (mm)'); ylabel('z (mm)'); zlabel('mo\_geta  (\muWb)');
title(sprintf('Loop benchmark — mo\\_geta surface (recorded convention: %s)', R.loop{end}.geta_convention));
sv(f, fd, 'F7a_loop_flux_3d', false);
f = nf3();
surf(RG2*1e3, ZG2*1e3, log10(max(gl.Bmag,1e-9)), 'EdgeColor','none');
colormap(f, turbo); colorbar; view(45,30);
xlabel('r (mm)'); ylabel('z (mm)'); zlabel('log_{10} |B| (T)');
title('Loop benchmark — FEMM |B| field surface (source tube excluded)');
sv(f, fd, 'F7b_loop_B_3d', false);

% ---------- F8: omega sequence ----------
f = nf();
semilogx(R.extras.omega.freqs, R.extras.omega.ratio,'-o','Color',CO, ...
         'MarkerFaceColor',CO); hold on
yline(0.5,'--','Color',CG,'LineWidth',2);
grid on; xlabel('frequency (Hz)'); ylabel('E_{harmonic} / E_{static}');
ylim([0.4 0.6]);
title('\omega-sequence, \sigma = 0 — FEMM peak-phasor / time-average convention (expect 0.5)');
sv(f, fd, 'F8_omega_ratio', true);

% ---------- F9: loop convergence ----------
f = nf();
loglog(R.conv.loop_h*1e3, R.conv.loopPhi_err,'-o','Color',CO,'MarkerFaceColor',CO); hold on
loglog(R.conv.loop_h*1e3, R.conv.loopB_err,'-s','Color',CG,'MarkerFaceColor',CG);
loglog(R.conv.loop_h*1e3, R.conv.loopB_err(end)*(R.conv.loop_h/R.conv.loop_h(end)).^2,'--','Color',CS);
grid on; xlabel('air mesh size h (mm)'); ylabel('max relative error over 6 probes');
title(sprintf('Axisym loop family — orders p_\\Phi = %.2f, p_B = %.2f; ABC truncation \\Delta = %.1e', ...
      R.conv.loopPhi_order, R.conv.loopB_order, R.trunc_delta_Bmag));
legend({'flux \Phi','|B|','slope 2 guide'},'Location','northwest');
sv(f, fd, 'F9_loop_convergence', true);

% ---------- dump numbers for the report builder ----------
Rj = R;
Rj.coax{end} = rmfield(Rj.coax{end},'grid');
Rj.loop{end} = rmfield(Rj.loop{end},'grid');
fid = fopen(fullfile(rundir,'report_numbers.json'),'w');
fwrite(fid, jsonencode(Rj)); fclose(fid);
fprintf('figures + report_numbers.json written to %s\n', fd);
end

function f = nf()
f = figure('Visible','off','Position',[40 40 1500 950],'Color','w');
set(f,'DefaultAxesFontSize',17,'DefaultLineLineWidth',2.4, ...
      'DefaultAxesTitleFontSizeMultiplier',1.05);
end
function f = nf3()
f = figure('Visible','off','Position',[40 40 1500 1000],'Color','w');
set(f,'DefaultAxesFontSize',17,'DefaultLineLineWidth',2);
end
function sv(f, fd, name, dosvg)
print(f, fullfile(fd,[name '.png']), '-dpng','-r160');
if dosvg
    try, print(f, fullfile(fd,[name '.svg']), '-dsvg','-painters'); catch, end
end
close(f);
end
