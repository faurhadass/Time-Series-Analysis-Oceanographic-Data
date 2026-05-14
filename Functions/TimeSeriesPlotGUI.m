function TimeSeriesPlotGUI(xsec, selected_points) 
    % TimeSeriesPlotGUI - Creates a GUI for selecting parameters to plot time series.
    % This function allows the user to choose the parameter, time frame, whether to remove the mean, 
    % and whether to detrend the data linearly before plotting.

    % Create the main GUI figure window
    fig = uifigure('Position', [100, 50, 350, 450], 'Name', 'Time Series Plot Options');

    % --- Parameter Selection Dropdown ---
    uilabel(fig, 'Position', [10, 390, 100, 20], 'Text', 'Select Parameter');
    parameterDropdown = uidropdown(fig, 'Position', [120, 390, 200, 20], ...
        'Items', {'Temperature', 'Salinity', 'Eastward Current Velocity (u)', ...
                  'Northward Current Velocity (v)', 'Current Speed Magnitude'}, ...
        'Value', 'Temperature');  % Default value

    % --- Time Frame Selection Dropdown ---
    uilabel(fig, 'Position', [10, 330, 100, 20], 'Text', 'Time Frame');
    timeFrameDropdown = uidropdown(fig, 'Position', [120, 330, 200, 20], ...
        'Items', {'3 Years', '1 Year', 'Seasonal'}, 'Value', '3 Years');

    % --- Remove Mean Option ---
    uilabel(fig, 'Position', [10, 290, 100, 20], 'Text', 'Remove Mean?');
    meanDropdown = uidropdown(fig, 'Position', [120, 290, 200, 20], ...
        'Items', {'Yes', 'No'}, 'Value', 'No');

    % --- Detrend Option ---
    uilabel(fig, 'Position', [10, 250, 120, 20], 'Text', 'Linear Detrend?');
    detrendDropdown = uidropdown(fig, 'Position', [140, 250, 180, 20], ...
        'Items', {'Yes', 'No'}, 'Value', 'No');

    % --- Confirm Button ---
    applyButton = uibutton(fig, 'Position', [120, 20, 100, 30], 'Text', 'Confirm', ...
        'ButtonPushedFcn', @(btn, event) applySelectionsToTimeSeriesPlot( ...
        parameterDropdown, timeFrameDropdown, meanDropdown, detrendDropdown, ...
        xsec, selected_points, fig));
end


% --- Callback to Gather Settings and Call the Time Series Plotting Function ---
function applySelectionsToTimeSeriesPlot(parameterDropdown, timeFrameDropdown, ...
    meanDropdown, detrendDropdown, xsec, selected_points, fig)
    % applySelectionsToTimeSeriesPlot - Callback function for applying the user-selected options
    % and calling the time series plotting function.
    %
    % Inputs:
    %   parameterDropdown - Dropdown for selecting the parameter to plot
    %   timeFrameDropdown - Dropdown for selecting the time frame
    %   meanDropdown      - Dropdown for deciding whether to remove the mean
    %   detrendDropdown   - Dropdown for deciding whether to detrend the data linearly
    %   xsec              - The dataset containing cross-sectional data
    %   selected_points   - The points selected by the user for plotting
    %   fig               - The GUI figure object (to be closed after plotting)

    % Retrieve user selections from the dropdown menus
    parameter = parameterDropdown.Value;
    timeFrame = timeFrameDropdown.Value;
    removeMean = strcmp(meanDropdown.Value, 'Yes');
    applyDetrend = strcmp(detrendDropdown.Value, 'Yes');

    disp('User Selection Recorded.');

    % Call the time series plotting function with the selected parameters
    plotTimeSeries(xsec, selected_points, parameter, timeFrame, removeMean, applyDetrend);

    % Close the GUI window after applying the selections
    close(fig);
end
