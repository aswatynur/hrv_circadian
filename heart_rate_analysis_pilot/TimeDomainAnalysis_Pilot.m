
% setup hrv_time analysis
pnn_thresh_ms = 6;  % ms
fs = 1000;          % hz
durations = [1 5 15];       % 5 minute

dir_rr = 'P:\HR_Pilot_Research\rr\';

% % Pilot project 1
% channel_nums =  {'p1_1'};
% mouse_seq = {'p1_1'};
% highlightDates = datetime({'20221219', '20230116', '20230208'}, 'InputFormat', 'yyyyMMdd');

% Pilot project 2
channel_nums =  {'p1_1', 'p2_2', 'p2_3', 'p2_4'};
mouse_seq = {'p1_1', 'p2_2', 'p2_3', 'p2_4'};
highlightDates = datetime({'20230509', '20230523', '20230607', '20230705'}, 'InputFormat', 'yyyyMMdd');

channel_nums =  {'p2_1'};

% destination folder to store results
dest_folder = 'P:\HR_Pilot_Research\hrv_time';

for n=1:length(channel_nums)
    
    % select channel number as mouse data directory
    dir_rr_mouse = strcat(dir_rr, channel_nums{n});
    
    % get all rr files related to the selected channel number
    dirlist = dir(fullfile(dir_rr_mouse, '*.*'));
    all_rr_files = arrayfun(@(x) fullfile(x.folder, x.name), dirlist, 'UniformOutput', false);
    
    % prepare a map to store a pair of date and all BPM in that date
    map_data_rr = containers.Map();
    
    % Create a waitbar
    h = waitbar(0, 'Loading file');

    % loop to load file and store it to the map
    for file_num=1:numel(all_rr_files)
        filename_rr = all_rr_files{file_num};
        if endsWith(filename_rr, 'txt') == 0 % ignore any non txt file
            continue;
        end
        
        % combine data to one day
        current_date = regexp(filename_rr, '\d{8}', 'match');
        current_date = current_date{1};
        if isKey(map_data_rr, current_date) == 0
            rr = loadIntegersFromFile(filename_rr)';
            map_data_rr(current_date) = rr;
        else
            rr_prev = map_data_rr(current_date);
            rr = loadIntegersFromFile(filename_rr)' + rr_prev(end);
            map_data_rr(current_date) = [rr_prev rr];
        end

        % Update the waitbar
        waitbar(file_num / numel(all_rr_files), h, sprintf('Load rri and rr from files: %d %%', floor(file_num / numel(all_rr_files) * 100)));
    end
    
    close(h);

    for d_num=1:length(durations)
        duration = durations(d_num);

        % initialise dates, and means and std_devs arrays
        keys = map_data_rr.keys;
        dates = datetime(keys', 'InputFormat', 'yyyyMMdd');
    
        % prepare table to store time domnain analysis results
        columns = {'Date', 'AVBPM', 'AVNN', 'SDNN', 'RMSSD', 'pNN6', 'SEM'};
        columntypes = {'datetime', 'double', 'double', 'double', 'double', 'double', 'double'};
        hrv_time_table = table('Size', [0, length(columns)], 'VariableTypes', columntypes, 'VariableNames', columns);
    
        h = waitbar(0, 'Calculate tome hrv');
        % now calculate hrv_time
        for i=1:length(keys)
            curr_date = keys{i};
            rr = map_data_rr(curr_date);
            [rr, rri, hrv_time] = get_time_domain(rr, fs, duration, 'range', pnn_thresh_ms);
            hrv_time.Date = datetime(repmat(curr_date, height(hrv_time), 1), 'InputFormat', 'yyyyMMdd');
            if height(hrv_time_table) > 0
                hrv_freq.Properties.VariableNames = hrv_freq_table.Properties.VariableNames;
            end
            hrv_time_table = [hrv_time_table; hrv_time];
    
            % Update the waitbar
            waitbar(i / length(keys), h, sprintf('Calculate time hrv: %d %%', floor(i / length(keys) * 100)));
        end
        close(h);
    
        folderPath = strcat(dest_folder, '\', channel_nums{n}, '\');
        if ~exist(folderPath, "dir")
            mkdir(folderPath)
        end
        writetable(hrv_time_table, strcat(folderPath, num2str(duration), 'minutes.csv'));
    end
end