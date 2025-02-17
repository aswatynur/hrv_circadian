% Step 1: Read the table from a CSV file (if applicable)
% dataTable = readtable('data.csv');



% Step 2: Convert date strings to datetime
dataTable.date = datetime(dataTable.date, 'InputFormat', 'yyyyMMdd');

% Step 3: Extract data from the table
dates = datetime(T.Date, 'InputFormat', 'yyyyMMdd');
means = T.Mean;
stdDevs = T.("Std Dev");

% Step 4: Generate the main plot with specified figure size
figure('Position', [100, 100, 800, 600]); % Set the position and size: [left, bottom, width, height]
errorbar(dates, means, stdDevs, 'o-'); % 'o-' specifies the line and marker style
xlabel('Date');
ylabel('Mean Value');
title('Mean Value with Standard Deviation');
grid on;
hold on; % Hold on to add more plots to the same figure

% Step 5: Highlight specific dates with markers
highlightDates = datetime({'20240408', '20240422', '20240513', '20240527', '20240610', '20240624'}, 'InputFormat', 'yyyyMMdd');
highlightMeans = means(ismember(dates, highlightDates));
highlightStdDevs = stdDevs(ismember(dates, highlightDates));

highlightPlot = plot(highlightDates, highlightMeans, 'r*', 'MarkerSize', 10); % 'r*' specifies red star markers

% Step 6: Add legend
legend({'Mean with Std Dev', 'Highlighted Dates'}, 'Location', 'best');

% Step 7: Analyze stability within 7 days after highlighted dates
stable_start_dates = [];
for i = 1:length(highlightDates)
    startDate = highlightDates(i)+1;
    endDate = startDate + days(7);
    rangeIndices = find(dates > startDate & dates <= endDate);
    
    if ~isempty(rangeIndices)
        rangeMeans = means(rangeIndices);
        rangeStdDevs = stdDevs(rangeIndices);
        
        % Stability criteria example: mean values should be within mean +/- 2*std_dev
        meanValue = mean(rangeMeans);
        stdValue = std(rangeMeans);
        
        % Initialize stability flag and start date
        stable = false;
        stableStartDate = [];
        
        % Check stability condition over the range
        mult = 2;
        for j = 1:length(rangeIndices)
            if all(rangeMeans(j:end) > meanValue - mult * stdValue & rangeMeans(j:end) < meanValue + mult * stdValue)
                stable = true;
                stableStartDate = dates(rangeIndices(j));
                break;
            end
        end
        
        % Store the stable start date
        if stable
            stable_start_dates = [stable_start_dates; stableStartDate];
            fprintf('Stable condition starts on %s within the range from %s to %s.\n', datestr(stableStartDate), datestr(startDate), datestr(endDate));
        else
            fprintf('No stable condition found within the range from %s to %s.\n', datestr(startDate), datestr(endDate));
        end
        
        % Plot stable period
        if stable
            stableIndices = find(dates >= stableStartDate & dates <= endDate);
            plot(dates(stableIndices), means(stableIndices), 'g-', 'LineWidth', 2); % Green line for stable period
        end
    end
end

hold off;
