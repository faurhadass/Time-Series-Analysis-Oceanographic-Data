function FourierPlotGUI(xsec, selected_points)


    % FourierPlotGUI - Creates a GUI for selecting parameters to plot Fourier Transform.
    % This function allows the user to choose the parameter, period range, time frame, 
    % and whether to remove the mean/linear trend before performing the FFT.

    % Create the main GUI figure window
    fig = uifigure('Position', [100, 50, 350, 450], 'Name', 'Fourier Transform Options');

    % --- Parameter Selection Dropdown ---
    uilabel(fig, 'Position', [10, 380, 100, 20], 'Text', 'Select Parameter');
    parameterDropdown = uidropdown(fig, 'Position', [120, 380, 200, 20], ...
        'Items', {'Temperature', 'Salinity', 'Eastward Current Velocity (u)', ...
                  'Northward Current Velocity (v)', 'Current Speed Magnitude'}, ...
        'Value', 'Temperature');  % Default value is 'Temperature'

    % --- Period Limits Slider ---
    uilabel(fig, 'Position', [10, 320, 100, 20], 'Text', 'Period Limits');
    periodRangeSlider = uislider(fig, 'range', 'Position', [120, 300, 200, 3], ...
        'Limits', [xsec.timeRes * 2, length(xsec.time)], 'Value', [xsec.timeRes * 2, length(xsec.time)], 'Orientation', 'horizontal');

    % --- Editable Text Areas for Min and Max Period Display ---
    minPeriodDisplay = uitextarea(fig, 'Position', [120, 230, 80, 20], ...
        'Editable', 'on', 'Value', {num2str(round(periodRangeSlider.Value(1)))}); 
    maxPeriodDisplay = uitextarea(fig, 'Position', [200, 230, 80, 20], ...
        'Editable', 'on', 'Value', {num2str(round(periodRangeSlider.Value(2)))}); 

    % --- Synchronize Slider and Text Displays ---
    periodRangeSlider.ValueChangedFcn = @(src, event) updatePeriodDisplays(src, minPeriodDisplay, maxPeriodDisplay);
    minPeriodDisplay.ValueChangedFcn = @(src, event) updateSliderFromText(src, maxPeriodDisplay, periodRangeSlider);
    maxPeriodDisplay.ValueChangedFcn = @(src, event) updateSliderFromText(minPeriodDisplay, src, periodRangeSlider);

    % --- Time Frame Selection Dropdown ---
    uilabel(fig, 'Position', [10, 180, 100, 20], 'Text', 'Time Frame');
    timeFrameDropdown = uidropdown(fig, 'Position', [120, 180, 200, 20], ...
        'Items', {'3 Years', '1 Year', 'Seasonal'}, 'Value', '3 Years');  % Default value is '3 Years'

    % --- Option to Detrend Data Before FFT Dropdown ---
    uilabel(fig, 'Position', [10, 140, 100, 20], 'Text', 'Detrend Method');
    detrendDropdown = uidropdown(fig, 'Position', [120, 140, 200, 20], ...
        'Items', {'None', 'Mean', 'Linear'}, 'Value', 'None');  % Default is 'None'


    % --- Magnitude Scale Selection Dropdown ---
    uilabel(fig, 'Position', [10, 100, 100, 20], 'Text', 'Magnitude Scale');
    magnitudeDropdown = uidropdown(fig, 'Position', [120, 100, 200, 20], ...
        'Items', {'Linear', 'Log'}, 'Value', 'Linear');  % Default value is 'Linear'

    % --- Confirm Button to Apply Settings and Plot ---
    applyButton = uibutton(fig, 'Position', [120, 20, 100, 30], 'Text', 'Confirm', ...
        'ButtonPushedFcn', @(btn, event) applySelectionsToFourierPlot( ...
        parameterDropdown, periodRangeSlider, timeFrameDropdown, ...
        detrendDropdown, magnitudeDropdown, xsec, selected_points, fig));
end

% --- Callback to Update Text Fields When the Slider Value Changes ---
function updatePeriodDisplays(slider, minDisplay, maxDisplay)
    % updatePeriodDisplays - Updates the minimum and maximum period displays
    % whenever the period range slider value changes.
    %
    % Inputs:
    %   slider     - The period range slider
    %   minDisplay - The text field for displaying the minimum period
    %   maxDisplay - The text field for displaying the maximum period
    
    minVal = round(slider.Value(1));  % Round the min period value
    maxVal = round(slider.Value(2));  % Round the max period value
    slider.Value = [minVal, maxVal];   % Update the slider with rounded values
    minDisplay.Value = {num2str(minVal)};  % Update the text field for min period
    maxDisplay.Value = {num2str(maxVal)};  % Update the text field for max period
end

% --- Callback to Update the Slider When the Text Fields Change ---
function updateSliderFromText(minDisplay, maxDisplay, slider)
    % updateSliderFromText - Updates the period range slider when the min or max
    % period text fields are modified.
    %
    % Inputs:
    %   minDisplay - The text field for the minimum period
    %   maxDisplay - The text field for the maximum period
    %   slider     - The period range slider
    
    minVal = str2double(minDisplay.Value{1});  % Parse the min period from the text field
    maxVal = str2double(maxDisplay.Value{1});  % Parse the max period from the text field
    
    if isnan(minVal) || isnan(maxVal)
        return;  % Exit if the input values are not valid numbers
    end

    % Clamp values to slider limits and ensure correct order (min <= max)
    minVal = max(slider.Limits(1), round(minVal));
    maxVal = min(slider.Limits(2), round(maxVal));
    
    if minVal > maxVal
        % Swap values if min is greater than max
        tmp = minVal;
        minVal = maxVal;
        maxVal = tmp;
    end
    
    minDisplay.Value = {num2str(minVal)};  % Update min period text field
    maxDisplay.Value = {num2str(maxVal)};  % Update max period text field
    slider.Value = [minVal, maxVal];       % Update slider with new values
end

% --- Gather Settings and Call the Fourier Plotting Function ---
function applySelectionsToFourierPlot(parameterDropdown, periodRangeSlider, timeFrameDropdown, ...
    detrendDropdown, magnitudeDropdown, xsec, selected_points, fig)
    % applySelectionsToFourierPlot - Retrieves the user-selected settings and
    % calls the function to plot the Fourier transform.
    %
    % Inputs:
    %   parameterDropdown - Dropdown for selecting the parameter to plot
    %   periodRangeSlider - Slider for selecting the period range
    %   timeFrameDropdown - Dropdown for selecting the time frame
    %   detrendDropdown     - Dropdown for deciding whether to remove the
    %   mean or trendline
    %   magnitudeDropdown - Dropdown for selecting the magnitude scale
    %   xsec              - The dataset containing cross-sectional data
    %   selected_points   - The points selected by the user for plotting
    %   fig               - The GUI figure object (to be closed after plotting)
    
    % Retrieve user selections from the dropdowns and slider
    parameter = parameterDropdown.Value;
    minPeriod = round(periodRangeSlider.Value(1));  % Round the min period value
    maxPeriod = round(periodRangeSlider.Value(2));  % Round the max period value
    timeFrame = timeFrameDropdown.Value;
    detrendOption = strcmp(detrendDropdown.Value, 'Yes');  % Convert to boolean
    magnitudeScale = magnitudeDropdown.Value;

    % Display selections in the console for user confirmation and debugging
    disp('User Selection Recorded.');
    
    % Close the GUI window after applying the settings
    close(fig);
   
    % Call the Fourier plotting function with the user-selected parameters
    plotFourier(xsec, selected_points, parameter, minPeriod, maxPeriod, timeFrame, detrendOption, magnitudeScale);
    
end
