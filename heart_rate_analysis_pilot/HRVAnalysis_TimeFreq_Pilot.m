
% setup hrv_time analysis
fs = 1000;          % hz
durations = [5];       % 5 minute
dir_rr = 'P:\HR_Pilot_Research\rr\';
pilotTimetables = ["P:\HR_Pilot_Research\pilot1timestamp.csv" "P:\HR_Pilot_Research\pilot2timestamp.csv"];
pilotChannelNums = {["p1_1"], ["p2_2", "p2_3", "p2_4"]};
% destination folder to store results
dest_folder = 'P:\HR_Pilot_Research';

% loop for each Pilot project
for pilotNum = 1:length(pilotTimetables)
	% loading timestamp
    T_Timestamp = readtable(pilotTimetables(pilotNum));
	channel_nums =  pilotChannelNums{pilotNum};

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
            if pilotNum == 1
                name = T_Timestamp.File_Name{fileNum};
                dateStr = regexp(name, '\d{2}-\d{2}-\d{4}', 'match');
                dateFormatted = datestr(datetime(dateStr, 'InputFormat', 'dd-MM-yyyy'), 'yyyymmdd');
                
                % Extract the rest of the string (time and am/pm part)
                timePart = name(end-2:end);
                
                % Concatenate the reformatted date with the time part
                fileName = strcat('rr_', dateFormatted, ' ', timePart);
            else
                fileName = strcat('rr_', T_Timestamp.File_Name{fileNum});
            end
			filePath = strcat(dir_rr, channel_nums(n), "\", fileName, ".txt");
			
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
			writetable(T_hrv_time, strcat(dest_folder, '\hrv_time\', channel_nums(n), '\', num2str(duration), 'minutes-aligned-new.csv')); 
		
			% rwite freq hrv
			writetable(T_hrv_freq, strcat(dest_folder, '\hrv_freq\', channel_nums(n), '\', num2str(duration), 'minutes-aligned-new.csv'));
		end
	end
end
