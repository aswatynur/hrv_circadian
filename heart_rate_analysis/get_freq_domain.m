function hrv_freq_table = get_freq_domain(rr, fs, duration, filter_type)
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
    totalGroups = ceil(rr(end)/(60*duration));
    groupRanges = 0:(60*duration):(totalGroups*60*duration);

    % prepare table to store freq domnain analysis results
    hrv_freq_table = table();
    
    % Group rr and rri data by minute ranges
    for i = 1:totalGroups
        
        % Define the start and end time of the current minute
        startTime = groupRanges(i);
        endTime = groupRanges(i+1);
        
        % Find indices of rr and rri within the current minute
        idx = rr > startTime & rr <= endTime;
        
        % Calculate hrv_freq
        try
            if length(length(rri(idx))) == 0
                 ME = MException('MATLAB:test', 'Error No rri: freq domain');
                 throw(ME);
            end
            hrv_freq = mhrv.hrv.hrv_freq(rri(idx), 'vlf_band', vlf_band, 'lf_band', lf_band, 'hf_band', hf_band, 'window_minutes', window_minutes, 'ar_order', ar_order, 'welch_overlap', welch_overlap, 'methods', methods);
            if height(hrv_freq_table) > 0
                hrv_freq.Properties.VariableNames = hrv_freq_table.Properties.VariableNames;
            end
            hrv_freq_table = [hrv_freq_table; hrv_freq];
        catch ME
            newRow = array2table(zeros(1, 11));
            if height(hrv_freq_table) > 0
                newRow.Properties.VariableNames = hrv_freq_table.Properties.VariableNames;
            end
            hrv_freq_table = [hrv_freq_table; newRow];
            fprintf('An error occurred: %s, number of rr is %d\n', ME.message, length(rri(idx)));
        end
    end
end