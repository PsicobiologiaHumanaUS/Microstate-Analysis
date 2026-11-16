function f = pmf_powerlaw(a, tmin, tmax)
% CALLED FROM: fit_models, boot_ks (via the refits) and simulate_labels.
% Bounded power-law pmf on tmin..tmax (a column that sums to 1).
s = (tmin:tmax)';
w = exp(-a*(log(s) - log(tmin)));
f = w / sum(w);
end
