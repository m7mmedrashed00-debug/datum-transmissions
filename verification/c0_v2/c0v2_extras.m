function ex = c0v2_extras(rundir)
%C0V2_EXTRAS  Contour study (audit Q5 recipe), omega-sequence (audit #12),
%   harmonic bi8 convention probe, and complex-circuit marshaling probe (P4).
%   All archived evidence; nothing here is interpreted beyond its own numbers.
mu0 = 4e-7*pi; I = 100; a = 0.005; b1 = 0.020; b2 = 0.022; R = 0.080;
ex = struct();

% ---------- build one mid-mesh coax (shared by all probes) ----------
h = 0.001; ms = 1.25;
buildcoax(0, h, ms, I, a, b1, b2, R);
mi_saveas(fullfile(rundir,'extras_static.fem')); mi_analyze(1); mi_loadsolution;

% ---------- contour study: anglestep x radius x offset x smoothing ----------
steps = [4 2 1 0.5 0.25]; radii = [sqrt(a*b1) 0.5*(a+b1) 0.85*b1];
offs  = deg2rad([0 7 23]);
res = zeros(numel(steps), numel(radii), numel(offs), 2);
for si = 1:numel(steps)
  for ri = 1:numel(radii)
    for oi = 1:numel(offs)
      for smi = 1:2
        if smi==1, mo_smooth('off'); else, mo_smooth('on'); end
        rc = radii(ri); th = offs(oi);
        p1 = rc*[cos(th) sin(th)]; p2 = -p1;
        mo_addcontour(p1(1),p1(2)); mo_addcontour(p2(1),p2(2));
        mo_bendcontour(180, steps(si));
        mo_addcontour(p1(1),p1(2)); mo_bendcontour(180, steps(si));
        v = mo_lineintegral(1); mo_clearcontour;
        res(si,ri,oi,smi) = abs(v(1)/I - 1);
      end
    end
  end
end
mo_smooth('on');
ex.contour.steps = steps; ex.contour.radii = radii;
ex.contour.offsets_deg = rad2deg(offs); ex.contour.relerr = res;
E_static_sel = energyannulus(a,b1);
ex.E_static = E_static_sel;
mo_close; mi_close;

% ---------- omega sequence, sigma=0: expect ratio -> 0.5 at every f ----------
freqs = [0.01 0.1 1 10];
ex.omega.freqs = freqs; ex.omega.ratio = zeros(size(freqs));
ex.omega.bi8_ratio = zeros(size(freqs));
for i = 1:numel(freqs)
    buildcoax(freqs(i), h, ms, I, a, b1, b2, R);
    mi_saveas(fullfile(rundir,sprintf('extras_f%g.fem',freqs(i))));
    mi_analyze(1); mi_loadsolution;
    Eh = energyannulus(a,b1);
    mo_selectblock(0,(a+b1)/2); bi8h = mo_blockintegral(8); mo_clearblock;
    ex.omega.ratio(i) = Eh/E_static_sel;
    ex.omega.bi8_upper_h{i} = bi8h;   % may be complex-valued; archived raw
    ex.omega.bi8_ratio(i) = abs(bi8h(1)) / ((mu0*I/pi)*(b1-a));
    mo_close; mi_close;
end

% ---------- P4: complex circuit-current marshaling probe ----------
ex.P4.attempted_current = 100*exp(1i*pi/6);
try
    buildcoax(1, h, ms, ex.P4.attempted_current, a, b1, b2, R);
    mi_saveas(fullfile(rundir,'extras_cplx.fem')); mi_analyze(1); mi_loadsolution;
    cp = mo_getcircuitproperties('Iplus');
    ex.P4.roundtrip = cp; ex.P4.ok = true;
    mo_selectblock(0,(a+b1)/2); ex.P4.bi8 = mo_blockintegral(8); mo_clearblock;
    mo_close; mi_close;
catch ME
    ex.P4.ok = false; ex.P4.error = ME.message;
    try, mi_close; catch, end
end
fprintf('[extras] contour table %dx%dx%dx2 | omega ratios: %s | P4 ok=%d\n', ...
    numel(steps),numel(radii),numel(offs), mat2str(ex.omega.ratio,4), ex.P4.ok);
end

function buildcoax(freq, h, ms, I, a, b1, b2, R)
newdocument(0);
mi_probdef(freq,'meters','planar',1e-8,1,30);
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
lbl(0,(b2+R)/2,'air',min(8*h,0.02),'');
for s = [1 -1]
    mi_selectarcsegment(0,s*R); mi_setarcsegmentprop(ms,'A0',0,0); mi_clearselected;
end
end

function E = energyannulus(a,b1)
mo_selectblock(0,(a+b1)/2); mo_selectblock(0,-(a+b1)/2);
E = mo_blockintegral(2); mo_clearblock;
end

function lbl(x,y,mat,msh,circuit)
mi_addblocklabel(x,y); mi_selectlabel(x,y);
if isempty(circuit), mi_setblockprop(mat,0,msh,'<None>',0,0,0);
else,                mi_setblockprop(mat,0,msh,circuit,0,0,1); end
mi_clearselected;
end
