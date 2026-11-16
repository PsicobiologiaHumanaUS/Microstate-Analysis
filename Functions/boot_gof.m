function b = boot_gof(model, n, f, tmin, tmax, Dobs, ADobs, CHobs, binIdx, B)
% CALLED FROM: fit_models, once per model, when nboot > 0.
% Parametric bootstrap: simulate n durations from the FITTED model, REFIT the model, and
% recompute D (KS), AD and chi-square. p = share of simulated values >= the observed one.
% b.D95 = 95th percentile of the simulated D; b.lo/b.hi = 95% envelope of the simulated pmf.
L = numel(f);  Db = zeros(B,1);  ADb = zeros(B,1);  CHb = zeros(B,1);  Pb = zeros(B,L);
for k = 1:B
    [~, idx] = sample_pmf(n, f, tmin);            % simulated durations (position in support)
    db = tmin - 1 + idx;
    if strcmp(model, 'geometric')
        fb = pmf_geometric(fit_geometric(db, tmin, tmax), tmin, tmax);
    else
        fb = pmf_powerlaw(fit_powerlaw(db, tmin, tmax), tmin, tmax);
    end
    cb = accumarray(idx, 1, [L 1]);
    Pb(k,:) = (cb / n)';
    Db(k) = max(abs(cumsum(cb)/n - cumsum(fb)));
    [ADb(k), CHb(k)] = gof_stats(cb, n, fb, binIdx);
end
tol = @(v) 1e-9 * max(1, abs(v));
b.KSp = (1 + sum(Db  >= Dobs  - tol(Dobs)))  / (B + 1);
b.ADp = (1 + sum(ADb >= ADobs - tol(ADobs))) / (B + 1);
if isnan(CHobs), b.CHp = NaN; else, b.CHp = (1 + sum(CHb >= CHobs - tol(CHobs))) / (B + 1); end
sD = sort(Db);  b.D95 = sD(min(B, ceil(0.95*B)));
S = sort(Pb, 1);
b.lo = S(max(1, round(0.025*B)), :)';
b.hi = S(min(B, ceil(0.975*B)), :)';
end
