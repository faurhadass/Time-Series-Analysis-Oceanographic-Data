function applySelectionsToPSDPlot( ...
    parameterDropdown, parameterDropdown2, methodDropdown, windowDropdown, ...
    overlapField, segmentField, arOrderField, ...
    nfftModeDropdown, nfftField, ...
    periodRadio, minRangeField, maxRangeField, ...
    timeFrameDropdown, detrendDropdown, magnitudeDropdown, ...
    unitDropdown, plotModeDropdown, ...
    xsec, selected_points, ...
    overlayFreqCheckbox, overlayDecayCheckbox)

% ----------- Parameter Setup -----------
param = parameterDropdown.Value;
param2=parameterDropdown2.Value;
method = methodDropdown.Value;
window = windowDropdown.Value;
overlap = overlapField.Value;
seg_length = segmentField.Value;
p = arOrderField.Value;
timeFrame = timeFrameDropdown.Value;
detrendType = detrendDropdown.Value;
scaleType = magnitudeDropdown.Value;
freq_axis_unit = unitDropdown.Value;
isPeriodMode = periodRadio.Value;
plotMode = plotModeDropdown.Value;
overlayFreq=overlayFreqCheckbox.Value;
overlayDecay=overlayDecayCheckbox.Value;

peaks= [];

fs = 1 / xsec.timeRes;                     % Sampling freq [cph]
minPeriod = xsec.timeRes * 2;              % Nyquist
maxPeriod = length(xsec.time) * xsec.timeRes;

if isPeriodMode
    minFreq = 1 / clamp(max(maxRangeField.Value, minPeriod), minPeriod, maxPeriod);
    maxFreq = 1 / clamp(min(minRangeField.Value, maxPeriod), minPeriod, maxPeriod);
else
    minFreq = clamp(minRangeField.Value, 1 / maxPeriod, 1 / minPeriod);
    maxFreq = clamp(maxRangeField.Value, 1 / maxPeriod, 1 / minPeriod);
end

% ----------- Frequency Unit Conversion Setup -----------
switch freq_axis_unit
    case 'Hertz'
        convFactor = 1 / 3600; % cph to Hz
        xLabelStr = 'Frequency (Hz)';
        freqUnitStr = 'Hz';
    case 'cpd'
        convFactor = 24;       % cph to cpd
        xLabelStr = 'Frequency (cpd)';
        freqUnitStr = 'cpd';
    case 'cph'
        convFactor = 1;        % No change
        xLabelStr = 'Frequency (cph)';
        freqUnitStr = 'cph';
end

% ----------- Segment Logic -----------
switch timeFrame
    case 'Seasonal'
        segment_labels = {'W', 'Sp', 'Sm', 'F'};
    case '1 Year'
        segment_labels = {'2016', '2017', '2018'};
    otherwise
        segment_labels = {'2016–2018'};
end

% ----------- Data Prep -----------
[plot_data, plot_title, data_unit] = assignPlotData(xsec, param);
[plot_data2, plot_title2, data_unit2] = assignPlotData(xsec, param2);
samples_per_year = size(plot_data, 3) / 3;

nrows = size(selected_points, 1);
ncols = length(segment_labels);

all_freq_data = cell(nrows, ncols);
all_psd_data = cell(nrows, ncols);

% For axis limits when needed
globalMinX = inf; globalMaxX = -inf;
globalMinY = inf; globalMaxY = -inf;

% --- Compute all PSD data ---
for i = 1:nrows
    lon = selected_points(i, 1);
    depth = selected_points(i, 2);
    segments = extractTimeSegments(xsec, plot_data, lon, depth, timeFrame, samples_per_year);
    segments2 = extractTimeSegments(xsec, plot_data2, lon, depth, timeFrame, samples_per_year);


    for s = 1:ncols
        data = applyDetrend(segments{s}, detrendType);
        data2 = applyDetrend(segments2{s}, detrendType);


        nfftMode = nfftModeDropdown.Value;
        switch nfftMode
            case 'Data Length'
                nfft = length(data);
            case 'Next Power of 2'
                nfft = 2^nextpow2(length(data));
            case 'Custom'
                nfft = round(nfftField.Value);
                if nfft <= 0
                    error('Custom FFT length must be a positive integer.');
                end
        end

        [f, psd] = computePSD(data, data2, nfft, fs, method, window, overlap, seg_length, p);

        if strcmpi(method, 'Cross PSD')
            psd = abs(psd);  % Magnitude of complex cross-PSD
        end


        idx = (f >= minFreq) & (f <= maxFreq);
        f = f(idx);
        psd = psd(idx);

        f_converted = f * convFactor;
        psd = psd / convFactor;

        all_freq_data{i, s} = f_converted;
        all_psd_data{i, s} = psd;

        % Update global limits (for modes that need it)
        globalMinX = min(globalMinX, min(f_converted));
        globalMaxX = max(globalMaxX, max(f_converted));
        globalMinY = min(globalMinY, min(psd));
        globalMaxY = max(globalMaxY, max(psd));
    end
end

% --- Determine number of subplots depending on plotMode ---
switch plotMode
    case 'Separate Data + Timeframes'
        nSubplots = nrows * ncols;
    case 'Same Plot, Separate Timeframes'
        nSubplots = ncols;
    case 'All Together'
        nSubplots = 1;
    case 'Compare Cross Sections'
        nSubplots = 1;
    otherwise
        error('Invalid plotMode.');
end
singlePlot = (nSubplots == 1);

% Prepare the method info string
methodInfo = sprintf('PSD Method: %s', method);
switch lower(method)
    case {'periodogram'}
        methodInfo = sprintf('%s, Window: %s, FFT Len:  %d', methodInfo, window, nfft);
    case {'welch'}
        methodInfo = sprintf('%s\nWindow: %s, Overlap: %d%%, Segment Len: %d%%, FFT Len:  %d',  ...
            methodInfo, window, round(overlap), round(seg_length), nfft);
    case {'parametric'}
        methodInfo = sprintf('%s\nAR Order (p): %d, FFT Len:  %d', methodInfo, round(p), nfft);

    case {'cross psd'}
        methodInfo = sprintf('%s, Window: %s, Overlap: %d%%, Segment Len: %d%%, FFT Len: %d',  ...
            methodInfo, window, round(overlap), round(seg_length), nfft);
end

figure('Name', methodInfo, 'NumberTitle', 'off');

hold on;

switch plotMode
    case 'Separate Data + Timeframes'
        % Plot each (point x timeframe) in separate subplot
        for i = 1:nrows
            lon = selected_points(i, 1);
            depth = selected_points(i, 2);
            bottom_depth=selected_points(i, 3);

            for s = 1:ncols
                subplot(nrows, ncols, (i-1)*ncols + s);
                f_converted = all_freq_data{i, s};
                psd = all_psd_data{i, s};

                if strcmpi(scaleType, 'Log')
                    loglog(f_converted, psd, 'b');
                    set(gca, 'XScale', 'log', 'YScale', 'log');
                    if overlayDecay
                        plotSpectralDecay(f_converted, psd, min(f_converted), max(f_converted), 'r');
                    end
                else
                    plot(f_converted, psd, 'b');
                end

                hold on;

                grid on;
                xlim([globalMinX, globalMaxX]);
                ylim([globalMinY, globalMaxY]);

                ax = gca;
                ax.YAxis.Exponent = 0;                    % don’t use scientific exponent
                ax.YRuler.SecondaryLabel.String = '';     % hide the '×10^n' text

                

                if ~singlePlot
                    title(sprintf('%.2f°E, %.2f°N, %.1fm, B:%.1fm- %s', lon, xsec.lat, depth, bottom_depth, segment_labels{s}));
                end

                if i == nrows
                    xlabel(xLabelStr);
                end

                if s == 1
                    if strcmp(method, 'Cross PSD')
                        ylabel(sprintf('%s*%s / %s', data_unit, data_unit2, freqUnitStr));
                    else
                        ylabel(sprintf('%s² / %s', data_unit, freqUnitStr));
                    end
                end

                if (overlayFreq)
                    peaks = internalWaveKnownSpectralPeaks(xsec.lat);
                    plotKnownPeaks(peaks, convFactor);
                end

            end
        end
        if strcmp(method, 'Cross PSD')
            sgtitle(sprintf('%s, %s | Cross PSD (%s)', plot_title, plot_title2, upper(timeFrame)));
        else
            sgtitle(sprintf('%s | PSD (%s)', plot_title, upper(timeFrame)));
        end

    case 'Same Plot, Separate Timeframes'
        % One subplot per timeframe, all points overlaid with legend labeling points
        for s = 1:ncols
            subplot(1, ncols, s);
            colors = lines(nrows);
            for i = 1:nrows
                f_converted = all_freq_data{i, s};
                psd = all_psd_data{i, s};
                lon = selected_points(i, 1);
                depth = selected_points(i, 2);
                bottom_depth=selected_points(i, 3);
                labelStr = sprintf('%.2f°E,%.2f°N, %.1fm, B: %.1fm', lon, xsec.lat, depth,bottom_depth);

                if strcmpi(scaleType, 'Log')
                    loglog(f_converted, psd, 'Color', colors(i,:), 'DisplayName', labelStr);
                    set(gca, 'XScale', 'log', 'YScale', 'log');
                    if overlayDecay
                        plotSpectralDecay(f_converted, psd, min(f_converted), max(f_converted), colors(i,:));
                    end
                else
                    plot(f_converted, psd, 'Color', colors(i,:), 'DisplayName', labelStr);
                end
                hold on;


            end
            grid on;
            xlim([globalMinX, globalMaxX]);
            ylim([globalMinY, globalMaxY]);
         
             ax = gca;
             ax.YAxis.Exponent = 0;                    % don’t use scientific exponent
             ax.YRuler.SecondaryLabel.String = '';     % hide the '×10^n' text


            if ~singlePlot
                title(segment_labels{s});
            end

            if (overlayFreq)
                peaks = internalWaveKnownSpectralPeaks(xsec.lat);
                plotKnownPeaks(peaks, convFactor);

            end

            xlabel(xLabelStr);
            if strcmp(method, 'Cross PSD')
                ylabel(sprintf('%s*%s / %s', data_unit, data_unit2, freqUnitStr));
            else
                ylabel(sprintf('%s² / %s', data_unit, freqUnitStr));
            end
            legend('Location', 'bestoutside', 'Interpreter', 'none');


        end
        if strcmp(method, 'Cross PSD')
            sgtitle(sprintf('%s, %s | Cross PSD (%s)', plot_title, plot_title2, upper(timeFrame)));
        else
            sgtitle(sprintf('%s | PSD (%s)', plot_title, upper(timeFrame)));
        end

    case 'All Together'
        % One single plot with all data from all points and timeframes combined
        colors = lines(nrows * ncols);
        colorIdx = 1;
        for s = 1:ncols
            for i = 1:nrows
                f_converted = all_freq_data{i, s};
                psd = all_psd_data{i, s};
                lon = selected_points(i, 1);
                depth = selected_points(i, 2);
                bottom_depth=selected_points(i, 3);
                labelStr = sprintf('%s - %.2f°E,%.2f°N, %.1fm, B: %.1fm',segment_labels{s}, lon, xsec.lat, depth,bottom_depth);

                if strcmpi(scaleType, 'Log')
                    loglog(f_converted, psd, 'Color', colors(colorIdx,:), 'DisplayName', labelStr);
                    if overlayDecay
                        plotSpectralDecay(f_converted, psd, min(f_converted), max(f_converted), colors(colorIdx,:));
                    end
                else
                    plot(f_converted, psd, 'Color', colors(colorIdx,:), 'DisplayName', labelStr);
                end

                hold on;


                colorIdx = colorIdx + 1;

            end
        end
        grid on;
        if strcmpi(scaleType, 'Log')
            set(gca, 'XScale', 'log', 'YScale', 'log');
        end
        xlabel(xLabelStr);
        if strcmp(method, 'Cross PSD')
            ylabel(sprintf('%s*%s / %s', data_unit, data_unit2, freqUnitStr));
        else
            ylabel(sprintf('%s² / %s', data_unit, freqUnitStr));
        end
        legend('Location', 'bestoutside', 'Interpreter', 'none');
        xlim([globalMinX, globalMaxX]);
        ylim([globalMinY, globalMaxY]);
         ax = gca;
         ax.YAxis.Exponent = 0;                    % don’t use scientific exponent
         ax.YRuler.SecondaryLabel.String = '';     % hide the '×10^n' text
        if (overlayFreq)
            peaks = internalWaveKnownSpectralPeaks(xsec.lat);
            plotKnownPeaks(peaks, convFactor);

        end
        if strcmp(method, 'Cross PSD')
            sgtitle(sprintf('%s, %s | Cross PSD (%s)', plot_title, plot_title2, upper(timeFrame)));
        else
            sgtitle(sprintf('%s | PSD (%s)', plot_title, upper(timeFrame)));
        end

   case 'Compare Cross Sections'
    all_xsecs = struct();
    all_selected = struct();

    % Store the first cross section as 'Xsec1'
    all_xsecs.Xsec1 = xsec;
    all_selected.Xsec1 = selected_points;

    % Ask user how many additional cross sections to add (1 or 2)
    prompt = 'How many additional cross sections to compare? (1 or 2): ';
    nExtra = str2double(inputdlg(prompt, 'Add Cross Sections', [1 35], {'1'}));

    for ix = 1:nExtra
        loadLatitudeDatasetFromMat();  % Load new xsec
        newName = sprintf('Xsec%d', ix + 1);  % e.g., Xsec2, Xsec3
        newSelected = chooseDataPointsToAnalyzeGUI(xsec);
        all_xsecs.(newName)    = xsec;
        all_selected.(newName) = newSelected;
    end

    xsecNames = fieldnames(all_xsecs);

    % Prepare lists for combined overlays
    all_combined_freqs  = {};
    all_combined_psds   = {};
    all_combined_labels = {};
    all_combined_lon    = [];
    all_combined_lat    = [];

    numX = length(xsecNames);

    % First pass: collect PSD data without plotting yet
    for a = 1:numX
        name     = xsecNames{a};
        thisXsec = all_xsecs.(name);
        points   = all_selected.(name);

        if ~isempty(points)
            points = sortrows(points, 1);  % sort by longitude
        end

        [plot_data, ~, ~] = assignPlotData(thisXsec, param);
        samples_per_year = size(plot_data, 3) / 3;

        for pp = 1:size(points,1)
            lon   = points(pp, 1);
            depth = points(pp, 2);
            bottom_depth=points(pp, 3);

            fs_local = 1 / thisXsec.timeRes;
            segs = extractTimeSegments(thisXsec, plot_data, lon, depth, timeFrame, samples_per_year);
            data = applyDetrend(segs{1}, detrendType);

            switch nfftMode
                case 'Data Length'
                    nfft = length(data);
                case 'Next Power of 2'
                    nfft = 2^nextpow2(length(data));
                case 'Custom'
                    nfft = round(nfftField.Value);
                    if nfft <= 0
                        error('Custom FFT length must be a positive integer.');
                    end
            end

            [f, psd] = computePSD(data, data2, nfft, fs_local, method, window, overlap, seg_length, p);
            idx    = (f >= minFreq) & (f <= maxFreq);
            f_conv = f(idx) * convFactor;
            psd    = psd(idx) / convFactor;

            labelStr = sprintf('%.2f°E, %.2f°N, %.1fm, B: %.1fm', lon, thisXsec.lat, depth, bottom_depth);

            all_combined_freqs{end+1}  = f_conv;
            all_combined_psds{end+1}   = psd;
            all_combined_labels{end+1} = labelStr;
            all_combined_lon(end+1,1)  = lon;
            all_combined_lat(end+1,1)  = thisXsec.lat;
        end
    end

    % Compute global Y-axis limits based on all PSD data
    all_psd_vals = cell2mat(all_combined_psds');
    globalMinY = min(all_psd_vals);
    globalMaxY = max(all_psd_vals);

    % Second pass: create subplots with consistent y-limits
    for a = 1:numX
        name     = xsecNames{a};
        thisXsec = all_xsecs.(name);
        points   = all_selected.(name);

        if ~isempty(points)
            points = sortrows(points, 1);
        end

        subplot(2, numX, a);
        hold on; grid on;

        [plot_data, plot_title, data_unit] = assignPlotData(thisXsec, param);
        samples_per_year = size(plot_data, 3) / 3;
        colorBankLocal = lines(max(size(points,1), 8));

        for pp = 1:size(points,1)
            lon   = points(pp, 1);
            depth = points(pp, 2);
            bottom_depth = points(pp, 3);
         
            fs_local = 1 / thisXsec.timeRes;
            segs = extractTimeSegments(thisXsec, plot_data, lon, depth, timeFrame, samples_per_year);
            data = applyDetrend(segs{1}, detrendType);

            switch nfftMode
                case 'Data Length'
                    nfft = length(data);
                case 'Next Power of 2'
                    nfft = 2^nextpow2(length(data));
                case 'Custom'
                    nfft = round(nfftField.Value);
                    if nfft <= 0
                        error('Custom FFT length must be a positive integer.');
                    end
            end

            [f, psd] = computePSD(data, data2, nfft, fs_local, method, window, overlap, seg_length, p);
            idx    = (f >= minFreq) & (f <= maxFreq);
            f_conv = f(idx) * convFactor;
            psd    = psd(idx) / convFactor;

            labelStr = sprintf('%.2f°E, %.2f°N, %.1fm, B: %.1fm', lon, thisXsec.lat, depth, bottom_depth);

            if strcmpi(scaleType, 'Log')
                loglog(f_conv, psd, 'DisplayName', labelStr, 'Color', colorBankLocal(pp,:));
                if overlayDecay
                    plotSpectralDecay(f_conv, psd, min(f_conv), max(f_conv), colorBankLocal(pp,:));
                end
                set(gca, 'XScale', 'log', 'YScale', 'log');
            else
                plot(f_conv, psd, 'DisplayName', labelStr, 'Color', colorBankLocal(pp,:));
            end
        end

        xlabel(xLabelStr);
        if strcmp(method, 'Cross PSD')
            ylabel(sprintf('%s*%s / %s', data_unit, data_unit2, freqUnitStr));
        else
            ylabel(sprintf('%s² / %s', data_unit, freqUnitStr));
        end
        title(sprintf('%s: %s', plot_title, name), 'Interpreter', 'none');
        legend('Location', 'bestoutside');
        xlim([globalMinX, globalMaxX]);
        ylim([globalMinY, globalMaxY]);

        ax = gca;
        ax.YAxis.Exponent = 0;
        ax.YRuler.SecondaryLabel.String = '';

        if overlayFreq
            peaks = internalWaveKnownSpectralPeaks(thisXsec.lat);
            plotKnownPeaks(peaks, convFactor);
        end

        hold off;
    end

    % Final overlay subplot
    subplot(2, numX, numX + (1:numX));
    hold on; grid on;

    numSeries     = numel(all_combined_freqs);
    colorBankGlobal = lines(max(numSeries, 8));
    [~, order]   = sortrows([all_combined_lat, all_combined_lon], [1 2]);

    for kk = 1:numSeries
        ii      = order(kk);
        f_conv  = all_combined_freqs{ii};
        psd     = all_combined_psds{ii};
        labelStr = all_combined_labels{ii};

        if strcmpi(scaleType, 'Log')
            loglog(f_conv, psd, 'Color', colorBankGlobal(kk,:), 'DisplayName', labelStr);
        else
            plot(f_conv, psd, 'Color', colorBankGlobal(kk,:), 'DisplayName', labelStr);
        end
    end

    xlabel(xLabelStr);
    if strcmp(method, 'Cross PSD')
        ylabel(sprintf('%s*%s / %s', data_unit, data_unit2, freqUnitStr));
    else
        ylabel(sprintf('%s² / %s', data_unit, freqUnitStr));
    end
    xlim([globalMinX, globalMaxX]);
    ylim([globalMinY, globalMaxY]);
    title(sprintf('%s PSD (All Cross Sections)', plot_title));
    legend('Location', 'bestoutside');

    if overlayFreq
        peaks = internalWaveKnownSpectralPeaks(all_combined_lat(order(1)));
        plotKnownPeaks(peaks, convFactor);
    end

    if strcmpi(scaleType, 'Log')
        set(gca, 'XScale', 'log', 'YScale', 'log');
    end

hold off;
end


function plotKnownPeaks(peaks, convFactor)
    xlim_vals = xlim;
    ylim_vals = ylim;

    % Define two stagger levels (high and low)
    y_high = ylim_vals(2) * 0.95;
    y_low  = ylim_vals(2) * 0.85;   % slightly lower

    for k = 1:length(peaks.freq_cph)
        x = peaks.freq_cph(k) * convFactor;
        if x >= xlim_vals(1) && x <= xlim_vals(2)
            name = peaks.name{k};

            % vertical line
            xline(x, '--', 'Color', [0.8 0 0], ...
                'LineWidth', 0.7, 'HandleVisibility', 'off');

            % stagger label height: odd=high, even=low
            if mod(k,2)==1
                y_annotate = y_high;
            else
                y_annotate = y_low;
            end

            text(x, y_annotate, name, ...
                'Rotation', 90, ...
                'VerticalAlignment', 'top', ...
                'HorizontalAlignment', 'center', ...
                'FontSize', 10, ...
                'Color', [0.8 0 0], ...
                'BackgroundColor', 'w', ...   % improve visibility
                'Margin', 1, ...
                'HandleVisibility', 'off');
        end
    end
end


end

% ----------- Helper Functions -----------

function out = clamp(val, minVal, maxVal)
out = min(max(val, minVal), maxVal);
end

function detrended = applyDetrend(data, type)
switch type
    case 'Mean',   detrended = data - mean(data);
    case 'Linear', detrended = detrend(data);
    otherwise,     detrended = data;
end
end

function plotSpectralDecay(f, P, fmin, fmax, color)
% Select fit range
mask = f >= fmin & f <= fmax;
f_fit = f(mask);
P_fit = P(mask);

if numel(f_fit) < 3
    warning('Not enough data in selected frequency range for decay fit.');
    return;
end

% Log-log linear fit
logf = log10(f_fit);
logP = log10(P_fit);
coeffs = polyfit(logf, logP, 1);
slope = coeffs(1);

% Fit line
P_fit_line = 10.^(polyval(coeffs, logf));

hold on;
eqnText = sprintf('E(f) ∝ f^{%.2f}', slope);
plot(f_fit, P_fit_line, '--', 'Color', color, 'LineWidth', 1.5, 'DisplayName', eqnText);

% Text with white background for better readability
text(f_fit(end), P_fit_line(end), eqnText, ...
    'HorizontalAlignment', 'right', ...
    'VerticalAlignment', 'bottom', ...
    'FontSize', 8, ...
    'FontWeight', 'bold', ...
    'Color', color, ...
    'BackgroundColor', 'w', ...
    'EdgeColor', color, ...
    'Margin', 2);

hold off;
end
