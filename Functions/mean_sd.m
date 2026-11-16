function s = mean_sd(v, spec)
% CALLED FROM: Table 2. Vector -> 'mean (SD)' text.
if isempty(v), s = 'NA'; else, s = [sprintf(spec, mean(v)) ' (' sprintf(spec, std(v)) ')']; end
end
