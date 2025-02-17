
% set the locaion of mat files
folders = ["C:\Users\anur803\OneDrive - The University of Auckland\Documents\Main_Project_2024_mat", "P:\Mat_Main_Research_2024_08_20240610pm"];

% prepare column
% columns = {'File_Name', 'Timestamp_Start', 'Time_Start', 'N_Ticks'};
% columntypes = {'string', 'double', 'datetime', 'int32'};
% T = table('Size', [0, length(columns)], 'VariableTypes', columntypes, 'VariableNames', columns);
T = readtable('P:\HR_Main_Research_2024/timestamp.csv');

pass = true;
for f_num = 1:length(folders)
    folder = folders(f_num);
    % get the list of mat files
    dirlist = dir(fullfile(folder, '**\*.*'));
    allFiles = arrayfun(@(x) fullfile(x.folder, x.name), dirlist, 'UniformOutput', false);
    allFiles = allFiles(contains(allFiles, "Mouse01 to 08_2024"));


    h = waitbar(0, 'Calculate tome hrv');
    for file_num=1:numel(allFiles)
        

        % get a file name
        filename = allFiles{file_num};
        
        % load data
        data = load(filename);
        
        [filepath,name,ext] = fileparts(filename);
        t = data.record_meta.record_start;
        dt = datetime(t, 'ConvertFrom', 'datenum');
        n_ticks = data.record_meta.n_ticks;
        % Add the new row
        T(end+1, :) = {name, t, dt, n_ticks};

        % Update the waitbar
        waitbar(file_num / length(allFiles), h, sprintf('Calculate time start: %d %%', floor(file_num / length(allFiles) * 100)));
    end
    close(h);   
end

% destination folder to store results
writetable(T, 'P:\HR_Main_Research_2024/timestamp.csv');
