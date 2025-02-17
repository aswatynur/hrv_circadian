
% setup hrv_time analysis
fs = 1000;          % hz
durations = [5];       % 5 minute

dir_rr = 'P:\HR_Main_Research_2024\rr\';
T_Timestamp = readtable('P:\HR_Main_Research_2024\timestamp.csv');
channel_nums =  ["1" "2" "3" "4" "5" "6" "8"];

% destination folder to store results
dest_folder = 'P:\HR_Main_Research_2024';

% init
initialTimestamp = T_Timestamp.Timestamp_Start(1);
idealAllNTicks = (T_Timestamp.Timestamp_Start(end) - T_Timestamp.Timestamp_Start(1)) * fs * 24 * 60 * 60 + T_Timestamp.N_Ticks(end);

for n=1:length(channel_nums)
    % Create a waitbar
    h = waitbar(0, 'Loading file');

    % init channel rr
    channelRR = [];

    % loading all rr channel data
    for fileNum = 1:height(T_Timestamp)
        % specify file path
        filePath = strcat(dir_rr, channel_nums(n), "\rr_", T_Timestamp.File_Name(fileNum), ".txt");
        
        % calculate tick dirrefent from the initial recording
        tickDiffFromInitTime = (T_Timestamp.Timestamp_Start(fileNum) - initialTimestamp) * fs * 24 * 60 * 60;
        
        % load rr
        rr = loadIntegersFromFile(filePath)' + tickDiffFromInitTime;
        
        channelRR = [channelRR rr];
        
        % Update the waitbar
        waitbar(fileNum / height(T_Timestamp), h, sprintf('Load rr from files: %d %%', floor(fileNum /height(T_Timestamp) * 100)));
    end
    close(h); 

    % Now do hrv analysis
    totalTickRange = tickDiffFromInitTime + T_Timestamp.N_Ticks(end);
    for dNum=1:length(durations)
        duration = durations(dNum);

        % calculate time hrv and freq_hrv
        [T_hrv_time, T_hrv_freq] = get_time_domain(channelRR, fs, duration, 'range', totalTickRange, initialTimestamp);
        
        % write time hrv
        writetable(T_hrv_time, strcat(dest_folder, '/hrv_time/', channel_nums(n), '/', num2str(duration), 'minutes-aligned-new.csv')); 
    
        % rwite freq hrv
        writetable(T_hrv_freq, strcat(dest_folder, '/hrv_freq/', channel_nums(n), '/', num2str(duration), 'minutes-aligned-new.csv'));
    end
    
end
