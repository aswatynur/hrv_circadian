duration = 1;

dir_hrv_time = 'P:\HR_Main_Research_2024\hrv_time\';
channel_nums =  ['1' '2' '3' '4' '5' '6' '8'];
mouse_seq = ['5' '6' '7' '8' '3' '4' '2'];
highlightDates = datetime({'20240408', '20240422', '20240513', '20240527', '20240610', '20240624'}, 'InputFormat', 'yyyyMMdd');

c_seq = 5;
t_seq = 3;
channel_num = channel_nums(c_seq);
ga_time = highlightDates(t_seq);
start_time = ga_time;
end_time = ga_time + days(1);

hrv_table = readtable(strcat(dir_hrv_time, channel_num, '/',num2str(duration), 'minutes-aligned.csv'));
hrv_table_ga_time = hrv_table(hrv_table.Date>=start_time & hrv_table.Date < end_time, :);

% Create a figure with multiple subplots
figure('Position', [10 0 800 800]);

% Number of data points
numPoints = height(hrv_table_ga_time);

% Generate x-tick values every 10 minutes
xTickValues = 1:30:numPoints;

% Generate corresponding x-tick labels (assuming the first data point is minute 1)
xTickLabels = arrayfun(@(x) sprintf('%02d:%02d', floor((x-1)/(60/duration)), mod(x-1, 60/(duration))), xTickValues, 'UniformOutput', false);

% Define the columns to plot (columns 3 to 8)
columnsToPlot = 3:8;

for i = 1:length(columnsToPlot)
    subplot(length(columnsToPlot), 1, i); % Create a subplot for each column
    plot(hrv_table_ga_time{:, columnsToPlot(i)}); % Plot the data in the i-th selected column
    title(hrv_table_ga_time.Properties.VariableNames{columnsToPlot(i)}); % Set the title as the column name
    xlabel('Time (minutes)'); % Label x-axis
    ylabel(hrv_table_ga_time.Properties.VariableNames{columnsToPlot(i)}); % Label y-axis

    % Set x-ticks and x-tick labels
    xticks(xTickValues);
    xticklabels(xTickLabels);
end

sgtitle(strcat('Time domain HRV, mouse\_', mouse_seq(c_seq), ', ', datestr(highlightDates(t_seq))));
