%% BAD_TRIALS_D1
% Identifies and removes poor-quality stimulation trials from
% single-differential (bipolar) HD-sEMG recordings based on waveform
% similarity across repeated trials.
%
% For each stimulation intensity and single-differential channel,
% trial-to-trial correlation coefficients are calculated from the M-wave
% waveforms. Correlations >= 0.75 and < 1 are considered high
% correlations. Trials that are poorly represented across more than half
% of the 56 single-differential channels are classified as bad trials and
% excluded from subsequent calculations.
%
% The function returns the retained trial indices and reconstructs the
% single-differential M-wave, H-reflex, and full-epoch datasets using only
% retained trials. Peak-to-peak M-wave amplitudes are recalculated after
% trial rejection.
%
% INPUTS:
%   setup                   - Structure containing analysis parameters,
%                             including the number of trials per intensity
%   num_stim_intensities    - Number of stimulation intensity levels
%   xSwp_Mwave_Tot_D1       - Single-differential M-wave epochs organized
%                             by stimulation intensity
%   Mwave_P2P_D1            - Original single-differential M-wave
%                             peak-to-peak values
%   xSwp_tot_Tot_D1         - Full stimulus-aligned single-differential epochs
%   xSwp_Hreflex_Tot_D1     - Single-differential H-reflex epochs
%
% OUTPUTS:
%   bad_trial_D1            - Trials excluded at each stimulation intensity
%   good_trials_D1          - Good-trial indices identified for each channel
%   number_good_D1          - Number of good trials for each channel/intensity
%   D1_P2P_Tot              - M-wave peak-to-peak values after trial rejection
%   xSwp_tot_Tot2_D1        - Full epochs containing retained trials only
%   xSwp_Mwave_Tot2_D1      - M-wave epochs containing retained trials only
%   good_trial              - Retained trial indices for each intensity
%   xSwp_Hreflex_Tot2_D1    - H-reflex epochs containing retained trials only
%
% NOTE:
%   Channel quality control is handled separately. This function removes
%   entire stimulation trials based on trial-to-trial waveform similarity.

function [bad_trial_D1, good_trials_D1, number_good_D1, D1_P2P_Tot, xSwp_tot_Tot2_D1, xSwp_Mwave_Tot2_D1, good_trial, xSwp_Hreflex_Tot2_D1] = bad_trials_D1(setup, num_stim_intensities, xSwp_Mwave_Tot_D1, Mwave_P2P_D1, xSwp_tot_Tot_D1, xSwp_Hreflex_Tot_D1);


%% Find Bad Trials by Correlation
for intensity = 1:num_stim_intensities
    current_x = xSwp_Mwave_Tot_D1{intensity};
    for iCh = 1:56
        corr_x= corrcoef(current_x(:,:,iCh)); % correlate trials
        matrix = zeros(setup.num_trials,setup.num_trials); % create empty matrix
        matrix(corr_x>=.75 & corr_x<1)=1; % put 1 in maxtrix where correlation is > .9 and < 1
        most_good = max(sum(matrix)); % find highest # of trials with high correlation 
        good_trials_D1{intensity,iCh} = find(sum(matrix)>=(most_good-1));
        number_good_D1(intensity, iCh) = sum((sum(matrix)>=(most_good-1))); % count # of good trials
        clear corr_x matrix most_good
    end
end
% save good_trials and number_good
Filename = sprintf('good_trials_D1');
save(Filename,'good_trials_D1')
Filename = sprintf('number_good_D1');
save(Filename,'number_good_D1')

temp=[];
bad_trial = [];
for intensity = 1:num_stim_intensities
    for iCh = 1:56
        temp = [temp good_trials_D1{intensity,iCh}];
    end
    for iTrial = 1:setup.num_trials
        if sum(temp==iTrial)/56 < .5 % if trial is bad for more than half of channels
            bad_trial= [bad_trial iTrial];
            
        end
    end
    bad_trial_all{intensity} = bad_trial;
    temp = [];
    bad_trial =[];
end

bad_trial_D1 = bad_trial_all;
Filename = sprintf('bad_trial_D1');
save(Filename,'bad_trial_D1')

for intensity = 1:num_stim_intensities
    good =1:setup.num_trials;
    good(bad_trial_D1{intensity})=[];
    good_trial{intensity} = good;
end

for intensity = 1:num_stim_intensities % iterate through intensities
    % obtain mean Peak-to-Peak over trials
    for iCh = 1:56 % iterate through channels
        D1_P2P_Tot{intensity}(:,iCh) = peak2peak(xSwp_Mwave_Tot_D1{intensity}(:,good_trial{intensity},iCh)); % obtain mean P2P       
        xSwp_tot_Tot2_D1{intensity}(:,:,iCh) = xSwp_tot_Tot_D1{intensity}(:,good_trial{intensity},iCh);
        xSwp_Mwave_Tot2_D1{intensity}(:,:,iCh) = xSwp_Mwave_Tot_D1{intensity}(:,good_trial{intensity},iCh);
        xSwp_Hreflex_Tot2_D1{intensity}(:,:,iCh) = xSwp_Hreflex_Tot_D1{intensity}(:,good_trial{intensity},iCh);
    end
end
