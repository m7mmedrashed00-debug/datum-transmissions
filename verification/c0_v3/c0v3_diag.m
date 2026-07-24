function out = c0v3_diag(rundir)
%C0V3_DIAG  Three audit-mandated diagnostics (C0v2 audit P0-03/P0-06/P1-07):
%   D1 bi8 floor: fixed h = 0.5 mm, arc maxseg halved {1.25, 0.625, 0.3125} —
%      tests the polygonization-sagitta floor hypothesis (own-logic, response
%      to C0v2 audit): if geometry-driven, |err| should shrink ~ms^2.
%   D2 two-depth unit test: identical mid mesh at depth 1 m and 2 m — FEMM
%      planar block integrals are volume integrals, so bi8 must scale by
%      exactly 2. Locks the Wb vs Wb*m bookkeeping (P0-06).
%   D3 solver-tolerance sweep: mid mesh at precision {1e-8, 1e-10, 1e-12} —
%      algebraic-error contribution must be small vs mesh error (P1-07).
mu0 = 4e-7*pi; I = 100; a = 0.005; b1 = 0.020; b2 = 0.022; R = 0.080;
bi8x = -(mu0*I/pi)*(b1-a); Eex = mu0*I^2/(4*pi)*log(b1/a);
out = struct();

% ---------- D1: maxseg halving at fixed h ----------
mss = [1.25 0.625 0.3125]; h = 0.0005;
for k = 1:numel(mss)
    build(0, h, mss(k), I, a, b1, b2, R, 1);
    mi_saveas(fullfile(rundir,sprintf('diag_ms%d.fem',k))); mi_analyze(1); mi_loadsolution;
    mo_selectblock(0,(a+b1)/2); v = mo_blockintegral(8); mo_clearblock;
    out.msdiag.ms(k) = mss(k); out.msdiag.bi8_signed_err(k) = v/bi8x - 1;
    out.msdiag.nelem(k) = mo_numelements;
    mo_close; mi_close;
end
fprintf('[diag D1] bi8 err vs maxseg: %s\n', mat2str(out.msdiag.bi8_signed_err,3));

% ---------- D2: two-depth unit test ----------
vals = zeros(1,2); depths = [1 2];
for k = 1:2
    build(0, 0.001, 1.25, I, a, b1, b2, R, depths(k));
    mi_saveas(fullfile(rundir,sprintf('diag_depth%d.fem',depths(k)))); mi_analyze(1); mi_loadsolution;
    mo_selectblock(0,(a+b1)/2); vals(k) = mo_blockintegral(8); mo_clearblock;
    mo_close; mi_close;
end
out.depth.bi8 = vals; out.depth.ratio = vals(2)/vals(1);
fprintf('[diag D2] bi8 depth ratio = %.9f (exact 2)\n', out.depth.ratio);

% ---------- D3: solver tolerance sweep ----------
precs = [1e-8 1e-10 1e-12];
for k = 1:numel(precs)
    build(0, 0.001, 1.25, I, a, b1, b2, R, 1, precs(k));
    mi_saveas(fullfile(rundir,sprintf('diag_tol%d.fem',k))); mi_analyze(1); mi_loadsolution;
    mo_selectblock(0,(a+b1)/2); mo_selectblock(0,-(a+b1)/2);
    out.tol.E(k) = mo_blockintegral(2); mo_clearblock;
    mo_selectblock(0,(a+b1)/2); out.tol.bi8(k) = mo_blockintegral(8); mo_clearblock;
    mo_smooth('on');
    mo_addcontour(sqrt(a*b1),0); mo_addcontour(-sqrt(a*b1),0); mo_bendcontour(180,1);
    mo_addcontour(sqrt(a*b1),0); mo_bendcontour(180,1);
    v = mo_lineintegral(1); out.tol.Iloop(k) = v(1); mo_clearcontour;
    mo_close; mi_close;
end
out.tol.prec = precs;
out.tol.dE_rel    = max(abs(diff(out.tol.E)))/Eex;
out.tol.dbi8_rel  = max(abs(diff(out.tol.bi8)))/abs(bi8x);
out.tol.dIl_rel   = max(abs(diff(out.tol.Iloop)))/I;
fprintf('[diag D3] tol deltas: E %.2e bi8 %.2e Iloop %.2e\n', ...
    out.tol.dE_rel, out.tol.dbi8_rel, out.tol.dIl_rel);
end

function build(freq, h, ms, I, a, b1, b2, R, depth, prec)
if nargin < 10, prec = 1e-8; end
newdocument(0);
mi_probdef(freq,'meters','planar',prec,depth,30);
mi_smartmesh(0);
for r = [a b1 b2 R]
    mi_addnode(r,0); mi_addnode(-r,0);
    mi_addarc(r,0,-r,0,180,ms); mi_addarc(-r,0,r,0,180,ms);
end
mi_addsegment(a,0,b1,0); mi_addsegment(-b1,0,-a,0);
mi_addmaterial('air',1,1,0,0,0,0,0,1,0,0,0);
mi_addmaterial('cu0',1,1,0,0,0,0,0,1,0,0,0);
mi_addcircprop('Iplus', I,1); mi_addcircprop('Iminus',-I,1);
mi_addboundprop('A0',0,0,0,0,0,0,0,0,0,0,0);
lbl(0,0,'cu0',h/2,'Iplus');
lbl(0, (a+b1)/2,'air',h,'');
lbl(0,-(a+b1)/2,'air',h,'');
lbl(0,(b1+b2)/2,'cu0',h/2,'Iminus');
lbl(0,(b2+R)/2,'air',8*h,'');
for s = [1 -1]
    mi_selectarcsegment(0,s*R); mi_setarcsegmentprop(ms,'A0',0,0); mi_clearselected;
end
end
function lbl(x,y,mat,msh,circuit)
mi_addblocklabel(x,y); mi_selectlabel(x,y);
if isempty(circuit), mi_setblockprop(mat,0,msh,'<None>',0,0,0);
else,                mi_setblockprop(mat,0,msh,circuit,0,0,1); end
mi_clearselected;
end
