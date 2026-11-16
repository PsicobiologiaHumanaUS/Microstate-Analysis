function hz = hazard_info(cnt, f_g, f_p, minRisk)
% CALLED FROM: fit_models. Hazard h(t) = P(ends at t | lasted until t).
% Empirical: cnt(t) / atrisk(t), with 95% Wilson intervals. Model-implied hazards:
% f(t) / P(T >= t). Also a likelihood-ratio test of "constant hazard" (geometric) against
% "logit hazard linear in t", on the range where at least minRisk durations are at risk.
L = numel(cnt);
atrisk = flipud(cumsum(flipud(cnt)));             % number of durations >= t
hz.atrisk = atrisk;
hz.h = cnt ./ max(atrisk, 1);                     % empirical hazard
m = max(atrisk, 1);  z = 1.96;
cen = (hz.h + z^2 ./ (2*m)) ./ (1 + z^2 ./ m);
hw  = z * sqrt(hz.h .* (1 - hz.h) ./ m + z^2 ./ (4*m.^2)) ./ (1 + z^2 ./ m);
hz.lo = max(cen - hw, 0);  hz.hi = min(cen + hw, 1);
hz.hg = f_g ./ max(1 - [0; cumsum(f_g(1:end-1))], 1e-12);   % geometric-implied hazard
hz.hp = f_p ./ max(1 - [0; cumsum(f_p(1:end-1))], 1e-12);   % power-law-implied hazard
ok = atrisk >= minRisk;  ok(end) = false;         % the last point always has hazard 1
hz.ok = ok;
k = cnt(ok);  mm = atrisk(ok);  x = ((0:L-1)' / 100);  x = x(ok);   % x in units of 100 samples
hz.hconst = sum(k) / sum(mm);                     % pooled hazard = ML geometric p
% --- model-implied hazards on the SAME range as the empirical one (n_t >= minRisk) ---------
hz.wmean_g = NaN;  hz.wmean_p = NaN;  hz.bg = NaN;  hz.bp = NaN;  hz.rmse_g = NaN;  hz.rmse_p = NaN;
if numel(k) >= 5
    he_ = hz.h(ok);  hg_ = hz.hg(ok);  hp_ = hz.hp(ok);
    hz.wmean_g = sum(mm .* hg_) / sum(mm);                 % mean hazard weighted by number at risk
    hz.wmean_p = sum(mm .* hp_) / sum(mm);                 %   (comparable with the pooled empirical hazard)
    hz.rmse_g  = sqrt(sum(mm .* (he_ - hg_).^2) / sum(mm));  % weighted RMSE to the empirical hazard
    hz.rmse_p  = sqrt(sum(mm .* (he_ - hp_).^2) / sum(mm));
    hz.bg = wls_slope(x, hg_, mm) / 100;                   % logit slope PER SAMPLE of the model hazard
    hz.bp = wls_slope(x, hp_, mm) / 100;
end
hz.b = NaN;  hz.pLR = NaN;  hz.hfit = nan(L,1);
if numel(k) >= 5 && hz.hconst > 0 && hz.hconst < 1
    h0 = hz.hconst;
    ll0 = sum(k .* log(h0) + (mm - k) .* log(1 - h0));
    X = [ones(numel(x),1), x];  beta = [log(h0/(1-h0)); 0];
    for it = 1:100                                % Newton-Raphson for the binomial logit model
        mu = 1 ./ (1 + exp(-X*beta));  mu = min(max(mu, 1e-10), 1 - 1e-10);
        g  = X' * (k - mm .* mu);
        H  = X' * (X .* repmat(mm .* mu .* (1 - mu), 1, 2));
        step = H \ g;  beta = beta + step;
        if max(abs(step)) < 1e-9, break, end
    end
    mu = 1 ./ (1 + exp(-X*beta));  mu = min(max(mu, 1e-10), 1 - 1e-10);
    ll1 = sum(k .* log(mu) + (mm - k) .* log(1 - mu));
    LR = max(2*(ll1 - ll0), 0);
    hz.b = beta(2) / 100;                         % slope of the logit hazard PER SAMPLE
    hz.pLR = erfc(sqrt(LR/2));                    % chi-square(1) upper tail
    hz.hfit(ok) = mu;                             % fitted hazard (for the plot)
end
end
