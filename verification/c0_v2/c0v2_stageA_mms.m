function rpt = c0v2_stageA_mms()
%C0V2_STAGEA_MMS  Stage A' — manufactured-solution functional self-test.
%   Response to SOL-RD03-C0e-R defect 5 / P0-4: the v1 coax field made T1 and
%   T3 trivially exact. Here the field comes from a manufactured vector
%   potential  A_z(x,y) = A0 sin(kx x) sin(ky y)  [Salari&Knupp2000 posture],
%   so EVERY functional is nontrivial and every operator must earn its order:
%     Bx =  dA/dy =  A0 ky sin(kx x) cos(ky y)
%     By = -dA/dx = -A0 kx cos(kx x) sin(ky y)
%     J  = (kx^2+ky^2)/mu0 * A            (from -lap(A)/mu0, planar linear)
%   Exact targets over the test window W = [x1,x2]x[y1,y2]:
%     T1 = int_W Bx dA
%     T2 = int_W (Bx^2+By^2)/(2 mu0) dA   (energy)
%     T3 = oint_dW H.t dl = I_enc = (kx^2+ky^2)/mu0 * int_W A dA  (Ampere/MMS)
%   Operators under test (the kinds actually applied to exported FEMM fields):
%     OP1/OP2: 2-D midpoint product-grid quadrature  (expected order 2)
%     OP3:     polygonal-path trapezoid circulation  (expected order 2)
%   PASS RULE (enforced, per audit): production grid N=200 rel.err < 1e-3 on
%   ALL THREE, AND fitted observed order within [1.7, 2.3] on ALL THREE.
%   Also: ellipke convention validation (m = k^2) against independent
%   30-digit values (mpmath, cross-checked vs DLMF Gamma identity) — gate for
%   the Stage B' loop reference. [NIST-DLMF19]
rpt = struct('name','c0v2_stageA_mms');
mu0 = 4e-7*pi;
A0 = 1e-3; kx = 37; ky = 59;
x1 = 0.025; x2 = 0.085; y1 = 0.015; y2 = 0.065;

% ---- exact targets (closed form) ----
Isin = @(k,u1,u2) (cos(k*u1)-cos(k*u2))/k;          % int sin(ku) du
Icos = @(k,u1,u2) (sin(k*u2)-sin(k*u1))/k;          % int cos(ku) du
Isin2= @(k,u1,u2) (u2-u1)/2 - (sin(2*k*u2)-sin(2*k*u1))/(4*k);
Icos2= @(k,u1,u2) (u2-u1)/2 + (sin(2*k*u2)-sin(2*k*u1))/(4*k);
T1ex = A0*ky * Isin(kx,x1,x2) * Icos(ky,y1,y2);
T2ex = ( (A0*ky)^2 * Isin2(kx,x1,x2)*Icos2(ky,y1,y2) ...
       + (A0*kx)^2 * Icos2(kx,x1,x2)*Isin2(ky,y1,y2) ) / (2*mu0);
T3ex = (kx^2+ky^2)/mu0 * A0 * Isin(kx,x1,x2) * Isin(ky,y1,y2);
rpt.exact = [T1ex T2ex T3ex];

Bx = @(x,y)  A0*ky*sin(kx*x).*cos(ky*y);
By = @(x,y) -A0*kx*cos(kx*x).*sin(ky*y);

Ns = [12 25 50 100 200 400];
res = zeros(numel(Ns),3);
for k = 1:numel(Ns)
    N = Ns(k);
    % OP1/OP2 — midpoint product grid
    xe = linspace(x1,x2,N+1); ye = linspace(y1,y2,N+1);
    xc = (xe(1:end-1)+xe(2:end))/2; yc = (ye(1:end-1)+ye(2:end))/2;
    [X,Y] = ndgrid(xc,yc); dA = (xe(2)-xe(1))*(ye(2)-ye(1));
    T1 = sum(Bx(X,Y),'all')*dA;
    T2 = sum((Bx(X,Y).^2+By(X,Y).^2)/(2*mu0),'all')*dA;
    % OP3 — polygonal circulation, N samples per edge, trapezoid, CCW
    T3 = edgeint(@(x,y) Bx(x,y)/mu0, @(x,y) By(x,y)/mu0, x1,x2,y1,y2, N);
    res(k,:) = abs([T1/T1ex-1, T2/T2ex-1, T3/T3ex-1]);
end
rpt.Ns = Ns; rpt.relerr = res;

% fitted observed order per functional (log-log LSQ over all levels)
p = zeros(1,3);
for j = 1:3
    c = polyfit(log(1./Ns), log(res(:,j)'), 1); p(j) = c(1);
end
rpt.observed_order = p;
iprod = find(Ns==200,1);
rpt.production_relerr = res(iprod,:);
rpt.pass_accuracy = all(res(iprod,:) < 1e-3);
rpt.pass_order    = all(p > 1.7 & p < 2.3);

% ---- ellipke convention validation [NIST-DLMF19] ----
% Independent 30-digit values (mpmath, 2026-07-23; K(m=1/2) cross-checked
% against Gamma(1/4)^2/(4 sqrt(pi)) identity, agreement to 28 digits):
ref = [ 0.5   1.85407467730137191843385034720 1.35064388104767550252017473534
        0.25  1.68575035481259604287120365780 1.46746220933942715545979526699
        0.75  2.15651564749964323543867499880 1.21105602756845952480356289955 ];
ee = zeros(size(ref,1),2);
for i = 1:size(ref,1)
    [K,E] = ellipke(ref(i,1));
    ee(i,:) = abs([K-ref(i,2), E-ref(i,3)]);
end
rpt.ellipke_abserr = ee;
rpt.pass_ellipke = all(ee(:) < 1e-12);

rpt.pass = rpt.pass_accuracy && rpt.pass_order && rpt.pass_ellipke;
fprintf('\n=== STAGE A'' (manufactured solution) ===\n');
fprintf('N        T1 int(Bx)    T2 energy     T3 circulation\n');
for k=1:numel(Ns), fprintf('%-6d   %-11.3e   %-11.3e   %-11.3e\n', Ns(k), res(k,:)); end
fprintf('fitted orders: %.3f  %.3f  %.3f (require 1.7..2.3 each)\n', p);
fprintf('production N=200 max relerr: %.3e (require <1e-3)\n', max(rpt.production_relerr));
fprintf('ellipke max |err| vs 30-digit refs: %.2e (require <1e-12)\n', max(ee(:)));
fprintf('STAGE A'' %s\n', tern(rpt.pass,'PASS','FAIL'));
end

function v = edgeint(Hx, Hy, x1,x2,y1,y2, N)
% CCW rectangle circulation with per-edge trapezoid rule
xs = linspace(x1,x2,N+1); ys = linspace(y1,y2,N+1);
v =     trapz(xs,  Hx(xs, y1*ones(size(xs))));          % bottom, +x
v = v + trapz(ys,  Hy(x2*ones(size(ys)), ys));          % right,  +y
v = v + trapz(xs, -Hx(xs, y2*ones(size(xs))));          % top,    -x (sign via dl)
v = v + trapz(ys, -Hy(x1*ones(size(ys)), ys));          % left,   -y
end

function s = tern(c,a,b), if c, s=a; else, s=b; end, end
