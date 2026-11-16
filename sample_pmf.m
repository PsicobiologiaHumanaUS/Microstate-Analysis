function [db, idx] = sample_pmf(n, f, tmin)
% CALLED FROM: boot_ks and simulate_labels. Draws n values from the pmf f on tmin..tmax
% by inverse CDF. db = durations (samples), idx = position inside the support.
cdf = cumsum(f(:));  cdf(end) = 1;
[~, idx] = histc(rand(n,1), [0; cdf]);
idx = min(max(idx, 1), numel(f));
db = tmin - 1 + idx;
end
