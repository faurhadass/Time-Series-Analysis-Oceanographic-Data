function plotTimeSeries(xsec, selected_points, parameter, timeFrame, removeMean, applyDetrend)
% plotTimeSeries - Plots time series at selected longitude-depth points.
%
% Inputs:
%   xsec            - Struct containing latitude dataset fields: lon, depth, lat, timeRes, and time
%   selected_points - Nx2 matrix of selected [lon, depth] points to extract data
%   parameter       - The parameter to plot (e.g., 'temperature', 'salinity', 'u', etc.)
%   timeFrame       - The time frame to plot ('3 Years', '1 Year', or 'Seasonal')
%   removeMean      - Boolean flag indicating whether to remove the mean from the data before plotting
%   applyDetrend    - Boolean flag indicating whether to apply linear detrending

% Retrieve the plot data for the selected parameter
[plot_data, plot_title, ~] = assignPlotData(xsec, parameter);

% Total number of time steps and samples per year (assuming 3 years of data)
totalT = size(plot_data, 3);
samples_per_year = totalT / 3;

% Segment labeling based on the selected time frame
if strcmpi(timeFrame, 'Seasonal')
    segment_labels = {'Winter', 'Spring', 'Summer', 'Fall'};
elseif strcmpi(timeFrame, '1 Year')
    segment_labels = {'Year 2016', 'Year 2017', 'Year 2018'};
else
    segment_labels = {'Years 2016-2018'};
end

num_selected = size(selected_points, 1);

% Compute global min and max across all selected points and segments
global_min = inf;
global_max = -inf;

for i = 1:num_selected
    selected_lon = selected_points(i, 1);
    selected_depth = selected_points(i, 2);
    segments = extractTimeSegments(xsec, plot_data, selected_lon, selected_depth, timeFrame, samples_per_year);

    for s = 1:length(segments)
        data_seg = segments{s};

        if removeMean
            data_seg = detrend(data_seg, 0);
        end
        if applyDetrend
            data_seg = detrend(data_seg, 1);
        end

        global_min = min(global_min, min(data_seg));
        global_max = max(global_max, max(data_seg));
    end
end

% Set up figure
nrows = num_selected;
ncols = length(segment_labels);
fig = figure;
set(fig, 'Units', 'pixels');
screen_size = get(0, 'ScreenSize');
fig_width = 300 * ncols;
fig_height = 300 * nrows;
left = (screen_size(3) - fig_width) / 2;
bottom = (screen_size(4) - fig_height) / 2;
set(fig, 'Position', [left, bottom, fig_width, fig_height]);

% Loop through points and plot
for i = 1:num_selected
    selected_lon = selected_points(i, 1);
    selected_depth = selected_points(i, 2);
    segments = extractTimeSegments(xsec, plot_data, selected_lon, selected_depth, timeFrame, samples_per_year);
    bottom_depth = selected_points(i, 3);

    for s = 1:length(segments)
        data_seg = segments{s};

        if removeMean
            data_seg = detrend(data_seg, 0);
        end
        if applyDetrend
            data_seg = detrend(data_seg, 1);
        end

        [min_val, min_idx] = min(data_seg);
        [max_val, max_idx] = max(data_seg);

        % Time vector
        if strcmpi(timeFrame, 'Seasonal')
            season_start_months = [1, 4, 7, 10];
            t_start = datetime(2016, season_start_months(s), 1, 13, 0, 0);
            t = t_start + hours((0:length(data_seg)-1) * xsec.timeRes);
        elseif strcmpi(timeFrame, '1 Year')
            idx_start = (s-1)*samples_per_year + 1;
            idx_end = s*samples_per_year;
            t = xsec.time(idx_start:idx_end);
        elseif strcmpi(timeFrame, '3 Years')
            t = xsec.time;
        else
            error('Invalid timeFrame');
        end

        [min_val, min_idx] = min(data_seg);
        [max_val, max_idx] = max(data_seg);
        mean_val = mean(data_seg);

        % Print per-segment summary
        fprintf('\n--- %s ---\n', segment_labels{s});
        fprintf('Point %d | Lon: %.2f°E | Depth: %.1fm\n', i, selected_lon, selected_depth);
        fprintf('  Min: %.3f at %s\n', min_val, datestr(t(min_idx), 'dd-mmm-yyyy HH:MM'));
        fprintf('  Max: %.3f at %s\n', max_val, datestr(t(max_idx), 'dd-mmm-yyyy HH:MM'));
        fprintf('  Mean: %.3f\n', mean_val);


        % Plot
        subplot(nrows, ncols, (i-1)*ncols + s);
        plot(t, data_seg, 'LineWidth', 1.1);
        hold on;
        plot(t(min_idx), min_val, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8);
        plot(t(max_idx), max_val, 'bs', 'MarkerFaceColor', 'b', 'MarkerSize', 8);
        hold off;

        % Set same y-axis scale for all subplots
        ylim([global_min, global_max]);

        grid on;
        title_str = sprintf('Long: %.2f°E, Lat: %.2f°N, Depth: %.1fm, Bottom: %.1fm - %s', ...
            selected_lon, xsec.lat, selected_depth, bottom_depth, segment_labels{s});
        title_str = sprintf('%s\nMin: %.2f, Max: %.2f', title_str, min_val, max_val);
        title(title_str);

        if i == num_selected
            xlabel('Time');
        end
        if s == 1
            ylabel('Value');
        end

        if strcmpi(timeFrame, 'Seasonal')
            datetick('x', 'mmm', 'keeplimits');
        elseif ~strcmpi(timeFrame, '3 Years')
            datetick('x', 'mmm yyyy', 'keeplimits');
        end
    end
end

sgtitle([plot_title, ' | Time Series (', upper(timeFrame), ')']);
end
