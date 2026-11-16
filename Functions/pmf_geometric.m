function f = pmf_geometric(p, tmin, tmax)
% CALLED FROM: fit_models, boot_ks (via the refits) and simulate_labels.
% Bounded geometric pmf on tmin..tmax (a column that sums to 1).
L = tmax - tmin + 1;  k = (0:L-1)';
f = p * exp(k*log1p(-p)) / (-expm1(L*log1p(-p)));
end
