function out = c0v3_coax(h, msdeg, rundir, tag, dogrid)
%C0V3_COAX  Coax known-answer solve, audit-corrected family (C0v2 audit):
%   P0-02: STRICT co-refinement — outer-air mesh = 8h UNCAPPED (the v2 cap
%          min(8h,0.02) broke geometric similarity at coarse levels).
%   P1-01: SIGNED values stored for every observable.
%   P0-10: smoothing OFF and ON recorded at EVERY level for contour+points.
%   P0-04: adds the conductor INTERNAL energy target E_in = mu0 I^2/(16 pi)
%          — a solver-executed distributed-source observable.
%   P1-04/P1-05: 15 FIXED probes (coordinates recorded in out.probes); max
%          error kept as diagnostic only.
%   P0-06: depth recorded; block integrals are volume integrals (x depth 1 m).
if nargin < 5, dogrid = false; end
mu0 = 4e-7*pi; I = 100; a = 0.005; b1 = 0.020; b2 = 0.022; R = 0.080;
out = struct('h',h,'msdeg',msdeg,'tag',tag,'depth',1);
out.exact.E    = mu0*I^2/(4*pi)*log(b1/a);
out.exact.Ein  = mu0*I^2/(16*pi);
out.exact.Bx_upper = -(mu0*I/pi)*(b1-a);
out.exact.Iloop = I;

newdocument(0);
mi_probdef(0,'meters','planar',1e-8,1,30);
mi_smartmesh(0);
for r = [a b1 b2 R]
    mi_addnode(r,0); mi_addnode(-r,0);
    mi_addarc(r,0,-r,0,180,msdeg); mi_addarc(-r,0,r,0,180,msdeg);
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
lbl(0,(b2+R)/2,'air',8*h,'');                 % UNCAPPED co-refinement (P0-02)
for s = [1 -1]
    mi_selectarcsegment(0,s*R); mi_setarcsegmentprop(msdeg,'A0',0,0); mi_clearselected;
end
fem = fullfile(rundir, sprintf('coax_%s.fem',tag));
mi_saveas(fem); mi_analyze(1); mi_loadsolution;
out.nnodes = mo_numnodes; out.nelem = mo_numelements;

% ---- signed energy observables ----
mo_selectblock(0,(a+b1)/2); mo_selectblock(0,-(a+b1)/2);
out.E = mo_blockintegral(2); mo_clearblock;
mo_selectblock(0,0);
out.Ein = mo_blockintegral(2); mo_clearblock;
% ---- signed bi8/bi9 per half ----
mo_selectblock(0,(a+b1)/2);
out.bi8_upper = mo_blockintegral(8); out.bi9_upper = mo_blockintegral(9);
mo_clearblock;
mo_selectblock(0,-(a+b1)/2);
out.bi8_lower = mo_blockintegral(8); mo_clearblock;

% ---- FIXED probe set (recorded), both smoothing states ----
rs = linspace(a*1.25, b1*0.85, 5); ths = deg2rad([17 121 258]);
[RS,TH] = ndgrid(rs, ths);
out.probes = [RS(:).*cos(TH(:)), RS(:).*sin(TH(:))];   % 15 x 2, exact coords
rc = sqrt(a*b1); out.amp_contour = struct('rc',rc,'anglestep',1);
for smth = ["off","on"]
    mo_smooth(char(smth));
    li = amp(rc,1);
    e = zeros(15,1);
    for i = 1:15
        bv = mo_getb(out.probes(i,1), out.probes(i,2));
        rr = hypot(out.probes(i,1), out.probes(i,2));
        e(i) = hypot(bv(1),bv(2))/(mu0*I/(2*pi*rr)) - 1;     % SIGNED
    end
    out.(sprintf('Iloop_%s',smth))      = li;
    out.(sprintf('Bpt_signed_%s',smth)) = e';
end
mo_smooth('on');

if dogrid
    rg = linspace(a*1.06, b1*0.94, 36); tg = linspace(0, 2*pi, 73); tg(end) = [];
    [RG,TG] = ndgrid(rg,tg); BM = zeros(size(RG));
    for ii = 1:numel(RG)
        bv = mo_getb(RG(ii)*cos(TG(ii)), RG(ii)*sin(TG(ii)));
        BM(ii) = hypot(bv(1),bv(2));
    end
    out.grid = struct('r',rg,'th',tg,'Bmag',BM,'Bexact',mu0*I./(2*pi*RG));
    out.grid.relerr = BM./out.grid.Bexact - 1;
end
mo_close; mi_close;
fprintf('[coax3 %s] h=%.4g nel=%d | E %+.3e Ein %+.3e bi8 %+.3e | Amp(on) %+.3e | Bpt(on)max %.3e\n', ...
    tag, h, out.nelem, out.E/out.exact.E-1, out.Ein/out.exact.Ein-1, ...
    out.bi8_upper/out.exact.Bx_upper-1, out.Iloop_on/I-1, max(abs(out.Bpt_signed_on)));
end

function li = amp(rc, stepdeg)
mo_addcontour(rc,0); mo_addcontour(-rc,0); mo_bendcontour(180,stepdeg);
mo_addcontour(rc,0); mo_bendcontour(180,stepdeg);
v = mo_lineintegral(1); li = v(1); mo_clearcontour;
end
function lbl(x,y,mat,msh,circuit)
mi_addblocklabel(x,y); mi_selectlabel(x,y);
if isempty(circuit), mi_setblockprop(mat,0,msh,'<None>',0,0,0);
else,                mi_setblockprop(mat,0,msh,circuit,0,0,1); end
mi_clearselected;
end
