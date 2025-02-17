% durations = [5 15 1];
duration = 15;
channel_nums = ['1' '2' '3' '4' '5' '6' '8'];
mouse_seq    = ['5' '6' '7' '8' '3' '4' '2'];
sex_seq      = ['F' 'M' 'F' 'M' 'F' 'M' 'M'];
T_Timestamp = readtable('P:\HR_Main_Research_2024\timestamp.csv');
dateStart = datestr(T_Timestamp(1,:).Time_Start, 'dd-mm-yyyy');
roundedSecond = dateshift(T_Timestamp(1,:).Time_Start, 'start', 'second', 'nearest');
timeStart = datestr(roundedMinute, 'HH:MM:SS');
age=2;
idk=10;
sex='S/M';

dirAwd = strcat('P:\HR_Main_Research_2024\awd\');
if ~exist(dirAwd, 'dir')
    mkdir(dirAwd);
end

interval = duration * 4;

for c_seq=1:length(channel_nums)
        
    channel_num = channel_nums(c_seq);
    dir_activity = strcat('P:\HR_Main_Research_2024\activity\', channel_num, '\');

    % get all activity files related to the selected channel number
    dirlist = dir(fullfile(dir_activity, '*.*'));
    all_activity_files = arrayfun(@(x) fullfile(x.folder, x.name), dirlist, 'UniformOutput', false);
    
    T_activity = table();

    for file_num=1:numel(all_activity_files)
        filename = all_activity_files{file_num};
        if endsWith(filename, 'txt') == 0 % ignore any non txt file
            continue;
        end
        currentDate = extractBefore(extractAfter(filename, 'activity_Mouse01 to 08_'), ' ');

        % Read the file into a table
        T = readtable(filename);

        % Rename the first column to 'activity'
        T.Properties.VariableNames{1} = 'Activity';
        
        % Convert the extracted string to a datetime object
        currentDate = datetime(currentDate, 'InputFormat', 'yyyyMMdd');  % Adjust format as per your filename
        
        % Assign it to the 'Date' column in the table
        T.Date = repmat(currentDate, height(T), 1);

        T_activity = [T_activity; T];
    end
    T_activity = align_activity(T_activity, T_Timestamp, duration);

    % save to AWD file
    colName = 'activity';
    dataName = strcat('Mouse ', mouse_seq(c_seq), '-', colName);
    cellArray = {dataName, dateStart, timeStart, interval, age, idk, sex};
    filename = strcat(dirAwd, num2str(duration),'minutes_',colName,'_channel',channel_num,'.awd');
    fileID = fopen(filename, 'w');
    for i = 1:length(cellArray)
        if ischar(cellArray{i}) || isstring(cellArray{i})
            fprintf(fileID, '%s\n', cellArray{i});
        else
            fprintf(fileID, '%d\n', cellArray{i});
        end
    end
    fprintf(fileID, '%.15f\n', T_activity.Activity);
    fclose(fileID);  

%     break;
end

function T_aligned = align_activity(T, T_Timestamp, duration)
    startTaken = 1;

    fs = 1000;

    tpm_num = 0;

    T_aligned = table();

    is_interpolate = 1;
    
    for t_idx = 1:height(T_Timestamp)
        dt = T_Timestamp{t_idx, 'Timestamp_Start'};
        n_ticks = T_Timestamp{t_idx, 'N_Ticks'};
        startTime = dateshift(datetime(dt, 'ConvertFrom', 'datenum'), 'start', 'minute');
        numOfData = ceil(n_ticks / (fs*60*duration));
        endTime = dateshift(datetime(dt+n_ticks/(fs*60*60*24), 'ConvertFrom', 'datenum'), 'start', 'minute');
        
        if height(T) - tpm_num < numOfData
            numOfData = height(T) - tpm_num;
        end
        endTaken = startTaken+numOfData-1;
        

        T_selected = T(startTaken:endTaken,:);
        timeArray = startTime:minutes(duration):endTime;
        if length(timeArray) > numOfData
            timeArray = timeArray(1:numOfData);
        end

        T_aligned = [T_aligned; T_selected];

        startTaken = startTaken+numOfData;

        % handling gap fill with 0s
        if t_idx < height(T_Timestamp)
            dt = T_Timestamp{t_idx+1, 'Timestamp_Start'};
            n_ticks = T_Timestamp{t_idx, 'N_Ticks'};
            nextStartTime = dateshift(datetime(dt, 'ConvertFrom', 'datenum'), 'start', 'minute');
            
            newDataCount = floor(minutes(nextStartTime-endTime)/duration);
            if newDataCount > 0
                timeArray = endTime+minutes(duration):minutes(duration):nextStartTime;
                if length(timeArray) > newDataCount
                    timeArray = timeArray(1:newDataCount);
                end
                zeroRows = array2table(zeros(newDataCount, width(T_aligned)), 'VariableNames', T_aligned.Properties.VariableNames);
                zeroRows.Date = timeArray';
                T_aligned = [T_aligned; zeroRows];
            end
        end
        tpm_num = tpm_num + numOfData;
    end

    
    % need to check and complete all data
    uniqueDates = unique(dateshift(T_aligned.Date, 'start', 'day'));
    newTable = T_aligned;
    for i = 2:length(uniqueDates)-1
        date = uniqueDates(i);
        rows = T_aligned(T_aligned.Date >= date & T_aligned.Date < date+1, :);
        numRows = height(rows);
        if numRows < 24*60/duration
            numToAdd = 24*60/duration - numRows;
            newRows = array2table(zeros(numToAdd, width(T_aligned)), 'VariableNames', T_aligned.Properties.VariableNames);
            newRows.Date = repmat(date + hours(23) + minutes(59) + seconds(59), 1, numToAdd)';
            newTable = [newTable; newRows];
        end
    end
    
    T_aligned = sortrows(newTable, 'Date');
        
%     interpolate zero or NaN rows
    if is_interpolate
        
        colData = T_aligned.Activity; % Using {} to access data from the table
        if isnumeric(colData)
            % Identify indices of non-zero and non-NaN elements
            validIdx = find(colData ~= 0 & ~isnan(colData));
        
            % Identify indices of zero or NaN elements
            missingIdx = find(colData == 0 | isnan(colData));
        
            % Perform PCHIP interpolation to estimate the missing values
            T_aligned{missingIdx, 'Activity'} = pchip(validIdx, colData(validIdx), missingIdx);
        end
    end

end