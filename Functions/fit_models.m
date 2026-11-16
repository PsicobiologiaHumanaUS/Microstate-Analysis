function r = fit_models(d, tmin, tmax, nboot, minRisk)
% CALLED FROM: the subject/microstate loop, once per fit. WHY: it is the first point
% where the durations of ONE microstate in ONE subject (already inside the bounds) exist.
% d: durations (samples), all within [tmin,tmax]. nboot: bootstrap replicates.
% minRisk: minimum number of durations still "alive" for a hazard point to be used.
n = numel(d);  L = tmax - tmin + 1;
cnt = accumarray(d - tmin + 1, 1, [L 1]);         % cnt(i): how many durations equal tmin+i-1
emp = cnt / n;                                    % empirical probability of each t in [tmin,tmax]
[pg, ll_g] = fit_geometric(d, tmin, tmax);        % ML estimate of p and log-likelihood
[al, ll_p] = fit_powerlaw(d, tmin, tmax);         % ML estimate of alpha and log-likelihood
f_g = pmf_geometric(pg, tmin, tmax);              % fitted geometric pmf on the support
f_p = pmf_powerlaw(al, tmin, tmax);               % fitted power-law pmf on the support
r.n = n;  r.tmin = tmin;  r.tmax = tmax;  r.L = L;  r.nboot = nboot;
r.t = (tmin:tmax)';  r.emp = emp;
r.g  = model_stats(ll_g, 1, n, emp, f_g);   r.g.p = pg;
r.pl = model_stats(ll_p, 1, n, emp, f_p);   r.pl.alpha = al;

% --- Anderson-Darling and chi-square (observed values) --------------------------
r.g.bin  = pool_bins(f_g, n);   [r.g.AD,  r.g.CH ] = gof_stats(cnt, n, f_g, r.g.bin);
r.pl.bin = pool_bins(f_p, n);   [r.pl.AD, r.pl.CH] = gof_stats(cnt, n, f_p, r.pl.bin);

% --- bootstrap p-values (KS, AD, chi-square), critical D and envelope ------------
mods = {'g','pl'};  names = {'geometric','power_law'};  fs_ = {f_g, f_p};
for k = 1:2
    m = mods{k};
    r.(m).KSp = NaN;  r.(m).ADp = NaN;  r.(m).CHp = NaN;  r.(m).D95 = NaN;
    r.(m).env_lo = [];  r.(m).env_hi = [];
    if nboot > 0
        b = boot_gof(names{k}, n, fs_{k}, tmin, tmax, r.(m).KS, r.(m).AD, r.(m).CH, r.(m).bin, nboot);
        r.(m).KSp = b.KSp;  r.(m).ADp = b.ADp;  r.(m).CHp = b.CHp;  r.(m).D95 = b.D95;
        r.(m).env_lo = b.lo;  r.(m).env_hi = b.hi;
    end
end

% --- cross-validated log-likelihood per duration ---------------------------------
r.g.CV  = cv_loglik(d, tmin, tmax, 'geometric');
r.pl.CV = cv_loglik(d, tmin, tmax, 'power_law');

% --- hazard: empirical, model-implied, and constant-hazard test ----------------------
r.hz = hazard_info(cnt, f_g, f_p, minRisk);
end
