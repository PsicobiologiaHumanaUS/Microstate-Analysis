%Script to compute chi-squared t-test to determine if transitions occurs
%randomly or non-randomly (Table 2; Table 1 exceeds the object of resent report)
clearvars -except ALLEEG
clc

%% ================= PROJECT SETUP AND DATA LOADING =================
% Locate the script or current working directory
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
        error(['Project folders not found. Check that ', ...
               'Functions and Dataset_V2 exist.']);
    end

    PROJECT_DIR = PARENT_DIR;
end

% Add auxiliary functions to MATLAB path
FUNCTIONS_DIR = fullfile(PROJECT_DIR, 'Functions');
addpath(genpath(FUNCTIONS_DIR));

% Locate dataset
DATASET_DIR = fullfile(PROJECT_DIR, 'Dataset_V2');
DATA_FILE = fullfile(DATASET_DIR, 'EEG', 'modkmeans_result.mat');

% Load ALLEEG if it is not already in the workspace
if ~exist('ALLEEG', 'var')
    if ~isfile(DATA_FILE)
        error('Dataset not found: %s', DATA_FILE);
    end
    loadedData = load(DATA_FILE);
    if ~isfield(loadedData, 'ALLEEG')
        error('The MAT file does not contain the variable ALLEEG.');
    end
    ALLEEG = loadedData.ALLEEG;
end

fprintf('Project directory: %s\n', PROJECT_DIR);
fprintf('Dataset loaded successfully: %d sessions\n', numel(ALLEEG));
fprintf('Functions added to MATLAB path.\n');

%% ================= PARAMETERS =================
nSessions = 60;
nStates = 4;
nTrans = nStates * (nStates - 1);
%% ================= PREALLOCATION =================
ObsMat = zeros(nSessions,nTrans);
ExpMat = zeros(nSessions,nTrans);
ZMat = zeros(nSessions,nTrans);
PtransMat = zeros(nSessions,nTrans);
Chi2Mat = zeros(nSessions,nStates);
Chi2PMat = zeros(nSessions,nStates);
%% ================= MAIN LOOP =================
for session = 1:nSessions
x = ALLEEG(session).microstate.fit.labels(:);
changeIdx = [1; find(diff(x) ~= 0) + 1];
data = x(changeIdx);
from = data(1:end-1);
to = data(2:end);
T = accumarray([from,to],1,[nStates,nStates]);
T(1:nStates+1:end) = 0;
stateCounts = histcounts(data,1:nStates+1)';
p_state = stateCounts / sum(stateCounts);
E = zeros(nStates,nStates);
for i = 1:nStates
N_i = sum(T(i,:));
if N_i == 0
continue
end
p_excl = p_state;
p_excl(i) = 0;
p_excl = p_excl / sum(p_excl);
E(i,:) = N_i * p_excl;
end
mask = ~eye(nStates);
ObsVec = T(mask)';
ExpVec = E(mask)';
ZVec = (ObsVec - ExpVec) ./ sqrt(ExpVec);
ZVec(ExpVec==0) = NaN;
PtransVec = 2*(1 - normcdf(abs(ZVec)));
ObsMat(session,:) = ObsVec;
ExpMat(session,:) = ExpVec;
ZMat(session,:) = ZVec;
PtransMat(session,:) = PtransVec;
for i = 1:nStates
Orow = T(i,:);
Erow = E(i,:);
Orow(i) = [];
Erow(i) = [];
valid = Erow > 0;
if sum(valid) < 2
Chi2Mat(session,i) = NaN;
Chi2PMat(session,i) = NaN;
continue
end
chi2 = sum((Orow(valid) - Erow(valid)).^2 ./ Erow(valid));
df = sum(valid) - 1;
p_chi2 = 1 - chi2cdf(chi2,df);
Chi2Mat(session,i) = chi2;
Chi2PMat(session,i) = p_chi2;
end
end
%% ================= COUNTS =================
for i = 1:nSessions
NumSigTransitions(i,1) = sum(PtransMat(i,:) < 0.05);
NumSigChi2PMat(i,1) = sum(Chi2PMat(i,:) < 0.05);
end
for j = 1:12
NumSigTransitions_columns(1,j) = sum(PtransMat(:,j) < 0.05);
end
for j = 1:4
NumSigChi2PMat_columns(1,j) = sum(Chi2PMat(:,j) < 0.05);
end
%% ================= TABLES ONLY =================
Table1 = array2table([NumSigTransitions_columns; PtransMat], ...
'VariableNames', {'A?B','A?C','A?D','B?A','B?C','B?D', ...
'C?A','C?B','C?D','D?A','D?B','D?C'});
Table2 = array2table([NumSigChi2PMat_columns; Chi2PMat], ...
'VariableNames', {'A','B','C','D'});
%% ================= OUTPUT =================
Table1
Table2
