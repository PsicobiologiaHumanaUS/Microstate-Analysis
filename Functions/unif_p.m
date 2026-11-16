function p = unif_p(pv)
% CALLED FROM: count_rows and Table 7. Kolmogorov-Smirnov test of the p-values against a
% uniform(0,1) distribution (what a correct model would produce). NaN if fewer than 10 values.
pv = sort(pv(~isnan(pv)));  m = numel(pv);
if m < 10, p = NaN; return, end
D = max(max((1:m)'/m - pv(:)), max(pv(:) - (0:m-1)'/m));
lam = (sqrt(m) + 0.12 + 0.11/sqrt(m)) * D;
if lam < 0.2, p = 1; return, end
kk = (1:100)';
p = min(max(2 * sum((-1).^(kk-1) .* exp(-2 * kk.^2 * lam^2)), 0), 1);
end
