function [a, ll] = fit_powerlaw(d, tmin, tmax)
% CALLED FROM: fit_models (data fit) and boot_ks (refit of every simulated sample).
% Maximum likelihood of the bounded power law; 1-D search over alpha.
n = numel(d);  s = (tmin:tmax)';  ls = log(s) - log(tmin);  sl = sum(log(d));
logZ = @(a) -a*log(tmin) + log(sum(exp(-a*ls)));  % log of the normalising sum (stable)
nll  = @(a) a*sl + n*logZ(a);
a  = fminbnd(nll, 0.01, 15, optimset('TolX',1e-10));
ll = -nll(a);
end
