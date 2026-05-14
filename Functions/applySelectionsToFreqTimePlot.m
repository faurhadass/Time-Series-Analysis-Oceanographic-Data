function applySelectionsToFreqTimePlot( ...
    transformDropdown, param1Dropdown, param2Dropdown, ...
    windowDropdown, winLenField, overlapField, ...
    nfftModeDropdown, nfftField, ...
    waveletTypeDropdown, voicesField, waveletStyleDropdown, ...
    freqMinField, freqMaxField, freqUnitDropdown, ...
    detrendDropdown, magnitudeDropdown, ...
    overlayFreqCheckbox, ...
    xsec, selected_points)

% === Retrieve Selections ===
transformType = transformDropdown.Value;
param1 = param1Dropdown.Value;
param2 = param2Dropdown.Value;

% Common settings
detrendMethod  = detrendDropdown.Value;
magnitudeScale = magnitudeDropdown.Value;   % 'Linear' or 'dB'
freq_axis_unit = freqUnitDropdown.Value;
overlayFreq    = overlayFreqCheckbox.Value;

fs        = 1 / xsec.timeRes;                     % [cph]
maxFreq   = fs / 2;                               % Nyquist [cph]
maxPeriod = length(xsec.time) * xsec.timeRes;     % hours
minFreq   = 1 / maxPeriod;

% Frequency Unit Conversion
switch freq_axis_unit
    case 'Hertz'
        freqConvFactor = 1 / 3600; % cph -> Hz
        freqLabelStr   = 'Frequency (Hz)';
    case 'cpd'
        freqConvFactor = 24;       % cph -> cpd
        freqLabelStr   = 'Frequency (cpd)';
    otherwise
        freqConvFactor = 1;        % cph
        freqLabelStr   = 'Frequency (cph)';
end

% User inputs converted to cph internally
minFreq_cph = freqMinField.Value / freqConvFactor;
maxFreq_cph = freqMaxField.Value / freqConvFactor;
minFreq_cph = max(minFreq_cph, minFreq);
maxFreq_cph = min(maxFreq_cph, maxFreq);

% Data prep
[plot_data1, ~, ~] = assignPlotData(xsec, param1);
if strcmp(transformType, 'Wavelet Coherence')
    [plot_data2, ~, ~] = assignPlotData(xsec, param2);
end

samples_per_year = size(plot_data1, 3) / 3;
timeFrame = '3 Years';

nplots = size(selected_points,1);
ncols  = ceil(sqrt(nplots));
nrows  = ceil(nplots / ncols);

% Collect handles and per-axes min/max to set global caxis after plotting
hImgs = gobjects(nplots,1);
localMins = nan(nplots,1);
localMaxs = nan(nplots,1);

for i = 1:nplots
    subplot(nrows, ncols, i);

    lon = selected_points(i, 1);
    depth = selected_points(i, 2);
    bottom_depth = selected_points(i, 3);

    segments1 = extractTimeSegments(xsec, plot_data1, lon, depth, timeFrame, samples_per_year);
    data1 = segments1{1};
    data1 = applyDetrend(data1, detrendMethod);

    if strcmp(transformType, 'Wavelet Coherence')
        segments2 = extractTimeSegments(xsec, plot_data2, lon, depth, timeFrame, samples_per_year);
        data2 = segments2{1};
        data2 = applyDetrend(data2, detrendMethod);
    end

    switch transformType
        case 'Spectrogram'
            windowType = lower(windowDropdown.Value);
            winLen     = winLenField.Value;
            overlap    = overlapField.Value;
            nfftMode   = nfftModeDropdown.Value;
            switch nfftMode
                case 'Data Length'
                    nfft = length(data1);
                case 'Next Power of 2'
                    nfft = 2^nextpow2(length(data1));
                case 'Custom'
                    nfft = nfftField.Value;
            end
            [hImgs(i), localMins(i), localMaxs(i)] = plotSpectrogram( ...
                fs, data1, windowType, winLen, overlap, nfft, ...
                magnitudeScale, overlayFreq, ...
                minFreq_cph, maxFreq_cph, ...
                freqConvFactor, freqLabelStr, ...
                xsec.lat, depth, lon, bottom_depth, xsec.time);

        case 'Wavelet'
            wavType = waveletTypeDropdown.Value;
            voices  = voicesField.Value;
            magStyle = waveletStyleDropdown.Value;
            [hImgs(i), localMins(i), localMaxs(i)] = plotWavelet( ...
                fs, data1, wavType, voices, ...
                magnitudeScale, magStyle, overlayFreq, ...
                minFreq_cph, maxFreq_cph, ...
                freqConvFactor, freqLabelStr, ...
                xsec.lat, depth, lon, bottom_depth, xsec.time);

        case 'Wavelet Coherence'
            % Coherence has its own [0,1] range; leave as-is
            plotWaveletCoherence(fs, data1, data2, ...
                                 xsec.lat, depth, lon, bottom_depth, xsec.time);
            % Keep placeholders to avoid NaNs breaking min/max
            hImgs(i) = gobjects(1);
            localMins(i) = NaN;
            localMaxs(i) = NaN;
    end
end

% --- Apply a shared magnitude scale across all non-empty subplots ---
% If you only want this when in dB, wrap with: if strcmpi(magnitudeScale,'dB')
valid = ~isnan(localMins) & ~isnan(localMaxs) & isgraphics(hImgs);
if any(valid)
    globalMin = min(localMins(valid));
    globalMax = max(localMaxs(valid));
    % Avoid degenerate ranges
    if globalMin == globalMax
        globalMax = globalMin + eps;
    end
    for hi = hImgs(valid).'
        ax = ancestor(hi, 'axes');
        caxis(ax, [globalMin, globalMax]);
    end
end

% Compose main figure title
mainTitleStr = sprintf('%s - %s', transformType, param1);
if strcmp(transformType, 'Wavelet Coherence')
    mainTitleStr = sprintf('%s & %s', mainTitleStr, param2);
end
if strcmp(transformType, 'Spectrogram')
    mainTitleStr = sprintf('%s (Window: %s, WinLen: %d%%, Overlap: %d%%)', ...
        mainTitleStr, lower(windowDropdown.Value), winLenField.Value, overlapField.Value);
end
sgtitle(mainTitleStr);
end

% ===== helper functions =====

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

function [hImg, sMin, sMax] = plotSpectrogram(fs, data, windowType, winLenPct, overlap, nfft, ...
                     magnitudeScale, overlayFreq, ...
                     minFreq_cph, maxFreq_cph, ...
                     freqConvFactor, freqLabelStr, ...
                     lat, depth, lon, bottom_depth, t)

    % --- Window setup ---
    winLength = max(2, floor(winLenPct/100 * length(data)));
    switch lower(windowType)
        case 'hann',     window = hann(winLength);
        case 'hamming',  window = hamming(winLength);
        case 'blackman', window = blackman(winLength);
        otherwise,       window = rectwin(winLength);
    end
    overlapSamples = round(overlap / 100 * winLength);

    % --- Compute spectrogram ---
    [s, f_cph, t_rel] = spectrogram(data, window, overlapSamples, nfft, fs);
    S = abs(s);
    if strcmpi(magnitudeScale, 'dB'), S = 20 * log10(S + eps); end

    % --- Map time ---
    t_disp = t(1) + hours(t_rel);

    % --- Frequency conversion & masking ---
    freqMask = (f_cph >= minFreq_cph) & (f_cph <= maxFreq_cph);
    f_disp = (f_cph(freqMask)) * freqConvFactor;
    S = S(freqMask, :);

    % --- Cache local min/max for global scaling ---
    sMin = min(S(:));
    sMax = max(S(:));

    % --- Plot ---
    ax = gca;
    hImg = imagesc(ax, t_disp, f_disp, S);
    axis(ax, 'xy');
    xlabel(ax, 'Time');
    ylabel(ax, freqLabelStr);
    title(ax, sprintf('Data Point %.2f°N, %.2f°E, %.1fm, B: %.1fm', ...
        lat, lon, depth, bottom_depth));
    c = colorbar(ax);
    ylabel(c, sprintf('Amplitude (%s)', magnitudeScale));
    ylim(ax, [min(f_disp) max(f_disp)]);

    % --- Overlay known frequency peaks (filtered to band) ---
    if overlayFreq
        peaks = internalWaveKnownSpectralPeaks(lat);
        hold(ax, 'on');
        plotKnownPeaks(peaks, freqConvFactor, [t_disp(1), t_disp(end)], ...
                       minFreq_cph, maxFreq_cph);
        hold(ax, 'off');
    end
end

function plotKnownPeaks(peaks, convFactor, timeLimits, minFreq_cph, maxFreq_cph)
    inBand = (peaks.freq_cph >= minFreq_cph) & (peaks.freq_cph <= maxFreq_cph);
    if ~any(inBand), return; end

    y_vals = peaks.freq_cph(inBand) * convFactor;
    names  = peaks.name(inBand);

    ax = gca;
    yl = ylim(ax);
    xmin = timeLimits(1); xmax = timeLimits(2);
    xText = xmin + (xmax - xmin) * 0.985;

    for k = 1:numel(y_vals)
        y = clamp(y_vals(k), yl(1), yl(2));
        plot([xmin xmax], [y y], '--', 'Color','k', 'LineWidth',0.5, 'HandleVisibility','off');
        text(xText, y, names{k}, 'VerticalAlignment','bottom', 'HorizontalAlignment','right', ...
            'FontSize',8, 'Color','k', 'Rotation',0, 'Clipping','on', 'Interpreter','none', ...
            'HandleVisibility','off');
    end
end

function [hImg, sMin, sMax] = plotWavelet(fs, data, wavType, voices, ...
                     magnitudeScale, magStyle, overlayFreq, ...
                     minFreq_cph, maxFreq_cph, ...
                     freqConvFactor, freqLabelStr, ...
                     lat, depth, lon, bottom_depth, timeVec)

    % --- Compute CWT within frequency limits ---
    [wt, f_cph] = cwt(data, wavType, fs, ...
                      'VoicesPerOctave', voices, ...
                      'FrequencyLimits', [minFreq_cph, maxFreq_cph]);

    % --- Amplitude/Power ---
    if strcmpi(magStyle, 'Amplitude')
        S = abs(wt);
        if strcmpi(magnitudeScale, 'dB'), S = 20 * log10(S + eps); end
        unitLabel = 'Amplitude';
    else
        S = abs(wt).^2;
        if strcmpi(magnitudeScale, 'dB'), S = 10 * log10(S + eps); end
        unitLabel = 'Power';
    end

    % --- Time axis ---
    dt = 1 / fs;  % hours
    t_rel = (0:length(data)-1) * dt;
    t_disp = timeVec(1) + hours(t_rel);

    % --- Frequency display axis ---
    f_disp = f_cph * freqConvFactor;

    % --- Cache local min/max for global scaling ---
    sMin = min(S(:));
    sMax = max(S(:));

    % --- Plot ---
    ax = gca;
    hImg = imagesc(ax, t_disp, f_disp, S);
    axis(ax, 'xy');
    xlabel(ax, 'Time');
    ylabel(ax, freqLabelStr);
    title(ax, sprintf('Data Point %.2f°N, %.2f°E, %.1fm, B: %.1fm', ...
        lat, lon, depth, bottom_depth));
    c = colorbar(ax);
    if strcmpi(magnitudeScale, 'dB')
        ylabel(c, sprintf('%s (dB)', unitLabel));
    else
        ylabel(c, unitLabel);
    end
    ylim(ax, [min(f_disp) max(f_disp)]);

    % --- Overlay known frequency peaks (filtered to band) ---
    if overlayFreq
        peaks = internalWaveKnownSpectralPeaks(lat);
        hold(ax, 'on');
        plotKnownPeaks(peaks, freqConvFactor, [t_disp(1), t_disp(end)], ...
                       minFreq_cph, maxFreq_cph);
        hold(ax, 'off');
    end
end

function plotWaveletCoherence(fs, x, y, ...
                             lat, depth, lon, bottom_depth, timeVec)

    % --- Compute time step in hours ---
    dt = hours(1 / fs);

    % --- Compute wavelet coherence ---
    [wcoh, ~, period, coi] = wcoherence(x, y, dt);

    % --- Convert period and COI to numeric (in hours) for plotting ---
    period_hr = hours(period);
    coi_hr = hours(coi);

    % --- Plot wavelet coherence ---
    h = pcolor(timeVec, log2(period_hr), wcoh);
    h.EdgeColor = 'none';
    shading flat;
    colormap jet;
    colorbar;

    % --- Axis formatting ---
    ax = gca;
    ax.XLabel.String = 'Time';
    ax.YLabel.String = 'Period (hr)';
    ax.Title.String = 'Wavelet Coherence';
    ax.YDir = 'normal';
    ytick = round(pow2(ax.YTick), 3);
    ax.YTickLabel = ytick;

    % --- Cone of influence ---
    hold on;
    plot(timeVec, log2(coi_hr), 'w--', 'LineWidth', 2);
    hold off;

    title(ax, sprintf('Data Point %.2f°N, %.2f°E, %.1fm, B: %.1fm', ...
        lat, lon, depth, bottom_depth));
end
