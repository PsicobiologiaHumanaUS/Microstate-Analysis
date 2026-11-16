function s = pct_sig(pv, a)
% CALLED FROM: Table 7. Percentage of subjects with p < a, as text.
pv = pv(~isnan(pv));
if isempty(pv), s = 'NA'; else, s = sprintf('%.1f', 100*sum(pv < a)/numel(pv)); end
end
