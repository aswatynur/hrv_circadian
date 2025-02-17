clc;
tic;

folder_hr = 'P:\HR_Main_Research_2024\hr';
folder_rri = 'P:\HR_Main_Research_2024\rri';

mice_num = 8;


for mouse_num=1:mice_num
    folder_hr_mouse = strcat(folder_hr,'\',num2str(mouse_num));
    dirlist = dir(fullfile(folder_hr_mouse, '*.*'));
    all_hr_files = arrayfun(@(x) fullfile(x.folder, x.name), dirlist, 'UniformOutput', false);
    
    prev_date = '123';
    prev_value = [];
    for file_num=1:numel(all_hr_files)
        filename = all_hr_files{file_num};
        if endsWith(filename, 'txt') == 0
            continue;
        end
        
        current_value = readmatrix(filename);
        current_date = extractBefore(extractAfter(filename, 'hr_Mouse01 to 08_'), ' ');
        if (strcmp(current_date, prev_date) == 1
            %calculate mean, std
            hr_value = [prev_value current_value];

            pren_value = [];
        end

    end


end