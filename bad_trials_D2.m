%% BAD_TRIALS_D2
% Identifies and removes poor-quality stimulation trials from
% double-differential (tripolar) HD-sEMG recordings based on waveform
% similarity across repeated trials.
%
% For each stimulation intensity and double-differential channel,
% trial-to-trial correlation coefficients are calculated from the M-wave
% waveforms. Correlations >= 0.75 and < 1 are considered high
% correlations. Trials that are poorly represented across more than half
% of the 48 double-differential channels are classified as bad trials and
% excluded from subsequent calculations.
%
% The function returns the retained trial indices and reconstructs the
% double-differential M-wave, H-reflex, baseline, and full-epoch datasets
% using only retained trials. Peak-to-peak and RMS measurements are
% recalculated after trial rejection.
%
% INPUTS:
%   setup                   - Structure containing analysis parameters,
%                             including the number of trials per intensity
%   num_stim_intensities    - Number of stimulation intensity levels
%   xSwp_Mwave_Tot_D2       - Double-differential M-wave epochs organized
%                             by stimulation intensity
%   xSwp_tot_Tot_D2         - Full stimulus-aligned double-differential epochs
%   xSwp_Hreflex_Tot_D2     - Double-differential H-reflex epochs
%   xSwp_Base_Tot_D2        - Double-differential baseline epochs
%
% OUTPUTS:
%   bad_trial_D2            - Trials excluded at each stimulation intensity
%   good_trials_D2          - Good-trial indices identified for each channel
%   number_good_D2          - Number of good trials for each channel/intensity
%   D2_P2P_Tot              - M-wave peak-to-peak values after trial rejection
%   xSwp_tot_Tot2_D2        - Full epochs containing retained trials only
%   xSwp_Mwave_Tot2_D2      - M-wave epochs containing retained trials only
%   good_trial              - Retained trial indices for each intensity
%   xSwp_Hreflex_Tot2_D2    - H-reflex epochs containing retained trials only
%   D2_P2P_Tot_Hreflex      - H-reflex peak-to-peak values
%   D2_RMS_Mwave            - M-wave RMS values
%   D2_RMS_Hreflex          - H-reflex RMS values
%   D2_RMS_Base             - Baseline RMS values
%
% NOTE:
%   Channel quality control is handled separately. This function removes
%   entire stimulation trials based on trial-to-trial waveform similarity.

function [bad_trial_D2, good_trials_D2, number_good_D2, D2_P2P_Tot, xSwp_tot_Tot2_D2, xSwp_Mwave_Tot2_D2, good_trial, xSwp_Hreflex_Tot2_D2, D2_P2P_Tot_Hreflex, D2_RMS_Mwave, D2_RMS_Hreflex, D2_RMS_Base] = bad_trials_D2(setup, num_stim_intensities, xSwp_Mwave_Tot_D2, xSwp_tot_Tot_D2, xSwp_Hreflex_Tot_D2, xSwp_Base_Tot_D2)
        
%% Find Bad Trials by Correlation
for intensity = 1:num_stim_intensities
    current_x = xSwp_Mwave_Tot_D2{intensity};
    for iCh = 1:48
        corr_x= corrcoef(current_x(:,:,iCh)); % correlate trials
        matrix = zeros(setup.num_trials,setup.num_trials); % create empty matrix
        matrix(corr_x>=.75 & corr_x<1)=1; % put 1 in maxtrix where correlation is > .9 and < 1
        most_good = max(sum(matrix)); % find # of trials the trial with the highest # of high correlations has
        good_trials_D2{intensity,iCh} = find(sum(matrix)>=(most_good-1)); % identify good trials
        number_good_D2(intensity, iCh) = sum((sum(matrix)>=(most_good-1))); % count # of good trials
        clear corr_x matrix most_good
    end
end
% save good_trials and number_good
Filename = sprintf('good_trials_D2');
save(Filename,'good_trials_D2')
Filename = sprintf('number_good_D2');
save(Filename,'number_good_D2')

temp=[];
bad_trial = [];
for intensity = 1:num_stim_intensities
    for iCh = 1:48
        temp = [temp good_trials_D2{intensity,iCh}];
    end
    for iTrial = 1:setup.num_trials
        if sum(temp==iTrial)/48 < .5
            bad_trial= [bad_trial iTrial];
            
        end
    end
    bad_trial_all{intensity} = bad_trial;
    temp = [];
    bad_trial =[];
end

bad_trial_D2 = bad_trial_all;
Filename = sprintf('bad_trial_D2');
save(Filename,'bad_trial_D2')

for intensity = 1:num_stim_intensities
    good =1:setup.num_trials;
    good(bad_trial_D2{intensity})=[];
    good_trial{intensity} = good;
end

for intensity = 1:num_stim_intensities % iterate through intensities
    % obtain mean Peak-to-Peak over trials
    for iCh = 1:48 % iterate through channels
        D2_P2P_Tot{intensity}(:,iCh) = peak2peak(xSwp_Mwave_Tot_D2{intensity}(:,good_trial{intensity},iCh)); % obtain mean P2P
        D2_P2P_Tot_Hreflex{intensity}(:,iCh) = peak2peak(xSwp_Hreflex_Tot_D2{intensity}(:,good_trial{intensity},iCh)); % obtain mean P2P
        D2_RMS_Mwave{intensity}(:,iCh) = rms(xSwp_Mwave_Tot_D2{intensity}(:,good_trial{intensity},iCh)); % obtain mean P2P
        D2_RMS_Hreflex{intensity}(:,iCh) = rms(xSwp_Hreflex_Tot_D2{intensity}(:,good_trial{intensity},iCh)); % obtain mean P2P
        D2_RMS_Base{intensity}(:,iCh) = rms(xSwp_Base_Tot_D2{intensity}(:,good_trial{intensity},iCh)); % obtain mean P2P 
        xSwp_tot_Tot2_D2{intensity}(:,:,iCh) = xSwp_tot_Tot_D2{intensity}(:,good_trial{intensity},iCh);
        xSwp_Mwave_Tot2_D2{intensity}(:,:,iCh) = xSwp_Mwave_Tot_D2{intensity}(:,good_trial{intensity},iCh);
        xSwp_Hreflex_Tot2_D2{intensity}(:,:,iCh) = xSwp_Hreflex_Tot_D2{intensity}(:,good_trial{intensity},iCh);
    end
end
