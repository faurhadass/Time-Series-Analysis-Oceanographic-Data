function PSDPlotGUI(xsec, selected_points)
% PSDPlotGUI - Creates a GUI for selecting PSD plotting options,
% with added Cross PSD method for two parameters.

fig = uifigure('Position', [100, 50, 750, 500], 'Name', 'PSD Options');

% === LEFT COLUMN: Estimation Method Settings ===

% --- Parameter Selection ---
uilabel(fig, 'Position', [20, 440, 120, 20], 'Text', 'Select Parameter');
parameterDropdown = uidropdown(fig, 'Position', [150, 440, 200, 22], ...
    'Items', {'Temperature', 'Salinity', 'Eastward Current Velocity (u)', ...
              'Northward Current Velocity (v)', 'Current Speed Magnitude'}, ...
    'Value', 'Temperature');

% --- Second Parameter Selection (for Cross PSD) ---
uilabel(fig, 'Position', [20, 410, 120, 20], 'Text', 'Select Parameter 2', 'Visible', 'off');
parameterDropdown2 = uidropdown(fig, 'Position', [150, 410, 200, 22], ...
    'Items', {'Temperature', 'Salinity', 'Eastward Current Velocity (u)', ...
              'Northward Current Velocity (v)', 'Current Speed Magnitude'}, ...
    'Value', 'Salinity', 'Visible', 'off');

% --- Estimation Method ---
uilabel(fig, 'Position', [20, 370, 120, 20], 'Text', 'Estimation Method');
methodDropdown = uidropdown(fig, 'Position', [150, 370, 200, 22], ...
    'Items', {'Periodogram', 'Welch', 'Parametric', 'Cross PSD'}, ...
    'ValueChangedFcn', @(dd, event) toggleMethodPanels(dd.Value), ...
    'Value', 'Periodogram');

% --- Window Panel (Periodogram and Welch) ---
windowPanel = uipanel(fig, 'Position', [20, 250, 340, 80], 'Title', 'Window Settings');
uilabel(windowPanel, 'Position', [10, 30, 100, 20], 'Text', 'Window Type');
windowDropdown = uidropdown(windowPanel, 'Position', [120, 30, 200, 22], ...
    'Items', {'Hamming', 'Hann', 'Blackman', 'Rectangular'}, 'Value', 'Hamming');

uilabel(windowPanel, 'Position', [10, 5, 100, 20], 'Text', 'FFT Length');
nfftModeDropdown = uidropdown(windowPanel, 'Position', [120, 5, 100, 22], ...
    'Items', {'Data Length', 'Next Power of 2', 'Custom'}, ...
    'Value', 'Data Length', ...
    'ValueChangedFcn', @(dd, event) toggleCustomNFFT(dd.Value));
nfftField = uieditfield(windowPanel, 'numeric', ...
    'Position', [230, 5, 80, 22], ...
    'Visible', 'off', ...
    'Value', 1024);

% --- Welch Panel ---
welchPanel = uipanel(fig, 'Position', [20, 140, 340, 90], 'Title', 'Welch Settings');
uilabel(welchPanel, 'Position', [10, 40, 130, 20], 'Text', 'Overlap (%)');
overlapField = uieditfield(welchPanel, 'numeric', 'Position', [150, 40, 60, 22], 'Value', 50);
uilabel(welchPanel, 'Position', [10, 10, 130, 20], 'Text', 'Segment Length (%)');
segmentField = uieditfield(welchPanel, 'numeric', 'Position', [150, 10, 60, 22], 'Value', 25);

% --- Parametric Panel ---
parametricPanel = uipanel(fig, 'Position', [20, 30, 340, 120], 'Title', 'Parametric Settings');
uilabel(parametricPanel, 'Position', [10, 70, 120, 20], 'Text', 'AR Order (Poles)');
arOrderField = uieditfield(parametricPanel, 'numeric', 'Position', [150, 70, 60, 22], 'Value', 10);

uilabel(parametricPanel, 'Position', [10, 40, 100, 20], 'Text', 'FFT Length');
nfftModeDropdownParam = uidropdown(parametricPanel, 'Position', [120, 40, 100, 22], ...
    'Items', {'Data Length', 'Next Power of 2', 'Custom'}, ...
    'Value', 'Data Length', ...
    'ValueChangedFcn', @(dd, event) toggleCustomNFFTParam(dd.Value));
nfftFieldParam = uieditfield(parametricPanel, 'numeric', ...
    'Position', [230, 40, 80, 22], ...
    'Visible', 'off', ...
    'Value', 1024);


% === RIGHT COLUMN: Plot-Specific Options ===

freqModeGroup = uibuttongroup(fig, 'Title', 'Display Range Mode', ...
    'Position', [400, 300, 320, 130]);
freqRadio = uiradiobutton(freqModeGroup, 'Text', 'Frequency Range (cph)', ...
    'Position', [10, 80, 180, 20]);
periodRadio = uiradiobutton(freqModeGroup, 'Text', 'Period Range (hours)', ...
    'Position', [10, 60, 180, 20], 'Value', true);
uilabel(freqModeGroup, 'Position', [10, 30, 120, 20], 'Text', 'Min Value');
minRangeField = uieditfield(freqModeGroup, 'numeric', ...
    'Position', [140, 30, 80, 22], 'Value', 3);
uilabel(freqModeGroup, 'Position', [10, 5, 120, 20], 'Text', 'Max Value');
maxRangeField = uieditfield(freqModeGroup, 'numeric', ...
    'Position', [140, 5, 80, 22], 'Value', 30);

uilabel(fig, 'Position', [400, 250, 100, 20], 'Text', 'Time Frame');
timeFrameDropdown = uidropdown(fig, 'Position', [500, 250, 200, 22], ...
    'Items', {'3 Years', '1 Year', 'Seasonal'}, 'Value', '3 Years');

uilabel(fig, 'Position', [400, 210, 100, 20], 'Text', 'Detrend Method');
detrendDropdown = uidropdown(fig, 'Position', [500, 210, 200, 22], ...
    'Items', {'None', 'Mean', 'Linear'}, 'Value', 'None');

uilabel(fig, 'Position', [400, 170, 120, 20], 'Text', 'Magnitude Scale');
magnitudeDropdown = uidropdown(fig, 'Position', [500, 170, 200, 22], ...
    'Items', {'Linear', 'Log'}, 'Value', 'Linear');

uilabel(fig, 'Position', [400, 130, 120, 20], 'Text', 'Frequency Axis');
unitDropdown = uidropdown(fig, 'Position', [500, 130, 200, 22], ...
    'Items', {'Hertz', 'cpd', 'cph'}, 'Value', 'cph');

uilabel(fig, 'Position', [400, 90, 120, 20], 'Text', 'Plot Mode');
plotModeDropdown = uidropdown(fig, 'Position', [500, 90, 200, 22], ...
    'Items', {'Separate Data + Timeframes', 'Same Plot, Separate Timeframes', 'All Together', 'Compare Cross Sections'}, ...
    'Value', 'Separate Data + Timeframes');

% === New Overlay Options ===
overlayFreqCheckbox = uicheckbox(fig, 'Position', [400, 60, 300, 20], ...
    'Text', 'Overlay Known Frequencies', 'Value', false);
overlayDecayCheckbox = uicheckbox(fig, 'Position', [400, 40, 300, 20], ...
    'Text', 'Overlay Decay Rate', 'Value', false);

% === Confirm Button ===
uibutton(fig, 'Position', [550, 10, 120, 30], 'Text', 'Confirm', ...
    'ButtonPushedFcn', @(btn, event) applySelectionsToPSDPlot( ...
        parameterDropdown, parameterDropdown2, methodDropdown, windowDropdown, ...
        overlapField, segmentField, arOrderField, ...
        nfftModeDropdown, nfftField, ...
        periodRadio, minRangeField, maxRangeField, ...
        timeFrameDropdown, detrendDropdown, magnitudeDropdown, ...
        unitDropdown, plotModeDropdown, ...
        xsec, selected_points, ...
        overlayFreqCheckbox, overlayDecayCheckbox));

% === Initialization ===
toggleMethodPanels('Periodogram');

    function toggleMethodPanels(method)
        switch method
            case 'Periodogram'
                windowPanel.Visible = 'on';
                welchPanel.Visible = 'off';
                parametricPanel.Visible = 'off';
                parameterDropdown2.Visible = 'off';
            case 'Welch'
                windowPanel.Visible = 'on';
                welchPanel.Visible = 'on';
                parametricPanel.Visible = 'off';
                parameterDropdown2.Visible = 'off';
            case 'Parametric'
                windowPanel.Visible = 'off';
                welchPanel.Visible = 'off';
                parametricPanel.Visible = 'on';
                parameterDropdown2.Visible = 'off';
            case 'Cross PSD'
                windowPanel.Visible = 'on';
                welchPanel.Visible = 'on';
                parametricPanel.Visible = 'off';
                parameterDropdown2.Visible = 'on';
        end
    end

    function toggleCustomNFFT(value)
        nfftField.Visible = strcmp(value, 'Custom');
    end

    function toggleCustomNFFTParam(value)
        nfftFieldParam.Visible = strcmp(value, 'Custom');
    end

end
