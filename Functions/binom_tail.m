function p = binom_tail(k, m, a)
% CALLED FROM: Table 4. P(X >= k) for X ~ Binomial(m, a): probability of at least k
% significant tests out of m if the model were correct (each test rejects with prob a).
if k <= 0, p = 1; else, p = betainc(a, k, m - k + 1); end
end
