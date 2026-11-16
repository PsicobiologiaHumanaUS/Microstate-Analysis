function bin = pool_bins(f, n)
% CALLED FROM: fit_models, once per model. Groups consecutive durations so that every
% pooled bin has an expected count of at least 5 (needed for the chi-square statistic).
L = numel(f);  bin = zeros(L,1);  b = 1;  acc = 0;
for t = 1:L
    bin(t) = b;  acc = acc + n*f(t);
    if acc >= 5 && t < L, b = b + 1;  acc = 0; end
end
nb = max(bin);
if nb > 1 && sum(n*f(bin == nb)) < 5, bin(bin == nb) = nb - 1; end
end
