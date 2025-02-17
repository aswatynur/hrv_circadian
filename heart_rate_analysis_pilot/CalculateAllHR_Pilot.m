clc;
tic;

% This script is used to calculate HR in BPM for pilot project main project mice.
% The code reads mat files consisted of ECG signal, activity, and validity
% data that converted from adicht files
% The output are: hr, rr, and rri, which are stored into specific folders
% organised by mouse number.

% set the locaion of mat files
folders = {'C:\Users\anur803\OneDrive - The University of Auckland\Documents\Pilot_Project_2022_mat\Converted_telemetry_20221026_mat'; 'C:\Users\anur803\OneDrive - The University of Auckland\Documents\Pilot_Project_2022_mat\Converted_telemetry_20230315_mat'};
nChannels = [3; 12];

% destination folder to store results
dest_folder = 'P:\HR_Pilot_Research';
for seq_folder = 1:length(folders)
    folder = folders{seq_folder};

    % get the list of mat files
    if seq_folder == 1
        allFiles = get_sorted_files(folder);
    else
        dirlist = dir(fullfile(folder, '**\*.mat'));
        allFiles = arrayfun(@(x) fullfile(x.folder, x.name), dirlist, 'UniformOutput', false);
        allFiles = allFiles(contains(allFiles, "Mouse03 to 06_"));
    end

    % looping to convert each selected file
    for file_num=1:numel(allFiles)
        % get a file name
        filename = allFiles{file_num};
        
        % load data
        data = load(filename);

        % get number of recording and channel
        numOfRecording = length(data.record_meta);
        numOfChannels = nChannels(seq_folder);

        % looping for all channel and store in activities, ecgs, and
        % validities
        activities = {};
        ecgs = {};
        validities = {};
        for seq_channel = 1:numOfChannels
            fieldValue = [];
            for seq_recording = 1:numOfRecording
                fieldName = strcat('data__chan_',num2str(seq_channel),'_rec_',num2str(seq_recording));
                
                % Access the field dynamically using parentheses
                fieldValue = [fieldValue; data.(fieldName)];
            end
            if mod(seq_channel, 3) == 1
                activities = [activities; fieldValue];
            elseif mod(seq_channel, 3) == 2
                ecgs = [ecgs; fieldValue];
            else
                validities = [validities; fieldValue];
            end
        end
            
        for channel_num=1:numel(ecgs)
            % calculate hr in BPM, rr and rri for eah channel using get_HR_BPM
            [new_rr, new_rri, new_hr, bpfecg] = get_HR_BPM(ecgs{channel_num});
            [filepath,name,ext] = fileparts(filename);

            % modify name so it is naturally sorted
            if contains(name, 'Test_')
                dateStr = regexp(name, '\d{2}-\d{2}-\d{4}', 'match');
                dateFormatted = datestr(datetime(dateStr, 'InputFormat', 'dd-MM-yyyy'), 'yyyymmdd');
                
                % Extract the rest of the string (time and am/pm part)
                timePart = name(end-2:end);
                
                % Concatenate the reformatted date with the time part
                name = strcat(dateFormatted, ' ', timePart);
            end
    
            % save ecgs into files
            save_to_txt(new_hr, strcat(dest_folder, '/hr/p',num2str(seq_folder),'_', num2str(channel_num), '/hr_', name, '.txt'));
            save_to_txt(new_rr, strcat(dest_folder, '/rr/p',num2str(seq_folder),'_', num2str(channel_num), '/rr_', name, '.txt'));
            save_to_txt(new_rri, strcat(dest_folder, '/rri/p',num2str(seq_folder),'_', num2str(channel_num), '/rri_', name, '.txt'));
        
            % save activities into files
            save_to_txt(get_mean_by_minutes(activities{channel_num}, 0.5), strcat(dest_folder, '/activity/p',num2str(seq_folder),'_', num2str(channel_num), '/activity_', name, '.txt'));

            % save validities into files
            save_to_txt(get_mean_by_minutes(validities{channel_num}, 5), strcat(dest_folder, '/validity/p',num2str(seq_folder),'_', num2str(channel_num), '/validity_', name, '.txt'));
        end

%         break;
    end

%     break;
end

function save_to_txt(data, fullPath)
    [folderPath, ~, ~] = fileparts(fullPath);
    if ~exist(folderPath, 'dir')
        % Folder does not exist, so create it
        mkdir(folderPath);
    end
    writematrix(data, fullPath);
end

function ratePerDuration=get_mean_by_minutes(data, duration)
    % Number of samples in 5 minutes
    samplesPerDuration = 1000 * 60 * duration;

    numSegments = ceil(length(data) / samplesPerDuration);
    ratePerDuration = zeros(1, numSegments);

    % Calculate rate for each 5-minute segment
    for i = 1:numSegments
        % Extract data for the current 5-minute segment
        endTake = i*samplesPerDuration;
        if endTake > length(data)
            endTake = length(data);
        end
        segmentData = data((i-1)*samplesPerDuration + 1 : endTake);
        
        % Calculate rate (you can define what "rate" means based on your application)
        % Example: Sum of the data or mean (depends on your specific rate calculation)
        ratePerDuration(i) = mean(segmentData);  % Modify this based on how you calculate the rate
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
