durations = [5];
hrv_types = {'hrv_time', 'hrv_freq'};
channel_nums = ['1' '2' '3' '4' '5' '6' '8'];
mouse_seq    = ['5' '6' '7' '8' '3' '4' '2'];
sex_seq      = ['F' 'M' 'F' 'M' 'F' 'M' 'M'];
T_Timestamp = readtable('P:\HR_Main_Research_2024\timestamp.csv');
dateStart = datestr(T_Timestamp(1,:).Time_Start, 'dd-mm-yyyy');
roundedSecond = dateshift(T_Timestamp(1,:).Time_Start, 'start', 'second', 'nearest');
timeStart = datestr(roundedSecond, 'HH:MM:SS');
age=2;
idk=10;

dirAwd = strcat('P:\HR_Main_Research_2024\awd\');
if ~exist(dirAwd, 'dir')
    mkdir(dirAwd);
end

for c_seq=1:length(channel_nums)
    sex = sex_seq(c_seq);
    for type_seq=1:length(hrv_types)
        for d_seq=1:length(durations)
            duration = durations(d_seq);
            interval = duration * 4;
            dir_hrv_time = strcat('P:\HR_Main_Research_2024\', hrv_types{type_seq}, '\');
            channel_num = channel_nums(c_seq);
            hrv_table = readtable(strcat(dir_hrv_time, num2str(channel_num), '\',num2str(duration), 'minutes-aligned-new.csv'));
            
            for col = 1:width(hrv_table)
                if isnumeric(hrv_table{:, col})
                    colName = hrv_table.Properties.VariableNames{col};
                    data = hrv_table{:, col};
                    dataName = strcat('Mouse ', mouse_seq(c_seq), '-', colName);

                    cellArray = {dataName, dateStart, timeStart, interval, age, idk, sex};
					destFolder = strcat(dirAwd, 'mouse-', mouse_seq(c_seq), '\', num2str(duration),'-minutes\');
                    
                    if ~exist(destFolder, 'dir')
						mkdir(destFolder);
					end
					
					destFile = strcat(destFolder, 'mouse-', mouse_seq(c_seq), '-telemetry-', colName, '.awd');
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