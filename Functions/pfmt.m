function s = pfmt(p)
% CALLED FROM: Table 8 and the hazard plot titles. Asymptotic p-value -> text.
if isnan(p), s = 'NA'; elseif p < 0.001, s = '<0.001'; else, s = sprintf('%.3f', p); end
end
