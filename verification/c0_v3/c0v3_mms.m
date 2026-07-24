function out = c0v3_mms(Ng, rundir, tag)
%C0V3_MMS  Solver-executed Method of Manufactured Solutions (C0v2 audit P0-04).
%   Manufactured solution on the unit-square-like domain [0,L]^2, L = 0.1 m:
%       A_z(x,y) = A0 sin(kx x) sin(ky y),  kx = pi/L, ky = 2*pi/L
%   so A_z = 0 EXACTLY on the boundary (Dirichlet A0 boundary is exact).
%   Manufactured forcing J = (kx^2+ky^2) A_z / mu0 is applied as PIECEWISE-
%   CONSTANT cell averages on an Ng x Ng block grid (exact separable averages),
%   CO-REFINED with the mesh (h = L/(2 Ng)); the discrete forcing is part of
%   the discretization, so solution error should converge at order ~2.
%   This exercises model generation -> PDE assembly -> solve -> extraction:
%   the path the audit said Stage A' does not touch.
%   Self-check (units guard, FEMM J is MA/m^2): total current over the lower
%   half domain y in [0, L/2] via blockintegral(7) vs exact 7957.747155 A.
%   Observables: signed A_z error at 3 interior probes (mo_geta, planar);
%   window energy over [L/4, 3L/4]^2 vs exact 1.6959346300 J/m.
mu0 = 4e-7*pi; L = 0.1; A0 = 1e-3; kx = pi/L; ky = 2*pi/L;
out = struct('Ng',Ng,'tag',tag,'h',L/(2*Ng));
% exact targets from closed forms (cross-checked against 25-digit mpmath)
IsinE = @(k,u1,u2) (cos(k*u1)-cos(k*u2))/k;
Isin2 = @(k,u1,u2) (u2-u1)/2 - (sin(2*k*u2)-sin(2*k*u1))/(4*k);
Icos2 = @(k,u1,u2) (u2-u1)/2 + (sin(2*k*u2)-sin(2*k*u1))/(4*k);
w1 = L/4; w2 = 3*L/4;
out.exact.Ewin  = ((A0*ky)^2*Isin2(kx,w1,w2)*Icos2(ky,w1,w2) + ...
                   (A0*kx)^2*Icos2(kx,w1,w2)*Isin2(ky,w1,w2))/(2*mu0);
out.exact.Ihalf = (kx^2+ky^2)/mu0 * A0 * IsinE(kx,0,L) * IsinE(ky,0,L/2);
probes = [0.030 0.020; 0.060 0.040; 0.050 0.065];
out.probes = probes;
Aex = @(x,y) A0*sin(kx*x).*sin(ky*y);
out.exact.Aprobes = Aex(probes(:,1), probes(:,2))';

newdocument(0);
mi_probdef(0,'meters','planar',1e-8,1,30);
mi_smartmesh(0);
g = linspace(0, L, Ng+1);
% nodes
for i = 1:Ng+1
    for j = 1:Ng+1
        mi_addnode(g(i), g(j));
    end
end
% segments (horizontal + vertical unit cells)
for i = 1:Ng
    for j = 1:Ng+1
        mi_addsegment(g(i), g(j), g(i+1), g(j));   % horizontal
        mi_addsegment(g(j), g(i), g(j), g(i+1));   % vertical (swapped roles)
    end
end
% boundary: A = 0 on all outer edge segments
mi_addboundprop('Azero',0,0,0,0,0,0,0,0,0,0,0);
for i = 1:Ng
    xm = (g(i)+g(i+1))/2;
    for yb = [0 L]
        mi_selectsegment(xm, yb); mi_setsegmentprop('Azero',0,1,0,0); mi_clearselected;
    end
    for xb = [0 L]
        mi_selectsegment(xb, xm); mi_setsegmentprop('Azero',0,1,0,0); mi_clearselected;
    end
end
% cell-average manufactured J as one material per cell (MA/m^2)
Isin = @(k,u1,u2) (cos(k*u1)-cos(k*u2))/k;
h = L/(2*Ng);
for i = 1:Ng
    for j = 1:Ng
        Javg = (kx^2+ky^2)/mu0 * A0 * Isin(kx,g(i),g(i+1))*Isin(ky,g(j),g(j+1)) ...
               / ((g(i+1)-g(i))*(g(j+1)-g(j)));
        nm = sprintf('J_%d_%d',i,j);
        mi_addmaterial(nm,1,1,0, Javg/1e6, 0,0,0,1,0,0,0);   % J in MA/m^2
        xc = (g(i)+g(i+1))/2; yc = (g(j)+g(j+1))/2;
        mi_addblocklabel(xc,yc); mi_selectlabel(xc,yc);
        mi_setblockprop(nm,0,h,'<None>',0,0,0); mi_clearselected;
    end
end
fem = fullfile(rundir, sprintf('mms_%s.fem',tag));
mi_saveas(fem); mi_analyze(1); mi_loadsolution;
out.nnodes = mo_numnodes; out.nelem = mo_numelements;

% units/source self-check: total current, lower half (y < L/2)
for i = 1:Ng
    for j = 1:Ng/2
        mo_selectblock((g(i)+g(i+1))/2, (g(j)+g(j+1))/2);
    end
end
Ihalf = mo_blockintegral(7); mo_clearblock;
out.Ihalf = Ihalf;
out.src_check_relerr = Ihalf/out.exact.Ihalf - 1;
assert(abs(out.src_check_relerr) < 0.01, 'C0v3:mms', 'source/units self-check failed');

% window energy [L/4, 3L/4]^2 (cell-aligned for all Ng in {8,16,32})
i1 = Ng/4 + 1; i2 = 3*Ng/4;
for i = i1:i2
    for j = i1:i2
        mo_selectblock((g(i)+g(i+1))/2, (g(j)+g(j+1))/2);
    end
end
out.Ewin = mo_blockintegral(2); mo_clearblock;
out.Ewin_signed_err = out.Ewin/out.exact.Ewin - 1;

% signed A at probes
Ap = zeros(1,3);
for q = 1:3
    gv = mo_geta(probes(q,1), probes(q,2)); Ap(q) = gv(1);
end
out.Aprobes = Ap;
out.Aprobe_signed_err = Ap./out.exact.Aprobes - 1;
mo_close; mi_close;
fprintf('[mms %s] Ng=%d nel=%d | src chk %+.2e | Ewin %+.3e | A errs %+.2e %+.2e %+.2e\n', ...
    tag, Ng, out.nelem, out.src_check_relerr, out.Ewin_signed_err, out.Aprobe_signed_err);
end
