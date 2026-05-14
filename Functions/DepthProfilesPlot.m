function DepthProfilesPlot(xsec, plot_data, plot_title, plot_unit, selected_points)
% DepthProfilesPlot - Plot monthly depth profiles in 2-month pairs for
% selected longitudes, using only the first calendar year of data.
% For each pair (Jan–Feb, Mar–Apr, ...), the first month is a solid line,
% the second month is a dashed line, both with the same color.
%
% Inputs:
%   xsec            - struct with fields: depth, lon, lat, time
%   plot_data       - data array (depth x lon x time) to plot
%   plot_title      - string, e.g. 'Temperature'
%   plot_unit       - string, e.g. ' (°C)'
%   selected_points - Nx2 array of [longitude, depth] (depth ignored here)

    if isempty(selected_points)
        error('No selected points provided.');
    end

    % --- normalize time to datetime ---
    if isdatetime(xsec.time)
        tvec = xsec.time(:);
    else
        tvec = datetime(xsec.time(:), 'ConvertFrom', 'datenum');
    end

    % --- extract unique longitude indices for selected points ---
    lon_vals = unique(selected_points(:,1));
    long_indices = zeros(size(lon_vals));
    for k = 1:numel(lon_vals)
        [~, long_indices(k)] = min(abs(xsec.lon(1,:) - lon_vals(k)));
    end

    % --- determine first calendar year in the series ---
    yr0 = year(tvec(1));
    in_first_year = year(tvec) == yr0;

    % For each month (1..12), take the first occurrence index if present
    month_first_idx = NaN(12,1);
    for m = 1:12
        idx = find(in_first_year & month(tvec) == m, 1, 'first');
        if ~isempty(idx)
            month_first_idx(m) = idx;
        end
    end

    % If no months exist in first year, abort
    if all(isnan(month_first_idx))
        error('No monthly samples found in the first year to plot.');
    end

    % --- color map: one color per 2-month pair (6 pairs) ---
    cmap = lines(6); % pair 1: Jan–Feb, 2: Mar–Apr, ..., 6: Nov–Dec

    % --- subplot grid ---
    nplots = numel(long_indices);
    ncols  = ceil(sqrt(nplots));
    nrows  = ceil(nplots / ncols);

    figure('Name', [plot_title ' Depth Profiles (Monthly, 2-Month Pairs)'], 'Color', 'w');

    % --- loop through longitudes ---
    for p = 1:nplots
        subplot(nrows, ncols, p); hold on;

        legend_entries = {};
        L = long_indices(p);

        % Loop over 2-month pairs
        for pair = 1:6
            m1 = 2*pair - 1; % first month in pair (solid)
            m2 = 2*pair;     % second month in pair (dashed)
            clr = cmap(pair, :);

            % First month (solid) if present
            idx1 = month_first_idx(m1);
            if ~isnan(idx1)
                plot(plot_data(:, L, idx1), xsec.depth(:, L), ...
                    'LineWidth', 1.3, 'Color', clr, 'LineStyle', '-');
                legend_entries{end+1} = datestr(tvec(idx1), 'mmm yyyy'); %#ok<AGROW>
            end

            % Second month (dashed) if present
            idx2 = month_first_idx(m2);
            if ~isnan(idx2)
                plot(plot_data(:, L, idx2), xsec.depth(:, L), ...
                    'LineWidth', 1.3, 'Color', clr, 'LineStyle', '--');
                legend_entries{end+1} = datestr(tvec(idx2), 'mmm yyyy'); %#ok<AGROW>
            end
        end

        % axes and labels
        set(gca, 'YDir', 'reverse');
        xlabel([plot_title, ' ', plot_unit]);
        ylabel('Depth (m)');
        axis tight;

        title(sprintf('%s at Lon %.2f° , Lat %.2f°', ...
            plot_title, xsec.lon(1, L), xsec.lat));

        grid on;
        if ~isempty(legend_entries)
            legend(legend_entries, 'Location', 'best');
        end
        hold off;
    end
end
