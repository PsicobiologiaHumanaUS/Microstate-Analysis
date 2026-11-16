function s = pstr(p, B)
% CALLED FROM: console printing, plot legends and Table 4. p-value -> text.
% A bootstrap p-value cannot be smaller than 1/(B+1), so small values print as '<'.
if isnan(p), s = 'NA';
elseif B > 0 && p <= 1/(B+1) + 1e-12, s = sprintf('<%.3f', 1/(B+1));
else, s = sprintf('%.3f', p); end
end
