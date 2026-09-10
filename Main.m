%% Main Script for M-wave Analysis
% Ernesto Bedoy
% 27 October 2020
%
% Reads TMSi Poly5 HD-sEMG Data
% Pre-processes Data
% Applies Spatial Filters 
% Measures M-wave Amplitude
% Plots M-wave Time Series, Heat Maps, and Recruitment Curves
% Correlates M-waves across electrodes

%% Initialization and File Reading
clear all; close all
[file_name, file_path] = uigetfile('*.poly5', 'Select Poly5 recording');

if isequal(file_name,0)
    error('No Poly5 file selected.');
end

data = TMSiSAGA.Poly5.read(fullfile(file_path,file_name));

load(fullfile(file_path,'intensities.mat'),'intensities');
load(fullfile(file_path,'bad_channels.mat'),'bad_chan_mono');

bad_chan_mono = bad_chan_mono(:)';

%% Setup Parameters
setup.num_trials = 10; % number of trials
setup.num_chan = 64; % number of channels 
fs = data.sample_rate;  % sample rate

%% Identify Channels
for iCh = 1:length(data.channels)
    cref(iCh)= strcmpi(data.channels{1,iCh}.alternative_name, 'CREF');
    status(iCh)= strcmpi(data.channels{1,iCh}.alternative_name, 'STATUS');
end
ref_chan = find(cref == 1); % reference channel number
setup.trigger_chan = find(status == 1); % trigger time channel  
setup.grid_num = ref_chan+1:ref_chan+setup.num_chan; % HD-EMG channel numbers

%% Create Epochs File 
% time windows of interest relative to TMS trigger (in seconds)
epoch.dtPre_tot = -.100; epoch.dtPost_tot = .500; % Total epoch = 100 ms prestim to 500 ms poststim  
epoch.dtPre_base = -.050; epoch.dtPost_base = -.025; % Baseline epoch = 50 ms to 25 ms prestim
epoch.dtPre_blank = -0.002; epoch.dtPost_blank = .005; % Blanking epoch = 2 ms prestim to 5 ms poststim
epoch.dtPre_Mwave = .005; % M-wave epoch = 5 to 16/30 ms poststim
prompt = 'Input M-wave end time in milliseconds (options: 16 or 30): '; %input(prompt); % number of trials 
epoch.dtPost_Mwave = input(prompt)/1000;
epoch.dtPre_Hreflex = epoch.dtPost_Mwave; epoch.dtPost_Hreflex = 0.050; % H-reflex epoch = end of M-wave epoch to 50 ms poststim

%% Time Window
% convert to sample #
nPre_tot = ceil(epoch.dtPre_tot*fs); nPost_tot = ceil(epoch.dtPost_tot*fs);
nPre_base = ceil(epoch.dtPre_base*fs); nPost_base = ceil(epoch.dtPost_base*fs); 
nPre_Mwave = ceil(epoch.dtPre_Mwave*fs); nPost_Mwave = floor(epoch.dtPost_Mwave*fs);
nPre_blank = ceil(epoch.dtPre_blank*fs); nPost_blank = floor(epoch.dtPost_blank*fs);
nPre_Hreflex = ceil(epoch.dtPre_Hreflex*fs); nPost_Hreflex = floor(epoch.dtPost_Hreflex*fs);
% convert to time
tSwp_Tot = (nPre_tot:nPost_tot)/fs;
tSwp_Base = (nPre_base:nPost_base)/fs; 
tSwp_Mwave = (nPre_Mwave:nPost_Mwave)/fs; 
tSwp_Hreflex = (nPre_Hreflex:nPost_Hreflex)/fs; 

%% Data Processing
% Extract HD-EMG data and adjust by removing offset
x = data.samples(setup.grid_num, :)';
x_adjusted = x - mean(x);

% Trigger detection based on threshold
thresh = -1030;
[~,iTrig] = findpeaks(data.samples(setup.trigger_chan,:)*-1,'MinPeakHeight',thresh,'MinPeakDistance',2800);

%% Generate Stimulation Intensity Order 
num_stim_intensities = length(iTrig)/setup.num_trials; % number of stim intensities
[~, intensity_index] = sort(intensities,'ascend'); % obtain order index
stim_order = zeros(1,length(iTrig)); % create stim order variable set to 0
k = 1; % initialize k
for j = 1:(num_stim_intensities) % itereate through all stim intensities
    for i = 1:setup.num_trials % iterate through all trials
        stim_order(intensity_index(k)) = j; % places sequential value in order of index
        k = k + 1; % increment k sequentially
    end
end

%% Blank Artifact
x_blank = x_adjusted;
for iRep = 1:length(iTrig)
    idx = iTrig(iRep);
    blank_end = diff([(idx+nPre_blank) (idx+nPost_blank)]) + 1; % get ending index for blanking window
    x_blank(idx+nPre_blank:idx+nPost_blank,:) = interp1([1 blank_end],x_blank([idx+nPre_blank idx+nPost_blank],:),1:blank_end,'linear');  
end

%% Apply High-Pass Filter 
fcl = 10/(fs/2); % 10 Hz cut off
[b,a] = butter(1, fcl,'high'); % high pass filter
filtsig = filtfilt(b,a,x_blank); % filter signal 

%% Derive Bad Spatially Filtered Channels

bad_chan_D1 = [];

for row = 0:7
    for col = 1:7

        d1_ch = row*7 + col;
        mono_ch = row*8 + [col col+1];

        if any(ismember(mono_ch,bad_chan_mono))
            bad_chan_D1(end+1) = d1_ch;
        end

    end
end

bad_chan_D2 = [];

for row = 0:7
    for col = 1:6

        d2_ch = row*6 + col;
        mono_ch = row*8 + [col col+1 col+2];

        if any(ismember(mono_ch,bad_chan_mono))
            bad_chan_D2(end+1) = d2_ch;
        end

    end
end

%% Single Differential Calculation
filtD1 = diff(filtsig, 1, 2);
filtD1(:, 8:8:end) = []; % Remove last row in longitudinal orientation

%% Double Differential Calculation
filtD2 = diff(filtD1, 1, 2);
filtD2(:, 7:7:end) = []; % Remove last row in longitudinal orientation

%% Epoch Extraction for the Monopolar Montage
iStart = 1; % first trial
iFin = length(iTrig); % last trial
for iRep = iStart:iFin %iterate through all trials
    idx = iTrig(iRep);
    Base_RMS(iRep,:) = rms(filtsig(idx+nPre_base:idx+nPost_base,:)); % Baseline RMG
    Mwave_RMS(iRep,:) = rms(filtsig(idx+nPre_Mwave:idx+nPost_Mwave,:)); % M-wave RMS
    Mwave_P2P(iRep,:) = peak2peak(filtsig(idx+nPre_Mwave:idx+nPost_Mwave,:)); % M-wave P2P
    xSwp_tot(:,iRep,:) = filtsig(idx+nPre_tot:idx+nPost_tot,:); % Filtered EMG of total epoch
    xSwp_Base(:,iRep,:) = filtsig(idx+nPre_base:idx+nPost_base,:); % Filtered EMG of baseline epoch
    xSwp_Mwave(:,iRep,:) = filtsig(idx+nPre_Mwave:idx+nPost_Mwave,:); % Filtered EMG of M-wave epoch
    xSwp_Hreflex(:,iRep,:) = filtsig(idx+nPre_Hreflex:idx+nPost_Hreflex,:); % Filtered EMG of H-reflex epoc
end
%% Organize Data by Intensity
for intensity= 1:num_stim_intensities % iterate through all intensity levels
    iStim = find(stim_order == intensity);
    xSwp_tot_Tot{intensity} = xSwp_tot(:,iStim,:); %,[length(tSwp_Tot)*setup.num_trials,setup.num_trials, setup.num_chan];
    xSwp_Base_Tot{intensity} = xSwp_Base(:,iStim,:);% ,[length(tSwp_Base)*setup.num_trials,setup.num_trials, setup.num_chan];
    xSwp_Mwave_Tot{intensity} = xSwp_Mwave(:,iStim,:); %,[length(tSwp_Mwave)*setup.num_trials,setup.num_trials, setup.num_chan];
    xSwp_Hreflex_Tot{intensity} = xSwp_Hreflex(:,iStim,:); %,[length(tSwp_Hreflex)*setup.num_trials,setup.num_trials, setup.num_chan];
end

%% Remove Bad Trials
[bad_trial_mono, good_trials_mono, number_good_mono, Mwave_P2P_Tot, xSwp_tot_Tot2, xSwp_Mwave_Tot2, mono_good_trial_tot, xSwp_Hreflex_Tot2] = bad_trials_mono(setup, num_stim_intensities, xSwp_Mwave_Tot, Mwave_P2P, xSwp_tot_Tot, xSwp_Hreflex_Tot);
Filename = sprintf('mono_good_trial_tot'); save(Filename,'mono_good_trial_tot');        
Filename = sprintf('Mwave_P2P_Tot'); save(Filename,'Mwave_P2P_Tot')

%% Epoch Extraction for the Bipolar Montage
iStart = 1; % first trial
iFin = length(iTrig); % last trial
for iRep = iStart:iFin %iterate through all trials
    idx = iTrig(iRep);
    Base_RMS_D1(iRep,:) = rms(filtD1(idx+nPre_base:idx+nPost_base,:)); % Baseline RMG
    Mwave_RMS_D1(iRep,:) = rms(filtD1(idx+nPre_Mwave:idx+nPost_Mwave,:)); % M-wave RMS
    Mwave_P2P_D1(iRep,:) = peak2peak(filtD1(idx+nPre_Mwave:idx+nPost_Mwave,:)); % M-wave P2P
    xSwp_tot_D1(:,iRep,:) = filtD1(idx+nPre_tot:idx+nPost_tot,:); % Filtered EMG of total epoch
    xSwp_Base_D1(:,iRep,:) = filtD1(idx+nPre_base:idx+nPost_base,:); % Filtered EMG of baseline epoch
    xSwp_Mwave_D1(:,iRep,:) = filtD1(idx+nPre_Mwave:idx+nPost_Mwave,:); % Filtered EMG of M-wave epoch
    xSwp_Hreflex_D1(:,iRep,:) = filtD1(idx+nPre_Hreflex:idx+nPost_Hreflex,:); % Filtered EMG of H-reflex epoc
end
for intensity= 1:num_stim_intensities % iterate through all intensity levels
    iStim = find(stim_order == intensity);
        xSwp_tot_Tot_D1{intensity} = xSwp_tot_D1(:,iStim,:); %,[length(tSwp_Tot)*setup.num_trials,setup.num_trials, setup.num_chan];
        xSwp_Base_Tot_D1{intensity} = xSwp_Base_D1(:,iStim,:);% ,[length(tSwp_Base)*setup.num_trials,setup.num_trials, setup.num_chan];
        xSwp_Mwave_Tot_D1{intensity} = xSwp_Mwave_D1(:,iStim,:); %,[length(tSwp_Mwave)*setup.num_trials,setup.num_trials, setup.num_chan];
        xSwp_Hreflex_Tot_D1{intensity} = xSwp_Hreflex_D1(:,iStim,:); %,[length(tSwp_Hreflex)*setup.num_trials,setup.num_trials, setup.num_chan];
end
% Remove bad trials
[bad_trial_D1, good_trials_D1, number_good_D1, D1_P2P_Tot, xSwp_tot_Tot2_D1, xSwp_Mwave_Tot2_D1, D1_good_trial_tot, xSwp_Hreflex_Tot2_D1] = bad_trials_D1(setup, num_stim_intensities, xSwp_Mwave_Tot_D1, Mwave_P2P_D1, xSwp_tot_Tot_D1, xSwp_Hreflex_Tot_D1);
Filename = sprintf('D1_good_trial_tot'); save(Filename,'D1_good_trial_tot');   
Filename = sprintf('D1_P2P_Tot'); save(Filename,'D1_P2P_Tot')

%% Epoch Extraction for the Tripolar Montage
iStart = 1; % first trial
iFin = length(iTrig); % last trial
for iRep = iStart:iFin %iterate through all trials
    idx = iTrig(iRep);
    xSwp_tot_D2(:,iRep,:) = filtD2(idx+nPre_tot:idx+nPost_tot,:); % Filtered EMG of total epoch
    xSwp_Base_D2(:,iRep,:) = filtD2(idx+nPre_base:idx+nPost_base,:); % Filtered EMG of baseline epoch
    xSwp_Mwave_D2(:,iRep,:) = filtD2(idx+nPre_Mwave:idx+nPost_Mwave,:); % Filtered EMG of M-wave epoch
    xSwp_Hreflex_D2(:,iRep,:) = filtD2(idx+nPre_Hreflex:idx+nPost_Hreflex,:); % Filtered EMG of H-reflex epoc
end
for intensity= 1:num_stim_intensities % iterate through all intensity levels
    iStim = find(stim_order == intensity);
    xSwp_tot_Tot_D2{intensity} = xSwp_tot_D2(:,iStim,:); %,[length(tSwp_Tot)*setup.num_trials,setup.num_trials, setup.num_chan];
    xSwp_Base_Tot_D2{intensity} = xSwp_Base_D2(:,iStim,:);% ,[length(tSwp_Base)*setup.num_trials,setup.num_trials, setup.num_chan];
    xSwp_Mwave_Tot_D2{intensity} = xSwp_Mwave_D2(:,iStim,:); %,[length(tSwp_Mwave)*setup.num_trials,setup.num_trials, setup.num_chan];
    xSwp_Hreflex_Tot_D2{intensity} = xSwp_Hreflex_D2(:,iStim,:); %,[length(tSwp_Hreflex)*setup.num_trials,setup.num_trials, setup.num_chan];
end

%% Remove Bad Trials
[bad_trial_D2, good_trials_D2, number_good_D2, D2_P2P_Tot, xSwp_tot_Tot2_D2, xSwp_Mwave_Tot2_D2, D2_good_trial_tot, xSwp_Hreflex_Tot2_D2, D2_P2P_Tot_Hreflex, D2_RMS_Mwave, D2_RMS_Hreflex, D2_RMS_Base] = bad_trials_D2(setup, num_stim_intensities, xSwp_Mwave_Tot_D2, xSwp_tot_Tot_D2, xSwp_Hreflex_Tot_D2, xSwp_Base_Tot_D2);
Filename = sprintf('D2_good_trial_tot'); save(Filename,'D2_good_trial_tot');  
Filename = sprintf('D2_P2P_Tot'); save(Filename,'D2_P2P_Tot')
Filename = sprintf('D2_P2P_Tot_Hreflex'); save(Filename,'D2_P2P_Tot_Hreflex'); 
Filename = sprintf('D2_RMS_Base'); save(Filename,'D2_RMS_Base'); 

%% Plot Time Series 
window = [0 epoch.dtPost_Hreflex*1000]; % time window to plot (stim is at 0 ms)
intensities=unique(intensities);

%% Give Bad Channels 0 Value
if exist('bad_chan_mono','var')
    for intensity = 1:length(intensities)
        temp = xSwp_Mwave_Tot2{intensity};
        for iCh = bad_chan_mono
            for iRep = 1:size(temp,2) % iterate through all trials
                xSwp_Mwave_Tot2{intensity}(:,iRep,iCh) = zeros(length(tSwp_Mwave),1);
                xSwp_Hreflex_Tot2{intensity}(:,iRep,iCh) = zeros(length(tSwp_Hreflex),1);
                xSwp_tot_Tot2{intensity}(:,iRep,iCh) = zeros(length(tSwp_Tot),1);
            end
        end
    end
end
if exist('bad_chan_D1','var')
    for intensity = 1:length(intensities)
    temp = xSwp_Mwave_Tot2_D1{intensity};
        for iCh = bad_chan_D1 
            for iRep = 1:size(temp,2)  % iterate through all trials
                xSwp_Mwave_Tot2_D1{intensity}(:,iRep,iCh) = zeros(length(tSwp_Mwave),1);
                xSwp_Hreflex_Tot2_D1{intensity}(:,iRep,iCh) = zeros(length(tSwp_Hreflex),1);
                xSwp_tot_Tot2_D1{intensity}(:,iRep,iCh) = zeros(length(tSwp_Tot),1);
            end
        end
    end
end
if exist('bad_chan_D2','var')
    for intensity = 1:length(intensities)
        temp = xSwp_Mwave_Tot2_D2{intensity};
        for iCh = bad_chan_D2 
            for iRep = 1:size(temp,2)  % iterate through all trials
                xSwp_Mwave_Tot2_D2{intensity}(:,iRep,iCh) = zeros(length(tSwp_Mwave),1);
                xSwp_Hreflex_Tot2_D2{intensity}(:,iRep,iCh) = zeros(length(tSwp_Hreflex),1);
                xSwp_tot_Tot2_D2{intensity}(:,iRep,iCh) = zeros(length(tSwp_Tot),1);
            end
        end
    end
end

%% Plot Time Series
% Monopolar Time Series
x_lin = [epoch.dtPre_Mwave*1000 epoch.dtPost_Mwave*1000];
Monopolar_Time_Series(window, intensities, num_stim_intensities, xSwp_Mwave_Tot2, xSwp_Hreflex_Tot2, tSwp_Tot, xSwp_tot_Tot2,x_lin)
close all

% Bipolar Time Series
Bipolar_Time_Series(window, intensities, num_stim_intensities, xSwp_Mwave_Tot2_D1, xSwp_Hreflex_Tot2_D1, tSwp_Tot, xSwp_tot_Tot2_D1, x_lin);
close all

% Tripolar Time Series
Tripolar_Time_Series(window, intensities, num_stim_intensities, xSwp_Mwave_Tot2_D2, xSwp_Hreflex_Tot2_D2, tSwp_Tot, xSwp_tot_Tot2_D2, x_lin);
close all

%% Plot Heat Maps
mono_local_max = Heat_Map(setup.num_chan, intensities, num_stim_intensities, Mwave_P2P_Tot, bad_chan_mono);
close all  
Filename = sprintf('mono_local_max'); save(Filename,'mono_local_max')

D1_local_max = Heat_Map(setup.num_chan-8, intensities, num_stim_intensities, D1_P2P_Tot, bad_chan_D1);
close all  
Filename = sprintf('D1_local_max'); save(Filename,'D1_local_max')

D2_local_max = Heat_Map(setup.num_chan-16, intensities, num_stim_intensities, D2_P2P_Tot, bad_chan_D2);
close all  
Filename = sprintf('D2_local_max'); save(Filename,'D2_local_max')

%% Plot Recruitment Curves

first = 1;
RC_Mwave = Recruitment_Curves(D2_local_max, first, intensities, D2_P2P_Tot);
close all
Filename = sprintf('RC_Mwave'); 
save(Filename,'RC_Mwave') % save RC max amplitudes

%% Correlate M-waves

% Monopolar
[high_corr_mono, corr_x_mono] = Correlation(setup.num_chan, xSwp_Mwave_Tot2, num_stim_intensities);
Filename = sprintf('corr_x_mono'); save(Filename,'corr_x_mono');
Filename = sprintf('high_corr_mono'); save(Filename,'high_corr_mono');

% Bipolar
[high_corr_D1, corr_x_D1] = Correlation(setup.num_chan-8, xSwp_Mwave_Tot2_D1, num_stim_intensities);
Filename = sprintf('corr_x_D1'); save(Filename,'corr_x_D1');
Filename = sprintf('high_corr_D1'); save(Filename,'high_corr_D1');

% Tripolar
[high_corr_D2, corr_x_D2] = Correlation(setup.num_chan-16, xSwp_Mwave_Tot2_D2, num_stim_intensities);
Filename = sprintf('corr_x_D2'); save(Filename,'corr_x_D2');
Filename = sprintf('high_corr_D2'); save(Filename,'high_corr_D2');


