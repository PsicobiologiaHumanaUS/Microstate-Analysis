function cv = cv_loglik(d, tmin, tmax, model)
% CALLED FROM: fit_models, once per model. Two-fold cross-validation: fit on the odd-numbered
% durations and score the even-numbered ones, then swap. Returns the mean held-out
% log-likelihood per duration (higher = better prediction of unseen data).
i1 = 1:2:numel(d);  i2 = 2:2:numel(d);
ll = 0;
for k = 1:2
    if k == 1, tr = d(i1); te = d(i2); else, tr = d(i2); te = d(i1); end
    if strcmp(model, 'geometric')
        f = pmf_geometric(fit_geometric(tr, tmin, tmax), tmin, tmax);
    else
        f = pmf_powerlaw(fit_powerlaw(tr, tmin, tmax), tmin, tmax);
    end
    ll = ll + sum(log(max(f(te - tmin + 1), realmin)));
end
cv = ll / numel(d);
end
