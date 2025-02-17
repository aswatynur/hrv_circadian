
dir_hr = 'P:\HR_Main_Research_2024\hr\';
channel_nums =  ['1' '2' '3' '4' '5' '6' '8'];
mouse_seq = ['5' '6' '7' '8' '3' '4' '2'];
highlightDates = datetime({'20240408', '20240422', '20240513', '20240527', '20240610', '20240624'}, 'InputFormat', 'yyyyMMdd');
missingDates = datetime({'20240326', '20240430', '20240521', '20240709', '20240710'}, 'InputFormat', 'yyyyMMdd');

% Window size
windowSize = 1;


for n=1:length(channel_nums)
    
    % select channel number as mouse data directory
    dir_mouse = strcat(dir_hr, channel_nums(n));

    % get all hr files related to the selected channel number
    dirlist = dir(fullfile(dir_mouse, '*.*'));
    all_hr_files = arrayfun(@(x) fullfile(x.folder, x.name), dirlist, 'UniformOutput', false);
    
    % prepare a map to store a pair of date and all BPM in that date
    map_data = containers.Map();

    % loop to load file and store it to the map
    for file_num=1:numel(all_hr_files)
        filename = all_hr_files{file_num};
        if endsWith(filename, 'txt') == 0 % ignore any non txt file
            continue;
        end
        
        current_date = extractBefore(extractAfter(filename, 'hr_Mouse01 to 08_'), ' ');
        if isKey(map_data, current_date) == 0
            map_data(current_date) = readmatrix(filename);
        else
            map_data(current_date) = [map_data(current_date)' readmatrix(filename)'];
        end
    end

    % initialise dates, and means and std_devs arrays
    keys = map_data.keys;
    dates = datetime(keys', 'InputFormat', 'yyyyMMdd');

    % averaging data in each windowSize interval
    if windowSize > 1
        for i=1:length(dates)
            data = map_data(keys{i});
            
            % Number of windows
            numWindows = length(data) - windowSize + 1;

            % Pre-allocate matrix for windows and rates
            windows = zeros(numWindows, windowSize);

            % Use vectorized approach to generate sliding windows
            % Each column of the `windows` matrix is a shifted version of the data array
            for win_i = 1:windowSize
                windows(:, win_i) = data(win_i:numWindows+win_i-1);
            end

            % Calculate the mean of each window and assign to map_data
            map_data(keys{i}) = mean(windows, 2);
        end

    end

    % initialise means and std_devs arrays
    means = zeros(length(map_data), 1);
    std_devs = zeros(length(map_data), 1);
    
    % loop to calculate means and std_devs
    for i=1:length(dates)
        array = map_data(keys{i});
        means(i) = mean(array);
        std_devs(i) = std(array);
    end
    

    % plot the mean of daily HR including standard deviation
    figure('Position', [10 200 1600 500]);
    dateTime = datetime(dates, 'InputFormat', 'yyyyMMdd');
    errorbar(dateTime, means, std_devs, '-o');
    xlabel('Date');
    ylabel('Mean value');
    title(strcat('Average daily HR of mice-', mouse_seq(n)));
    grid on;
    hold on;
    
    % marking GA administration date
    highlightMeans = means(ismember(dateTime, highlightDates));
    highlightDevs = std_devs(ismember(dateTime, highlightDates));
    plot(highlightDates, highlightMeans, 'r*', 'MarkerSize', 10);
    
    % marking the incomplete data date
    missingMeans = means(ismember(dateTime, missingDates));
    missingDevs = std_devs(ismember(dateTime, missingDates));
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
% %             stdValue = std(rangeStdDevs);
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
    legend({'Daily HR'; 'GA administration'; 'Incomplete data'; 'Stable condition'}, 'Location', 'best');

    hold off;

    break;
end





