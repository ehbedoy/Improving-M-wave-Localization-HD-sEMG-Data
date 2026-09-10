Improving localization and measurements of M-waves using high-density surface electromyography

Overview

This project provides the high-density surface electromyography (HD-sEMG) dataset and associated MATLAB analysis code for the study:

“Improving localization and measurements of M-waves using high-density surface electromyography.”

The recordings were acquired from multiple HD-sEMG grids positioned over the forearm during electrical stimulation of the median, ulnar, and radial nerves. The dataset is provided to support reuse of the recordings and reproduction or extension of the analyses reported in the associated publication.

Data and Code Availability

The raw HD-sEMG dataset and associated recording metadata are archived on Zenodo. MATLAB code used to process and analyze the recordings is maintained in the associated GitHub repository.

Dataset: 10.5281/zenodo.22286228

Analysis code: https://github.com/ehbedoy/Improving-M-wave-Localization-HD-sEMG-Data

Participants

Data are provided for five deidentified participants, identified as:

* sub-01
* sub-02
* sub-03
* sub-04
* sub-05

Experimental Conditions

Peripheral nerve stimulation was performed separately for three nerves:

* Median nerve
* Ulnar nerve
* Radial nerve

Multiple HD-sEMG grids were used to record evoked responses from the forearm. Recordings were acquired at 4000 Hz using TMSi SAGA 64+ HD-sEMG grids arranged as an 8 × 8 array of 64 Ag/AgCl electrodes (4.5-mm electrode diameter; 8.75-mm interelectrode distance).

Data Organization

Data are organized first by participant, then by the peripheral nerve stimulated, and finally by HD-sEMG grid. 
Each grid folder contains the raw Poly5 recording and the corresponding stimulation-intensity and bad-channel metadata required by Main.

Example:

sub-01/
├── stim-median/
│   ├── grid-post-1/
│   │   ├── sub-01_stim-median_grid-post-1.poly5
│   │   ├── intensities.mat
│   │   └── bad_channels.mat
│   │
│   ├── grid-post-2/
│   │   ├── sub-01_stim-median_grid-post-2.poly5
│   │   ├── intensities.mat
│   │   └── bad_channels.mat
│   │
│   ├── grid-ant/
│   │   ├── sub-01_stim-median_grid-ant.poly5
│   │   ├── intensities.mat
│   │   └── bad_channels.mat
│   │
│   └── grid-ulnar/
│       ├── sub-01_stim-median_grid-ulnar.poly5
│       ├── intensities.mat
│       └── bad_channels.mat
│
├── stim-ulnar/
│   └── ...
│
└── stim-radial/
    └── ...

The same organization is used for median, ulnar, and radial nerve stimulation. The number of available grids may vary between participants and stimulation conditions.

Grid Naming

The grid labels used in the filenames indicate the approximate recording location:

* grid-ant — anterior grid
* grid-ulnar — ulnar-side grid
* grid-post-01 — posterior grid 1
* grid-post-02 — posterior grid 2

File Format

Raw HD-sEMG recordings are provided in TMSi Poly5 (.poly5) format.

The associated MATLAB analysis code reads these files using the TMSiSAGA.Poly5 interface. The sampling rate and channel information are obtained directly from the Poly5 recording.

The analysis identifies the HD-sEMG channels relative to the CREF channel and uses the STATUS channel to identify stimulation triggers.

Stimulation Intensity Information

Each stimulation intensity was repeated 10 times, with stimulation intensities presented in randomized order.

Each grid folder contains an intensities.mat file containing the stimulation intensity associated with each stimulation trial in acquisition order. The Main analysis script uses these values to group detected responses by stimulation intensity and generate M-wave recruitment curves.

Pairs of HD-sEMG grids recorded during the same stimulation sequence contain identical copies of the corresponding intensities.mat file. The file is duplicated so that all metadata required to analyze an individual Poly5 recording are contained within the same grid folder.

Analysis Pipeline

The MATLAB analysis pipeline performs the following major steps. Main performs the primary preprocessing and M-wave analysis and calls additional analysis functions as needed.

1. Read the raw TMSi Poly5 recording — Main
2. Identify the 64 HD-sEMG channels and stimulation trigger channel — Main
3. Detect individual stimulation events — Main
4. Remove the DC offset from the HD-sEMG signals — Main
5. Blank the stimulation artifact using linear interpolation from 2 ms before to 5 ms after stimulation — Main
6. Apply a 10-Hz high-pass Butterworth filter — Main
7. Generate monopolar, single-differential, and double-differential HD-sEMG signals — Main
   * Plot monopolar time series — Monopolar_Time_Series
   * Plot single-differential (bipolar) time series — Bipolar_Time_Series
   * Plot double-differential (tripolar) time series — Tripolar_Time_Series
8. Extract stimulus-aligned epochs for each trial — Main
9. Calculate M-wave RMS and peak-to-peak amplitude — Main
10. Organize trials and M-wave measurements by stimulation intensity — Main
11. Identify and remove poor-quality stimulation trials — bad_trials_mono, bad_trials_D1, and bad_trials_D2
12. Generate spatial maps of M-wave peak-to-peak amplitude and identify local response maxima — Heat_Map
13. Generate M-wave recruitment curves from channels identified from the spatial maps — Recruitment_Curves
14. Evaluate similarity of M-wave waveforms across recording channels — Correlation

The M-wave measurement window begins 5 ms after stimulation. In the published analysis, a 5–30 ms window was used for all monopolar recordings and for the spatially filtered recordings from Subject 1. A 5–16 ms window was used for the remaining spatially filtered recordings. Main prompts the user to select an M-wave window ending at either 16 or 30 ms.

Channel Quality Control

Channels identified as having excessive noise, artifacts, or no recorded signal during the published analysis were excluded from analysis. The channel exclusions used for each Poly5 recording are provided in the corresponding bad_channels.mat file.

Each bad_channels.mat file contains the variable bad_chan_mono, which specifies excluded channels using the original monopolar 64-channel HD-sEMG grid numbering. Main uses these monopolar exclusions to determine the corresponding affected single-differential and double-differential channels.

For heat-map visualization, values at excluded electrode locations were estimated from adjacent electrodes. These substitutions were used only for visualization.

Trial Quality Control

Poor-quality stimulation trials are identified separately from bad channels using bad_trials_mono, bad_trials_D1, and bad_trials_D2 for the monopolar, single-differential, and double-differential montages, respectively.

For each stimulation intensity and channel, the functions evaluate trial-to-trial M-wave waveform similarity using correlation. Trial pairs with correlation coefficients greater than or equal to 0.75 and less than 1 are treated as similar. A trial is excluded when it is classified as a retained trial in fewer than half of the channels within the corresponding montage.

Following trial rejection, M-wave measurements and time-series data are reconstructed using the retained trials.

Software Requirements

The analysis code was written in MATLAB.

Required software and toolboxes include:

* MATLAB
* TMSi SAGA Interface for MATLAB (TMSiSAGA) — required for reading the raw .poly5 recordings
* Signal Processing Toolbox — used for filtering, stimulation-event detection, RMS, peak-to-peak measurements, and signal-correlation analyses
* Image Processing Toolbox — used to identify regional maxima in the spatial M-wave maps
* Curve Fitting Toolbox — used for interpolation of recruitment curves
* Statistics and Machine Learning Toolbox — required by portions of the current analysis code using statistical functions

TMSi SAGA MATLAB Interface

The TMSi SAGA Interface for MATLAB is required to read the raw Poly5 recordings.

Download and installation information are available from the official TMSi MATLAB page:

https://www.tmsi.artinis.com/matlab

After downloading and installing the interface, ensure that it is available on the MATLAB path before running the analysis code.

For example: addpath(genpath('path_to_TMSi_SAGA_interface'))

Replace path_to_TMSi_SAGA_interface with the location of the installed or extracted TMSi SAGA MATLAB interface.

Main reads the selected Poly5 recording using: data = TMSiSAGA.Poly5.read(fullfile(file_path,file_name));

The official TMSi SAGA MATLAB interface is currently documented for 64-bit Windows systems.

Running the Analysis

1. Download or clone the analysis-code repository.
2. Add the analysis-code directory and TMSi SAGA MATLAB interface to the MATLAB path.
3. Run Main.m.
4. When prompted, select the .poly5 recording to be analyzed.
5. Main automatically loads intensities.mat and bad_channels.mat from the same folder as the selected Poly5 recording.
6. When prompted, select the appropriate M-wave end time (16 or 30 ms) for the recording being analyzed.

Main performs preprocessing, applies the recording-specific channel exclusions, identifies and removes poor-quality trials, calculates M-wave measurements, and calls the associated functions for time-series visualization, spatial heat maps, recruitment curves, and waveform-correlation analyses.

Related Publication

Bedoy, E. H., Guirola Diaz, E. A., Dalrymple, A. N., Levy, I., Hyatt, T., Griffin, D. M., Wittenberg, G. F., & Weber, D. J. (2025). Improving localization and measurements of M-waves using high-density surface electromyography. Journal of Neurophysiology, 133 (1), 299–309.

https://doi.org/10.1152/jn.00354.2024

Experimental Protocol

General experimental procedures and data collection methods are available through protocols.io:

https://doi.org/10.17504/protocols.io.261ger4xyl47/v1

Analysis Code

Analysis code and additional documentation are available at:

https://github.com/ehbedoy/Improving-M-wave-Localization-HD-sEMG-Data

Contact

Douglas J. Weber
Carnegie Mellon University
dougweber@cmu.edu
