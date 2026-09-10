%% Recruitment Curves
% Ernesto Bedoy
% 28 October 2020
%
% Plots Recruitment Curves 

function max_P2P = RC(local_max, first, intensities,P2P_Tot)

%% Get unique channels identified as local maximums
iChan = local_max{first}; 
for intensity = first+1:length(intensities)
   iChan = [iChan; local_max{intensity}];
end
iChan = unique(iChan,'sorted');

%% Plot Recruitment Curves 
intensity_range = 1:length(intensities);
for iCh = 1:length(iChan)
    channel = iChan(iCh);
    figure1 = figure;
    axes1 = axes('Parent',figure1);
    hold(axes1,'on');
    for intensity = 1:length(intensities) % iterate through all stim intensities
        P2P(intensity,:) = P2P_Tot{intensity}(:,channel); % Obtain P2P values for specified channel
        plot(intensity,P2P(intensity,:),'-o','color','k','LineWidth',2) % Plot P2P values as open circles
        hold on
    end
    % fit a line through the mean P2P values for each intensity level
    f = fit(intensity_range',mean(P2P(intensity_range,:),2),'pchip');
    h = plot(f,'k'); set(h,'LineWidth',4); % plot fitted line
    hLeg = legend(); set(hLeg,'visible','off'); % do not display legend
    % label plot
    xlabel('Stimulation Intensity (mA)');
    set(gca,'xtick',[1:length(intensities)],'xticklabel',intensities)
    xlim([1 length(intensities)])
    ylabel('Peak-to-Peak (uV)');
    title(sprintf(['Recruitment Curve for Ch ', num2str(channel)]));
    set(gca,'fontweight','bold','fontsize',16)
    saveas(figure1,sprintf('RC%d.bmp',iCh)); 
    clear f h
    max_P2P(iCh) = max(mean(P2P(intensity_range,:),2));
end
