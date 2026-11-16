# EEG Microstate Analysis

This repository contains MATLAB scripts and auxiliary functions developed for the analysis of EEG microstate durations and transitions.

The code accompanies the manuscript:

**A Competitive Framework for Modeling EEG Microstate Durations** (In Preparation)

The repository provides the analysis scripts, supporting functions, and instructions required to reproduce the analyses.

## 1. Repository structure

```text
Microstate-Analysis/
│
├── Dataset_V2/
│   └── README.md
│
├── Functions/
│   └── Auxiliary MATLAB functions (.m)
│
├── Results/
│   ├── README.md
│
├── Scripts/
│   └── fit_geom_power_main.m 
│   └── Transition analysis script.m
│
├── README.md
└── .gitignore
```

## 2. Dataset

The analyses use a publicly available EEG microstate dataset containing categorized microstate sequences from one participant across 60 eyes-open resting-state sessions collected over three months.

The original dataset is available from Figshare:

https://doi.org/10.6084/m9.figshare.24877770.v3

**The dataset is not included or redistributed in this repository.** Users must download it directly from Figshare.

After downloading and extracting the dataset, place the file in the following location:

```text
Dataset_V2/
└── EEG/
    └── modkmeans_result.mat
```

The MATLAB scripts expect the following data structure:

- `ALLEEG(session).microstate.fit.labels`: microstate label sequence.
- `ALLEEG(session).srate`: EEG sampling frequency (Hz).

## 3. Analysis scripts

### 3.1. `fit_geom_power_main.m` — Microstate duration analysis

This script implements a comparative framework to evaluate two alternative probability distributions for EEG microstate durations:

- **Bounded geometric distribution:** models durations under a constant switching probability.
- **Bounded power-law distribution:** models durations following a power-law relationship.

For each of the four microstates (A, B, C, and D) and each session, the script:

1. Extracts microstate durations from the categorical label sequence.
2. Excludes the first and last runs, whose durations may be incomplete.
3. Applies lower and upper duration bounds.
4. Estimates both distributions using maximum likelihood.
5. Evaluates goodness of fit using parametric-bootstrap Kolmogorov–Smirnov, Anderson–Darling, and chi-square tests.
6. Compares model performance using AIC and BIC.
7. Computes cross-validated log-likelihood.
8. Examines empirical and model-implied hazard functions, including tests of constant hazard.
9. Generates figures and summary tables.

The analysis is performed across all 60 sessions. Figures are generated only for the sessions specified in the script settings.

### 3.2. Transition analysis — Chi-square tests

This script examines whether transitions between microstates occur according to the expected transition probabilities under a specified independence-based null model.

For each session, it:

1. Extracts consecutive microstate transitions.
2. Computes the observed transition matrix.
3. Estimates the expected transition counts.
4. Calculates standardized Z scores and corresponding two-tailed p-values for individual transitions.
5. Performs row-wise chi-square tests to assess deviations between observed and expected transition distributions.
6. Summarizes the number of significant transitions and significant chi-square tests across sessions.

The results are organized into two MATLAB tables containing transition-level and microstate-level statistics.

## 4. Auxiliary functions

The `Functions/` directory contains MATLAB functions supporting the main duration-analysis pipeline.

The functions called by the duration-analysis script include:

| Function | Description |
|---|---|
| `simulate_labels` | Generates simulated microstate label sequences for testing the analysis under a known duration distribution. |
| `fit_models` | Fits the bounded geometric and power-law distributions and computes model-comparison and goodness-of-fit statistics. |
| `plot_session` | Generates session-level figures showing duration distributions and hazard functions for both models. |
| `write_tables` | Exports the analysis tables to tab-separated text files and, optionally, a Word document. |

Additional formatting and statistical helper functions are used to prepare the summary tables and statistical output. 

## 5. Requirements

- MATLAB R2016b or later.
- No additional MATLAB toolboxes are required by the duration-analysis script.

## 6. Running the analyses

1. Clone or download this repository.
2. Download the original dataset directly from Figshare.
3. Place `modkmeans_result.mat` in `Dataset_V2/EEG/`.
4. Open MATLAB and navigate to the project.
5. Open the desired script from the `Scripts/` directory.
6. Run the complete script.

The scripts automatically locate the project directory, add the auxiliary functions to the MATLAB path, and load the dataset.

For the duration-analysis script, the main analysis parameters can be adjusted in the `SETTINGS` section, including the number of sessions, duration bounds, number of bootstrap replicates, and figure-generation options.

## 7. Output files

The duration-analysis script generates:

- MATLAB `.fig` files containing session-level visualizations.
- Tab-separated text files containing the analysis tables.
- An optional Word document containing the formatted tables.

Generated outputs are stored in the `Results/` directory when configured accordingly.

The transition-analysis script currently creates the summary tables `Table1` and `Table2` in the MATLAB workspace.

Generated results are not included in the repository.

## 8. Reproducibility

A fixed random seed (`rng(12345)`) is used in the duration-analysis script to ensure reproducibility of the bootstrap procedures.

The scripts are designed to operate on the original dataset without modifying or redistributing it.

## 9. Citation

If you use these scripts or the associated analyses, please cite the corresponding manuscript:

**[Full reference to be added upon publication.]**

Please also cite the original dataset:

[Figshare dataset](https://doi.org/10.6084/m9.figshare.24877770.v3).
