function ref = c0v2_loop_reference(probes, src)
%C0V2_LOOP_REFERENCE  Independent semi-analytic reference for the axisym
%   finite-cross-section loop benchmark (audit defect 10 fix: NO singular
%   filament energy; the reference matches the ACTUAL finite source by 2-D
%   quadrature of the exact filament kernels over the source cross-section).
%
%   Filament kernels (loop radius as, plane z=zs, unit current), with
%   k^2 = 4 as r / ((as+r)^2 + (z-zs)^2), m = k^2  [MATLAB ellipke takes m]:
%     Aphi = (mu0/(pi k)) sqrt(as/r) [ (1-k^2/2) K(m) - E(m) ]
%     Br   = (mu0 (z-zs) / (2 pi r S)) [ -K(m) + (as^2+r^2+(z-zs)^2)/D * E(m) ]
%     Bz   = (mu0 / (2 pi S)) [  K(m) - (as^2-r^2+... ) ... ]  (standard forms)
%   with S = sqrt((as+r)^2+(z-zs)^2), D = (as-r)^2+(z-zs)^2.
%   [NASA-Loop2013 form; ellipke m-convention validated in Stage A'.]
%   Flux target: Phi(r,z) = 2 pi r Aphi(r,z). Superposition over the source
%   rectangle with uniform J = I/S_area via integral2, AbsTol/RelTol 1e-12.
mu0 = 4e-7*pi;
Sarea = (src.r2-src.r1)*(src.z2-src.z1);
Jd = src.I/Sarea;                    % A/m^2, uniform
n = size(probes,1);
ref = struct('Aphi',zeros(n,1),'Br',zeros(n,1),'Bz',zeros(n,1),'Phi',zeros(n,1));
tol = {'AbsTol',1e-14,'RelTol',1e-11};
for i = 1:n
    r = probes(i,1); z = probes(i,2);
    ref.Aphi(i) = Jd*integral2(@(as,zs) kernA (as,zs,r,z), src.r1,src.r2,src.z1,src.z2, tol{:});
    ref.Br(i)   = Jd*integral2(@(as,zs) kernBr(as,zs,r,z), src.r1,src.r2,src.z1,src.z2, tol{:});
    ref.Bz(i)   = Jd*integral2(@(as,zs) kernBz(as,zs,r,z), src.r1,src.r2,src.z1,src.z2, tol{:});
    ref.Phi(i)  = 2*pi*r*ref.Aphi(i);
end
ref.Bmag = hypot(ref.Br, ref.Bz);

    function v = kernA(as,zs,r,z)
        m  = 4*as.*r ./ ((as+r).^2 + (z-zs).^2); k = sqrt(m);
        [K,E] = ellipke(m);
        v = (mu0./(pi*k)).*sqrt(as./r).*((1-m/2).*K - E);
    end
    function v = kernBr(as,zs,r,z)
        dz = z - zs;
        S2 = (as+r).^2 + dz.^2; S = sqrt(S2); D = (as-r).^2 + dz.^2;
        m  = 4*as.*r ./ S2; [K,E] = ellipke(m);
        v = (mu0.*dz)./(2*pi*r.*S) .* ( -K + (as.^2 + r.^2 + dz.^2)./D .* E );
    end
    function v = kernBz(as,zs,r,z)
        dz = z - zs;
        S2 = (as+r).^2 + dz.^2; S = sqrt(S2); D = (as-r).^2 + dz.^2;
        m  = 4*as.*r ./ S2; [K,E] = ellipke(m);
        v = (mu0)./(2*pi*S) .* ( K + (as.^2 - r.^2 - dz.^2)./D .* E );
    end
end
