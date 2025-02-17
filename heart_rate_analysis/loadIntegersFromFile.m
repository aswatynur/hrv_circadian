% function to load text file
% Function to load integers from a text file efficiently
function integers = loadIntegersFromFile(filename)
    % Open the file
    fid = fopen(filename, 'r');
    if fid == -1
        error('Cannot open file: %s', filename);
    end
    
    % Read the entire file content as a string
    fileContent = fread(fid, '*char')';
    
    % Close the file
    fclose(fid);
    
    % Convert the string content to numeric values
    integers = sscanf(fileContent, '%d,');
end