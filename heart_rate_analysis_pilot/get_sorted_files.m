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