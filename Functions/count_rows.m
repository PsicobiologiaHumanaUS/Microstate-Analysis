function c = count_rows(pv, a)
% CALLED FROM: Table 5, once per column (model x microstate). pv: bootstrap p-values of all
% subjects. Returns 5 text cells: non-significant n, significant n, % significant,
% binomial p (observed rejections vs the expected a), uniformity p of the p-values.
pv = pv(~isnan(pv));  m = numel(pv);
if m == 0, c = repmat({'NA'}, 5, 1); return, end
k = sum(pv < a);
c = {sprintf('%d', m-k); sprintf('%d', k); sprintf('%.1f', 100*k/m); fmt(binom_tail(k, m, a), '%.3f'); fmt(unif_p(pv), '%.3f')};
end
