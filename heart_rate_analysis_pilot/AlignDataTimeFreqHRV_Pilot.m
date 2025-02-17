timestamp_files = ["P:\HR_Pilot_Research\pilot1timestamp.csv"; "P:\HR_Pilot_Research\pilot2timestamp.csv"];
channel_nums = {{'p1_1'}, {'p2_1', 'p2_2', 'p2_3', 'p2_4'}};

folder_sources = ["P:\HR_Pilot_Research\hrv_time\"; "P:\HR_Pilot_Research\hrv_freq\"];
durations = [1 5 15];

fs = 1000;
is_interpolate = 1;



for t_seq = 1:length(timestamp_files)
    T_Timestamp = readtable(timestamp_files(t_seq));
    ch_nums = channel_nums{t_seq};

    for f_seq = 1:length(folder_sources)
        folder_source = folder_sources(f_seq);

        for c_seq = 1:length(ch_nums)
            channel_num = ch_nums(c_seq);

            for d_seq = 1:length(durations)
                duration = durations(d_seq);

                filename = strcat(folder_source, channel_num, '\',  num2str(duration),'minutes.csv');
                T_hrv = readtable(filename);
                T_hrvNew = T_hrv([], :);
                startTaken = 1;
            
                tpm_num = 0;
            
                for t_idx = 1:height(T_Timestamp)
                    dt = T_Timestamp{t_idx, 'Timestamp_Start'};
                    n_ticks = T_Timestamp{t_idx, 'N_Ticks'};
                    startTime = dateshift(datetime(dt, 'ConvertFrom', 'datenum'), 'start', 'minute');
                    numOfData = ceil(n_ticks / (fs*60*duration));
                    endTime = dateshift(datetime(dt+n_ticks/(fs*60*60*24), 'ConvertFrom', 'datenum'), 'start', 'minute');
                    
                    if height(T_hrv) - tpm_num < numOfData
                        numOfData = height(T_hrv) - tpm_num;
                    end
                    endTaken = startTaken+numOfData-1;
                    
            
                    T_selected = T_hrv(startTaken:endTaken,:);
                    timeArray = startTime:minutes(duration):endTime;
                    if length(timeArray) > numOfData
                        timeArray = timeArray(1:numOfData);
                    end
                    
                    T_selected.Date = timeArray';
            
                    
                    T_hrvNew = [T_hrvNew; T_selected];
                    startTaken = startTaken+numOfData;
            
                    % handling gap feel with 0s
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
                            numCols = width(T_hrvNew);
                            zeroRows = array2table(zeros(newDataCount, numCols), 'VariableNames', T_hrv.Properties.VariableNames);
                            zeroRows.Date = timeArray';
                            T_hrvNew = [T_hrvNew; zeroRows];
                        end
                    end
            
                    tpm_num = tpm_num + numOfData;
                end
            
                % need to check and complete all data
                uniqueDates = unique(dateshift(T_hrvNew.Date, 'start', 'day'));
                newTable = T_hrvNew;
                for i = 2:length(uniqueDates)-1
                    date = uniqueDates(i);
                    rows = T_hrvNew(T_hrvNew.Date >= date & T_hrvNew.Date < date+1, :);
                    numRows = height(rows);
                    if numRows < 24*60/duration
                        numToAdd = 24*60/duration - numRows;
                        newRows = array2table(zeros(numToAdd, width(T_hrvNew)), 'VariableNames', T_hrvNew.Properties.VariableNames);
                        newRows.Date = repmat(date + hours(23) + minutes(59) + seconds(59), 1, numToAdd)';
                        newTable = [newTable; newRows];
                    end
                end
                
                T_hrvNew = sortrows(newTable, 'Date');
                
                % interpolate zero or NaN rows
                if is_interpolate
                    numCols = size(T_hrvNew, 2);
                    % Iterate through each column
                    for col = 1:numCols
                        % Extract the data in the current column
                        colData = T_hrvNew{:, col}; % Using {} to access data from the table
                        if isnumeric(colData)
                            % Identify indices of non-zero and non-NaN elements
                            validIdx = find(colData ~= 0 & ~isnan(colData));
                        
                            % Identify indices of zero or NaN elements
                            missingIdx = find(colData == 0 | isnan(colData));
                        
                            % Perform PCHIP interpolation to estimate the missing values
                            T_hrvNew{missingIdx, col} = pchip(validIdx, colData(validIdx), missingIdx);
                        end
                    end
                end
                writetable(T_hrvNew, strcat(folder_source, channel_num, '\',  num2str(duration),'minutes-aligned.csv'));
            %     break;
            end
        end
    end
end


