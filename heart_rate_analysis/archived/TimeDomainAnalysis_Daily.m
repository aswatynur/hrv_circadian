
% setup hrv_time analysis
pnn_thresh_ms = 6;

fs = 1000;


dir_rr = 'P:\HR_Main_Research_2024\rr\';
dir_rri = 'P:\HR_Main_Research_2024\rri\';
channel_nums =  ['1' '2' '3' '4' '5' '6' '8'];
mouse_seq = ['5' '6' '7' '8' '3' '4' '2'];
highlightDates = datetime({'20240408', '20240422', '20240513', '20240527', '20240610', '20240624'}, 'InputFormat', 'yyyyMMdd');
missingDates = datetime({'20240326', '20240430', '20240521', '20240525', '20240709', '20240710'}, 'InputFormat', 'yyyyMMdd');

for n=1:length(channel_nums)
    
    % select channel number as mouse data directory
    dir_rr_mouse = strcat(dir_rr, channel_nums(n));
    dir_rri_mouse = strcat(dir_rri, channel_nums(n));

    % get all rr files related to the selected channel number
    dirlist = dir(fullfile(dir_rr_mouse, '*.*'));
    all_rr_files = arrayfun(@(x) fullfile(x.folder, x.name), dirlist, 'UniformOutput', false);
    
    % get all rri files related to the selected channel number
    dirlist = dir(fullfile(dir_rri_mouse, '*.*'));
    all_rri_files = arrayfun(@(x) fullfile(x.folder, x.name), dirlist, 'UniformOutput', false);
    
    % prepare a map to store a pair of date and all BPM in that date
    map_data_rr = containers.Map();
    map_data_rri = containers.Map();
    
    % Create a waitbar
    h = waitbar(0, 'Please wait...');

    % loop to load file and store it to the map
    for file_num=1:numel(all_rr_files)
        filename_rr = all_rr_files{file_num};
        filename_rri = all_rri_files{file_num};
        if endsWith(filename_rr, 'txt') == 0 % ignore any non txt file
            continue;
        end
        
        % combine data to one day
        current_date = extractBefore(extractAfter(filename_rr, 'rr_Mouse01 to 08_'), ' ');
        if isKey(map_data_rr, current_date) == 0
            rr = loadIntegersFromFile(filename_rr)';
            map_data_rr(current_date) = rr;
%             map_data_rri(current_date) = [rr(1) loadIntegersFromFile(filename_rri)'];
        else
            rr_prev = map_data_rr(current_date);
            rr = loadIntegersFromFile(filename_rr)' + rr_prev(end);
%             rri = [rr(1) loadIntegersFromFile(filename_rri)'];
            map_data_rr(current_date) = [rr_prev rr];
%             map_data_rri(current_date) = [map_data_rri(current_date) rri];
        end

        % Update the waitbar
        waitbar(file_num / numel(all_rr_files), h, sprintf('Load rri and rr from files: %d %%', floor(file_num / numel(all_rr_files) * 100)));
    end
    
    close(h);

    % initialise dates, and means and std_devs arrays
    keys = map_data_rr.keys;
    dates = datetime(keys', 'InputFormat', 'yyyyMMdd');

    % now calculate rri
    for i=1:length(keys)
        rr = map_data_rr(keys{i});
        current_date = keys{i};
        rri = rr(2:end)-rr(1:end-1);
        map_data_rri(keys{i}) =  [rr(end) rri];
    end

    % prepare table to store time domnain analysis results
    columns = {'Date', 'AVNN', 'SDNN', 'RMSSD', 'pNN6', 'SEM'};
    columntypes = {'datetime', 'double', 'double', 'double', 'double', 'double'};
    hrv_time_table = table('Size', [length(dates), length(columns)], 'VariableTypes', columntypes, 'VariableNames', columns);
    hrv_time_table.Date = dates;

    % loop to filter rri
    for i=1:length(dates)
        try
            rr = map_data_rr(keys{i});
            rri = map_data_rri(keys{i});
            [rri_clean, rr_clean] = rr_filter(rri, rr, fs, 'range');
            hrv_time = mhrv.hrv.hrv_time(rri_clean, 'pnn_thresh_ms', pnn_thresh_ms);
            hrv_time_table.AVNN(i) = hrv_time.AVNN(1);
            hrv_time_table.SDNN(i) = hrv_time.SDNN(1);
            hrv_time_table.RMSSD(i) = hrv_time.RMSSD(1);
            hrv_time_table.pNN6(i) = hrv_time.pNN6(1);
            hrv_time_table.SEM(i) = hrv_time.SEM(1);
        catch ME
            hrv_time_table.AVNN(i) = hrv_time_table.AVNN(i-1);
            hrv_time_table.SDNN(i) = hrv_time_table.SDNN(i-1);
            hrv_time_table.RMSSD(i) = hrv_time_table.RMSSD(i-1);
            hrv_time_table.pNN6(i) = hrv_time_table.pNN6(i-1);
            hrv_time_table.SEM(i) = hrv_time_table.SEM(i-1);
            disp(strcmp(keys{i} , ME.message));
        end
    end    

    % plot the mean of daily HR including standard deviation
    figure('Position', [10 200 1600 500]);
    means = hrv_time_table.AVNN;
    std_devs = hrv_time_table.SDNN;
    errorbar(dates, means, std_devs, '-o');
    xlabel('Date');
    ylabel('Mean value');
    title(strcat('Average daily HR of mice-', mouse_seq(n)));
    grid on;
    hold on;
    
    % marking GA administration date
    highlightMeans = means(ismember(dates, highlightDates));
    highlightDevs = std_devs(ismember(dates, highlightDates));
    plot(highlightDates, highlightMeans, 'r*', 'MarkerSize', 10);
    
    % marking the incomplete data date
    missingMeans = means(ismember(dates, missingDates));
    missingDevs = std_devs(ismember(dates, missingDates));
    plot(missingDates, missingMeans, '>', 'MarkerSize', 10, 'Color', [1 0.5 0]);

%     % marking the stable condition
%     stable_start_dates = [];
%     for i = 1:length(highlightDates)
%         startDate = highlightDates(i);
%         endDate = startDate + days(12);
%         rangeIndices = find(dates > startDate & dates <= endDate & ~ismember(dates, missingDates));
%     
%          if ~isempty(rangeIndices)
%             rangeMeans = means(rangeIndices);
%             rangeStdDevs = std_devs(rangeIndices);
%             
%             % Stability criteria example: mean values should be within mean +/- 2*std_dev
%             meanValue = mean(rangeMeans);
%             stdValue = std(rangeMeans);
%             
%             % Initialize stability flag and start date
%             stable = false;
%             stableStartDate = [];
%             
%             % Check stability condition over the range
%             mult = 2;
%             for j = 1:length(rangeIndices)
%                 if all(rangeMeans(j:end) > meanValue - mult * stdValue & rangeMeans(j:end) < meanValue + mult * stdValue)
%                     stable = true;
%                     stableStartDate = dates(rangeIndices(j));
%                     break;
%                 end
%             end
% 
% %             % Store the stable start date
% %             if stable
% %                 stable_start_dates = [stable_start_dates; stableStartDate];
% %                 fprintf('Stable condition starts on %s within the range from %s to %s.\n', datestr(stableStartDate), datestr(startDate), datestr(endDate));
% %             else
% %                 fprintf('No stable condition found within the range from %s to %s.\n', datestr(startDate), datestr(endDate));
% %             end
% 
%             % Plot stable period
%             if stable
%                 stableIndices = find(dates >= stableStartDate & dates <= endDate);
%                 plot(dates(stableIndices), means(stableIndices), 'g-', 'LineWidth', 2); % Green line for stable period
%             end
%          end
%     end

    % add legend
%     legend({'Daily HR'; 'GA administration'; 'Incomplete data'; 'Stable condition'}, 'Location', 'best');
    legend({'Daily HR'; 'GA administration'; 'Incomplete data'}, 'Location', 'best');

    hold off;

    break;
end