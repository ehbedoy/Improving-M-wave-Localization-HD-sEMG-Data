%% Heat Map
% Ernesto Bedoy
% 27 October 2020
%
% Plots Heat Maps of Peak-to-Peak Values

function local_max = Heat_Map(num_chan, intensities, num_stim_intensities, P2P, bad_chan)

%% Get Peak-to-Peak Values
if ~isempty(bad_chan)
    for intensity = 1:length(intensities)
        for iBad = 1:length(bad_chan) % assign double differential channel # 
            iCh = bad_chan(iBad);
            temp = P2P{intensity};
            for iRep = 1:size(temp,1) % iterate through all trials
                if any(iCh == 1:num_chan/8) % first column
                   temp2 = P2P{intensity}(iRep,iCh+num_chan/8); temp1 = temp2;
                  %temp2 = 0; temp1 = nan;
                  %temp2 = 0; temp1 = 0;
                elseif any(iCh == num_chan-(num_chan/8)+1:num_chan) % last column
                      temp1 = P2P{intensity}(iRep,iCh-num_chan/8); temp2 = temp1;
                  %temp2 = 0; temp1 = nan;
                 %temp2 = 0; temp1 = 0;
                    % elseif any(iCh == [42 47])
                    % temp1 = D2_P2P_Tot{}(iRep,iCh-1); temp2 = temp1;
                    %elseif any(iCh == 48)
                    %temp1 = D2_P2P_Tot{intensity}(iRep,iCh-2); temp2 = temp1;
                else % remaining columns
                    temp1 = P2P{intensity}(iRep,iCh-num_chan/8);
                    temp2 = P2P{intensity}(iRep,iCh+num_chan/8);
                    %temp2 = 0; temp1 = nan;  
                   %temp2 = 0; temp1 = 0;
                end
                P2P{intensity}(iRep,iCh) = mean([temp1 temp2]);
            end
        end
    end
end

%% Plot Heat Maps
for intensity = 1:num_stim_intensities % iterate through intensities
    % obtain mean Peak-to-Peak over trials
    for iCh = 1:num_chan % iterate through channels
        mean_P2P(iCh) = nanmean(P2P{intensity}(:,iCh));
    end
    mean_P2P = mean_P2P./max(mean_P2P); % normalize
    % reshape to match bipolar configuration on grid (7x8)
    grid = reshape(mean_P2P,[num_chan/8,8]);
    % flip to match orientation on grid
    grid_flip = fliplr(grid);
    grid_flip = flipud(grid_flip);
    figure1 = figure;
    % Create axes
    axes1 = axes('Parent',figure1); hold(axes1,'on');
    [C,h] = contourf(grid_flip,'ShowText','off','linewidth',4);
    caxis([0,1]) % comment out
    hold on
    % place dot at the centers of electrode pairs used in bipolar differential
    for j = 1:8 % iterate across x-axis
        for i = 1:num_chan/8 % iterate along y-axis
            scatter(j,i,'k','filled')
        end
    end
    box(axes1,'on');
    axis(axes1,'tight');
    % Set the remaining axes properties
    set(axes1,'BoxStyle','full','Layer','top','YTick',[1:num_chan/8]);
    intensity_value = intensities(intensity); % Get stim intensity value
    sgtitle({['Peak-to-Peak Contour Map (' num2str(intensity_value) ' mA)']},'fontweight','bold','FontSize',15);
    grid(isnan(grid)) = 0;
    set(gca,'xtick',[])
    set(gca,'xticklabel',[])
    set(gca,'ytick',[])
    set(gca,'yticklabel',[])
    h2 = colorbar
    clabel(C,h,'FontWeight','bold')
    colorbar( 'off' ) 
   if num_chan == 64
        saveas(figure1,sprintf('Mono_HeatMap%d.bmp',intensity));
        saveas(figure1,sprintf('Mono_HeatMap%d.fig',intensity));
        saveas(figure1,sprintf('Mono_HeatMap%d.svg',intensity));
    elseif num_chan == 56
        saveas(figure1,sprintf('D1_HeatMap%d.bmp',intensity));
        saveas(figure1,sprintf('D1_HeatMap%d.fig',intensity));
        saveas(figure1,sprintf('D1_HeatMap%d.svg',intensity));
    elseif num_chan == 48
            saveas(figure1,sprintf('D2_HeatMap%d.jpg',intensity));
            saveas(figure1,sprintf('D2_HeatMap%d.fig',intensity));
            saveas(figure1,sprintf('D2_HeatMap%d.svg',intensity));

    end
    local_max{intensity} = find(imregionalmax(grid)); % Obtain local maximums
end
