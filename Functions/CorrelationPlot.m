function CorrelationPlot(xsec, selected_points)
    %% --- Select First Point ---
    idx1 = listdlg( ...
        'PromptString', 'Select the FIRST point for correlation:', ...
        'ListString', composePointLabels(selected_points), ...
        'SelectionMode', 'single', ...
        'ListSize', [300, 200]);

    if isempty(idx1)
        disp('No first point selected. Exiting.');
        return;
    end
    point1 = selected_points(idx1, :);
    xsec1 = xsec;

    % Immediately select parameter for first point
    [data1, title1, unit1] = selectParameterToPlot(xsec1);

    %% --- Ask if user wants to load a new dataset for second point ---
    choice = questdlg( ...
        'Do you want to select the second point from the same dataset or load another?', ...
        'Select Data Source', ...
        'Same dataset', 'Load another', 'Cancel', ...
        'Same dataset');

    if strcmp(choice, 'Cancel') || isempty(choice)
        disp('Operation canceled.');
        return;
    end

    if strcmp(choice, 'Load another')
        loadLatitudeDatasetFromMat();

        if ~exist('xsec', 'var') || isempty(xsec)
            disp('Second dataset load failed. Aborting.');
            return;
        end

        selected_points_2 = chooseDataPointsToAnalyzeGUI(xsec);
        if isempty(selected_points_2)
            disp('No point selected from second dataset.');
            return;
        end

        idx2 = listdlg( ...
            'PromptString', 'Select the SECOND point:', ...
            'ListString', composePointLabels(selected_points_2), ...
            'SelectionMode', 'single', ...
            'ListSize', [300, 200]);
        if isempty(idx2)
            disp('No second point selected.');
            return;
        end
        point2 = selected_points_2(idx2, :);
        xsec2 = xsec;

    else
        idx2 = listdlg( ...
            'PromptString', 'Select the SECOND point for correlation:', ...
            'ListString', composePointLabels(selected_points), ...
            'SelectionMode', 'single', ...
            'ListSize', [300, 200]);

        if isempty(idx2)
            disp('No second point selected. Exiting.');
            return;
        end
        point2 = selected_points(idx2, :);
        xsec2 = xsec;
    end

    % Immediately select parameter for second point
    [data2, title2, unit2] = selectParameterToPlot(xsec2);

    %% --- Extract 3-Year Time Series ---
    timeFrame = '3 Years';
    samples_per_year = length(xsec1.time) / 3;

    ts1 = extractTimeSegments(xsec1, data1, point1(1), point1(2), timeFrame, samples_per_year);
    ts2 = extractTimeSegments(xsec2, data2, point2(1), point2(2), timeFrame, samples_per_year);

    ts1 = ts1{1};
    ts2 = ts2{1};
    t = xsec1.time;

    %% --- Plot Correlation ---
    plotTimeSeriesCorrelation(ts1, ts2, t, title1, title2, unit1, unit2, point1, point2, xsec1.lat, xsec2.lat);
end

%% Helper: Format point list for display
function labels = composePointLabels(points)
    labels = arrayfun(@(i) sprintf('Point %d: Lon %.2f, Depth %.1f', ...
        i, points(i,1), points(i,2)), 1:size(points,1), 'UniformOutput', false);
end


function plotTimeSeriesCorrelation(ts1, ts2, t, label1, label2, unit1, unit2, point1, point2, lat1, lat2)

% --- Normalize the signals ---
ts1 = (ts1 - mean(ts1)) / std(ts1);
ts2 = (ts2 - mean(ts2)) / std(ts2);

% --- Cross-correlation ---
maxLag = 9000;  % max lag in hours 
[xc, lags] = xcorr(ts1, ts2, maxLag, 'coeff');

% --- Find maximum correlation and lag ---
[maxCorr, idxMax] = max(xc);
lagAtMax = lags(idxMax);

% Print to command window
fprintf('Maximum correlation: %.3f at lag %d hours\n', maxCorr, lagAtMax);

% --- Plot ---
figure;

% --- Time Series Plot ---
subplot(2,1,1);
plot(t, ts1, 'b'); hold on;
plot(t, ts2, 'r');

legend_str1 = sprintf('Normalized %s | Lat: %.2f°N | Lon: %.2f°E | Depth: %.1fm', ...
    label1, lat1, point1(1), point1(2));
legend_str2 = sprintf('Normalized %s | Lat: %.2f°N | Lon: %.2f°E | Depth: %.1fm', ...
    label2, lat2, point2(1), point2(2));

legend(legend_str1, legend_str2, 'Location', 'best');
ylabel(['[' unit1 '/' unit2 ']']);
title('Time Series');
grid on;

% --- Cross-Correlation Plot ---
subplot(2,1,2);
plot(lags, xc, 'm'); hold on;
xlabel('Lag (hours)');
ylabel('Cross-correlation');
xlim([-maxLag, maxLag]);
title('Cross-correlation Function');
grid on;

% --- Find and label local maxima ---
[peaks, locs] = findpeaks(xc, lags, 'MinPeakProminence', 0.05);  % adjust as needed

% Plot markers and annotate with lag values
plot(locs, peaks, 'ko', 'MarkerFaceColor', 'y');
for i = 1:length(peaks)
    text(locs(i), peaks(i), sprintf('  %d h', locs(i)), ...
        'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left', ...
        'FontSize', 8, 'Color', 'k');
end

end
