function out = c0v3_loop_domain(rundir, ref, probes, src)
%C0V3_LOOP_DOMAIN  Closes C0v2 audit P0-05: outer-domain study AT THE FINEST
%   MESH (hair = 1 mm), three justified ABC radii, near-source resolution held
%   constant while the boundary moves. Signed per-probe values recorded; the
%   plateau criterion |delta(R2->R3)| gates per the approved matrix.
Rset = [0.10 0.14 0.20];
hair = 0.001;
out = struct('Rset',Rset,'hair',hair);
for k = 1:numel(Rset)
    R = Rset(k);
    newdocument(0);
    mi_probdef(0,'meters','axi',1e-8,0,30);
    mi_smartmesh(0);
    mi_addnode(src.r1,src.z1); mi_addnode(src.r2,src.z1);
    mi_addnode(src.r2,src.z2); mi_addnode(src.r1,src.z2);
    mi_addsegment(src.r1,src.z1,src.r2,src.z1);
    mi_addsegment(src.r2,src.z1,src.r2,src.z2);
    mi_addsegment(src.r2,src.z2,src.r1,src.z2);
    mi_addsegment(src.r1,src.z2,src.r1,src.z1);
    mi_addmaterial('air',1,1,0,0,0,0,0,1,0,0,0);
    mi_addmaterial('coil',1,1,0,0,0,0,0,1,0,0,0);
    mi_addcircprop('Isrc', src.I, 1);
    mi_addblocklabel((src.r1+src.r2)/2,(src.z1+src.z2)/2);
    mi_selectlabel((src.r1+src.r2)/2,(src.z1+src.z2)/2);
    mi_setblockprop('coil',0,hair/8,'Isrc',0,0,1); mi_clearselected;
    mi_addblocklabel(src.r2+0.01, src.z2+0.01);
    mi_selectlabel(src.r2+0.01, src.z2+0.01);
    mi_setblockprop('air',0,hair,'<None>',0,0,0); mi_clearselected;
    mi_makeABC(7, R, 0, 0, 0);
    fem = fullfile(rundir, sprintf('loopdom_R%03d.fem', round(R*100)));
    mi_saveas(fem); mi_analyze(1); mi_loadsolution;
    out.run(k).R = R; out.run(k).nelem = mo_numelements;
    n = size(probes,1); g = zeros(n,1); Bm = zeros(n,1);
    mo_smooth('on');
    for i = 1:n
        gv = mo_geta(probes(i,1), probes(i,2)); g(i) = gv(1);
        bv = mo_getb(probes(i,1), probes(i,2)); Bm(i) = hypot(bv(1),bv(2));
    end
    out.run(k).Phi = g';                       % geta = 2*pi*r*A (locked v2)
    out.run(k).Bmag = Bm';
    out.run(k).Phi_signed_err  = (g./ref.Phi  - 1)';
    out.run(k).Bmag_signed_err = (Bm./ref.Bmag - 1)';
    if k == 2   % grid sample at the middle radius for the 3-D figures
        rgv = linspace(0.004, 0.065, 30); zgv = linspace(-0.035, 0.035, 30);
        [RG,ZG] = ndgrid(rgv,zgv); GA = nan(size(RG)); BM = nan(size(RG));
        for ii = 1:numel(RG)
            if hypot(RG(ii)-(src.r1+src.r2)/2, ZG(ii)-(src.z1+src.z2)/2) < 0.004, continue, end
            gv = mo_geta(RG(ii), ZG(ii)); GA(ii) = gv(1);
            bv = mo_getb(RG(ii), ZG(ii)); BM(ii) = hypot(bv(1),bv(2));
        end
        out.grid = struct('r',rgv,'z',zgv,'geta',GA,'Bmag',BM);
    end
    mo_close; mi_close;
    fprintf('[loopdom R=%.2f] nel=%d | maxPhi err %+.3e | maxB err %+.3e\n', R, ...
        out.run(k).nelem, max(abs(out.run(k).Phi_signed_err)), max(abs(out.run(k).Bmag_signed_err)));
end
% plateau deltas (per-probe max abs change between successive radii)
d12P = max(abs(out.run(2).Phi  - out.run(1).Phi ) ./ abs(ref.Phi'));
d23P = max(abs(out.run(3).Phi  - out.run(2).Phi ) ./ abs(ref.Phi'));
d12B = max(abs(out.run(2).Bmag - out.run(1).Bmag) ./ ref.Bmag');
d23B = max(abs(out.run(3).Bmag - out.run(2).Bmag) ./ ref.Bmag');
out.plateau = struct('dPhi_12',d12P,'dPhi_23',d23P,'dB_12',d12B,'dB_23',d23B);
fprintf('[loopdom] plateau: dPhi 0.10->0.14 %.2e | 0.14->0.20 %.2e ; dB %.2e | %.2e\n', ...
    d12P, d23P, d12B, d23B);
end
