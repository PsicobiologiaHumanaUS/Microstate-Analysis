function m = model_stats(ll, k, n, emp, f)
% CALLED FROM: fit_models, twice (one per model), so AIC, BIC, R2 and KS are computed identically.
% ll: log-likelihood, k: parameters, n: durations, emp: empirical pmf, f: model pmf.
m.ll  = ll;  m.k = k;
m.AIC = 2*k - 2*ll;                               % Akaike information criterion
m.BIC = k*log(n) - 2*ll;                          % Bayesian information criterion
m.R2  = 1 - sum((emp - f).^2) / sum((emp - mean(emp)).^2);   % R-squared between pmfs
m.KS  = max(abs(cumsum(emp) - cumsum(f)));        % KS distance between the two CDFs
m.f   = f;                                        % fitted pmf (kept for plotting)
end
