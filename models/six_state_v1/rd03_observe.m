function [y, uy] = rd03_observe(x, p)
%RD03_OBSERVE  Observation layer y = h(x) + eps for the RD-03 spine v0.2.
%   y  = [ i_meas ; p_meas ; Tf_meas ]  - what the bench can actually see.
%   uy = per-channel standard uncertainty carried WITH the observation
%        (time-varying compensation uncertainty pending [Eichstadt2010]).
%   Note: pressure observation is the SENSOR state ps1, not the true P -
%   sensor dynamics are modeled so real pressure-channel lag is not
%   misdiagnosed as valve lag [NBS67].
y  = [ x(1) ; x(7) ; x(6) ];
uy = [ p.sd_i ; p.sd_p ; p.sd_T ];
end
