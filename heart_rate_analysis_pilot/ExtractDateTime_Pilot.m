
% set the locaion of mat files
folders = ["C:\Users\anur803\OneDrive - The University of Auckland\Documents\Pilot_Project_2022_mat\Converted_telemetry_20221026_mat"; "C:\Users\anur803\OneDrive - The University of Auckland\Documents\Pilot_Project_2022_mat\Converted_telemetry_20230315_mat"];
pilots = ["pilot1"; "pilot2"];


for seq_folder = 1:length(folders)
    
    % prepare column
    columns = {'File_Name', 'Timestamp_Start', 'Time_Start', 'N_Ticks'};
    columntypes = {'string', 'double', 'datetime', 'int32'};
    T = table('Size', [0, length(columns)], 'VariableTypes', columntypes, 'VariableNames', columns);
    % T = readtable('P:\HR_Main_Research_2024/timestamp.csv');

    folder = folders(seq_folder);
    
    % get the list of mat files
    if seq_folder == 1
        allFiles = get_sorted_files(folder);
    else
        dirlist = dir(fullfile(folder, '**\*.mat'));
        allFiles = arrayfun(@(x) fullfile(x.folder, x.name), dirlist, 'UniformOutput', false);
        allFiles = allFiles(contains(allFiles, "Mouse03 to 06_"));
    end

    h = waitbar(0, 'Extract time date');
    for file_num=1:numel(allFiles)
        % get a file name
        filename = allFiles{file_num};
        
        % load data
        data = load(filename);
        
        [filepath,name,ext] = fileparts(filename);
        t = data.record_meta.record_start;
        dt = datetime(t, 'ConvertFrom', 'datenum');
        n_ticks = sum([data.record_meta.n_ticks]);
        % Add the new row
        T(end+1, :) = {name, t, dt, n_ticks};

        % Update the waitbar
        waitbar(file_num / length(allFiles), h, sprintf('Calculate time start: %d %%', floor(file_num / length(allFiles) * 100)));
    end
    close(h);   

    % destination folder to store results
    writetable(T, strcat('P:\HR_Pilot_Research\', pilots(seq_folder),'timestamp.csv'));
end


