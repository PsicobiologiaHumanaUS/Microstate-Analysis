function fig = plot_session(resRow, subj, fs, stateNames)
% CALLED FROM: the loop, after the 4 microstates of a subject are fitted, for the
% subjects listed in PLOT_SESSIONS. resRow = 1x4 cell of result structs.
% Returns the figure handle; the loop saves it as a .fig file.
% Row 1: fitted histograms with R2 and KS p-value of each model.
% Row 2: log of the histogram and log of the models (+ shaded 95% bootstrap envelope).
% Row 3: empirical hazard (95% intervals), hazard implied by the geometric and the power-law model,
% and the logit-linear fit of the empirical hazard.
% Every panel has a legend of exactly two lines (two columns when there are 3 or 4 entries).
% The session appears once, as a heading above all panels; the titles of rows 2 and 3 have two lines.
% Only the range [tmin, tmax] is drawn.
nS = numel(resRow);
ms = @(t) 1000 * t / fs;
cG = [0.85 0.10 0.10];  cP = [0.10 0.35 0.85];                 % geometric red, power law blue
fig = figure('Color','w','Position',[40 40 1500 950], 'Name', ['Session ' subj]);
% Panel positions [left bottom width height] (normalised): a large vertical gap leaves room for the
% x label and the two-line titles; the top margin holds the subject heading.
mL = 0.055;  mR = 0.012;  mT = 0.085;  mB = 0.065;  gH = 0.06;  gV = 0.115;
wP = (1 - mL - mR - (nS-1)*gH) / nS;
hP = (1 - mT - mB - 2*gV) / 3;
posf = @(row, col) [mL + (col-1)*(wP+gH), 1 - mT - row*hP - (row-1)*gV, wP, hP];
annotation(fig, 'textbox', [0 0.925 1 0.065], 'String', ['Session ' subj], 'EdgeColor', 'none', ...
           'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
           'FontWeight', 'bold', 'FontSize', 15);                 % heading with the subject
for s = 1:nS
    r = resRow{s};
    if isempty(r)
        subplot('Position', posf(1,s)); axis off; title(sprintf('%s: not fitted', stateNames{s}));
        continue
    end
    X = ms(r.t);  half = 0.5 * 1000 / fs;
    xl = [ms(r.tmin) - half, ms(r.tmax) + half];

    % --- row 1: histogram + models --------------------------------------------
    subplot('Position', posf(1,s));
    bar(X, r.emp, 1, 'FaceColor', [.82 .82 .82], 'EdgeColor', 'none'); hold on;
    hg = plot(X, r.g.f,  '-', 'Color', cG, 'LineWidth', 1.8);
    hp = plot(X, r.pl.f, '-', 'Color', cP, 'LineWidth', 1.8);
    xlim(xl);
    xlabel('duration (ms)'); ylabel('probability');
    title(sprintf('Microstate %s (n=%d)', stateNames{s}, r.n));      % the subject is in the heading
    % two-line legend (one line per model), short text so it fits inside the panel
    legend([hg hp], {sprintf('Geom. R^2=%.3f, KS p=%s', r.g.R2,  pstr(r.g.KSp,  r.nboot)), ...
                     sprintf('Power R^2=%.3f, KS p=%s', r.pl.R2, pstr(r.pl.KSp, r.nboot))}, ...
           'Location', 'northeast', 'FontSize', 7, 'Box', 'off');
    box off;

    % --- row 2: log histogram + log models (+ shaded 95% envelopes) ---------------
    subplot('Position', posf(2,s));
    pos = r.emp > 0;
    ylo = min(r.emp(pos)) / 3;  yhi = 2 * max(r.emp);
    if ~isempty(r.g.env_lo)                     % envelopes first, so the lines stay on top
        bandG = patch([X(:); flipud(X(:))], [max(r.g.env_lo(:), ylo*1.001); flipud(max(r.g.env_hi(:), ylo*1.002))], ...
                      cG, 'FaceAlpha', 0.15, 'EdgeColor', 'none', 'HandleVisibility', 'off'); hold on;
        bandP = patch([X(:); flipud(X(:))], [max(r.pl.env_lo(:), ylo*1.001); flipud(max(r.pl.env_hi(:), ylo*1.002))], ...
                      cP, 'FaceAlpha', 0.15, 'EdgeColor', 'none', 'HandleVisibility', 'off');   %#ok<NASGU>
    end
    hd = semilogy(X(pos), r.emp(pos), 'k.', 'MarkerSize', 9); hold on;
    hg2 = semilogy(X, r.g.f,  '-', 'Color', cG, 'LineWidth', 1.8);
    hp2 = semilogy(X, r.pl.f, '-', 'Color', cP, 'LineWidth', 1.8);
    set(gca, 'YScale', 'log');
    xlim(xl);  ylim([ylo, yhi]);
    xlabel('duration (ms)'); ylabel('probability (log scale)');
    title({'log scale', '(shaded: 95% envelope)'});                   % two-line title
    try                                         % two-line legend: 2 columns x 2 rows
        legend([hd hg2 hp2], {'data', 'geometric', 'power law'}, 'Location', 'northeast', ...
               'FontSize', 7, 'Box', 'off', 'NumColumns', 2);
    catch                                       % MATLAB older than R2018a has no NumColumns
        legend([hd hg2 hp2], {'data', 'geometric', 'power law'}, 'Location', 'northeast', ...
               'FontSize', 7, 'Box', 'off');
    end
    box off;

    % --- row 3: hazard: empirical + geometric + power law (+ logit-linear fit) ----------
    subplot('Position', posf(3,s));
    hz = r.hz;  ok = hz.ok;
    he = errorbar(X(ok), hz.h(ok), hz.h(ok) - hz.lo(ok), hz.hi(ok) - hz.h(ok), 'k.', ...
             'MarkerSize', 9, 'Color', [.45 .45 .45]); hold on;
    hg3 = plot(X(ok), hz.hg(ok), '-', 'Color', cG, 'LineWidth', 1.8);      % hazard implied by the geometric
    hp3 = plot(X(ok), hz.hp(ok), '-', 'Color', cP, 'LineWidth', 1.8);      % hazard implied by the power law
    hh = [he hg3 hp3];  hl = {'empirical', 'geometric', 'power law'};
    if ~all(isnan(hz.hfit(ok)))
        hf = plot(X(ok), hz.hfit(ok), '--', 'Color', [.1 .1 .1], 'LineWidth', 1.4);
        hh(end+1) = hf;  hl{end+1} = 'logit fit';
    end
    xlim(xl);  ylim([0, min(1, max(4*hz.hconst, 0.05))]);
    xlabel('duration (ms)'); ylabel('hazard h(t)');
    title({sprintf('hazard: slope per 100 ms = %.2f', hz.b * fs / 10), ...
           sprintf('p = %s', pfmt(hz.pLR))});                         % two-line title
    try                                         % two-line legend: 2 columns x 2 rows
        legend(hh, hl, 'Location', 'northeast', 'FontSize', 7, 'Box', 'off', 'NumColumns', 2);
    catch
        legend(hh, hl, 'Location', 'northeast', 'FontSize', 7, 'Box', 'off');
    end
    box off;
end
end
