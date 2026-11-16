function x = simulate_labels(nMicro, truth, par, tmin, tmax)
% CALLED FROM: the simulated-data section, once per fake subject.
% Builds a fake label series (one label per sample, microstates 1..4, never repeating
% the previous label) whose durations follow the bounded model chosen in SIM_TRUTH.
nS = numel(par);  F = cell(nS,1);
for k = 1:nS
    if strcmp(truth, 'geometric'), F{k} = pmf_geometric(par(k), tmin, tmax);
    else,                          F{k} = pmf_powerlaw(par(k), tmin, tmax); end
end
lab = zeros(nMicro,1);  dur = zeros(nMicro,1);
lab(1) = randi(nS);
for k = 1:nMicro
    if k > 1
        others = setdiff(1:nS, lab(k-1));
        lab(k) = others(randi(numel(others)));
    end
    dur(k) = sample_pmf(1, F{lab(k)}, tmin);
end
x = repelem(lab, dur);
end
