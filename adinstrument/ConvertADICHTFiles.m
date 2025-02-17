clc;
tic;

% adding adinstrument path containing code to convert ADICHT file to mat
% file
addpath('H:\MATLAB\adinstrument\adinstruments_sdk_matlab\')


% input: selecting a folder containing ADICHT files to be converted (pop up
% windows)
folder = uigetdir('U:\Aswaty Nur', 'Select a directory containing adicht files to convert to mat');

% get all files in the folder and subfolders
dirlist = dir(fullfile(folder, '**\*.*'));
allFiles = arrayfun(@(x) fullfile(x.folder, x.name), dirlist, 'UniformOutput', false);

% only select out those of interest (adicht and csv files)
allFiles = allFiles(contains(allFiles, ".adicht") | contains(allFiles, ".csv$"));

% input: selecting a folder to save mat files
saveFolder = uigetdir('U:\Aswaty Nur', 'Select a directory to save the converted files');

% preparing logfile to store unconverted files
logfile = fopen(fullfile(saveFolder, 'log.txt'), 'a');

% looping to convert each selected file
for i=1:numel(allFiles)
    % get a file name
    filename = allFiles{i};
    
    try
        
        % divide filename to path, name, and extension
        [pathstr,name,ext] = fileparts(filename);

        destfile = fullfile(saveFolder, strcat(name, '.mat'));

        if exist(destfile, 'file') == 0

            % read adicht file using adi package
            f = adi.readFile(filename);
            
            % convert file to mat file and save to the specified folder with '.mat' 
            % extension 
            f.exportToMatFile(destfile);

        end

    catch

        % show unconvertable file to terminal and store in log.txt file
        msg = strcat('Cannot convert file: ', filename);
        warning(msg);
        fprintf(logfile, '%s: %s\n', datetime('now'), msg);
        continue;

    end

end
                
fclose(logfile);
