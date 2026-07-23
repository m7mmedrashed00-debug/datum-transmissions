function out = c0v2_coax_bench(h, msdeg, rundir, tag, dogrid)
if nargin < 5, dogrid = false; end
%C0V2_COAX_BENCH  One coax solve at annulus mesh size h [m], arc maxseg msdeg
%   [deg] (P0/M2 fix: co-refined with h), with retained artifacts + realized
%   mesh metrics + smoothing-state-explicit extraction (audit defects 6,7,9).
%
%   Geometry (planar, depth 1 m): inner conductor r<=a (+I), return shell
%   b1..b2 (-I), sigma=0 both, A=0 at R. The air annulus is SPLIT into upper
%   and lower halves by the y=0 diameter so that the block integrals of Bx
%   and By over each half have NONZERO exact targets (audit defect 13 —
%   operator-level test for mo_blockintegral(8)/(9)):
%     upper half: int Bx dA = -(mu0 I/pi)(b1-a),  int By dA = 0
%     lower half: int Bx dA = +(mu0 I/pi)(b1-a),  int By dA = 0
%   Exact energy (annulus): E = mu0 I^2/(4 pi) ln(b1/a)  per meter.
%   Ampere loop at rc = sqrt(a b1): I. Pointwise B at 15 points (5 radii x
%   3 angles, angles chosen off the mesh symmetry axes).
mu0 = 4e-7*pi; I = 100; a = 0.005; b1 = 0.020; b2 = 0.022; R = 0.080;
out = struct('h',h,'msdeg',msdeg,'tag',tag);
out.exact.E    = mu0*I^2/(4*pi)*log(b1/a);
out.exact.Bx_upper = -(mu0*I/pi)*(b1-a);
out.exact.Iloop = I;

newdocument(0);
mi_probdef(0,'meters','planar',1e-8,1,30);
mi_smartmesh(0);
% circles with co-refined maxseg; diameter nodes exist on all circles
for r = [a b1 b2 R]
    mi_addnode(r,0); mi_addnode(-r,0);
    mi_addarc(r,0,-r,0,180,msdeg); mi_addarc(-r,0,r,0,180,msdeg);
end
% split ONLY the air annulus with radial diameter segments
mi_addsegment(a,0,b1,0); mi_addsegment(-b1,0,-a,0);
mi_addmaterial('air',1,1,0,0,0,0,0,1,0,0,0);
mi_addmaterial('cu0',1,1,0,0,0,0,0,1,0,0,0);
mi_addcircprop('Iplus', I,1); mi_addcircprop('Iminus',-I,1);
mi_addboundprop('A0',0,0,0,0,0,0,0,0,0,0,0);
setblk(0,0,'cu0',h/2,'Iplus');
setblk(0, (a+b1)/2,'air',h,'');      % upper half annulus
setblk(0,-(a+b1)/2,'air',h,'');      % lower half annulus
setblk(0,(b1+b2)/2,'cu0',h/2,'Iminus');
setblk(0,(b2+R)/2,'air',min(8*h,0.02),'');
for s = [1 -1]
    mi_selectarcsegment(0,s*R); mi_setarcsegmentprop(msdeg,'A0',0,0); mi_clearselected;
end
fem = fullfile(rundir, sprintf('coax_%s.fem',tag));
mi_saveas(fem); mi_analyze(1); mi_loadsolution;

out.nnodes = mo_numnodes; out.nelem = mo_numelements;

% --- energy over both half-annulus regions (element integral) ---
mo_selectblock(0, (a+b1)/2); mo_selectblock(0,-(a+b1)/2);
out.E = mo_blockintegral(2); mo_clearblock;
out.err.E = abs(out.E/out.exact.E - 1);

% --- operator-level bi8/bi9 with nonzero targets, per half ---
mo_selectblock(0,(a+b1)/2);
out.bi8_upper = mo_blockintegral(8); out.bi9_upper = mo_blockintegral(9);
mo_clearblock;
mo_selectblock(0,-(a+b1)/2);
out.bi8_lower = mo_blockintegral(8); out.bi9_lower = mo_blockintegral(9);
mo_clearblock;
out.err.bi8 = abs(out.bi8_upper/out.exact.Bx_upper - 1);
out.err.bi8_asym = abs((out.bi8_upper + out.bi8_lower)/out.exact.Bx_upper); % should ~0
out.err.bi9 = abs(out.bi9_upper/out.exact.Bx_upper);                        % 0-target, normalized to bi8 scale

% --- Ampere + pointwise, BOTH smoothing states (audit defect 9) ---
rc = sqrt(a*b1);
rs = linspace(a*1.25, b1*0.85, 5); ths = deg2rad([17 121 258]);
for smth = ["off","on"]
    mo_smooth(char(smth));
    li = ampereloop(rc, 1);                       % anglestep 1 deg default here
    e_pt = 0;
    for rr = rs
        for tt = ths
            bv = mo_getb(rr*cos(tt), rr*sin(tt));
            e_pt = max(e_pt, abs(hypot(bv(1),bv(2))/(mu0*I/(2*pi*rr)) - 1));
        end
    end
    out.(sprintf('Iloop_%s',smth)) = li;
    out.(sprintf('err_Iloop_%s',smth)) = abs(li/I - 1);
    out.(sprintf('err_Bpt_%s',smth))   = e_pt;
end
mo_smooth('on');   % restore default state explicitly (recorded)

if dogrid
    % polar sampling grid for the 3-D error-surface figure (smoothing ON,
    % recorded): 36 radii x 72 angles across the annulus interior
    rg = linspace(a*1.06, b1*0.94, 36); tg = linspace(0, 2*pi, 73); tg(end) = [];
    [RG,TG] = ndgrid(rg,tg);
    BM = zeros(size(RG));
    for ii = 1:numel(RG)
        bv = mo_getb(RG(ii)*cos(TG(ii)), RG(ii)*sin(TG(ii)));
        BM(ii) = hypot(bv(1),bv(2));
    end
    out.grid.r = rg; out.grid.th = tg; out.grid.Bmag = BM;
    out.grid.Bexact = mu0*I./(2*pi*RG);
    out.grid.relerr = BM./out.grid.Bexact - 1;
end

mo_close; mi_close;
fprintf('[coax %s] h=%.4g ms=%.3g nel=%d | E %.3e | bi8 %.3e | Amp(off) %.3e | Bpt(off) %.3e\n', ...
    tag, h, msdeg, out.nelem, out.err.E, out.err.bi8, out.err_Iloop_off, out.err_Bpt_off);
end

function li = ampereloop(rc, stepdeg)
mo_addcontour(rc,0); mo_addcontour(-rc,0); mo_bendcontour(180,stepdeg);
mo_addcontour(rc,0); mo_bendcontour(180,stepdeg);
v = mo_lineintegral(1); li = v(1); mo_clearcontour;
end

function setblk(x,y,mat,msh,circuit)
mi_addblocklabel(x,y); mi_selectlabel(x,y);
if isempty(circuit), mi_setblockprop(mat,0,msh,'<None>',0,0,0);
else,                mi_setblockprop(mat,0,msh,circuit,0,0,1); end
mi_clearselected;
end
