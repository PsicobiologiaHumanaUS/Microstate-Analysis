function [p, ll] = fit_geometric(d, tmin, tmax)
% CALLED FROM: fit_models (data fit) and boot_ks (refit of every simulated sample).
% Maximum likelihood of the bounded geometric; no closed form, so a 1-D search over p.
n = numel(d);  L = tmax - tmin + 1;  S1 = sum(d - tmin);
nll = @(p) -( n*log(p) + S1*log1p(-p) - n*log(-expm1(L*log1p(-p))) );
p  = fminbnd(nll, 1e-6, 1-1e-6, optimset('TolX',1e-10));
ll = -nll(p);
end
