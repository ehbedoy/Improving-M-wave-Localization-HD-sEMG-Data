%% M-wave Correlation
% Ernesto Bedoy
% 27 October 2020
%
% Correlate M-waves

function [high_corr, corr_x] = Correlation(num_chan, xSwp_Mwave_Tot, num_stim_intensities)

%% Find M-wave correlations 
for intensity = 1:num_stim_intensities
    current_x = permute(xSwp_Mwave_Tot{intensity}, [1 3 2]);
    for iTrial =1:size(current_x,3)
        corr_x{intensity,iTrial} = corrcoef(current_x(:,:,iTrial)); % correlate channels
        matrix = zeros(num_chan,num_chan); % create empty matrix
        matrix(corr_x{intensity,iTrial}>=.9 & corr_x{intensity,iTrial}<1)=1; % put 1 in maxtrix where correlation is > .9 and < 1
        high_corr{intensity,iTrial} = matrix;
    end
    clear current_x
end
