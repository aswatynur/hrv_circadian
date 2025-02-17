% function to calculate time domain hrv
% input:
%   rr: peak to peak
%   fs: sample frequency in a second
%   duration: data will be breakdown into duration, (minutes)
%   filter_type: removing ectopic and artefact (range, moving_average,
%                                               quotient, combined)
% output: hrv_time
function [T_hrv_time, T_hrv_freq] = get_time_domain(rr, fs, duration, filter_type, totalTickRange, initialTimestamp)
    % setup hrv_time analysis    
    pnn_thresh_ms = 6;

    % setup freq_time analysis  
    % description: VLF frequency band range (Hz)
    vlf_band = [0.0056, 0.152];
    % description: LF frequency band range (Hz)
    lf_band = [0.152,  1.240];
    % description: HF frequency band range (Hz)    
    hf_band = [1.240,   5];
    % description: Duration of winodow for spectral averaging (min)
    window_minutes = [];
    % description: Percent overlap between windows when using welch method ('%')
    welch_overlap = 50;
    % description: Order of AR model to fit (n.u.)
    ar_order = 30;
    % description: Frequency range for log-log slope calculation (beta) (Hz)
    beta_band = [0.0056, 0.152];
    % method {'lomb', 'ar', 'welch', 'fft'}
    methods = {'welch'};

    % get rr, rri and filtering rr and rri
    rri =  [rr(1) diff(rr)];
    [rri, rr] = rr_filter(rri, rr, fs, filter_type, 1);

    % get the number of rr groups
    totalGroups = ceil(totalTickRange/fs/(60*duration));
    groupRanges = 0:(60*duration):(totalGroups*60*duration);

    % prepare table to store time domnain analysis results
    columns = {'Timestamp', 'AVBPM', 'AVNN', 'SDNN', 'RMSSD', 'pNN6', 'SEM'};
    columntypes = {'datetime', 'double', 'double', 'double', 'double', 'double', 'double'};
    T_hrv_time = table('Size', [0, length(columns)], 'VariableTypes', columntypes, 'VariableNames', columns);

    % prepare table to store freq domnain analysis results
    freqColumns = {'Timestamp', 'BETA', 'HF_NORM', 'HF_PEAK', 'HF_POWER', 'LF_NORM', 'LF_PEAK', 'LF_POWER', 'LF_TO_HF', 'TOTAL_POWER', 'VLF_NORM', 'VLF_POWER'};
    
    freqColumntypes = {'datetime', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double'};
    T_hrv_freq = table('Size', [0, length(freqColumns)], 'VariableTypes', freqColumntypes, 'VariableNames', freqColumns);

    h = waitbar(0, 'Calculate hrv');

    % Group rr and rri data by minute ranges
    for i = 1:totalGroups
        
        % Define the start and end tick of the current minute
        startSecond = groupRanges(i);
        endSecond = groupRanges(i+1);
        startTime = initialTimestamp + (startSecond/(24*60*60));
        
        % Find indices of rr and rri within the current minute
        idx = rr > startSecond & rr <= endSecond;
        
        % Calculate hrv_time
        try
            if length(length(rri(idx))) == 0
                 ME = MException('MATLAB:test', 'Error No rri: time domain');
                 throw(ME);
            end
            newHrvTime = mhrv.hrv.hrv_time(rri(idx), 'pnn_thresh_ms', pnn_thresh_ms);
            newHrvTime.AVBPM = 60*fs/newHrvTime.AVNN;
            newHrvTime.Timestamp = datetime(startTime, 'ConvertFrom', 'datenum');
            T_hrv_time = [T_hrv_time; newHrvTime];
        catch ME
            newRow = array2table(nan(1, 7));
            newRow.Properties.VariableNames = T_hrv_time.Properties.VariableNames;
            newRow.Timestamp = datetime(startTime, 'ConvertFrom', 'datenum');
            T_hrv_time = [T_hrv_time; newRow];
            fprintf('An error occurred on hrv time: %s, number of rr is %d\n', ME.message, length(rri(idx)));
        end

        % Calculate hrv_freq
        try
            newHrvFreq = mhrv.hrv.hrv_freq(rri(idx), 'vlf_band', vlf_band, 'lf_band', lf_band, 'hf_band', hf_band, 'window_minutes', window_minutes, 'ar_order', ar_order, 'welch_overlap', welch_overlap, 'methods', methods);
            newHrvFreq.Properties.VariableNames = freqColumns(1,2:12);
            newHrvFreq.Timestamp = datetime(startTime, 'ConvertFrom', 'datenum');
            T_hrv_freq = [T_hrv_freq; newHrvFreq];
        catch ME
            newRow = array2table(nan(1, 11));
            newRow.Properties.VariableNames = freqColumns(1,2:12);
            newRow.Timestamp = datetime(startTime, 'ConvertFrom', 'datenum');
            T_hrv_freq = [T_hrv_freq; newRow];
            fprintf('An error occurred on hrv freq: %s, number of rr is %d\n', ME.message, length(rri(idx)));
        end
        
        waitbar(i / totalGroups, h, sprintf('Calculate time hrv: %d %%', floor(i / totalGroups * 100)));
    end
    close(h);
end
