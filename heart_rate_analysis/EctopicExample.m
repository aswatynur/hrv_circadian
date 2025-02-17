clc;
tic;

% This script is used to generate plot of ectopic example and filtered results.
% 
% set the locaion of mat files
filename = 'C:\Users\anur803\OneDrive - The University of Auckland\Documents\Main_Project_2024_mat\Mouse01 to 08_20240603 am.mat';
data = load(filename);
ecg = data.data__chan_2_rec_1;
[rr, rri, hr, bpfecg] = get_HR_BPM(ecg);

fs = 1000;
filter_type = 'range';
[rri_clean, rr_clean] = rr_filter([rr(1) rri], rr, fs, filter_type, 0);
rri_clean = floor(rri_clean * fs);
rr_clean = floor(rr_clean * fs);
ectopicIndices = setdiff(rr, rr_clean);

% Define the signal range you want to plot
startIdx = 50000;
endIdx = 55000;

% Extract the segment of the ECG signal
ecgSegment = ecg(startIdx:endIdx);

% Define the time vector for this segment
timeSegment = ((startIdx:endIdx)-startIdx) / fs;  % Convert to seconds

% Extract corresponding RRI data
rrFilteredSegment = rr_clean(rr_clean>=startIdx & rr_clean<=endIdx) - startIdx +1;  % Replace with the relevant extraction method
rrUnfilteredSegment = rr(rr>=startIdx & rr<=endIdx) - startIdx + 1;  % Replace with the relevant extraction method

% Adjust indices to be relative to the start of the segment
ectopicIndices = ectopicIndices(ectopicIndices>=startIdx & ectopicIndices<=endIdx) - startIdx + 1;

% Plot the ECG segment
figure('Position', [10 0 500 600]);

% Plot the unfiltered RRI data
subplot(3, 1, 1);
plot(timeSegment, ecgSegment);
hold on;
plot(timeSegment(rrUnfilteredSegment), ecgSegment(rrUnfilteredSegment), 'kx', 'MarkerSize', 8);
hold off;
xlabel('Time (s)');
title('ECG Signal Segment with Unfiltered R-R Interval');

% Mark ectopic beats on the ECG plot
subplot(3, 1, 2);
plot(timeSegment, ecgSegment);
hold on;
plot(timeSegment(ectopicIndices), ecgSegment(ectopicIndices), 'ro', 'MarkerSize', 8);
hold off;
xlabel('Time (s)');
title('ECG Signal Segment with Ectopic Beats');

% Plot the filtered RRI data
subplot(3, 1, 3);
plot(timeSegment, ecgSegment);
hold on;
plot(timeSegment(rrFilteredSegment), ecgSegment(rrFilteredSegment), 'mx', 'MarkerSize', 8);
hold off;
xlabel('Time (s)');
title('ECG Signal Segment with Filtered R-R Interval');

% Optional: Adjust layout for clarity
linkaxes(findall(gcf,'type','axes'),'x'); % Link x-axes for zooming