%% BAD_TRIALS_MONO
% Identifies and removes poor-quality stimulation trials from monopolar
% HD-sEMG recordings based on waveform similarity across repeated trials.
%
% For each stimulation intensity and monopolar channel, trial-to-trial
% correlation coefficients are calculated from the M-wave waveforms.
% Correlations >= 0.75 and < 1 are considered high correlations. Trials
% that are poorly represented across more than half of the 64 channels are
% classified as bad trials and excluded from subsequent calculations.
%
% The function returns the retained trial indices and reconstructs the
% monopolar M-wave, H-reflex, and full-epoch datasets using only retained
% trials. Peak-to-peak M-wave amplitudes are recalculated after trial
% rejection.
%
% INPUTS:
%   setup                 - Structure containing analysis parameters,
%                           including the number of trials per intensity
%   num_stim_intensities  - Number of stimulation intensity levels
%   xSwp_Mwave_Tot        - M-wave epochs organized by stimulation intensity
%   Mwave_P2P             - Original monopolar M-wave peak-to-peak values
%   xSwp_tot_Tot          - Full stimulus-aligned monopolar epochs
%   xSwp_Hreflex_Tot      - H-reflex epochs organized by intensity
%
% OUTPUTS:
%   bad_trial_mono        - Trials excluded at each stimulation intensity
%   good_trials_mono      - Good-trial indices identified for each channel
%   number_good_mono      - Number of good trials for each channel/intensity
%   Mwave_P2P_Tot         - M-wave peak-to-peak values after trial rejection
%   xSwp_tot_Tot2         - Full epochs containing retained trials only
%   xSwp_Mwave_Tot2       - M-wave epochs containing retained trials only
%   good_trial            - Retained trial indices for each intensity
%   xSwp_Hreflex_Tot2     - H-reflex epochs containing retained trials only
%
% NOTE:
%   Channel quality control is handled separately. This function removes
%   entire stimulation trials based on trial-to-trial waveform similarity.

function [bad_trial_mono, good_trials_mono, number_good_mono, Mwave_P2P_Tot, xSwp_tot_Tot2, xSwp_Mwave_Tot2, good_trial, xSwp_Hreflex_Tot2] =bad_trials_mono(setup, num_stim_intensities, xSwp_Mwave_Tot, Mwave_P2P, xSwp_tot_Tot, xSwp_Hreflex_Tot)

%% Find Bad Trials by Correlation
for intensity = 1:num_stim_intensities
    current_x = xSwp_Mwave_Tot{intensity};
    for iCh = 1:64
        corr_x= corrcoef(current_x(:,:,iCh)); % correlate trials
        matrix = zeros(setup.num_trials,setup.num_trials); % create empty matrix
        matrix(corr_x>=.75 & corr_x<1)=1; % put 1 in maxtrix where correlation is > .9 and < 1
        most_good = max(sum(matrix)); % find highest # of trials with high correlation 
       % find trial # that has high correlation with at least half of the total # of trials
        good_trials_mono{intensity,iCh} = find(sum(matrix)>=(most_good-1));
        number_good_mono(intensity, iCh) = sum((sum(matrix)>=(most_good-1))); % count # of good trials
        clear corr_x matrix most_good
    end
end

%% Save good_trials and number_good
Filename = sprintf('good_trials_mono');
save(Filename,'good_trials_mono')
Filename = sprintf('number_good_mono');
save(Filename,'number_good_mono')

%% Finds Trials That are Bad for More Than Half of Channels
temp=[];
bad_trial = [];
for intensity = 1:num_stim_intensities
    for iCh = 1:64
        temp = [temp good_trials_mono{intensity,iCh}];
    end
    for iTrial = 1:setup.num_trials
        if sum(temp==iTrial)/64 < .5 
            bad_trial= [bad_trial iTrial];
            
        end
    end
    bad_trial_all{intensity} = bad_trial;
    temp = [];
    bad_trial =[];
end

bad_trial_mono = bad_trial_all;
Filename = sprintf('bad_trial_mono');
save(Filename,'bad_trial_mono')

%% Epoch Extraction with Good Trials
for intensity = 1:num_stim_intensities
    good =1:setup.num_trials;
    good(bad_trial_mono{intensity})=[];
    good_trial{intensity} = good;
end

for intensity = 1:num_stim_intensities % iterate through intensities
    for iCh = 1:64 % iterate through channels
        Mwave_P2P_Tot{intensity}(:,iCh) = peak2peak(xSwp_Mwave_Tot{intensity}(:,good_trial{intensity},iCh)); % obtain mean P2P       
        xSwp_tot_Tot2{intensity}(:,:,iCh) = xSwp_tot_Tot{intensity}(:,good_trial{intensity},iCh);
        xSwp_Mwave_Tot2{intensity}(:,:,iCh) = xSwp_Mwave_Tot{intensity}(:,good_trial{intensity},iCh);
        xSwp_Hreflex_Tot2{intensity}(:,:,iCh) = ...
        xSwp_Hreflex_Tot{intensity}(:,good_trial{intensity},iCh);
    end
end


