% durations = [1 5 15];
durations = [5];
pilotChannels = {["p1_1"], ["p2_2", "p2_3", "p2_4"]};
pilotMouseSeqs = {["Pilot1-1"], ["Pilot2-1" "Pilot2-2" "Pilot2-3" "Pilot2-4"]};
pilotTimestamp = ["P:\HR_Pilot_Research\pilot1timestamp.csv", "P:\HR_Pilot_Research\pilot2timestamp.csv"];

hrv_types = {'hrv_time', 'hrv_freq'};

age=2;
idk=10;
sex='S/M';

dirAwd = strcat('P:\HR_Pilot_Research\awd\');
if ~exist(dirAwd, 'dir')
    mkdir(dirAwd);
end

for pilotNum = 1:length(pilotChannels)
    channel_nums = pilotChannels{pilotNum};
    mouse_seq = pilotMouseSeqs{pilotNum};
    timestampFile = pilotTimestamp(pilotNum);
    T_Timestamp = readtable(timestampFile);
    dateStart = datestr(T_Timestamp(1,:).Time_Start, 'dd-mm-yyyy');
    roundedMinute = dateshift(T_Timestamp(1,:).Time_Start, 'start', 'minute', 'nearest');
    timeStart = datestr(roundedMinute, 'HH:MM');


    for c_seq=1:length(channel_nums)
        for type_seq=1:length(hrv_types)
            for d_seq=1:length(durations)
                duration = durations(d_seq);
                interval = duration * 4;
                dir_hrv_time = strcat('P:\HR_Pilot_Research\', hrv_types{type_seq}, '\');
                channel_num = channel_nums(c_seq);
                hrv_table = readtable(strcat(dir_hrv_time, channel_num, '\',num2str(duration), 'minutes-aligned-new.csv'));
                
                for col = 1:width(hrv_table)
                    if isnumeric(hrv_table{:, col})
                        colName = hrv_table.Properties.VariableNames{col};
                        data = hrv_table{:, col};
                        dataName = strcat('Pilot', num2str(pilotNum), '-Mouse', num2str(c_seq), '-', colName);
                        cellArray = {dataName, dateStart, timeStart, interval, age, idk, sex};
                        destFolder = strcat(dirAwd, channel_num, '\', num2str(duration),'-minutes\');
                        if ~exist(destFolder)
                            mkdir(destFolder);
                        end
                        destFile = strcat(destFolder, mouse_seq(c_seq),'-telemetry-',colName,'.awd');
                        fileID = fopen(destFile, 'w');
                        for i = 1:length(cellArray)
                            if ischar(cellArray{i}) || isstring(cellArray{i})
                                fprintf(fileID, '%s\n', cellArray{i});
                            else
                                fprintf(fileID, '%d\n', cellArray{i});
                            end
                        end
                        fprintf(fileID, '%.15f\n', data);
                        fclose(fileID);
                    end
                end
    
    %             break;
            end
    %         break;
        end
    %     break;
    end
end