function c0v3_figures(rundir)
%C0V3_FIGURES  v3 report figures — sequential numbering by appearance (audit
%   P2-01), math-notation titles (P2-03), unclipped axes (P2-02), standard
%   typography (>=23 pt axes, 3.2 pt lines). Auto-writes figure_inventory.json
%   (audit P1-11/P2-14).
S = load(fullfile(rundir,'results.mat')); R = S.R;
fd = fullfile(rundir,'figs');
CO=[242 84 27]/255; CG=[28 31 38]/255; CS=[138 146 155]/255; CB=[30 110 190]/255;
inv = {};

% F01 Stage A-prime
f=nf(); A=R.stageA;
loglog(A.Ns,A.relerr(:,1),'-o','Color',CO,'MarkerFaceColor',CO); hold on
loglog(A.Ns,A.relerr(:,2),'-s','Color',CG,'MarkerFaceColor',CG);
loglog(A.Ns,A.relerr(:,3),'-^','Color',CB,'MarkerFaceColor',CB);
loglog(A.Ns,A.relerr(end,2)*(A.Ns/A.Ns(end)).^(-2),'--','Color',CS);
grid on; xlabel('cells per direction N'); ylabel('|relative error|');
title(sprintf('Stage A'' operator self-test — orders %.2f / %.2f / %.2f', A.observed_order));
legend({'T1 relative error','T2 relative error','T3 relative error','slope -2'},'Location','southwest');
inv=sv(f,fd,'F01_stageA',inv,'Stage A-prime operator self-test convergence');

% F02 MMS (solver-executed)
f=nf(); hM=cellfun(@(s)s.h,R.mms); eW=cellfun(@(s)abs(s.Ewin_signed_err),R.mms);
eA=cell2mat(cellfun(@(s)abs(s.Aprobe_signed_err)',R.mms,'Uni',false));
loglog(hM*1e3,eW,'-o','Color',CO,'MarkerFaceColor',CO); hold on
loglog(hM*1e3,max(eA,[],1),'-s','Color',CG,'MarkerFaceColor',CG);
loglog(hM*1e3,eW(end)*(hM/hM(end)).^2,'--','Color',CS);
grid on; xlabel('mesh size h (mm)'); ylabel('|relative error|');
title(sprintf('Solver-executed MMS — E_{win} order %.2f, A-probe order %.2f', R.mms_order, R.mms_orderA));
legend({'window energy','max A-probe','slope 2'},'Location','northwest');
inv=sv(f,fd,'F02_mms',inv,'Solver-executed MMS convergence');

% F03 coax family signed-error convergence (N-based h)
f=nf(); he=R.heff*1e3;
eE=abs(R.cv.E.signed_relerr); eI=abs(R.cv.Ein.signed_relerr); e8=abs(R.cv.bi8.signed_relerr);
eAm=abs(cellfun(@(s)s.Iloop_on/100-1,R.coax)); eB=R.Bpt_max;
loglog(he,eE,'-o','Color',CO,'MarkerFaceColor',CO); hold on
loglog(he,eI,'-v','Color',[0.2 0.55 0.25],'MarkerFaceColor',[0.2 0.55 0.25]);
loglog(he,e8,'-s','Color',CG,'MarkerFaceColor',CG);
loglog(he,eAm,'-^','Color',CB,'MarkerFaceColor',CB);
loglog(he,eB,'-d','Color',CS,'MarkerFaceColor',CS);
loglog(he,eE(end)*(R.heff/R.heff(end)).^2,'--','Color',CS);
grid on; xlabel('realized characteristic size h_{eff} (mm), N-based'); ylabel('|signed relative error|');
title(sprintf('Coax family, 6 meshes strict co-refinement (N_{el} %d \\rightarrow %d)', R.Nelem(1), R.Nelem(end)));
legend({'annulus energy','internal energy','\intB_x dA (upper)','Ampere (smoothed)','max fixed-probe |B| (smoothed)','slope 2'},'Location','southeast');
inv=sv(f,fd,'F03_coax_convergence',inv,'Coax 6-mesh signed-error convergence');

% F04 orders + asymptotic (Celik)
f=nf();
labs={'E Celik','E fit(3)','E_{in} Celik','bi8 fit(3)','Amp Celik','B_{pt} fit'};
vals=[R.cv.E.p_celik, R.cv.E.p_fit_last3, R.cv.Ein.p_celik, R.cv.bi8.p_fit_last3, R.cv.Amp.p_celik, R.Bpt_order];
bar(vals,'FaceColor',CO,'EdgeColor','none'); hold on; yline(2,'--','Color',CG,'LineWidth',2.5);
set(gca,'XTickLabel',labs,'XTickLabelRotation',18); ylabel('observed order p'); grid on
title(sprintf('Observed orders — energy asymptotic ratio %.4f (Celik, unequal r)', R.cv.E.asymptotic_ratio));
inv=sv(f,fd,'F04_orders',inv,'Observed orders and asymptotic check');

% F05 GCI meta-verification / coverage (unclipped, P2-02)
f=nf();
v = [R.cv.E.true_finest_err, R.cv.E.rich_err_vs_exact, R.cv.E.GCI12, ...
     R.cv.bi8.true_finest_err, 2e-5];
bar(v,'FaceColor',CO,'EdgeColor','none');
set(gca,'YScale','log','XTickLabel',{'E true finest','E Richardson','E GCI_{fine}','bi8 true finest','bi8 criterion'});
ylim([min(v)*0.3, max(v)*5]); grid on; ylabel('relative error / index');
title('GCI meta-verification: energy covered; bi8 gated on TRUE error (GCI withdrawn)');
inv=sv(f,fd,'F05_gci_meta',inv,'GCI meta-verification and bi8 true-error gating');

% F06 bi8 maxseg diagnostic
f=nf(); D=R.diag.msdiag;
loglog(D.ms,abs(D.bi8_signed_err),'-o','Color',CO,'MarkerFaceColor',CO); hold on
loglog(D.ms,abs(D.bi8_signed_err(end))*(D.ms/D.ms(end)).^2,'--','Color',CS);
set(gca,'XDir','reverse'); grid on
xlabel('arc maxseg (deg) \rightarrow finer'); ylabel('|bi8 signed error|');
title('bi8 floor diagnostic — maxseg halving at fixed h = 0.5 mm (slope-2 = sagitta hypothesis)');
legend({'measured','\propto maxseg^2'},'Location','northwest');
inv=sv(f,fd,'F06_bi8_diag',inv,'bi8 arc-discretization diagnostic');

% F07 smoothing ON/OFF full series (P0-10)
f=nf();
Ioff=abs(cellfun(@(s)s.Iloop_off/100-1,R.coax)); Ion=abs(cellfun(@(s)s.Iloop_on/100-1,R.coax));
Boff=cellfun(@(s)max(abs(s.Bpt_signed_off)),R.coax); Bon=R.Bpt_max;
loglog(he,Ioff,'-o','Color',CO,'MarkerFaceColor',CO); hold on
loglog(he,Ion,'-o','Color',CG,'MarkerFaceColor',CG);
loglog(he,Boff,'--s','Color',CO);
loglog(he,Bon,'--s','Color',CG);
grid on; xlabel('h_{eff} (mm)'); ylabel('|signed relative error|');
title('Smoothing series, every mesh: circles = Ampere loop, squares = max fixed-probe |B|');
legend({'Ampere off','Ampere on (authoritative)','B_{pt} off','B_{pt} on (authoritative)'},'Location','southeast');
inv=sv(f,fd,'F07_smoothing',inv,'Full smoothing OFF/ON series');

% F08 contour study (v2 measured data)
f=nf(); cs=R.v2.extras.contour; mk={'-o','-s','-^'}; hold on
for ri=1:numel(cs.radii)
    plot(cs.steps,squeeze(max(cs.relerr(:,ri,:,1),[],3)),mk{ri},'Color',CO,'MarkerFaceColor',CO);
    plot(cs.steps,squeeze(max(cs.relerr(:,ri,:,2),[],3)),mk{ri},'Color',CG,'MarkerFaceColor',CG);
end
set(gca,'XScale','log','YScale','log','XDir','reverse'); grid on
xlabel('contour anglestep (deg) \rightarrow finer'); ylabel('|I_{loop}/I - 1|');
title('Ampere-contour study (v2 data): flat in anglestep; smoothing state dominates');
inv=sv(f,fd,'F08_contour',inv,'Contour anglestep study (v2 measured data)');

% F09 omega ratio (v2 measured data)
f=nf();
semilogx(R.v2.extras.omega.freqs,R.v2.extras.omega.ratio,'-o','Color',CO,'MarkerFaceColor',CO);
hold on; yline(0.5,'--','Color',CG,'LineWidth',2.5); ylim([0.4 0.6]); grid on
xlabel('frequency (Hz)'); ylabel('E_{harm}/E_{static}');
title('Harmonic convention (v2 data): peak-phasor, time-averaged energy');
inv=sv(f,fd,'F09_omega',inv,'Harmonic energy convention (v2 measured data)');

% F10 loop mesh family (v2)
f=nf(); c2=R.v2.conv;
loglog(c2.loop_h*1e3,c2.loopPhi_err,'-o','Color',CO,'MarkerFaceColor',CO); hold on
loglog(c2.loop_h*1e3,c2.loopB_err,'-s','Color',CG,'MarkerFaceColor',CG);
loglog(c2.loop_h*1e3,c2.loopB_err(end)*(c2.loop_h/c2.loop_h(end)).^2,'--','Color',CS);
grid on; xlabel('air mesh h (mm)'); ylabel('max |relative error| over 6 probes');
title(sprintf('Loop mesh family (v2 data): p_{\\Phi} = %.2f, p_B = %.2f', c2.loopPhi_order, c2.loopB_order));
legend({'flux \Phi','|B|','slope 2'},'Location','northwest');
inv=sv(f,fd,'F10_loop_mesh',inv,'Loop mesh-family convergence (v2 measured data)');

% F11 loop domain plateau (new, P0-05)
f=nf(); L=R.loopdom;
Rs=L.Rset;
mP=arrayfun(@(k)max(abs(L.run(k).Phi_signed_err)),1:3);
mB=arrayfun(@(k)max(abs(L.run(k).Bmag_signed_err)),1:3);
semilogy(Rs,mP,'-o','Color',CO,'MarkerFaceColor',CO); hold on
semilogy(Rs,mB,'-s','Color',CG,'MarkerFaceColor',CG);
grid on; xlabel('ABC outer radius R_{dom} (m)'); ylabel('max |signed relative error|');
title(sprintf('Loop domain study at finest mesh — plateau \\Delta(0.14\\rightarrow0.20): \\Phi %.1e, |B| %.1e', ...
    L.plateau.dPhi_23, L.plateau.dB_23));
legend({'flux \Phi','|B|'},'Location','northeast');
inv=sv(f,fd,'F11_loop_domain',inv,'Loop outer-domain plateau at finest mesh');

% F12-F15: 3-D surfaces
gc = R.coax{end}.grid;
[RG,TG]=ndgrid(gc.r,gc.th); X=RG.*cos(TG); Y=RG.*sin(TG);
f=nf3(); surf([X X(:,1)]*1e3,[Y Y(:,1)]*1e3,[gc.Bexact gc.Bexact(:,1)]*1e3,'EdgeColor','none');
colormap(f,turbo); colorbar; view(40,32);
xlabel('x (mm)'); ylabel('y (mm)'); zlabel('|B| (mT)');
title('Coax annulus — analytic |B| = \mu_0I/(2\pi r) reference surface');
inv=sv(f,fd,'F12_coax_B_3d',inv,'Analytic |B| reference surface');
f=nf3(); surf([X X(:,1)]*1e3,[Y Y(:,1)]*1e3,[gc.relerr gc.relerr(:,1)]*100,'EdgeColor','none');
colormap(f,turbo); colorbar; view(40,32);
xlabel('x (mm)'); ylabel('y (mm)'); zlabel('pointwise |B| error (%)');
title(sprintf('Pointwise |B| signed-error surface — finest mesh (h_{eff} = %.3g mm, 2592 samples)', R.heff(end)*1e3));
inv=sv(f,fd,'F13_coax_err_3d',inv,'Finest-mesh pointwise error surface');
gl = R.loopdom.grid; [RG2,ZG2]=ndgrid(gl.r,gl.z);
f=nf3(); surf(RG2*1e3,ZG2*1e3,gl.geta*1e6,'EdgeColor','none');
colormap(f,turbo); colorbar; view(45,30);
xlabel('r (mm)'); ylabel('z (mm)'); zlabel('\Phi = 2\pi r A_{\phi}  (\muWb)');
title('Loop benchmark — flux-function surface (R_{dom} = 0.14 m, finest mesh)');
inv=sv(f,fd,'F14_loop_flux_3d',inv,'Loop flux-function surface');
f=nf3(); surf(RG2*1e3,ZG2*1e3,log10(max(gl.Bmag,1e-9)),'EdgeColor','none');
colormap(f,turbo); colorbar; view(45,30);
xlabel('r (mm)'); ylabel('z (mm)'); zlabel('log_{10} |B| (T)');
title('Loop benchmark — |B| magnitude surface (source tube excluded)');
inv=sv(f,fd,'F15_loop_B_3d',inv,'Loop |B| magnitude surface');

% inventory (P1-11/P2-14)
fid=fopen(fullfile(rundir,'figure_inventory.json'),'w');
fwrite(fid,jsonencode(struct('count',numel(inv),'figures',{inv}))); fclose(fid);
fprintf('figures: %d, inventory written\n', numel(inv));
end

function f=nf()
f=figure('Visible','off','Position',[40 40 1560 1000],'Color','w');
set(f,'DefaultAxesFontSize',23,'DefaultLineLineWidth',3.2,'DefaultLineMarkerSize',11, ...
      'DefaultLegendFontSize',19,'DefaultAxesLabelFontSizeMultiplier',1.05);
end
function f=nf3()
f=figure('Visible','off','Position',[40 40 1560 1040],'Color','w');
set(f,'DefaultAxesFontSize',21,'DefaultLineLineWidth',2.4);
end
function inv=sv(f,fd,name,inv,desc)
ax=findall(f,'Type','axes');
for a=ax', grid(a,'on'); a.GridAlpha=0.28; a.LineWidth=1.2; end
print(f,fullfile(fd,[name '.png']),'-dpng','-r170');
close(f);
inv{end+1}=struct('file',[name '.png'],'desc',desc);
end
