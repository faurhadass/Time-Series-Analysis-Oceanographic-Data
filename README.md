# Time Series Analysis of Oceanographic Data

A MATLAB toolkit for analyzing oceanographic time series and identifying internal wave dynamics along the Eastern Mediterranean continental shelf and slope. The codebase combines time-domain, frequency-domain, and time–frequency techniques with a suite of interactive GUIs for visualization and exploration of multi-parameter datasets.

Developed as part of undergraduate research at Ruppin Academic Center under the advisory of Professors Benny Salomon and Steve Brenner.

## Overview

The Eastern Mediterranean continental shelf and slope host complex circulation patterns where internal waves play a significant role in cross-shelf transport of nutrients, pollutants, and water masses. This project applies signal processing techniques to three-dimensional fields of current velocity, temperature, and salinity to:

- Detect and characterize internal waves along a north–south gradient where the shelf geometry narrows significantly
- Investigate frequency content, amplitude, and seasonal variability
- Compare internal wave activity between the wider southern shelf and the narrower northern shelf
- Assess the role of internal waves in cross-shelf material exchange

## Data

Analyses are based primarily on Princeton Ocean Model (POM) simulations:

- **Spatial resolution:** 1/60° (~1.5–1.8 km)
- **Temporal resolution:** hourly
- **Coverage:** continuous three-year integration
- **Forcing:** ocean reanalysis at the open western boundary, atmospheric reanalysis at the surface

> Note: Raw data files are excluded from this repository. The codebase is shared as a reference for the analysis pipeline.

## Analytical Methods

- **Time-domain analysis** — Direct examination of temperature, salinity, and current-velocity time series across multiple cross-sections and depths
- **Frequency-domain analysis** — Fast Fourier Transform (FFT) and Power Spectral Density (PSD) estimation to identify dominant oscillatory modes (tidal, inertial, internal-wave frequencies)
- **Time–frequency analysis** — Spectrogram and wavelet-style visualizations to track how spectral content evolves over time
- **Spatial analysis** — Interpolated contour plots and depth profiles across cross-shelf transects
- **Validation** — Comparison of detected spectral peaks against theoretical predictions and prior observational studies

## Repository Structure
Main Code/
├── time_series_analysis_main.m      # Top-level entry point
├── Functions/                        # All analysis and GUI functions
│   ├── load_ocean_data.m
│   ├── loadLatitudeDatasetFromMat.m
│   ├── saveLatitudeDatasetToMat.m
│   ├── chooseDataPointsToAnalyzeGUI.m
│   ├── TimeSeriesPlotGUI.m
│   ├── FourierPlotGUI.m
│   ├── PSDPlotGUI.m
│   ├── FreqTimePlotGUI.m
│   ├── DepthProfilesPlot.m
│   ├── CorrelationPlot.m
│   ├── computePSD.m
│   ├── plotFourier.m
│   ├── plotTimeSeries.m
│   ├── createInterpolatedContourPlot.m
│   ├── internalWaveKnownSpectralPeaks.m
│   ├── interactivePeakPlotterGUI.m
│   ├── playAnimatedProfile.m
│   ├── saveAnimatedProfileAsMp4.m
│   └── ... (helper utilities)
└── docs/
└── Final Report.pdf              # Full project writeup
## GUI Features

The toolkit emphasizes interactive exploration. Key interfaces include:

- **Data point selection** — Choose cross-shelf locations and depth layers for analysis
- **Time series viewer** — Plot raw and processed signals with adjustable time windows
- **Fourier and PSD viewers** — Compute and overlay spectra; mark known internal-wave spectral peaks for reference
- **Frequency–time viewer** — Track how dominant frequencies evolve, useful for capturing seasonal cycles and event-driven variability
- **Depth profiles and correlation plots** — Examine vertical structure and inter-parameter relationships
- **Animated profiles** — Render and export depth-evolution animations as MP4

## Documentation

The full project report — including detailed methodology, results, and discussion — is available in `docs/Final Report.pdf`.

## Author

**Hadassah Brenner-Faur** — B.Sc. Electrical and Electronics Engineering (Honors), Ruppin Academic Center

**Advisors:** Prof. Benny Salomon, Prof. Steve Brenner
