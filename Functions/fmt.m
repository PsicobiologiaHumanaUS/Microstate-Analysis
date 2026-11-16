function s = fmt(x, spec)
% CALLED FROM: the table-building section. Number -> text; NaN -> 'NA'.
if isnan(x), s = 'NA'; else, s = sprintf(spec, x); end
end
