clc;
tic;

% This script is used to calculate HR in BPM for 7 main project mice.
% The code reads mat files consisted of ECG signal, activity, and validity
% data that converted from adicht files
% The output are: hr, rr, and rri, which are stored into specific folders
% organised by mouse number.

% set the locaion of mat files
folder = 'C:\Users\anur803\OneDrive - The University of Auckland\Documents\Main_Project_2024_mat';
%folder = 'P:\Mat_Main_Research_2024_08_20240610pm';
%folder = 'P:\other';

% get the list of mat files
dirlist = dir(fullfile(folder, '**\*.*'));
allFiles = arrayfun(@(x) fullfile(x.folder, x.name), dirlist, 'UniformOutput', false);
allFiles = allFiles(contains(allFiles, "Mouse01 to 08_2024"));

% channel used to record activity and ecg signals was interchanged at
% 2024-04-10, so it needs to be handle here
switch_marker = 'C:\Users\anur803\OneDrive - The University of Auckland\Documents\Main_Project_2024_mat\Mouse01 to 08_20240410 am.mat';
switch_condition = true;
% switch_condition = false;

% destination folder to store results
dest_folder = 'P:\HR_Main_Research_2024';

% looping to convert each selected file
for file_num=1:numel(allFiles)
    % get a file name
    filename = allFiles{file_num};

    % set switch_condition to false when filename consist '20240410'
    if strcmp(filename, switch_marker) == 1
        switch_condition = false;
%         break;
    end
    
    % load data
    data = load(filename);
    
    % exchange channel
    if switch_condition
        ecgs = {
            data.data__chan_1_rec_1;
            data.data__chan_5_rec_1;
            data.data__chan_8_rec_1;
            data.data__chan_11_rec_1;
            data.data__chan_14_rec_1;
            data.data__chan_17_rec_1;
            data.data__chan_20_rec_1;
            data.data__chan_23_rec_1;
            };
    else
        ecgs = {
            data.data__chan_2_rec_1;
            data.data__chan_5_rec_1;
            data.data__chan_8_rec_1;
            data.data__chan_11_rec_1;
            data.data__chan_14_rec_1;
            data.data__chan_17_rec_1;
            data.data__chan_20_rec_1;
            data.data__chan_23_rec_1;
            };
    end
    
    for channel_num=1:numel(ecgs)
        % calculate hr in BPM, rr and rri for eah channel using get_HR_BPM
        [new_rr, new_rri, new_hr, bpfecg] = get_HR_BPM(ecgs{channel_num});
        [filepath,name,ext] = fileparts(filename);

        % save results into files
        writematrix(new_hr, strcat(dest_folder, '/hr/', num2str(channel_num), '/hr_', name, '.txt'));
        writematrix(new_rr, strcat(dest_folder, '/rr/', num2str(channel_num), '/rr_', name, '.txt'));
        writematrix(new_rri, strcat(dest_folder, '/rri/', num2str(channel_num), '/rri_', name, '.txt'));
    end
end
