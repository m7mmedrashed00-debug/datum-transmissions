function o = rd03_solveropts(mode, reltol)
%RD03_SOLVEROPTS  Central solver options with STATE-SCALED vector AbsTol.
%   mode: 'fast' (transient, default) | 'slow' (thermal horizon)
%   AbsTol per state ~ 1e-6..1e-8 x typical magnitude:
%   [i(A); xp(m); v(m/s); P(Pa); Tw(C); Tf(C); ps1(Pa); ps2(Pa/s)]
if nargin < 1 || isempty(mode), mode = 'fast'; end
if nargin < 2, reltol = 1e-6; end
abstol = [1e-8; 1e-11; 1e-9; 1e-2; 1e-5; 1e-5; 1e-2; 1e1];
switch mode
    case 'fast', o = odeset('RelTol',reltol,'AbsTol',abstol,'MaxStep',0.005);
    case 'slow', o = odeset('RelTol',max(reltol,1e-5),'AbsTol',abstol*10,'MaxStep',1);
    otherwise, error('rd03_solveropts:mode','fast|slow');
end
end
