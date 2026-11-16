%% MICROSTATE DURATIONS: BOUNDED GEOMETRIC vs BOUNDED POWER count_rowsLAW 
% For microstates A, B, C, D in every subject (session) this script
%   1. cuts the label series into microstate durations (samples),
%   2. keeps only durations inside the bounds [tmin, tmax] (lower and upper bound),
%   3. fits two models by maximum likelihood on that bounded support,
%   4. tests each fit with a parametric-bootstrap Kolmogorov-Smirnov test,
%   5. compares the models with AIC and BIC,
%   6. computes further adequacy statistics (Anderson-Darling, chi-square, cross-validation,
%      uniformity of the p-values across subjects, constant-hazard test),
%   7. draws the figures (3 rows: histogram, log histogram, hazard with both models) for the first 10 subjects
%      and saves each one as a MATLAB .fig file (folder FIG_DIR, by default the current folder), and
%   8. writes all tables to tab-separated text files (always) and to a Word file (optional)
%      in the current folder.
%
% t = number of samples since the previous transition. Duration in ms = 1000*t/fs.
% Support of both models: t = tmin, tmin+1, ..., tmax   (L = tmax - tmin + 1 values)
%
%   GEOMETRIC   P(t) = p (1-p)^(t-tmin) / [1 - (1-p)^L]
%   POWER LAW   P(t) = t^(-alpha) / sum_{s=tmin}^{tmax} s^(-alpha)
%
% Both are proper probability distributions on the SAME bounded support, so they
% have no mass below tmin or above tmax, and their likelihoods are comparable.
% tmin and tmax are treated as fixed bounds, so each model has k = 1 parameter
% (p, or alpha). With equal k, AIC and BIC differences between the models coincide.
%
% DATA: ALLEEG(session).microstate.fit.labels  (one label per sample, 1..4)
%       ALLEEG(session).srate                   (sampling frequency, Hz)
%
% First run with USE_SIMULATED_TEST = true (fake data with known truth).
% Then set it to false to use your ALLEEG.
% Needs MATLAB R2016b or later (local functions in scripts). No toolboxes.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all
clearvars -except ALLEEG
clc
rng(12345);                % fixed seed: the bootstrap p-values are reproducible (report it in the Methods)

%% ============================== PROJECT SETUP ==============================

% Locate the main project directory automatically
SCRIPT_PATH = mfilename('fullpath');

if isempty(SCRIPT_PATH)
    SEARCH_DIR = pwd;
else
    SEARCH_DIR = fileparts(SCRIPT_PATH);
end

PROJECT_DIR = SEARCH_DIR;

% Search upwards until the project folders are found
while true

    if isfolder(fullfile(PROJECT_DIR, 'Functions')) && ...
       isfolder(fullfile(PROJECT_DIR, 'Dataset_V2'))
        break;
    end

    PARENT_DIR = fileparts(PROJECT_DIR);

    if strcmp(PARENT_DIR, PROJECT_DIR)
        error(['Project folders not found. Please check that ', ...
               'Functions and Dataset_V2 exist in the project.']);
    end

    PROJECT_DIR = PARENT_DIR;
end

% Add auxiliary functions to the MATLAB search path
FUNCTIONS_DIR = fullfile(PROJECT_DIR, 'Functions');
addpath(genpath(FUNCTIONS_DIR));

% Define dataset location
DATASET_DIR = fullfile(PROJECT_DIR, 'Dataset_V2');

% Locate and load dataset
DATA_FILE = fullfile(DATASET_DIR, 'EEG', 'modkmeans_result.mat');

if ~isfile(DATA_FILE)
    error('Dataset file not found: %s', DATA_FILE);
end

loadedData = load(DATA_FILE);

if ~isfield(loadedData, 'ALLEEG')
    error('ALLEEG variable not found in the dataset.');
end

ALLEEG = loadedData.ALLEEG;

fprintf('Project directory: %s\n', PROJECT_DIR);
fprintf('Dataset loaded: %d sessions\n', numel(ALLEEG));
fprintf('Functions added to MATLAB path.\n');

%% ============================== SETTINGS ==================================
USE_SIMULATED_TEST = false;  % false: your ALLEEG (default); true: 3 fake sessions, only to test the script
SIM_TRUTH      = 'geometric';% truth of the fake data: 'geometric' or 'power_law'
nSessions      = 60;         % number of subjects (sessions) in ALLEEG
nStates        = 4;          % microstates A..D
stateNames     = {'A','B','C','D'};
MIN_N          = 50;         % minimum number of durations needed to fit a state
LOWER_BOUND_MS = [];         % [] = shortest observed duration of each fit; or a value in ms
UPPER_BOUND_MS = [];         % [] = longest observed duration of each fit;  or a value in ms
                             % (for publication a COMMON bound, e.g. 400, is easier to defend)
NBOOT          = 1000;       % bootstrap replicates for the KS/AD/chi-square p-values (0 = skip; use 20 for a quick test)
ALPHA          = 0.05;       % significance level of all the tests
MIN_RISK_HAZ   = 20;         % hazard is evaluated only where at least this many durations are still 'alive'
N_FIGS         = 10;         % number of FIGURES (drawn and saved). The analysis and the tables ALWAYS use all nSessions
PLOT_SESSIONS  = 1:min(N_FIGS, nSessions);   % sessions that get a figure: the first N_FIGS; or e.g. [3 7 12], []
SAVE_FIGS      = true;       % true: save each plotted figure as a MATLAB .fig file
RESULTS_DIR = fullfile(PROJECT_DIR, 'Results');
        if ~exist(RESULTS_DIR, 'dir')
            mkdir(RESULTS_DIR);
        end
FIG_DIR  = RESULTS_DIR;
OUT_BASE = fullfile(RESULTS_DIR, 'Microstate_tables');
WRITE_DOCX     = true;       % true: also try to write a Word file (the .txt files are always written)

%% ======================== DATA SOURCE (simulated test) =====================
if USE_SIMULATED_TEST
    nSessions = 3;  PLOT_SESSIONS = 1:nSessions;
    simFs = 500;  simTmin = 16;  simTmax = 250;       % fake fs, bounds in samples
    rng(1);
    if strcmp(SIM_TRUTH, 'geometric')
        truePar = [0.048 0.047 0.050 0.040];          % p of A..D
    else
        truePar = [2.3 2.2 2.4 2.1];                  % alpha of A..D
    end
    simLabels = cell(nSessions,1);
    for ss = 1:nSessions                              % one fake label series per subject
        simLabels{ss} = simulate_labels(1000, SIM_TRUTH, truePar, simTmin, simTmax);
    end
    fprintf('SIMULATED TEST (%s): %d subjects, fs = %d Hz\n\n', SIM_TRUTH, nSessions, simFs);
end

%% ====================== FIGURE FOLDER: CHECK BEFORE STARTING ==================
SCRIPT_VERSION = 'v8: analysis on ALL sessions, N_FIGS=10 figures saved as .fig';
fprintf('Running microstates_publication_full.m  (%s)\n', SCRIPT_VERSION);
fprintf('Current folder      : %s\n', pwd);
if ~USE_SIMULATED_TEST                        % real data: ALLEEG must hold at least nSessions sessions
    if ~exist('ALLEEG', 'var') || isempty(ALLEEG)
        error('ALLEEG is not in the workspace. Load your EEG sets first (or set USE_SIMULATED_TEST = true only to test the script).');
    end
    if numel(ALLEEG) < nSessions
        error('nSessions = %d but ALLEEG has only %d sessions. Change nSessions.', nSessions, numel(ALLEEG));
    end
end
fprintf('Analysis            : ALL %d sessions x %d microstates (all tables use all of them)\n', nSessions, nStates);
fprintf('Figures             : only sessions %s  (N_FIGS = %d)\n', mat2str(PLOT_SESSIONS), N_FIGS);
fprintf('SAVE_FIGS           : %d\n', SAVE_FIGS);
savedFigs = {};                               % full paths of the .fig files that were really saved
if SAVE_FIGS
    if ~exist(FIG_DIR, 'dir'), mkdir(FIG_DIR); end
    testFile = fullfile(FIG_DIR, 'write_test.tmp');          % can we write in this folder?
    fidT = fopen(testFile, 'w');
    if fidT < 0
        warning('Cannot write in %s. The figures will be saved in %s instead.', FIG_DIR, tempdir);
        FIG_DIR = tempdir;
    else
        fclose(fidT);  delete(testFile);
    end
    fprintf('Figures will go to  : %s\n\n', FIG_DIR);
end

%% =============================== STORAGE ===================================
% Rows = subjects, columns = microstates A..D. NaN = not fitted.
M = @() nan(nSessions, nStates);
dur_median_ms = M();  dur_mean_ms = M();      % median / mean duration (ms) of the durations analysed
n_used = zeros(nSessions,nStates);            % durations inside [tmin,tmax] (used in the fit)
n_low  = zeros(nSessions,nStates);            % durations discarded for being < tmin
n_high = zeros(nSessions,nStates);            % durations discarded for being > tmax
tmin_mat = M();  tmax_mat = M();              % bounds actually used (samples)
p_geo_mat = M(); alpha_mat = M();             % fitted parameters
AIC_g = M(); AIC_p = M(); BIC_g = M(); BIC_p = M();      % information criteria
dAIC = M();  dBIC = M();                      % (power law) - (geometric); > 0 favours geometric
R2_g = M();  R2_p = M();                      % R-squared of each model
KS_g = M();  KS_p = M();                      % KS distance D of each model
KSp_g = M(); KSp_p = M();                     % bootstrap KS p-values
AD_g = M();  AD_p = M();  ADp_g = M();  ADp_p = M();     % Anderson-Darling statistic and bootstrap p
CH_g = M();  CH_p = M();  CHp_g = M();  CHp_p = M();     % chi-square statistic (pooled bins) and bootstrap p
D95_g = M(); D95_p = M();                     % 95th percentile of the bootstrap KS distance (critical D)
CV_g = M();  CV_p = M();                      % cross-validated log-likelihood per duration
hconst_mat = M();                             % constant switching probability per sample (pooled hazard)
hslope_mat = M();  hslopeP_mat = M();         % slope of logit hazard per 100 ms, and LR-test p-value
hmeanG_mat = M();  hmeanPL_mat = M();         % model-implied hazard: mean over the evaluated range (weighted by number at risk)
hbG_mat = M();     hbPL_mat = M();            % model-implied hazard: logit slope per 100 ms
hrmseG_mat = M();  hrmsePL_mat = M();         % weighted RMSE between empirical and model-implied hazard
res_store = cell(nSessions, nStates);         % full result structs (for plotting)
subjLabel = cell(nSessions,1);                % subject names for the tables
fs_vec = nan(nSessions,1);

%% ========================= LOOP THROUGH SUBJECTS ===========================
for session = 1:nSessions

    if USE_SIMULATED_TEST
        x  = simLabels{session};  fs = simFs;
        subjLabel{session} = sprintf('S%02d', session);
    else
        x  = ALLEEG(session).microstate.fit.labels;
        fs = ALLEEG(session).srate;
        subjLabel{session} = sprintf('S%02d', session);
        if isfield(ALLEEG, 'subject') && ~isempty(ALLEEG(session).subject)
            subjLabel{session} = char(string(ALLEEG(session).subject));  % real subject name if present
        end
    end
    x = x(:);  fs_vec(session) = fs;

    changeIdx  = [1; find(diff(x) ~= 0) + 1; numel(x) + 1];   % first sample of every run
    runLengths = diff(changeIdx);                              % duration of every run (samples)
    runValues  = x(changeIdx(1:end-1));                        % label of every run
    runLengths = runLengths(2:end-1);   % drop first run (onset unknown) and last run (cut)
    runValues  = runValues(2:end-1);

    for s = 1:nStates
        dAll = runLengths(runValues == s);        % all durations of microstate s (samples)
        if isempty(dAll), continue, end

        % --- bounds (samples) -------------------------------------------------
        if isempty(LOWER_BOUND_MS), tmin = min(dAll); else, tmin = ceil(LOWER_BOUND_MS*fs/1000); end
        if isempty(UPPER_BOUND_MS), tmax = max(dAll); else, tmax = floor(UPPER_BOUND_MS*fs/1000); end

        % --- discard durations outside the bounds ------------------------------
        n_low(session,s)  = sum(dAll < tmin);
        n_high(session,s) = sum(dAll > tmax);
        d = dAll(dAll >= tmin & dAll <= tmax);    % durations analysed
        n_used(session,s) = numel(d);
        if numel(d) < MIN_N || tmax <= tmin
            fprintf('Subject %s  %s: only %d durations in [%d,%d], skipped\n', ...
                    subjLabel{session}, stateNames{s}, numel(d), tmin, tmax);
            continue
        end

        r = fit_models(d, tmin, tmax, NBOOT, MIN_RISK_HAZ);   % fit both models, tests, criteria

        dur_median_ms(session,s) = 1000 * median(d) / fs;
        dur_mean_ms(session,s)   = 1000 * mean(d)   / fs;
        tmin_mat(session,s) = tmin;   tmax_mat(session,s) = tmax;
        p_geo_mat(session,s) = r.g.p; alpha_mat(session,s) = r.pl.alpha;
        AIC_g(session,s) = r.g.AIC;   AIC_p(session,s) = r.pl.AIC;
        BIC_g(session,s) = r.g.BIC;   BIC_p(session,s) = r.pl.BIC;
        dAIC(session,s)  = r.pl.AIC - r.g.AIC;
        dBIC(session,s)  = r.pl.BIC - r.g.BIC;
        R2_g(session,s)  = r.g.R2;    R2_p(session,s)  = r.pl.R2;
        KS_g(session,s)  = r.g.KS;    KS_p(session,s)  = r.pl.KS;
        KSp_g(session,s) = r.g.KSp;   KSp_p(session,s) = r.pl.KSp;
        AD_g(session,s) = r.g.AD;  AD_p(session,s) = r.pl.AD;  ADp_g(session,s) = r.g.ADp;  ADp_p(session,s) = r.pl.ADp;
        CH_g(session,s) = r.g.CH;  CH_p(session,s) = r.pl.CH;  CHp_g(session,s) = r.g.CHp;  CHp_p(session,s) = r.pl.CHp;
        D95_g(session,s) = r.g.D95; D95_p(session,s) = r.pl.D95;
        CV_g(session,s) = r.g.CV;   CV_p(session,s) = r.pl.CV;
        hconst_mat(session,s) = r.hz.hconst;
        hslope_mat(session,s) = r.hz.b * fs / 10;      % logit-hazard slope per 100 ms (100 ms = fs/10 samples)
        hslopeP_mat(session,s) = r.hz.pLR;
        hmeanG_mat(session,s)  = r.hz.wmean_g;   hmeanPL_mat(session,s) = r.hz.wmean_p;
        hbG_mat(session,s)     = r.hz.bg * fs / 10;  hbPL_mat(session,s) = r.hz.bp * fs / 10;   % per 100 ms
        hrmseG_mat(session,s)  = r.hz.rmse_g;    hrmsePL_mat(session,s) = r.hz.rmse_p;
        res_store{session,s} = r;

        fprintf(['%s %s: n=%4d [%d,%d]  p=%.3f  alpha=%.2f  R2(G/PL)=%.3f/%.3f  ' ...
                 'KSp(G/PL)=%s/%s  dAIC=%7.1f\n'], subjLabel{session}, stateNames{s}, ...
                 r.n, tmin, tmax, r.g.p, r.pl.alpha, r.g.R2, r.pl.R2, ...
                 pstr(r.g.KSp, NBOOT), pstr(r.pl.KSp, NBOOT), r.pl.AIC - r.g.AIC);
    end

    if ismember(session, PLOT_SESSIONS)           % figures only for the first N_FIGS sessions
        try                                       % a figure problem must never stop the analysis or the tables
            hFig = plot_session(res_store(session,:), subjLabel{session}, fs, stateNames);
            drawnow;                                  % show the figure now
            if SAVE_FIGS                              % save it as a .fig file and CHECK that the file exists
                figName = sprintf('microstates_session%02d_%s.fig', session, ...
                                  regexprep(subjLabel{session}, '[^A-Za-z0-9_-]', '_'));
                figFile = fullfile(FIG_DIR, figName);
                saved = false;
                try                                   % method 1: savefig
                    savefig(hFig, figFile);
                    saved = (exist(figFile, 'file') == 2);
                catch ME1
                    warning('savefig failed: %s', ME1.message);
                end
                if ~saved
                    try                               % method 2: saveas (format taken from the .fig extension)
                        saveas(hFig, figFile);
                        saved = (exist(figFile, 'file') == 2);
                    catch ME2
                        warning('saveas failed: %s', ME2.message);
                    end
                end
                if ~saved
                    try                               % method 3: hgsave (older MATLAB)
                        hgsave(hFig, figFile);
                        saved = (exist(figFile, 'file') == 2);
                    catch ME3
                        warning('hgsave failed: %s', ME3.message);
                    end
                end
                if saved
                    savedFigs{end+1} = figFile;       %#ok<SAGROW>
                    fprintf('Figure saved: %s\n', figFile);
                else
                    warning('FIGURE NOT SAVED as .fig: %s  (a PNG copy is attempted instead)', figFile);
                    try, print(hFig, strrep(figFile, '.fig', '.png'), '-dpng', '-r150'); catch, end
                end
            end
        catch MEfig
            warning('The figure of session %d could not be drawn or saved: %s', session, MEfig.message);
            if ~isempty(MEfig.stack)
                fprintf('   (error in %s, line %d)\n', MEfig.stack(1).name, MEfig.stack(1).line);
            end
        end
    end
end

%% ============================ SAVED FIGURES: LIST ===========================
if SAVE_FIGS
    dfig = dir(fullfile(FIG_DIR, 'microstates_session*.fig'));
    fprintf('\n%d .fig file(s) in %s\n', numel(dfig), FIG_DIR);
    for kf = 1:numel(dfig), fprintf('   %s  (%.1f MB)\n', dfig(kf).name, dfig(kf).bytes/1e6); end
    if numel(dfig) == 0
        warning(['No .fig file was found. Check the messages above: subjects to plot, SAVE_FIGS, ' ...
                 'and the folder shown in "Figures will go to".']);
    end
end

%% ============================== WORD TABLES ================================
% Each table is built as: header rows (cell N x 2: text, column span), body (cell matrix of
% text), and the rows to print in bold. blocks{} collects headings, paragraphs and tables in
% the order they will appear in the Word file; write_tables(...) writes them at the end.
blocks = {};
blocks{end+1} = struct('type','heading','text','Microstate duration analysis: tables');
blocks{end+1} = struct('type','para','text', sprintf(['Microstate durations were analysed on the bounded support [t_min, t_max] ' ...
    '(lower and upper bound, in samples; durations outside it were discarded: %d below t_min, %d above t_max, %d analysed). ' ...
    'Two models were fitted by maximum likelihood on that support: a bounded geometric distribution, ' ...
    'P(t) = p(1-p)^(t-t_min) / [1-(1-p)^L], and a bounded power law, P(t) = t^(-{alpha}) / sum_(s=t_min)^(t_max) s^(-{alpha}), ' ...
    'with L = t_max - t_min + 1. Duration in ms = 1000 t / fs. Tests marked with a bootstrap p-value used %d parametric-bootstrap replicates.'], ...
    sum(n_low(:)), sum(n_high(:)), sum(n_used(:)), NBOOT));

nc = 1 + 2*nStates;

% ---------------- Table 1: median and mean duration, per subject ----------------
h1 = {'Subject',1};  h2 = {'',1};
for s = 1:nStates
    h1(end+1,:) = {['Microstate ' stateNames{s}], 2};
    h2(end+1,:) = {'Median (ms)',1};  h2(end+1,:) = {'Mean (ms)',1};
end
T1num = nan(nSessions, nc-1);
for s = 1:nStates, T1num(:,2*s-1) = dur_median_ms(:,s);  T1num(:,2*s) = dur_mean_ms(:,s); end
body1 = cell(nSessions+2, nc);
for i = 1:nSessions
    body1{i,1} = subjLabel{i};
    for c = 1:nc-1, body1{i,c+1} = fmt(T1num(i,c), '%.1f'); end
end
body1{nSessions+1,1} = 'Average';  body1{nSessions+2,1} = 'SD';
for c = 1:nc-1
    v = T1num(~isnan(T1num(:,c)), c);
    body1{nSessions+1,c+1} = fmt(mean(v), '%.1f');
    body1{nSessions+2,c+1} = fmt(std(v),  '%.1f');
end
blocks{end+1} = struct('type','caption','text','Table 1. Median and mean duration (ms) of each microstate, per subject.');
blocks{end+1} = struct('type','table','header',{{h1,h2}},'body',{body1}, ...
                       'boldRows',[nSessions+1 nSessions+2],'firstW',1300);
blocks{end+1} = struct('type','para','text', ...
    'Average and SD below the table: mean and standard deviation, across subjects, of the values in each column.');

% ---------------- Table 2: data analysed and fitted parameters (long) -------------
h = {'Subject',1; 'Microstate',1; 'Durations analysed (n)',1; 'Discarded < t_min / > t_max',1; ...
     't_min (ms)',1; 't_max (ms)',1; 'Geometric p (per sample)',1; 'Power law {alpha}',1};
body = {};
for i = 1:nSessions
    for s = 1:nStates
        if isnan(dAIC(i,s)), continue, end
        body(end+1,:) = {subjLabel{i}, stateNames{s}, sprintf('%d',n_used(i,s)), ...
            sprintf('%d / %d', n_low(i,s), n_high(i,s)), fmt(1000*tmin_mat(i,s)/fs_vec(i),'%.1f'), ...
            fmt(1000*tmax_mat(i,s)/fs_vec(i),'%.1f'), fmt(p_geo_mat(i,s),'%.4f'), fmt(alpha_mat(i,s),'%.3f')}; %#ok<SAGROW>
    end
end
blocks{end+1} = struct('type','caption','text','Table 2. Data analysed and fitted parameters, per subject and microstate.');
blocks{end+1} = struct('type','table','header',{{h}},'body',{body},'boldRows',[],'firstW',1100);

% ---------------- Table 3: AIC / BIC summary per microstate ----------------------
h = {'Microstate',1; 'Subjects (n)',1; 'AIC geometric',1; 'AIC power law',1; '{Delta}AIC (PL - G)',1; ...
     'BIC geometric',1; 'BIC power law',1; '{Delta}BIC (PL - G)',1; 'Favours geometric / power law (n)',1};
body = cell(nStates, 9);
for s = 1:nStates
    ok = ~isnan(dAIC(:,s));
    body(s,:) = {stateNames{s}, sprintf('%d',sum(ok)), mean_sd(AIC_g(ok,s),'%.1f'), mean_sd(AIC_p(ok,s),'%.1f'), ...
                 mean_sd(dAIC(ok,s),'%.1f'), mean_sd(BIC_g(ok,s),'%.1f'), mean_sd(BIC_p(ok,s),'%.1f'), ...
                 mean_sd(dBIC(ok,s),'%.1f'), sprintf('%d / %d', sum(dBIC(ok,s)>0), sum(dBIC(ok,s)<0))};
end
blocks{end+1} = struct('type','caption','text','Table 3. Model comparison across subjects (mean (SD)).');
blocks{end+1} = struct('type','table','header',{{h}},'body',{body},'boldRows',[],'firstW',1500);
blocks{end+1} = struct('type','para','text', ['{Delta} = (power law) - (geometric): positive values favour the geometric model. ' ...
    'Both models have one parameter (t_min and t_max are fixed bounds), so {Delta}AIC = {Delta}BIC. ' ...
    'Rule of thumb: |{Delta}| > 10 strong evidence, |{Delta}| < 2 no real difference.']);

% ---------------- Table 4: AIC / BIC per subject and microstate -------------------
h = {'Subject',1; 'Microstate',1; 'n',1; 'AIC geometric',1; 'AIC power law',1; '{Delta}AIC',1; ...
     'BIC geometric',1; 'BIC power law',1; '{Delta}BIC',1; 'Preferred model',1};
body = {};
for i = 1:nSessions
    for s = 1:nStates
        if isnan(dAIC(i,s)), continue, end
        if abs(dBIC(i,s)) < 2, pref = 'Equivalent'; elseif dBIC(i,s) > 0, pref = 'Geometric'; else, pref = 'Power law'; end
        body(end+1,:) = {subjLabel{i}, stateNames{s}, sprintf('%d',n_used(i,s)), fmt(AIC_g(i,s),'%.1f'), ...
            fmt(AIC_p(i,s),'%.1f'), fmt(dAIC(i,s),'%.1f'), fmt(BIC_g(i,s),'%.1f'), fmt(BIC_p(i,s),'%.1f'), ...
            fmt(dBIC(i,s),'%.1f'), pref}; %#ok<SAGROW>
    end
end
blocks{end+1} = struct('type','caption','text','Table 4. AIC, BIC and their difference, per subject and microstate.');
blocks{end+1} = struct('type','table','header',{{h}},'body',{body},'boldRows',[],'firstW',1100);

% ---------------- Table 5: Kolmogorov-Smirnov per subject and microstate ----------
h1 = {'Subject',1};  h2 = {'',1};
for s = 1:nStates
    h1(end+1,:) = {['Microstate ' stateNames{s}], 2};
    h2(end+1,:) = {'Geometric',1};  h2(end+1,:) = {'Power law',1};
end
Dm = cell(1,2*nStates);  Pm = cell(1,2*nStates);
for s = 1:nStates, Dm{2*s-1} = KS_g(:,s); Dm{2*s} = KS_p(:,s); Pm{2*s-1} = KSp_g(:,s); Pm{2*s} = KSp_p(:,s); end
body = cell(nSessions+5, nc);
for i = 1:nSessions
    body{i,1} = subjLabel{i};
    for c = 1:2*nStates
        star = '';  if ~isnan(Pm{c}(i)) && Pm{c}(i) < ALPHA, star = '*'; end
        body{i,c+1} = [fmt(Dm{c}(i),'%.3f') ' (' pstr(Pm{c}(i), NBOOT) ')' star];
    end
end
rowN = {sprintf('Non-significant (p {ge} %.2f), n', ALPHA); sprintf('Significant (p < %.2f), n', ALPHA); ...
        'Significant, %'; 'Binomial test vs 5% rejections, p'; 'Uniformity of the p-values (KS), p'};
for k = 1:5, body{nSessions+k,1} = rowN{k}; end
for c = 1:2*nStates
    body(nSessions+1:nSessions+5, c+1) = count_rows(Pm{c}, ALPHA);
end
blocks{end+1} = struct('type','caption','text','Table 5. Kolmogorov-Smirnov distance D (bootstrap p-value) per subject and microstate.');
blocks{end+1} = struct('type','table','header',{{h1,h2}},'body',{body}, ...
                       'boldRows',nSessions+1:nSessions+5,'firstW',2300);
blocks{end+1} = struct('type','para','text', sprintf(['D = largest distance between the empirical and the fitted cumulative distribution on [t_min, t_max]. ' ...
    'p-values come from a parametric bootstrap (%d replicates: data simulated from the fitted model, model refitted, D recomputed), ' ...
    'because the classical KS p-value is not valid when parameters are estimated from the same data and the data are discrete. ' ...
    '* = significant (the model is rejected). Non-significant means no evidence against the model. ' ...
    'If the model is correct, about %.0f%% of the tests are expected to be significant by chance (binomial row), ' ...
    'and the p-values should be uniformly distributed between 0 and 1 (last row; informative with about 20 or more subjects).'], NBOOT, 100*ALPHA));

% ---------------- Table 6: other goodness-of-fit statistics (long) -----------------
h1 = {'Subject',1; 'Microstate',1; 'Geometric',5; 'Power law',5};
sub = {'R{sq}',1; 'Critical D (95%)',1; 'Anderson-Darling A{sq} (p)',1; 'Chi-square (p)',1; 'CV log-lik / duration',1};
h2 = [{'',1; '',1}; sub; sub];
body = {};
for i = 1:nSessions
    for s = 1:nStates
        if isnan(dAIC(i,s)), continue, end
        body(end+1,:) = {subjLabel{i}, stateNames{s}, ...
            fmt(R2_g(i,s),'%.3f'), fmt(D95_g(i,s),'%.3f'), [fmt(AD_g(i,s),'%.2f') ' (' pstr(ADp_g(i,s),NBOOT) ')'], ...
            [fmt(CH_g(i,s),'%.1f') ' (' pstr(CHp_g(i,s),NBOOT) ')'], fmt(CV_g(i,s),'%.3f'), ...
            fmt(R2_p(i,s),'%.3f'), fmt(D95_p(i,s),'%.3f'), [fmt(AD_p(i,s),'%.2f') ' (' pstr(ADp_p(i,s),NBOOT) ')'], ...
            [fmt(CH_p(i,s),'%.1f') ' (' pstr(CHp_p(i,s),NBOOT) ')'], fmt(CV_p(i,s),'%.3f')}; %#ok<SAGROW>
    end
end
blocks{end+1} = struct('type','caption','text','Table 6. Additional goodness-of-fit statistics, per subject and microstate.');
blocks{end+1} = struct('type','table','header',{{h1,h2}},'body',{body},'boldRows',[],'firstW',1000);
blocks{end+1} = struct('type','para','text', ['R{sq}: agreement between the empirical and fitted probabilities (descriptive). ' ...
    'Critical D (95%): 95th percentile of the KS distance expected if the model were true; an observed D (Table 5) below it is compatible with the model. ' ...
    'Anderson-Darling: like KS but weights the tails more. Chi-square: observed vs expected counts after pooling bins to an expected count {ge} 5. ' ...
    'p-values of A{sq} and chi-square are also from the parametric bootstrap. ' ...
    'CV log-lik: mean log-likelihood per duration on held-out data (fit on odd-numbered durations, test on even-numbered ones, and vice versa); higher is better.']);

% ---------------- Table 7: summary of the adequacy statistics ----------------------
h = {'Microstate',1; 'Model',1; 'Median R{sq}',1; 'KS significant (%)',1; 'Anderson-Darling significant (%)',1; ...
     'Chi-square significant (%)',1; 'Uniformity of p-values (KS / AD / chi-square)',1; 'CV log-lik / duration (median)',1; ...
     'Favoured by cross-validation (n)',1};
body = {};
for s = 1:nStates
    ok = ~isnan(dAIC(:,s));
    for mdl = 1:2
        if mdl == 1
            nm = 'Geometric';  R2v = R2_g(ok,s);  pk = KSp_g(ok,s);  pa = ADp_g(ok,s);  pc = CHp_g(ok,s);  cv = CV_g(ok,s);
            fav = sprintf('%d', sum(CV_g(ok,s) > CV_p(ok,s)));
        else
            nm = 'Power law';  R2v = R2_p(ok,s);  pk = KSp_p(ok,s);  pa = ADp_p(ok,s);  pc = CHp_p(ok,s);  cv = CV_p(ok,s);
            fav = sprintf('%d', sum(CV_p(ok,s) > CV_g(ok,s)));
        end
        body(end+1,:) = {stateNames{s}, nm, fmt(median(R2v),'%.3f'), pct_sig(pk,ALPHA), pct_sig(pa,ALPHA), pct_sig(pc,ALPHA), ...
            [fmt(unif_p(pk),'%.3f') ' / ' fmt(unif_p(pa),'%.3f') ' / ' fmt(unif_p(pc),'%.3f')], ...
            fmt(median(cv),'%.3f'), fav}; %#ok<SAGROW>
    end
end
blocks{end+1} = struct('type','caption','text','Table 7. Summary across subjects of the adequacy statistics.');
blocks{end+1} = struct('type','table','header',{{h}},'body',{body},'boldRows',[],'firstW',1300);
blocks{end+1} = struct('type','para','text', sprintf(['Percentages: share of subjects in which the model is rejected at p < %.2f (about %.0f%% is expected by chance if the model is correct). ' ...
    'Uniformity: p-value of a KS test of the subject-level p-values against a uniform distribution (a small value means the p-values pile up near 0, i.e. systematic misfit).'], ALPHA, 100*ALPHA));

% ---------------- Table 8: hazard check (constant-hazard test) ---------------------
h1 = {'Subject',1};  h2 = {'',1};
for s = 1:nStates
    h1(end+1,:) = {['Microstate ' stateNames{s}], 2};
    h2(end+1,:) = {'Pooled h (per sample)',1};  h2(end+1,:) = {'Slope b per 100 ms (p)',1};
end
body = cell(nSessions+4, nc);
for i = 1:nSessions
    body{i,1} = subjLabel{i};
    for s = 1:nStates
        star = '';  if ~isnan(hslopeP_mat(i,s)) && hslopeP_mat(i,s) < ALPHA, star = '*'; end
        body{i,2*s}   = fmt(hconst_mat(i,s), '%.4f');
        body{i,2*s+1} = [fmt(hslope_mat(i,s),'%.2f') ' (' pfmt(hslopeP_mat(i,s)) ')' star];
    end
end
body{nSessions+1,1} = 'Average';  body{nSessions+2,1} = 'SD';
body{nSessions+3,1} = sprintf('Flat hazard (p {ge} %.2f), n', ALPHA);
body{nSessions+4,1} = sprintf('Non-flat hazard (p < %.2f), n', ALPHA);
for s = 1:nStates
    vh = hconst_mat(~isnan(hconst_mat(:,s)), s);   vb = hslope_mat(~isnan(hslope_mat(:,s)), s);
    pv = hslopeP_mat(~isnan(hslopeP_mat(:,s)), s);
    body{nSessions+1,2*s} = fmt(mean(vh),'%.4f');  body{nSessions+1,2*s+1} = fmt(mean(vb),'%.2f');
    body{nSessions+2,2*s} = fmt(std(vh),'%.4f');   body{nSessions+2,2*s+1} = fmt(std(vb),'%.2f');
    body{nSessions+3,2*s} = '';  body{nSessions+3,2*s+1} = sprintf('%d', sum(pv >= ALPHA));
    body{nSessions+4,2*s} = '';  body{nSessions+4,2*s+1} = sprintf('%d', sum(pv <  ALPHA));
end
blocks{end+1} = struct('type','caption','text','Table 8. Hazard (switching probability) check, per subject and microstate.');
blocks{end+1} = struct('type','table','header',{{h1,h2}},'body',{body}, ...
                       'boldRows',nSessions+1:nSessions+4,'firstW',2300);
blocks{end+1} = struct('type','para','text', sprintf(['Hazard h(t) = probability that a microstate ends at t given that it has lasted until t. A geometric model implies a constant hazard. ' ...
    'Pooled h: total number of endings divided by total number of microstate-samples at risk (equal to the geometric p). ' ...
    'Slope b: slope of the logit of the hazard against time, per 100 ms, estimated by maximum likelihood on the range where at least %d durations are still at risk; ' ...
    'p: likelihood-ratio test against a constant hazard. b > 0: hazard rises with time; b < 0: hazard falls (as in a power law). * = hazard not flat.'], MIN_RISK_HAZ));

% ---------------- Table 9: hazard of the two models vs the empirical hazard (summary) ----------
h = {'Microstate',1; 'Empirical pooled h',1; 'Geometric: mean h',1; 'Power law: mean h',1; ...
     'Empirical slope b (per 100 ms)',1; 'Geometric: slope b',1; 'Power law: slope b',1; ...
     'Hazard RMSE geometric',1; 'Hazard RMSE power law',1; 'Hazard closer to geometric / power law (n)',1};
body = cell(nStates, 10);
for s = 1:nStates
    ok = ~isnan(hrmseG_mat(:,s));
    body(s,:) = {stateNames{s}, mean_sd(hconst_mat(ok,s),'%.4f'), mean_sd(hmeanG_mat(ok,s),'%.4f'), mean_sd(hmeanPL_mat(ok,s),'%.4f'), ...
                 mean_sd(hslope_mat(ok,s),'%.2f'), mean_sd(hbG_mat(ok,s),'%.2f'), mean_sd(hbPL_mat(ok,s),'%.2f'), ...
                 mean_sd(hrmseG_mat(ok,s),'%.4f'), mean_sd(hrmsePL_mat(ok,s),'%.4f'), ...
                 sprintf('%d / %d', sum(hrmseG_mat(ok,s) < hrmsePL_mat(ok,s)), sum(hrmsePL_mat(ok,s) < hrmseG_mat(ok,s)))};
end
blocks{end+1} = struct('type','caption','text','Table 9. Hazard implied by each model compared with the empirical hazard, across subjects (mean (SD)).');
blocks{end+1} = struct('type','table','header',{{h}},'body',{body},'boldRows',[],'firstW',1500);
blocks{end+1} = struct('type','para','text', sprintf(['Model-implied hazard: h(t) = f(t) / P(T {ge} t) from each fitted model, evaluated over the same range as the empirical hazard ' ...
    '(at least %d durations at risk). Mean h: average over that range weighted by the number at risk, so it is directly comparable with the pooled empirical hazard. ' ...
    'Slope b: weighted least-squares slope of logit h against time, per 100 ms (a geometric model implies a slope near 0; a power law implies a clearly negative slope). ' ...
    'RMSE: root mean squared difference between the empirical and the model hazard, weighted by the number at risk (lower is closer to the data).'], MIN_RISK_HAZ));

% ---------------- Table 10: the same, per subject and microstate -------------------------------
h = {'Subject',1; 'Microstate',1; 'Empirical pooled h',1; 'Geometric: mean h',1; 'Power law: mean h',1; ...
     'Empirical slope b',1; 'Geometric: slope b',1; 'Power law: slope b',1; 'RMSE geometric',1; 'RMSE power law',1; 'Hazard closer to',1};
body = {};
for i = 1:nSessions
    for s = 1:nStates
        if isnan(hrmseG_mat(i,s)), continue, end
        if hrmseG_mat(i,s) < hrmsePL_mat(i,s), cl = 'Geometric'; else, cl = 'Power law'; end
        body(end+1,:) = {subjLabel{i}, stateNames{s}, fmt(hconst_mat(i,s),'%.4f'), fmt(hmeanG_mat(i,s),'%.4f'), fmt(hmeanPL_mat(i,s),'%.4f'), ...
            fmt(hslope_mat(i,s),'%.2f'), fmt(hbG_mat(i,s),'%.2f'), fmt(hbPL_mat(i,s),'%.2f'), ...
            fmt(hrmseG_mat(i,s),'%.4f'), fmt(hrmsePL_mat(i,s),'%.4f'), cl}; %#ok<SAGROW>
    end
end
blocks{end+1} = struct('type','caption','text','Table 10. Hazard implied by each model compared with the empirical hazard, per subject and microstate.');
blocks{end+1} = struct('type','table','header',{{h}},'body',{body},'boldRows',[],'firstW',1100);

write_tables(OUT_BASE, blocks, WRITE_DOCX);   % writes Microstate_tables.txt, one .txt per table, and the Word file

%% ============================== CONSOLE SUMMARY ============================
fprintf('\n====================== SUMMARY (medians over subjects) ======================\n');
fprintf('State  tmin(ms) tmax(ms)   p      alpha | R2 geo   R2 PL | dAIC(PL-G) | geo pref | KS/AD/Chi2 non-signif. geo | PL | flat hazard\n');
for s = 1:nStates
    ok = ~isnan(dAIC(:,s));
    fprintf('  %s    %6.1f   %6.1f   %.3f   %.2f  | %.3f   %.3f |  %8.1f  | %2d / %2d | %2d/%2d/%2d  | %2d/%2d/%2d | %2d of %2d\n', ...
        stateNames{s}, 1000*median(tmin_mat(ok,s)./fs_vec(ok)), 1000*median(tmax_mat(ok,s)./fs_vec(ok)), ...
        median(p_geo_mat(ok,s)), median(alpha_mat(ok,s)), median(R2_g(ok,s)), median(R2_p(ok,s)), ...
        median(dAIC(ok,s)), sum(dAIC(ok,s)>0), sum(ok), ...
        sum(KSp_g(ok,s)>=ALPHA), sum(ADp_g(ok,s)>=ALPHA), sum(CHp_g(ok,s)>=ALPHA), ...
        sum(KSp_p(ok,s)>=ALPHA), sum(ADp_p(ok,s)>=ALPHA), sum(CHp_p(ok,s)>=ALPHA), ...
        sum(hslopeP_mat(ok,s)>=ALPHA), sum(ok));
end
if USE_SIMULATED_TEST
    fprintf('\n---------------- TEST: TRUE vs ESTIMATED (median) ----------------\n');
    for s = 1:nStates
        if strcmp(SIM_TRUTH,'geometric')
            fprintf('  %s   p true %.3f / est %.3f\n', stateNames{s}, truePar(s), median(p_geo_mat(:,s)));
        else
            fprintf('  %s   alpha true %.2f / est %.2f\n', stateNames{s}, truePar(s), median(alpha_mat(:,s)));
        end
    end
end

if SAVE_FIGS
    fprintf('\nREMINDER: %d figure(s) saved as .fig in %s\n', numel(savedFigs), FIG_DIR);
end
