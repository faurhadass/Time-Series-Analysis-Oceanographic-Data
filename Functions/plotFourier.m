function plotFourier(xsec, selected_points, parameter, minPeriod, maxPeriod, timeFrame, detrendOption, magnitudeScale)
% plotFourier - Interactively plots FFT spectra for selected (lon, depth) points
%               in an oceanographic cross-section dataset, across time segments.
%
% Inputs:
%   xsec             - Struct with time-resolved data (fields: .timeRes, etc.)
%   selected_points  - Nx2 matrix of [longitude, depth] pairs
%   parameter        - String: field name in xsec (e.g. 'temperature')
%   minPeriod        - Minimum period to show in hours (e.g., 2)
%   maxPeriod        - Maximum period to show in hours (e.g., 1000)
%   timeFrame        - Time segmentation: 'Seasonal', '1 Year', or '3 Years'
%   detrendOption     - 'None', 'Mean', 'Linear'
%   magnitudeScale   - 'Linear' or 'Log' scale for amplitude


% ---------------- Instructions in Command Window ----------------
controlsText = [
    '--- Keyboard Controls ---' newline ...
    '→ / ← : Shift period window right/left' newline ...
    '↑ / ↓ : Zoom in/out on period range' newline ...
    'r     : Reset to last edited period range' newline ...
    'e     : Enter new min/max period manually' newline ...
    '+     : Increase number of peaks' newline ...
    '-     : Decrease number of peaks' newline ...
    'p     : Increase peak prominence factor' newline ...
    'o     : Decrease peak prominence factor' newline ...
    'm     : Increase minimum peak distance' newline ...
    'n     : Decrease minimum peak distance' newline ...
    'Return: Save selected peaks to file and close window' newline ...
    'Click on a point or peak to review and optionally select it' newline ...
    '-------------------------' newline
    ];

fprintf('%s\n', controlsText);


% ---------------- Initial Setup ----------------
xlims = [1/maxPeriod, 1/minPeriod];  % Frequency bounds

selected_peaks = {};  % initialize as an empty cell array


[plot_data, plot_title, data_unit] = assignPlotData(xsec, parameter);
fs = 1 / xsec.timeRes;               % Sampling frequency (1/hour)
totalT = size(plot_data, 3);        % Total time steps
samples_per_year = totalT / 3;

% Peak detection parameters
num_peaks = 0;
peakPromFactor = 0.1;
minDistanceFactor = 3;

% Compute limits
minAllowedPeriod = xsec.timeRes * 2;
maxAllowedPeriod = length(xsec.time) * xsec.timeRes;

% Clamp period range to allowed limits
[minPeriod, maxPeriod] = clampPeriodRange(minPeriod, maxPeriod);
resetMinPeriod = minPeriod;
resetMaxPeriod = maxPeriod;


% Segment labels
if strcmpi(timeFrame, 'Seasonal')
    segment_labels = {'Winter', 'Spring', 'Summer', 'Fall'};
    num_samples=floor(length(xsec.time)/4);
elseif strcmpi(timeFrame, '1 Year')
    segment_labels = {'Year 2016', 'Year 2017', 'Year 2018'};
    num_samples=floor(length(xsec.time)/3);
else
    segment_labels = {'Years 2016–2018'};
    num_samples=length(xsec.time)/3;
end

% ---------------- Create Figure ----------------
nrows = size(selected_points, 1);
ncols = length(segment_labels);
fig = figure('KeyPressFcn', @keyPressCallback);
screen_size = get(0, 'ScreenSize');
fig_width = 300 * ncols;
fig_height = 300 * nrows;
set(fig, 'Position', [(screen_size(3)-fig_width)/2, (screen_size(4)-fig_height)/2, fig_width, fig_height]);
set(fig, 'WindowButtonDownFcn', @mouseClickCallback);

updatePlot();  % Initial plot



% ------------------ Keypress Callback ------------------
    function keyPressCallback(~, event)
        shiftFactor = 3;        % Shift window in hours
        zoomFactor = 0.9;
        promStep = 0.05;          % Adjust prominence factor
        distanceStep = 5;        % Adjust min peak distance

        % Initialize a string to store the summary of changes

        switch event.Key
            case 'rightarrow'
                minPeriod = minPeriod - shiftFactor;
                maxPeriod = maxPeriod - shiftFactor;

            case 'leftarrow'
                minPeriod = minPeriod + shiftFactor;
                maxPeriod = maxPeriod + shiftFactor;

            case 'uparrow'
                center = (minPeriod + maxPeriod) / 2;
                half = (maxPeriod - minPeriod)/2 * zoomFactor;
                minPeriod = center - half;
                maxPeriod = center + half;

            case 'downarrow'
                center = (minPeriod + maxPeriod) / 2;
                half = (maxPeriod - minPeriod)/2 / zoomFactor;
                minPeriod = center - half;
                maxPeriod = center + half;

            case 'r'
                minPeriod = resetMinPeriod;
                maxPeriod = resetMaxPeriod;

            case 'e'
                try
                    newMin = input('New minPeriod (hrs): ');
                    newMax = input('New maxPeriod (hrs): ');
                    if isnumeric(newMin) && isnumeric(newMax) && newMin > 0 && newMax > newMin
                        minPeriod = newMin;
                        maxPeriod = newMax;
                        resetMinPeriod = newMin;
                        resetMaxPeriod = newMax;
                    else
                        disp('Invalid input: min > 0, max > min required.');
                    end
                catch
                    disp('Input canceled or invalid.');
                end

            case 'equal'
                num_peaks = num_peaks + 1;

            case 'hyphen'
                num_peaks = max(0, num_peaks - 1);


            case 'p'
                peakPromFactor = min(1, peakPromFactor + promStep);

            case 'o'
                peakPromFactor = max(0.001, peakPromFactor - promStep);

            case 'm'
                minDistanceFactor = minDistanceFactor + distanceStep;

            case 'n'
                minDistanceFactor = max(1, minDistanceFactor - distanceStep);
            case 'return'  % Enter key pressed
                num_peaks=0;
                updatePlot();

                % Convert to table with column names:
                peakTable = cell2table(selected_peaks, 'VariableNames', {'Frequency [cycles/hour]', 'Period [hours]', 'Amplitude', 'Latitude [°]', 'Longitude [°]', 'Depth [m]', 'Timeframe','Segment', 'Index', 'Parameter'});

                [file, path] = uiputfile('selected_peaks.mat', 'Save Selected Peaks As');
                if ischar(file)  % user didn't cancel
                    save(fullfile(path, file), 'peakTable');
                    disp(['Selected peaks saved to: ', fullfile(path, file)]);
                else
                    disp('Save canceled. Peaks not saved.');
                end
                return;
        end

        % Clamp to dataset-based constraints
        [minPeriod, maxPeriod] = clampPeriodRange(minPeriod, maxPeriod);
        [num_peaks, peakPromFactor, minDistanceFactor] = clampPeakParams( ...
            num_peaks, peakPromFactor, minDistanceFactor, num_samples);


        xlims = sort([1/maxPeriod, 1/minPeriod]);
        num_peaks = min(max(num_peaks, 0), 20);
        peakPromFactor = min(max(peakPromFactor, 0.001), 1);
        minDistanceFactor = min(max(minDistanceFactor, 1), 555);

        % Append final clamped values to summary
        summary = [sprintf('\nClamped values: \n[%.2f, %.2f] hours for minPeriod, maxPeriod\n', minPeriod, maxPeriod)];
        summary = [summary, sprintf('num_peaks: %d, peakPromFactor: %.2f, minDistanceFactor: %d\n', num_peaks, peakPromFactor, minDistanceFactor)];

        % Display the summary at the command line
        disp(summary);

        updatePlot();
    end


% ------------------ Mouse Click Callback ------------------
    function mouseClickCallback(~, ~)

        ax = gca;  % Get clicked axes (subplot)
        point = get(ax, 'CurrentPoint');
        x_click = point(1, 1);
        y_click = point(1, 2);

        % Check bounds
        if ~inBounds(x_click, y_click, ax)
            disp('Clicked point is outside the axis limits.');
            return;
        end

        % Get line(s) in this subplot
        lines = findobj(ax, 'Type', 'line');
        if isempty(lines)
            disp('No line plots found in clicked subplot.');
            return;
        end

        % Use the topmost line
        x_data = lines(1).XData;
        y_data = lines(1).YData;

        % Find index of closest peak to click
        [~, idx] = min((x_data - x_click).^2 + (y_data - y_click).^2);
        x_closest = x_data(idx);
        y_closest = y_data(idx);
        period = 1 / x_closest;

        % Mark it
        hold(ax, 'on');
        h = plot(ax, x_closest, y_closest, 'gx', 'MarkerSize', 8, 'LineWidth', 1.5);
        drawnow;

        % Ask to save
        msg = { ...
            sprintf('Closest point:'), ...
            sprintf('Period = %.2f Hours', period), ...
            sprintf('Amplitude = %.3f', y_closest), ...
            '', ...
            'Save this point?' ...
            };
        choice = questdlg(msg, 'Save Point?', 'Yes', 'No', 'No');

        if strcmp(choice, 'Yes')
            % Define key values for comparison
            new_x = x_closest;
            new_y = y_closest;

            % Initialize duplicate flag
            is_duplicate = false;

            % Check if selected_peaks is not empty
            if ~isempty(selected_peaks)
                for i = 1:size(selected_peaks, 1)
                    if isequal(selected_peaks{i,1}, new_x) && isequal(selected_peaks{i,3}, new_y)
                        is_duplicate = true;
                        break;
                    end
                end
            end

            % Save only if not already saved
            if ~is_duplicate
                selected_peaks{end + 1, 1} = x_closest;
                selected_peaks{end, 2} = period;
                selected_peaks{end, 3} = y_closest;
                selected_peaks{end, 4} = ax.UserData{1};
                selected_peaks{end, 5} = ax.UserData{2};
                selected_peaks{end, 6} = ax.UserData{3};
                selected_peaks{end, 7} = ax.UserData{4};
                selected_peaks{end, 8} = ax.UserData{5};
                selected_peaks{end, 9} = ax.UserData{6};
                selected_peaks{end, 10} = ax.UserData{7};
            end

            % Delete the point from the plot
            updatePlot();
        else
            delete(h);  % Delete even if not saved
            disp('Point not saved.');
        end

    end

    function inside = inBounds(x, y, ax)
        xlim_vals = xlim(ax);
        ylim_vals = ylim(ax);
        inside = x >= xlim_vals(1) && x <= xlim_vals(2) && ...
            y >= ylim_vals(1) && y <= ylim_vals(2);
    end


% ------------------ Update Plot ------------------
    function updatePlot()
        clf;
        for i = 1:nrows
            lon = selected_points(i, 1);
            depth = selected_points(i, 2);
            segments = extractTimeSegments(xsec, plot_data, lon, depth, timeFrame, samples_per_year);

            for s = 1:ncols
                data = segments{s};
                if strcmp(detrendOption, 'Mean')
                    data = data - mean(data);
                end

                if strcmp(detrendOption, 'Linear')
                    data = detrend(data,1);
                end

                N = length(data);
                f = (0:N-1) * fs / N;
                Y = fft(data);
                P2 = abs(Y / N);
                P1 = P2(1:N/2+1);
                P1(2:end-1) = 2 * P1(2:end-1);

                subplot(nrows, ncols, (i-1)*ncols + s);

                subplotIndex = (i-1)*ncols + s;

                if exist('selected_peaks', 'var') && ~isempty(selected_peaks)
                    for p = 1:size(selected_peaks, 1)
                        peakIndex = selected_peaks{p, 9};
                        if isequal(peakIndex, subplotIndex)
                            f_peak = selected_peaks{p, 1};
                            amp_peak = selected_peaks{p, 3};
                            period = selected_peaks{p, 2};
                            plot(f_peak, amp_peak, 'gx', 'MarkerSize', 8, 'LineWidth', 1.5);
                            text(f_peak, amp_peak, sprintf('%.1f ', period), ...
                                'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', ...
                                'FontSize', 8, 'Color', 'k');
                            hold on;
                        end
                    end
                end


                if strcmpi(magnitudeScale, 'Linear')
                    plot(f(1:N/2+1), P1, 'b');   hold on;
                    plotPeaksInRange(f, P1, xlims, num_peaks, peakPromFactor, minDistanceFactor);  
                else
                    logP1 = log(P1 + eps);
                    plot(f(1:N/2+1), logP1, 'b');
                    plotPeaksInRange(f, logP1, xlims, num_peaks, peakPromFactor, minDistanceFactor);
                end

                hold off;

                grid on;
                xlim(xlims);
                title(sprintf('%.2f°E, %.1fm - %s', lon, depth, segment_labels{s}));

                ax = gca;
                ax.UserData = {xsec.lat,  lon, depth, timeFrame, segment_labels{s}, subplotIndex, [parameter, ' ', data_unit]};


                if i == nrows, xlabel('Frequency (cph)'); end
                if s == 1, ylabel('Amplitude'); end
            end
        end
        sgtitle(sprintf('%s | Fourier Transform (%s)', plot_title, upper(char(timeFrame))));
    end

% ------------------ Peak Plotting Helper ------------------
    function plotPeaksInRange(freq, amp, xlims, num_peaks, prom, dist)
        if num_peaks <= 0, return; end

        inRange = freq >= xlims(1) & freq <= xlims(2);
        amp_window = amp(inRange);

        if isempty(amp_window), return; end

        [~, locs_rel] = findpeaks(amp_window, ...
            'MinPeakProminence', prom * max(amp_window), ...
            'MinPeakDistance', dist, ...
            'NPeaks', num_peaks);

        locs_full = find(inRange);
        locs = locs_full(locs_rel);

        plot(freq(locs), amp(locs), 'ro');
    end

    function [minP, maxP] = clampPeriodRange(minP, maxP)
        minAllowed = xsec.timeRes * 2;
        maxAllowed = length(xsec.time) - 1;

        if minP < minAllowed
            minP = minAllowed + 1;
            warning('minPeriod too low. Adjusting to %.2f', minP);

        end
        if maxP > maxAllowed
            warning('maxPeriod too high. Adjusting to %d', maxAllowed);
            maxP = maxAllowed;
        end
        if minP >= maxP
            warning('Adjusted minPeriod >= maxPeriod. Forcing minimal range.');
            minP = max(minAllowed + 1, maxP - 1);
            maxP = minP + 1;
        end
    end

    function [nPeaks, prom, minDist] = clampPeakParams(nPeaks, prom, minDist, num_samples)
        maxMinDist = floor(num_samples / 10);

        % Clamp num_peaks
        nPeaks = max(0, min(20, nPeaks));

        % Clamp peakPromFactor
        prom = max(0.001, min(1, prom));

        % Clamp minDistanceFactor
        minDist = max(1, min(maxMinDist, minDist));
    end

end
