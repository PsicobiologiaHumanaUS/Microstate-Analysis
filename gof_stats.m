function [AD, CH] = gof_stats(cnt, n, f, binIdx)
% CALLED FROM: fit_models (observed data) and boot_gof (every simulated sample).
% AD: Anderson-Darling statistic for a discrete distribution (tail-weighted KS-like).
% CH: Pearson chi-square after pooling bins (binIdx assigns each t to a pooled bin).
Fn = cumsum(cnt) / n;                             % empirical CDF
F  = min(cumsum(f), 1);                           % model CDF
j  = 1:numel(f)-1;                                % the last point has F = 1 (excluded)
AD = n * sum(((Fn(j) - F(j)).^2 .* f(j)) ./ max(F(j) .* (1 - F(j)), 1e-12));
O  = accumarray(binIdx, cnt);                     % observed counts per pooled bin
E  = n * accumarray(binIdx, f);                   % expected counts per pooled bin
if numel(O) < 2, CH = NaN; else, CH = sum((O - E).^2 ./ max(E, 1e-12)); end
end
