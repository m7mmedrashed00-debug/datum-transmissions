function out = c0v2_loop_bench(hair, rundir, tag, Rdom, ref, probes, src, dogrid)
if nargin < 8, dogrid = false; end
%C0V2_LOOP_BENCH  One axisymmetric solve of the finite-cross-section loop at
%   air mesh size hair [m], ABC open boundary at Rdom, retained artifacts.
%   Observables at probe points (all >=14 mm from the source centroid):
%     Phi = flux through the circle (r,z)  vs quadrature reference
%     |B|                                  vs quadrature reference
%   Also runs the mo_geta AXISYM CONVENTION PROBE on this mesh: FEMM axisym
%   documentation implies the reported potential is the modified 2*pi*r*A;
%   the probe tests g against BOTH Phi and Aphi interpretations and records
%   which matches (convention evidence, archived — never assumed).
out = struct('h',hair,'tag',tag,'Rdom',Rdom);
newdocument(0);
mi_probdef(0,'meters','axi',1e-8,0,30);
mi_smartmesh(0);
% source rectangle
mi_addnode(src.r1,src.z1); mi_addnode(src.r2,src.z1);
mi_addnode(src.r2,src.z2); mi_addnode(src.r1,src.z2);
mi_addsegment(src.r1,src.z1,src.r2,src.z1);
mi_addsegment(src.r2,src.z1,src.r2,src.z2);
mi_addsegment(src.r2,src.z2,src.r1,src.z2);
mi_addsegment(src.r1,src.z2,src.r1,src.z1);
mi_addmaterial('air',1,1,0,0,0,0,0,1,0,0,0);
mi_addmaterial('coil',1,1,0,0,0,0,0,1,0,0,0);
mi_addcircprop('Isrc', src.I, 1);
% labels
mi_addblocklabel((src.r1+src.r2)/2,(src.z1+src.z2)/2);
mi_selectlabel((src.r1+src.r2)/2,(src.z1+src.z2)/2);
mi_setblockprop('coil',0,hair/8,'Isrc',0,0,1); mi_clearselected;
mi_addblocklabel(src.r2+0.01, src.z2+0.01);
mi_selectlabel(src.r2+0.01, src.z2+0.01);
mi_setblockprop('air',0,hair,'<None>',0,0,0); mi_clearselected;
% open boundary: 7-shell improvised ABC centered on origin
mi_makeABC(7, Rdom, 0, 0, 0);
fem = fullfile(rundir, sprintf('loop_%s.fem',tag));
mi_saveas(fem); mi_analyze(1); mi_loadsolution;
out.nnodes = mo_numnodes; out.nelem = mo_numelements;

n = size(probes,1);
g = zeros(n,1); B = zeros(n,2);
mo_smooth('on');
for i = 1:n
    gv = mo_geta(probes(i,1), probes(i,2)); g(i) = gv(1);
    bv = mo_getb(probes(i,1), probes(i,2)); B(i,:) = bv(1:2);
end
out.geta = g; out.B = B;
% convention probe (archived evidence, decided by data not assumption)
e_as_Phi  = median(abs(g./ref.Phi  - 1));
e_as_Aphi = median(abs(g./ref.Aphi - 1));
out.geta_err_as_Phi = e_as_Phi; out.geta_err_as_Aphi = e_as_Aphi;
if e_as_Phi < e_as_Aphi, out.geta_convention = '2*pi*r*Aphi (flux)';
else,                    out.geta_convention = 'Aphi';
end
out.err.Phi  = max(abs(g ./ ref.Phi - 1));          % scored under flux reading
if e_as_Aphi < e_as_Phi, out.err.Phi = max(abs(2*pi*probes(:,1).*g ./ ref.Phi - 1)); end
out.err.Bmag = max(abs(hypot(B(:,1),B(:,2)) ./ ref.Bmag - 1));

if dogrid
    % r-z sampling grid for 3-D figures: FEMM geta + getb on a 30x30 grid
    % clear of the source rectangle (exclusion margin 4 mm)
    rgv = linspace(0.004, 0.065, 30); zgv = linspace(-0.035, 0.035, 30);
    [RG,ZG] = ndgrid(rgv,zgv);
    GA = nan(size(RG)); BM = nan(size(RG));
    for ii = 1:numel(RG)
        if hypot(RG(ii)-(src.r1+src.r2)/2, ZG(ii)-(src.z1+src.z2)/2) < 0.004
            continue                              % exclusion tube
        end
        gv = mo_geta(RG(ii), ZG(ii)); GA(ii) = gv(1);
        bv = mo_getb(RG(ii), ZG(ii)); BM(ii) = hypot(bv(1),bv(2));
    end
    out.grid.r = rgv; out.grid.z = zgv; out.grid.geta = GA; out.grid.Bmag = BM;
end

mo_close; mi_close;
fprintf('[loop %s] h=%.4g nel=%d | Phi %.3e | |B| %.3e | geta==%s (%.1e vs %.1e)\n', ...
    tag, hair, out.nelem, out.err.Phi, out.err.Bmag, out.geta_convention, e_as_Phi, e_as_Aphi);
end
