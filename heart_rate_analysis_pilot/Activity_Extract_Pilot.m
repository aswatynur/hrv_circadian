clc;
tic;

% set the locaion of mat files
pilotFolders = ["C:\Users\anur803\OneDrive - The University of Auckland\Documents\Pilot_Project_2022_mat\Converted_telemetry_20221026_mat" "C:\Users\anur803\OneDrive - The University of Auckland\Documents\Pilot_Project_2022_mat\Converted_telemetry_20230315_mat"];
pilotChannels = {[1], [1 4 7 10]};
pilotMouseNums = {["1"], ["1" "2" "3" "4"]};
pilotMouseSexes = {["M"], ["M" "M" "M" "M"]};
pilotTimetables = ["P:\HR_Pilot_Research\pilot1timestamp.csv" "P:\HR_Pilot_Research\pilot2timestamp.csv"];

% setup frequency
fs = 1000;

% loop for each Pilot project
for pilotNum = 1:length(pilotFolders)

    % loading timestamp
    T_Timestamp = readtable(pilotTimetables(pilotNum));
    
    channelNums =  pilotChannels{pilotNum};
    mouseNums = pilotMouseNums{pilotNum};
    mouseSexex = pilotMouseSexes{pilotNum};
    pilotFolder = pilotFolders(pilotNum);

    % setup start time for AWD
    dateStart = datestr(T_Timestamp(1,:).Time_Start, 'dd-mm-yyyy');
    roundedSecond = dateshift(T_Timestamp(1,:).Time_Start, 'start', 'second', 'nearest');
    timeStart = datestr(roundedSecond, 'HH:MM:SS');
    age=2;
    idk=10;
    
    % init
    initialTimestamp = T_Timestamp.Timestamp_Start(1);
    totalTickRange = (T_Timestamp.Timestamp_Start(end) - T_Timestamp.Timestamp_Start(1)) * fs * 24 * 60 * 60 + T_Timestamp.N_Ticks(end);
    T_Timestamp.Tick_Start = ((T_Timestamp.Timestamp_Start - T_Timestamp.Timestamp_Start(1))) * (24*60*60*fs) + 1;
    T_Timestamp.Tick_End = T_Timestamp.Tick_Start + T_Timestamp.N_Ticks - 1;
    
    % get the number of tick per group
    n = fs * 60;  % 60 seconds, 1000 Hz
    totalGroups = ceil(totalTickRange/n);
    groupRanges = 0:(n):(totalGroups*n);
    
    % get the list of mat files
    if pilotNum == 1
        T_Timestamp.File_Path = get_sorted_files(pilotFolder);
    else
        dirlist = dir(fullfile(pilotFolder, '**\*.mat'));
        allFiles = arrayfun(@(x) fullfile(x.folder, x.name), dirlist, 'UniformOutput', false);
        allFiles = allFiles(contains(allFiles, "Mouse03 to 06_"));
        T_Timestamp.File_Path = allFiles;
    end
    
    
    % organised activity
    allActivities = repmat({nan(1,totalGroups)}, 1, length(mouseNums));
    lastIndex = 0;
    
    currentGroup = 1;
    for rowNum = 1:height(T_Timestamp)
        % load data activity
        filename = T_Timestamp(rowNum, :).File_Path{1};
        disp(filename);
        if T_Timestamp.N_Ticks < n
            continue;
        end
        for checkGroup = currentGroup:totalGroups
            startIdx = groupRanges(checkGroup) + 1;
            endIdx = groupRanges(checkGroup + 1);
            if startIdx >= T_Timestamp.Tick_Start(rowNum) && startIdx <= T_Timestamp.Tick_End(rowNum) && endIdx >= T_Timestamp.Tick_Start(rowNum) && endIdx <= T_Timestamp.Tick_End(rowNum)
                break;
            end
        end
        currentGroup = checkGroup;
    
        relativeStartTick = startIdx - T_Timestamp.Tick_Start(rowNum) + 1;    
    
        activityData = load_file(filename, channelNums);
        for channelNum=1:numel(activityData)
            % get activity mean per channel
            a = activityData{channelNum}(round(relativeStartTick):end);
            activityMean = arrayfun(@(i) mean(a(i:i+n-1)),1:n:length(a)-n+1)';
            
            % replace data in allActivities
            allActivities{channelNum}(currentGroup:currentGroup+length(activityMean)-1) = activityMean;

            disp(length(activityMean));
        end
    end
    
    
    % save allActivities to file
    dirAwd = "P:\HR_Pilot_Research\awd\";
    durations = [1 5 15];
    for mouseNum = 1:length(mouseNums)
        sex = mouseSexex(mouseNum);
        for durNum = 1:length(durations)
            duration = durations(durNum);
            destFolder = strcat(dirAwd, 'p', num2str(pilotNum), '_', mouseNums(mouseNum), '\', num2str(duration),'-minutes\');
            destFile = strcat(destFolder, 'pilot', num2str(pilotNum), '_mouse-', mouseNums(mouseNum),'-telemetry-activity.awd');
            if ~exist(destFolder, 'dir')
                mkdir(destFolder);
            end
            
            % Reshape the array into a matrix with 15 rows
            numGroups = floor(length(allActivities{mouseNum}) / duration);
            reshapedActivity = reshape(allActivities{mouseNum}(1:numGroups*duration), duration, []); % [] automatically calculates the number of columns
            
            % Calculate the mean of each column (each group of 15 elements)
            averagedActivity = mean(reshapedActivity, 1, 'omitnan');
            
            colName = 'activity';
            dataName = strcat('Pilot', num2str(pilotNum), '-Mouse', mouseNums(mouseNum), '-', colName);
            interval = durations(durNum) * 4;
            cellArray = {dataName, dateStart, timeStart, interval, age, idk, sex};
            fileID = fopen(destFile, 'w');
            for i = 1:length(cellArray)
                if ischar(cellArray{i}) || isstring(cellArray{i})
                    fprintf(fileID, '%s\n', cellArray{i});
                else
                    fprintf(fileID, '%d\n', cellArray{i});
                end
            end
            fprintf(fileID, '%.15f\n', averagedActivity);
            fclose(fileID);
    
        end
    end
end

function activities = load_file(filename, channels)
    % load data
    data = load(filename);

     % get number of recording and channel
    numOfRecording = length(data.record_meta);
    
    % looping for all channel and store in activities
    activities = {};

    for channelNum = 1:length(channels)
        fieldValue = [];
        channel = channels(channelNum);
        for seq_recording = 1:numOfRecording
            fieldName = strcat('data__chan_',num2str(channel),'_rec_',num2str(seq_recording));
            
            % Access the field dynamically using parentheses
            fieldValue = [fieldValue; data.(fieldName)];
        end
        activities = [activities; fieldValue];
    end
end

function fullPathSortedFiles = get_sorted_files(folderPath)
    filePattern = fullfile(folderPath, '*.mat');
    files = dir(filePattern);
    
    % Extract dates from filenames
    nFiles = length(files);
    dates = zeros(nFiles, 1); % Pre-allocate for date numbers
    
    for i = 1:nFiles
        % Extract filename
        fileName = files(i).name;
        
        % Step 3: Extract the date part (in format dd_mm_yyyy)
        % Filename format is 'Test_dd_mm_yyyy hh;minute;second.0 pm.mat'
        % Example: Test_26-12-2022 10;39;46.7 pm.mat
    
        % Find the start and end of the date part
        dateStr = fileName(6:15); % Extract the part 'dd-mm-yyyy'
        
        % Convert the date string to a serial date number
        % Specify the date format to match the extracted format
        dates(i) = datenum(dateStr, 'dd-mm-yyyy');
    end
    
    % Sort the files based on the date
    [~, sortIdx] = sort(dates);
    
    % Load or process the sorted files
    sortedFiles = files(sortIdx);
    
    fullPathSortedFiles = strings(nFiles, 1); % Pre-allocate a string array
    
    % Now, sortedFiles contains the files in sorted order based on dd_mm_yyyy
    for i = 1:nFiles
        fullPathSortedFiles(i) = fullfile(folderPath, sortedFiles(i).name);
    end
end