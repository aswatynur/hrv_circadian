function results = cosine_fit(data, days, isBefore, duration)
    % Define the cosine function
    cosineModel = @(b, t) b(1) * cos(2 * pi / b(2) * t + b(3)) + b(4);

    % Calculate activity range and dynamic buffer
    activity_range = max(data) - min(data);
    buffer = 0.1 * activity_range; % 10% of the range as buffer

    % Initial guess for [A, f, phi, C]
%     initialGuess = [max(data) + mean(data), 1/(24), 0, mean(data)];
    initialGuess = [(max(data) - min(data)) / 2, 24, 0, mean(data)];
    
    % Set frequency bounds (in Hz), assume that tau is between 23-25 hours
%     freq_min = 23; % Lower bound for frequency
%     freq_max = 25;  % Upper bound for frequency
    freq_min = 23.5; % Lower bound for frequency
    freq_max = 24.5;  % Upper bound for frequency
    
    % Set lower bound and upper bound for parameters
%     lb = [0, freq_min, -pi, -inf]; % Lower bounds for [Amplitude, Frequency, Phase, Offset]
%     ub = [inf, freq_max, pi, inf]; % Upper bounds for [Amplitude, Frequency, Phase, Offset]
    lb = [0, freq_min, -pi, min(data)]; % Lower bounds for [Amplitude, Frequency, Phase, Offset]
    ub = [inf, freq_max, pi, max(data)]; % Upper bounds for [Amplitude, Frequency, Phase, Offset]

    % Set time space
    if isBefore
        results.time = linspace(0, 24*days, length(data));
    elseif days==3
        results.time = linspace(0, 24*(days), length(data));
    else
        results.time = linspace(0, 24*(days), length(data));
    end

    % get interpolation first
    [data_interp, results.dataConfidence] = pchip_interpolate(data);

    % Set new options for lsqcurvefit
    options = optimoptions('lsqcurvefit', ...
                           'MaxIterations', 1000, ...  % Increase max iterations
                           'MaxFunctionEvaluations', 2000, ... % Increase max function evaluations
                           'TolFun', 1e-6, ... % Relax function tolerance
                           'TolX', 1e-6);   % Relax solution tolerance

    % Fit the combined data
    try
        [b, resnorm, residuals, exitflag, output, lambda, jacobian] = ...
            lsqcurvefit(cosineModel, initialGuess, results.time', data, lb, ub, options);
    catch
        data = data_interp;
        initialGuess = [max(data) + mean(data), 1/(24), 0, mean(data)]; 
        [b, resnorm, residuals, exitflag, output, lambda, jacobian] = ...
            lsqcurvefit(cosineModel, initialGuess, results.time', data, lb, ub, options);
    end

    % Generate fitted values
    results.fitData = cosineModel(b, results.time);    

    % Find peaks and valleys
    [results.peaks, results.locsPeaks] = findpeaks(results.fitData, results.time);
    [results.valleys, results.locsValleys] = findpeaks(-results.fitData, results.time); % Find valleys by finding peaks of the negative data
    results.beta = b;

    % get confidence interval
    results.CI = calculate_confidence(b, resnorm, jacobian, data);

    % get F_Test
    [results.FStat, results.PValue] = calculate_f_test(data, results.time', results.fitData);
    
end

function CI = calculate_confidence(beta, resnorm, jacobian, data)
    % Compute the covariance matrix
    J = full(jacobian); % Convert to full matrix if sparse
    covB = inv(J' * J) * resnorm / (length(data) - length(beta));

    stderrB = sqrt(diag(covB));

    % Confidence level (e.g., 95% confidence level)
    alpha = 0.05;
    
    % Calculate the critical value from the t-distribution
    t_value = tinv(1-alpha/2, length(data) - length(beta));
    
    % Calculate the confidence intervals
    CI = [beta - t_value*stderrB, beta + t_value*stderrB];

    % disp('Parameter estimates and 95% confidence intervals:');
    % for i = 1:length(beta)
    %     fprintf('Parameter %d: %.4f (%.4f, %.4f)\n', i, beta(i), CI(i, 1), CI(i, 2));
    % end
end

function [F_stat, p_value] = calculate_f_test(data, time, fitData)
    RSS_full = sum((data - fitData').^2);
    
    reducedModel = @(b, t) b(1) * ones(size(t));
    initialGuessReduced = mean(data);
    b_reduced = lsqcurvefit(reducedModel, initialGuessReduced, time', data', [], []);
    reducedData = reducedModel(b_reduced, time);
    RSS_reduced = sum((data - reducedData).^2);

    p_full = 4;  % Full cosinor model now has 4 parameters: mesor, amplitude, acrophase, period
    p_reduced = 1;  % Reduced model has 1 parameter: mesor
    N = length(time);  % Number of data points
    
    % Calculate the F-statistic
    F_stat = ((RSS_reduced - RSS_full) / (p_full - p_reduced)) / (RSS_full / (N - p_full));

    % Calculate the p-value
    p_value = 1 - fcdf(F_stat, p_full - p_reduced, N - p_full);

end

function [arr_interp, confidence] = pchip_interpolate(arr)
    % Find the indices of non-NaN values
    x = find(~isnan(arr));
    
    % Get the non-NaN values from the array
    y = arr(x);
    
    % Find the indices of all elements (including NaN)
    xi = 1:length(arr);
    
    % Perform pchip interpolation
    arr_interp = arr; % Create a copy of the array for interpolation
    arr_interp(isnan(arr)) = pchip(x, y, xi(isnan(arr))); % Interpolate NaN values

    % Find the proportion of valid data (non-NaN)
    validDataCount = sum(~isnan(arr)); % Number of valid data points
    totalDataCount = length(arr);      % Total number of data points
    
    % Calculate confidence as the proportion of valid data
    confidence = validDataCount / totalDataCount;

end
