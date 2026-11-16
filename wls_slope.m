function b = wls_slope(x, h, w)
% CALLED FROM: hazard_info, twice (geometric and power-law hazards). Weighted least-squares
% slope of logit(h) against x (x in units of 100 samples), weights w = number at risk.
h = min(max(h(:), 1e-12), 1 - 1e-12);
y = log(h ./ (1 - h));
X = [ones(numel(x),1), x(:)];
beta = (X' * (X .* [w(:) w(:)])) \ (X' * (y .* w(:)));
b = beta(2);
end
