% setup data parameters
durations = [5 15];
days = 7;

dir_plots = 'P:\HR_Pilot_Research\plots\';
pilotChannels = {{'p1_1'}, {'p2_2', 'p2_3', 'p2_4'}};
pilotMouseSeqs = {["Pilot1-1"], ["Pilot2-2" "Pilot2-3" "Pilot2-4"]};
sex_seqs      = {["M"], ["M" "M" "M" "M"]};
highlightDates1 = datetime({'20221219', '20230116', '20230208'}, 'InputFormat', 'yyyyMMdd');
highlightDates2 = datetime({'20230509', '20230523', '20230607', '20230705'}, 'InputFormat', 'yyyyMMdd');
pilotHighlightDates = {highlightDates1; highlightDates2};
pilotGATimes = {[8.5 11.5 11.5]; [12 9 14 16]};
hrv_types = {'hrv_time', 'hrv_freq'};

% table to store model parameters i.e. Mesor, amplitude, phase,
variableNames = {'GA', 'Mouse', 'Sex', 'State', 'Metric', 'Amplitude', 'FRP', 'Acrophase', 'Mesor', 'PhaseShift', 'Duration', 'CI_Amplitude_Min', 'CI_FRP_Min', 'CI_Mesor_Min', 'CI_PhaseShift_Min', 'CI_Amplitude_Max', 'CI_FRP_Max', 'CI_Mesor_Max', 'CI_PhaseShift_Max', 'F_Stat', 'P_Value', 'CT', 'Data_Confidence'};
variableTypes = {'string', 'string', 'string', 'string', 'string', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double'};
dir_cosinor = 'P:\HR_Pilot_Research\';

for pilot_seq = 1:length(pilotChannels)
    channel_nums = pilotChannels{pilot_seq};
    sex_seq = sex_seqs{pilot_seq};
    highlightDates = pilotHighlightDates{pilot_seq};
    ga_times = pilotGATimes{pilot_seq};
    mouse_seq = pilotMouseSeqs{pilot_seq};
    T_cosinor = table('Size', [0 length(variableTypes)], 'VariableNames', variableNames, 'VariableTypes',  variableTypes);

    for c_seq=1:length(channel_nums)
        for h_seq=1:length(highlightDates)
            for type_seq=1:length(hrv_types)
                for d_seq=1:length(durations)
    
                    duration = durations(d_seq);
                    dir_hrv_time = strcat('P:\HR_Pilot_Research\', hrv_types{type_seq}, '\');
                    channel_num = channel_nums{c_seq};
                    dateRange = highlightDates(h_seq) + (-1*days:days+2);
                    startDate = highlightDates(h_seq) - days;
                    endDate = highlightDates(h_seq) + 10; % add by 10 since the calculation of after effect is started on day 3 to 9
                    hrv_table = readtable(strcat(dir_hrv_time, channel_num, '\',num2str(duration), 'minutes-aligned-new.csv'));
                    
                    % Define the columns to plot (columns 3 to 8)
                    numCols = width(hrv_table);
                    
                    for col = 1:numCols
                        
                        if isnumeric(hrv_table{:, col})
                            
                            % select data
                            dataBeforeGA = hrv_table(hrv_table.Timestamp>=startDate & hrv_table.Timestamp<highlightDates(h_seq), :);
                            dataGA = hrv_table(hrv_table.Timestamp>=highlightDates(h_seq) & hrv_table.Timestamp<highlightDates(h_seq)+3, :);
                            dataAfterGA = hrv_table(hrv_table.Timestamp>=highlightDates(h_seq)+3 & hrv_table.Timestamp<endDate, :);
                            colData = [dataBeforeGA{:, col}' dataGA{:, col}' dataAfterGA{:, col}'];
                    
                            % Fit the combined data
                            beforeFit = cosine_fit(dataBeforeGA{:, col}, days, true, duration);
                            gaFit = cosine_fit(dataGA{:, col}, 3, false, duration);
                            afterFit = cosine_fit(dataAfterGA{:, col}, days, false, duration);
                            colFit = [beforeFit.fitData, gaFit.fitData, afterFit.fitData];
                            timeFit = [beforeFit.time, gaFit.time, afterFit.time];
                            colName = hrv_table.Properties.VariableNames{col};
                            
                            % Create a figure with multiple subplots
                            fig = figure('Position', [10 0 800 1000]);
                        
                            lastIndex = 0;
                            for j = 1:length(dateRange)
    
                                % Number of data points
                                numPoints = height(hrv_table(hrv_table.Timestamp>=dateRange(j) & hrv_table.Timestamp<(dateRange(j)+1), :));
                                
                                % initiate subplot
                                subplot(length(dateRange), 1, j); % Create a subplot for each date
    
                                % set time, yData, and yFit
                                startIndex = lastIndex+1;
                                endIndex = lastIndex+numPoints;
                                time = timeFit(startIndex : endIndex);
                                yData = colData(startIndex : endIndex);
                                yFit = colFit(startIndex : endIndex);
                                
                                % set background color for GA t
                                if dateRange(j) == highlightDates(h_seq)
                                    y_limits = [min(yData)+0.1*max(yData) max(yData)];
                                    x_start_idx = floor(ga_times(h_seq) * (60/duration));
                                    x_end_idx = floor(x_start_idx + (5 * 60 / duration));
                                    x_start = time(x_start_idx);
                                    x_end = time(x_end_idx);
                                    patch([x_start x_end x_end x_start], [y_limits(1) y_limits(1) y_limits(2) y_limits(2)], ...
                                        [1, 1, 0.8], 'FaceAlpha', 1, 'EdgeColor', 'none');  % Light yellow with 50% transparency
                                end
                                
                                % set lastIndex
                                lastIndex = endIndex;
                        
                                % plotting
                                hold on;
                                plot(time, yData); % Plot the data in the i-th selected column
                                if (j < days+1) || (j > days+3)
                                    plot(time, yFit, 'r-');  % Fitted cosine curve as red line
                                    
                                    % Find the peak and valley
                                    [peakValue, peakIndex] = max(yFit); % Find maximum (peak)
                                    [valleyValue, valleyIndex] = min(yFit); % Find minimum (valley)
                                    
                                    % Mark the peak and valley with filled markers using scatter
                                    
                                    scatter(time(peakIndex), peakValue, 100, 'g', 'filled', 'MarkerEdgeColor', 'k', ...
                                        'MarkerFaceAlpha', 0.5, 'DisplayName', 'Peak'); % Peak marker with fill color and opacity
                                    
                                    scatter(time(valleyIndex), valleyValue, 100, 'r', 'filled', 'MarkerEdgeColor', 'k', ...
                                        'MarkerFaceAlpha', 0.5, 'DisplayName', 'Valley'); % Valley marker with fill color and opacity
                        
                                end
                                % hide legend
                                legend('hide');
                        
                                % set and formatting xlabel and ylabel
                                xticks(round(time(1)):2:round(time(end)));
                                xlim([round(time(1))-0.5 round(time(end))+0.5]);
    
                                if j == days+1
                                    xlabel('');
                                    h = ylabel(strcat('GA',num2str(h_seq)), 'Rotation', 0); % Label y-axis
                                    currentPos = get(h, 'Position');
                                    set(h, 'Position', currentPos + [-1 -1 00]);
                                else
                                    xlabel('');
                                    if j-1 < days
                                        h = ylabel(num2str((j-1)-days), 'Rotation', 0);
                                    elseif j-1 > days
                                        h = ylabel(strcat('+', num2str((j-1)-days)), 'Rotation', 0);
                                    end
                                    currentPos = get(h, 'Position');
                                    set(h, 'Position', currentPos + [-1 -1 0]);
                                    
                                    if j == length(dateRange)
                                        xlabel('Time (hours)'); % Label x-axis
                                    end
                                end
    
                                hold off;
                            end
                            sgtitle(strcat(strrep(colName, '_', ' '), ', Mouse-', mouse_seq(c_seq), ', GA',num2str(h_seq),':', datestr(highlightDates(h_seq))));
                            
                            % Save the plot as a MATLAB .fig file
                            dirPlot = strcat(dir_plots, channel_num, '\ga_', num2str(h_seq), '\', hrv_types{type_seq}, '_', num2str(duration), 'minutes\');
                            if ~exist(dirPlot, 'dir')
                                mkdir(dirPlot);
                            end
                            
%                             filefig = strcat(dirPlot, colName, '.fig');
%                             savefig(fig, filefig);
                    
                            filefig = strcat(dirPlot, colName);
                            print(fig, filefig, '-dpng', '-r300'); % '-r300' specifies 300 dpi resolution
                            
                            % Close the figure
                            close(fig);
    
                            % DRAW WAVE PLOT
                            % adjust beforeFit acrophase to day 11, where
                            % beforeFit started
                            beforeRad = beforeFit.beta(3) + ((24-beforeFit.beta(2))*10*2*pi/beforeFit.beta(2));
                             
                            b1 = [beforeFit.beta(1), beforeFit.beta(2), beforeRad, beforeFit.beta(4)];
                            b2 = afterFit.beta;
                            params = {b1, b2};
                            ttitle = strcat(strrep(colName, '_', ' '), ', Mouse-', mouse_seq(c_seq), ', GA',num2str(h_seq),':', datestr(highlightDates(h_seq)));
                            plot_wave(params, dirPlot, colName, ttitle)
    
    
                            % save cosinor results to table
                            % {'GA', 'Mouse', 'Sex', 'State', 'Metric', 'Amplitude', 'FRP', 'Acrophase', 'Mesor', 'PhaseShift', 'Duration', 'CI_Amplitude_Min', 'CI_FRP_Min', 'CI_Mesor_Min', 'CI_PhaseShift_Min', 'CI_Amplitude_Max', 'CI_FRP_Max', 'CI_Mesor_Max', 'CI_PhaseShift_Max', 'F_Stat', 'P_Value'}
                            beforeCT = -999;
                            gaCT = -999;
                            afterCT = -999;
                            if length(beforeFit.locsPeaks) > 0
                                beforeCT = beforeFit.locsPeaks(end)+24;
                            end
                            if length(afterFit.locsPeaks) > 0
                                afterCT = afterFit.locsPeaks(1);
                            end
                            if length(gaFit.locsPeaks) > 0
                                gaCT = gaFit.locsPeaks(1);
                            end
                            T_cosinor(end+1, :) = {num2str(h_seq), mouse_seq(c_seq), sex_seq(c_seq), ...
                                'before', colName, beforeFit.beta(1), beforeFit.beta(2), ...
                                beforeFit.beta(3), beforeFit.beta(4), NaN, duration, ...
                                beforeFit.CI(1,1), beforeFit.CI(1,2), beforeFit.CI(1,3), beforeFit.CI(1,4), ...
                                beforeFit.CI(1,5), beforeFit.CI(1,6), beforeFit.CI(1,7), beforeFit.CI(1,8), ...
                                beforeFit.FStat, beforeFit.PValue, beforeCT, beforeFit.dataConfidence};
                            T_cosinor(end+1, :) = {num2str(h_seq), mouse_seq(c_seq), sex_seq(c_seq), ...
                                'ga', colName, gaFit.beta(1), gaFit.beta(2), ...
                                gaFit.beta(3), gaFit.beta(4), NaN, duration, ...
                                gaFit.CI(1,1), gaFit.CI(1,2), gaFit.CI(1,3), gaFit.CI(1,4), ...
                                gaFit.CI(1,5), gaFit.CI(1,6), gaFit.CI(1,7), gaFit.CI(1,8), ...
                                gaFit.FStat, gaFit.PValue, gaCT, gaFit.dataConfidence};
                            
                            % Calculate phaseShift
                            % Calculate the phase shift in radians
                            delta = mod((afterFit.beta(3) - beforeRad) * beforeFit.beta(2)/2/pi, 24);
                            if delta > 12
                                phaseShift_hours = delta - 24;
                            elseif delta < -12
                                phaseShift_hours = delta + 24;
                            else
                                phaseShift_hours = delta;
                            end

                            T_cosinor(end+1, :) = {num2str(h_seq), mouse_seq(c_seq), sex_seq(c_seq), ...
                                'after', colName, afterFit.beta(1), afterFit.beta(2), ...
                                afterFit.beta(3), afterFit.beta(4), phaseShift_hours, duration, ...
                                afterFit.CI(1,1), afterFit.CI(1,2), afterFit.CI(1,3), afterFit.CI(1,4), ...
                                afterFit.CI(1,5), afterFit.CI(1,6), afterFit.CI(1,7), afterFit.CI(1,8), ...
                                afterFit.FStat, afterFit.PValue, afterCT, afterFit.dataConfidence};
    %                         if col==3
    %                             break;
    %                         end
%                             break;
                        end
                    end
%                     break; %duration
                end
%                 break; %hrv type 
            end
%             break; %GA time
        end
%         break; %channel number
    end
    
    % save T_cosinor based on duration
    for d_seq = 1:length(durations)
        duration = durations(d_seq);
        writetable(T_cosinor(T_cosinor.Duration==duration, 1:end), strcat(dir_cosinor, num2str(duration), '-minutes-cosinor-pilot', num2str(pilot_seq), '.csv'));
    end
end

