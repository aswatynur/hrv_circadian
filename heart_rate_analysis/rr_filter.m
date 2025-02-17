function [rri_clean, rr_clean] = rr_filter(rri, rr, fs, filter_type, replace_ectopic)
    % setup filter type
    % range
    rr_min = 0.05;
    rr_max = 0.24;
    % moving average
    win_length = 10;
    win_threshold = 20;
    % filter_quotient
    rr_max_change = 20;
    
    if strcmp(filter_type, 'range') == 1
        [rri_clean, rr_clean] = mhrv.rri.filtrr(rri/fs, rr/fs, 'filter_quotient', false, 'filter_ma', false, 'filter_range', true, 'rr_min', rr_min, 'rr_max', rr_max);
    elseif strcmp(filter_type, 'moving_average') == 1
        [rri_clean, rr_clean] = mhrv.rri.filtrr(rri/fs, rr/fs, 'filter_quotient', false, 'filter_ma', true, 'win_length', win_length, 'win_threshold', win_threshold);
    elseif strcmp(filter_type, 'quotient') == 1
        [rri_clean, rr_clean] = mhrv.rri.filtrr(rri/fs, rr/fs, 'filter_quotient', true, 'rr_max_change', rr_max_change);
    else
        [rri_clean, rr_clean] = mhrv.rri.filtrr(rri/fs, rr/fs, 'filter_ma', true, 'win_length', win_length, 'win_threshold', win_threshold, 'filter_range', true, 'rr_min', rr_min, 'rr_max', rr_max, 'filter_quotient', true, 'rr_max_change', rr_max_change);
    end

    % replace ectopic with pchip interpolation
    if replace_ectopic
        ectopics = setdiff(rr/fs, rr_clean);
        % Define tolerance for matching ectopic values
        tolerance = 1e-4;  % Adjust tolerance as needed

        % Identify indices of ectopic beats in RRI
        is_ectopic = ismembertol(rr/fs, ectopics);
        
        % Assuming equal time intervals between RRI samples
        time = 1:length(rr);
        
        % Get indices and values of non-ectopic beats
        time_valid = time(~is_ectopic);
        rri_valid = rri(~is_ectopic);
        rr_valid = rr(~is_ectopic);
        
        % Perform PCHIP interpolation to estimate ectopic values
        rri_clean = rri;
        rri_clean(is_ectopic) = pchip(time_valid, rri_valid, time(is_ectopic));
        rri_clean = rri_clean / fs;

        rr_clean = rr / fs;
  

    end
    
end
