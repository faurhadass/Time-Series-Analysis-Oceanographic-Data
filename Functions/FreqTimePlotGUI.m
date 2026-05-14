function FreqTimePlotGUI(xsec, selected_points)
% FreqTimePlotGUI - GUI for selecting frequency-time plotting options.

fig = uifigure('Position', [100, 50, 850, 560], 'Name', 'Freq-Time Plot Options');

% === LEFT SIDE ===

% --- Transform Type ---
uilabel(fig, 'Position', [20, 500, 120, 20], 'Text', 'Transform Type');
transformDropdown = uidropdown(fig, 'Position', [150, 500, 200, 22], ...
    'Items', {'Spectrogram', 'Wavelet', 'Wavelet Coherence'}, ...
    'ValueChangedFcn', @(dd, event) toggleTransformPanels(dd.Value));

% --- Parameter 1 ---
uilabel(fig, 'Position', [20, 460, 120, 20], 'Text', 'Parameter 1');
param1Dropdown = uidropdown(fig, 'Position', [150, 460, 200, 22], ...
    'Items', {'Temperature', 'Salinity', 'Eastward Current Velocity (u)', ...
              'Northward Current Velocity (v)', 'Current Speed Magnitude'}, ...
    'Value', 'Temperature');

% --- Parameter 2 (for coherence only) ---
uilabel(fig, 'Position', [20, 430, 120, 20], 'Text', 'Parameter 2');
param2Dropdown = uidropdown(fig, 'Position', [150, 430, 200, 22], ...
    'Items', {'Temperature', 'Salinity', 'Eastward Current Velocity (u)', ...
              'Northward Current Velocity (v)', 'Current Speed Magnitude'}, ...
    'Value', 'Salinity', ...
    'Visible', 'off');

% === Spectrogram Settings Panel ===
spectrogramPanel = uipanel(fig, 'Position', [20, 230, 350, 180], 'Title', 'Spectrogram Settings');

uilabel(spectrogramPanel, 'Position', [10, 130, 100, 20], 'Text', 'Window Type');
windowDropdown = uidropdown(spectrogramPanel, 'Position', [120, 130, 200, 22], ...
    'Items', {'Hamming', 'Hann', 'Blackman', 'Rectangular'}, 'Value', 'Hamming');

uilabel(spectrogramPanel, 'Position', [10, 100, 220, 20], 'Text', 'Window Length (% of Data Length)');
winLenField = uieditfield(spectrogramPanel, 'numeric', ...
    'Position', [240, 100, 60, 22], ...
    'Limits', [1, 100], 'RoundFractionalValues', true, ...
    'Value', 20);

uilabel(spectrogramPanel, 'Position', [10, 70, 100, 20], 'Text', 'Overlap (%)');
overlapField = uieditfield(spectrogramPanel, 'numeric', ...
    'Position', [120, 70, 80, 22], 'Value', 50);

uilabel(spectrogramPanel, 'Position', [10, 40, 100, 20], 'Text', 'NFFT Mode');
nfftModeDropdown = uidropdown(spectrogramPanel, 'Position', [120, 40, 120, 22], ...
    'Items', {'Data Length', 'Next Power of 2', 'Custom'}, ...
    'Value', 'Data Length', ...
    'ValueChangedFcn', @(dd, event) toggleCustomNFFT(dd.Value));

uilabel(spectrogramPanel, 'Position', [10, 10, 100, 20], 'Text', 'NFFT');
nfftField = uieditfield(spectrogramPanel, 'numeric', ...
    'Position', [120, 10, 80, 22], ...
    'Visible', 'off', ...
    'Value', 512);

% === Wavelet Settings Panel ===
waveletPanel = uipanel(fig, 'Position', [20, 30, 350, 180], 'Title', 'Wavelet Settings', 'Visible', 'off');

uilabel(waveletPanel, 'Position', [10, 110, 100, 20], 'Text', 'Wavelet Type');
waveletTypeDropdown = uidropdown(waveletPanel, 'Position', [120, 110, 200, 22], ...
    'Items', {'amor', 'morse', 'bump'}, 'Value', 'amor');

uilabel(waveletPanel, 'Position', [10, 80, 100, 20], 'Text', 'Voices/Octave');
voicesField = uieditfield(waveletPanel, 'numeric', ...
    'Position', [120, 80, 80, 22], 'Value', 10);

uilabel(waveletPanel, 'Position', [10, 50, 100, 20], 'Text', 'Plot Type');
waveletStyleDropdown = uidropdown(waveletPanel, 'Position', [120, 50, 200, 22], ...
    'Items', {'Amplitude', 'Power (Scalogram)'}, 'Value', 'Power (Scalogram)');

% === RIGHT SIDE ===

uilabel(fig, 'Position', [400, 460, 120, 20], 'Text', 'Detrend Method');
detrendDropdown = uidropdown(fig, 'Position', [520, 460, 200, 22], ...
    'Items', {'None', 'Mean', 'Linear'}, 'Value', 'None');

uilabel(fig, 'Position', [400, 420, 120, 20], 'Text', 'Magnitude Scale');
magnitudeDropdown = uidropdown(fig, 'Position', [520, 420, 200, 22], ...
    'Items', {'Linear', 'dB'}, 'Value', 'Linear');

% === Frequency Axis Controls ===
freqGroup = uibuttongroup(fig, 'Title', 'Frequency Axis', 'Position', [400, 260, 400, 130]);

uilabel(freqGroup, 'Position', [10, 75, 100, 20], 'Text', 'Min Freq');
freqMinField = uieditfield(freqGroup, 'numeric', ...
    'Position', [120, 75, 80, 22], 'Value', 1/length(xsec.time) * xsec.timeRes);

uilabel(freqGroup, 'Position', [10, 35, 100, 20], 'Text', 'Max Freq');
freqMaxField = uieditfield(freqGroup, 'numeric', ...
    'Position', [120, 35, 80, 22], 'Value', 1 / 2*xsec.timeRes);

uilabel(freqGroup, 'Position', [240, 55, 80, 20], 'Text', 'Freq Unit');
freqUnitDropdown = uidropdown(freqGroup, 'Position', [320, 55, 70, 22], ...
    'Items', {'Hertz', 'cpd', 'cph'}, 'Value', 'cph');

% === Overlay Frequencies and Confirm ===
overlayFreqCheckbox = uicheckbox(fig, 'Position', [400, 210, 300, 22], ...
    'Text', 'Overlay Known Frequencies', 'Value', false);

uibutton(fig, 'Position', [620, 160, 160, 35], 'Text', 'Confirm', ...
    'ButtonPushedFcn', @(btn, event) applySelectionsToFreqTimePlot( ...
        transformDropdown, param1Dropdown, param2Dropdown, ...
        windowDropdown, winLenField, overlapField, ...
        nfftModeDropdown, nfftField, ...
        waveletTypeDropdown, voicesField, waveletStyleDropdown, ...
        freqMinField, freqMaxField, freqUnitDropdown, ...
        detrendDropdown, magnitudeDropdown, ...
        overlayFreqCheckbox, ...
        xsec, selected_points));

% === Initialize ===
toggleTransformPanels('Spectrogram');

    function toggleTransformPanels(method)
    % Show/hide relevant panels and fields based on the transform type

    % Always hide all optional panels/fields first
    spectrogramPanel.Visible = 'off';
    waveletPanel.Visible = 'off';
    param2Dropdown.Visible = 'off';
    detrendDropdown.Visible = 'off';
    magnitudeDropdown.Visible = 'off';
    freqGroup.Visible = 'off';
    overlayFreqCheckbox.Visible = 'off';

    switch method
        case 'Spectrogram'
            spectrogramPanel.Visible = 'on';
            detrendDropdown.Visible = 'on';
            magnitudeDropdown.Visible = 'on';
            freqGroup.Visible = 'on';
            overlayFreqCheckbox.Visible = 'on';
        case 'Wavelet'
            waveletPanel.Visible = 'on';
            detrendDropdown.Visible = 'on';
            magnitudeDropdown.Visible = 'on';
            freqGroup.Visible = 'on';
            overlayFreqCheckbox.Visible = 'on';
        case 'Wavelet Coherence'
            param2Dropdown.Visible = 'on';  % show param2
            % Only param1 + param2 visible
    end
end


    function toggleCustomNFFT(value)
        nfftField.Visible = strcmp(value, 'Custom');
    end

end
