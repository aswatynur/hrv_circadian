function plot_wave(params, dirPlot, colName, ttitle)
    
    % Duration for the plot (24 hours, with finer time resolution)
    t = linspace(0, 24, 1000); % 1000 points between 0 and 24 hours
    
    % Cosine model function
    cosineModel = @(b, t) b(1) * cos(2 * pi / b(2) * t + b(3)) + b(4);
    
    % Initialize figure
    figureHandle = figure;
    hold on;
    
    % Plot each parameter set
    colors = ['r', 'b']; % Colors for the plots
    legend_text = ["Before", "After"];
    
    for i = 1:length(params)
        b = params{i};
        y = cosineModel(b, t); % Compute the cosine model
        plot(t, y, 'Color', colors(i), 'LineWidth', 2, 'DisplayName', legend_text(i));
        
        % Add horizontal line for mesor
        yline(b(4), '--', 'Color', colors(i), 'DisplayName', sprintf('Mesor (%s)', legend_text(i)));
        
        % Add vertical line for acrophase
        acrophaseTime = mod(-b(3) * b(2) / (2 * pi), b(2)); % Time of acrophase, modulo FRP
        xline(acrophaseTime, ':', 'Color', colors(i), 'DisplayName', sprintf('Mesor (%s)', legend_text(i)));
    end
    
    % Add labels and legend
    xlabel('Time (hours)');
    ylabel(colName);
    title(ttitle);
    legend('Location', 'best');
    
    % Customize grid and ticks
    xticks(0:4:24); % Set x-axis ticks at 4-hour intervals
    grid on;
    
    hold off;
%     
%     % Save the figure
%     filefig = strcat(dirPlot, colName, '-wave.fig');
%     saveas(figureHandle, filefig); % Save as .fig
    filefig = strcat(dirPlot, colName, '-wave.png');
    exportgraphics(figureHandle, filefig, 'Resolution', 300); % Save as .png with 300 DPI

    % Close the figure
    close(figureHandle);
end