clc;
tic;

folders = ["C:\Users\anur803\OneDrive - The University of Auckland\Documents\Main_Project_2024_mat" "P:\Mat_Main_Research_2024_08_20240610pm"];
switch_marker = 'C:\Users\anur803\OneDrive - The University of Auckland\Documents\Main_Project_2024_mat\Mouse01 to 08_20240410 am.mat';
swicthCondition = true;
duration = 1;
fs = 1000;
channelNums =  ["1" "2" "3" "4" "5" "6" "8"];
mouseNums = ["5" "6" "7" "8" "3" "4" "2"];
mouseSexex = ['F' 'M' 'F' 'M' 'F' 'M' 'M'];

% loading timestamp
T_Timestamp = readtable('P:\HR_Main_Research_2024\timestamp.csv');

% setup start time for AWD
dateStart = datestr(T_Timestamp(1,:).Time_Start, 'dd-mm-yyyy');
roundedSecond = dateshift(T_Timestamp(1,:).Time_Start, 'start', 'second', 'nearest');
timeStart = datestr(roundedSecond, 'HH:MM:SS');
age=2;
idk=10;

% init
initialTimestamp = T_Timestamp.Timestamp_Start(1);
totalTickRange = (T_Timestamp.Timestamp_Start(end) - T_Timestamp.Timestamp_Start(1)) * fs * 24 * 60 * 60 + T_Timestamp.N_Ticks(end);
T_Timestamp.Tick_Start = ((T_Timestamp.Timestamp_Start - T_Timestamp.Timestamp_Start(1))) * (24*60*60*1000) + 1;
T_Timestamp.Tick_End = T_Timestamp.Tick_Start + T_Timestamp.N_Ticks - 1;

% get the number of tick per group
n = fs * 60 * duration;  % 60 seconds, 1000 Hz
totalGroups = ceil(totalTickRange/n);
groupRanges = 0:(fs*60*duration):(totalGroups*fs*60*duration);

% looping through folders to get all folders
allFiles = [];
for folder_seq = 1:length(folders)
    folder = folders(folder_seq);
    
    % get all mat data
    dirlist = dir(fullfile(folder, '**\*.*'));
    folderFiles = arrayfun(@(x) fullfile(x.folder, x.name), dirlist, 'UniformOutput', false);
    allFiles = [allFiles; folderFiles(contains(folderFiles, "Mouse01 to 08_2024"))];
end
T_Timestamp.File_Path = allFiles;

% organised activity
allActivities = repmat({nan(1,totalGroups)}, 1, length(mouseNums));
lastIndex = 0;

currentGroup = 1;
for rowNum = 1:height(T_Timestamp)
    % load data activity
    filename = T_Timestamp(rowNum, :).File_Path{1};
    disp(filename);
    for checkGroup = currentGroup:totalGroups
        startIdx = groupRanges(checkGroup) + 1;
        endIdx = groupRanges(checkGroup + 1);
        if startIdx >= T_Timestamp.Tick_Start(rowNum) && startIdx <= T_Timestamp.Tick_End(rowNum) && endIdx >= T_Timestamp.Tick_Start(rowNum) && endIdx <= T_Timestamp.Tick_End(rowNum)
            break;
        end
    end
    currentGroup = checkGroup;

    relativeStartTick = startIdx - T_Timestamp.Tick_Start(rowNum) + 1;    

    if strcmp(filename, switch_marker) == 1
        switch_condition = false;
        disp('Back to normal');
    end
    activityData = load_file(filename, swicthCondition);
    for channelNum=1:numel(activityData)
        % get activity mean per channel
        a = activityData{channelNum}(round(relativeStartTick):end);
        activityMean = arrayfun(@(i) mean(a(i:i+n-1)),1:n:length(a)-n+1)';
        
        % replace data in allActivities
        allActivities{channelNum}(currentGroup:currentGroup+length(activityMean)-1) = activityMean;
    end

end


% save allActivities to file
dirAwd = "P:\HR_Main_Research_2024\awd\";
durations = [1 5 15];
for mouseNum = 1:length(mouseNums)
    sex = mouseSexex(mouseNum);
    for durNum = 1:length(durations)
        duration = durations(durNum);
        destFolder = strcat(dirAwd, 'mouse-', mouseNums(mouseNum), '/', num2str(duration),'-minutes/');
        destFile = strcat(destFolder, 'mouse-', mouseNums(mouseNum),'-telemetry-activity.awd');
        if ~exist(destFolder, 'dir')
            mkdir(destFolder);
        end
        
        % Reshape the array into a matrix with 15 rows
        numGroups = floor(length(allActivities{mouseNum}) / duration);
        reshapedActivity = reshape(allActivities{mouseNum}(1:numGroups*duration), duration, []); % [] automatically calculates the number of columns
        
        % Calculate the mean of each column (each group of 15 elements)
        averagedActivity = mean(reshapedActivity, 1, 'omitnan');
        
        colName = 'activity';
        dataName = strcat('Mouse ', mouseNums(mouseNum), '-', colName);
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


function activity = load_file(filename, swicthCondition)
    % load data
    data = load(filename);
    
    % exchange channel
    if swicthCondition
        activity = {
            data.data__chan_2_rec_1;
            data.data__chan_4_rec_1;
            data.data__chan_7_rec_1;
            data.data__chan_10_rec_1;
            data.data__chan_13_rec_1;
            data.data__chan_16_rec_1;
            data.data__chan_19_rec_1;
            data.data__chan_22_rec_1;
            };
    else
        activity = {
            data.data__chan_1_rec_1;
            data.data__chan_4_rec_1;
            data.data__chan_7_rec_1;
            data.data__chan_10_rec_1;
            data.data__chan_13_rec_1;
            data.data__chan_16_rec_1;
            data.data__chan_19_rec_1;
            data.data__chan_22_rec_1;
            };
    end
end