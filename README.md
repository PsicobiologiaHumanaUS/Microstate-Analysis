# Microstate-Analysis
MATLAB scripts for EEG microstate analysis using a publicly available resting-state dataset, for the paper: "A Competitive Framework for Modeling EEG Microstate Durations" (In preparation)
## Dataset Access and Organization

The dataset analyzed in this study is publicly available through Figshare:

[https://doi.org/10.6084/m9.figshare.24877770.v3](https://doi.org/10.6084/m9.figshare.24877770.v3)

**The original dataset is not included or redistributed in this GitHub repository.** Users must obtain the data directly from the original repository.

After downloading and extracting the dataset, place the `Dataset_V2` folder in the root directory of this repository, maintaining the original folder structure:

```text
Microstate-Analysis/
└── Dataset_V2/
    └── EEG/
        └── modkmeans_result.mat
```

The analysis scripts will automatically locate and load the required MATLAB file from this directory.

Please refer to the original Figshare record for dataset provenance and access conditions.
