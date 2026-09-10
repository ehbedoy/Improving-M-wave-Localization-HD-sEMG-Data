%% Monopolar Time Series Plot
% Ernesto Bedoy
% 27 October 2020
%
% Plots Monopolar Times Series 

function Monopolar_Time_Plot(window, intensities, num_stim_intensities, xSwp_Mwave_Tot2, xSwp_Hreflex_Tot2, tSwp_Tot, xSwp_tot_Tot2,x_lin)

%% Plot M-wave Time Series
nRows = 8; % number of rows (medial-laterally)
nCols = 8; % number of columns (proximal-distally)
for intensity = 1:num_stim_intensities % iterate through intensities
    iCh = 1; % initialize channel number to read
    figure1 = figure('units','normalized','outerposition',[0 0 1 1]);
    axes1 = axes('Parent',figure1);
    hold(axes1,'on');
    ymax1 = round(max(squeeze(max(squeeze(max(xSwp_Mwave_Tot2{intensity})))))); % get most negative peak value
    ymin1 = round(min(squeeze(min(squeeze(min(xSwp_Mwave_Tot2{intensity})))))); % get most positive peak value
    ymax2 = round(max(squeeze(max(squeeze(max(xSwp_Hreflex_Tot2{intensity})))))); % get most negative peak value
    ymin2 = round(min(squeeze(min(squeeze(min(xSwp_Hreflex_Tot2{intensity})))))); % get most positive peak value
    ymax = max([ymax1 ymax2]);
    ymin = min([ymin1 ymin2]);
    ymax = round(ymax + ymax*.20); % add 20% cushion
    ymin = round(ymin + ymin*.20,-1); % add 20% cushion
    xPlot = 1; % initialize channel number to plot in x-axis of grid
    yPlot = 0; % initialize channel number to plot in y-axis of grid
    for iRow = 1:nRows % iterate through rows
        for iCol = 1:nCols % iterate through columns
            iPlot = 8*xPlot-yPlot; % channel position to plot
            hAx = subplot(nCols, nRows, iPlot);
            plot(tSwp_Tot*1000, xSwp_tot_Tot2{intensity}(:,:,iCh),'LineWidth',2,'color','k');
            set(gca,'Visible','off'); % remove axis from plot
            ylim([ymin ymax]); % limit y-axis to max amplitude M-wave + 20% cushion
            xlim([window(1) window(2)]); % limits for x-axis 
            xline(x_lin,'r','linewidth',2);
            xPlot = xPlot+1; % iterate along x-axis of grid (medial-laterally)
            iCh = iCh + 1; % iterate channel to read
        end
        yPlot = yPlot+1; % iterate along the y-axis of grid (proximal-distaly)l
        xPlot = 1;
    end
    intensity_value = intensities(intensity); % Get stim intensity value
    sgtitle({['Monopolar Time Series at ' num2str(intensity_value) ' mA'] ['(' num2str(window(1)) ' to ' num2str(window(2)) ' ms)']},'fontweight','bold','FontSize',20);
    saveas(figure1,sprintf('Mono_TimeSeries%d.bmp',intensity)); 
    saveas(figure1,sprintf('Mono_TimeSeries%d.fig',intensity)); 
    saveas(figure1,sprintf('Mono_TimeSeries%d.svg',intensity)); 
end
