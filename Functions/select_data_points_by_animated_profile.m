function selected_points = select_data_points_by_animated_profile(xsec)
selected_points = [];
time_skip = 10;
contour_levels = 10;

unique_lons = unique(xsec.lon);
lon_strings = arrayfun(@(lon) sprintf('%.4f', lon), unique_lons, 'UniformOutput', false);


[plot_data, plot_title, ~] = selectParameterToPlot(xsec);
if isempty(plot_data)
    disp('No data selected or operation canceled. Exiting function.');
    return;
end

fig = figure('Units', 'normalized', 'OuterPosition', [0 0 1 1]);
setappdata(fig, 'selected_points', []);
setappdata(fig, 'xsec', xsec);
setappdata(fig, 'stop_flag', false);
setappdata(fig, 'time_skip_current', time_skip);
setappdata(fig, 'contour_levels', contour_levels);

set(fig, 'WindowButtonDownFcn', @(src, ~) onClick(src));
set(fig, 'KeyPressFcn', @onKeyPress);

% Mode flags
setappdata(fig, 'depth_column_mode', false);
setappdata(fig, 'fixed_depth_value', []);
setappdata(fig, 'water_column_mode', false);
setappdata(fig, 'fixed_lon_value', []);
setappdata(fig, 'highlight_line', []);
setappdata(fig, 'plot_mode', 'interpolation');  % Default plot mode

depth_fine = linspace(min(xsec.depth(:)), max(xsec.depth(:)), xsec.nz);
lon_values = unique(xsec.lon(1, :));
Cmin = min(plot_data(:));
Cmax = max(plot_data(:));

uiwait(msgbox({ ...
    'Click to select (Lon, Depth) on each frame.', ...
    '→ : Fast forward (increase time step)', ...
    '← : Slow (decrease time step)', ...
    '↑ : Increase number of contour levels', ...
    '↓ : Decrease number of contour levels', ...
    '"d" to toggle Depth Column Mode (fixes depth)', ...
    '"w" to toggle Water Column Mode (fixes longitude)', ...
    '"i" to toggle Interpolated Contour Mode', ...
    '"s" to toggle Scatter Mode ', ...
    '"q" to quit and finalize selection.'}, ...
    'Instructions'));

t = 1;
while t <= xsec.nt
    if ~ishandle(fig) || getappdata(fig, 'stop_flag')
        disp('Animation stopped by user or figure closed.');
        break;
    end

    updateTimeStep(fig, t);
    time_skip_current = getappdata(fig, 'time_skip_current');
    contour_levels = getappdata(fig, 'contour_levels');  % <-- Get updated contour levels

    clf(fig);

    plotMode = getappdata(fig, 'plot_mode');

    if strcmp(plotMode, "interpolation")
        data_interp = interpolateData(xsec, plot_data, depth_fine, t);
        plotContour(fig, lon_values, depth_fine, data_interp, contour_levels, Cmin, Cmax, plot_title, xsec, t);
    else
        plotScatter(fig, plot_data, plot_title, xsec, t);
    end

    plotSelectedPoints(fig, lon_values, depth_fine);

    drawnow;
    pause(0.03);

    t = t + time_skip_current;
    t = max(1, min(t, xsec.nt));
end

if ishandle(fig)
    selected_points = finalizePlot(fig, lon_values, depth_fine, data_interp, contour_levels, Cmin, Cmax, plot_title, xsec, t);
end

% Ask for bottom depths before saving
bottom_depths = zeros(size(selected_points,1),1);
for i = 1:size(selected_points,1)
    prompt = sprintf('Enter bottom depth for point at latitude %.2f, longitude %.2f, depth %.1f: ', ...
        xsec.lat, selected_points(i,1), selected_points(i,2));
    depth = input(prompt);
    bottom_depths(i) = depth;
end

% Add as extra column
selected_points = [selected_points(:,1:2) bottom_depths];

if ~isempty(selected_points)
    saveSelectedPoints(selected_points);
end



% --- Nested Functions ---
    function updateTimeStep(fig, t)
        setappdata(fig, 'current_time_step', t);
    end

    function data_interp = interpolateData(xsec, plot_data, depth_fine, t)
        data_interp = nan(length(depth_fine), xsec.nx);
        for j = 1:xsec.nx
            data_interp(:, j) = interp1(xsec.depth(:, j), plot_data(:, j, t), depth_fine, 'linear');
        end
    end

    function ax= plotContour(fig, lon_values, depth_fine, data_interp, contour_levels, Cmin, Cmax, plot_title, xsec, t)
        ax = axes('Parent', fig);
        contourf(ax, lon_values, depth_fine, data_interp, contour_levels, 'LineColor', 'none');
        clim(ax, [Cmin Cmax]);
        set(ax, 'YDir', 'reverse');
        xlabel(ax, 'Longitude (°E)');
        ylabel(ax, 'Depth (m)');
        axis tight;
        title(ax, sprintf('%s Profile | Lat: %.2f°N | Time: %s', ...
            plot_title, xsec.lat(1), datestr(xsec.time(t), 'mmm dd, yyyy HH:MM')));
        colorbar(ax);
        colormap(ax, jet);
        hold on;

        for i = 1:length(lon_values)
            plot([lon_values(i), lon_values(i)], [min(depth_fine), max(depth_fine)], 'k:', 'LineWidth', 1);
        end

        if getappdata(fig, 'water_column_mode')
            selected_lon = getappdata(fig, 'fixed_lon_value');
            hl = getappdata(fig, 'highlight_line');
            if isgraphics(hl)
                delete(hl);
            end
            ylims = get(gca, 'YLim');
            hl = line(gca, [selected_lon selected_lon], ylims, ...
                'Color', 'magenta', 'LineWidth', 2, 'LineStyle', '--');
            setappdata(fig, 'highlight_line', hl);
        end

        if getappdata(fig, 'depth_column_mode')
            selected_depth = getappdata(fig, 'fixed_depth_value');
            hl = getappdata(fig, 'highlight_line');
            if isgraphics(hl)
                delete(hl);
            end
            xlims = get(gca, 'XLim');
            hl = line(gca, xlims, [selected_depth selected_depth], ...
                'Color', 'cyan', 'LineWidth', 2, 'LineStyle', '--');
            setappdata(fig, 'highlight_line', hl);
        end

    end

    function ax= plotScatter(fig, plot_data, plot_title, xsec, t)
        ax = axes('Parent', fig);

        % Get the data for this timestep
        data_t = plot_data(:, :, t);
        lon = xsec.lon(:);
        depth = xsec.depth(:);
        values = data_t(:);

        scatter(ax, lon, depth, values, 'filled');
        set(ax, 'YDir', 'reverse');
        xlabel(ax, 'Longitude (°E)');
        ylabel(ax, 'Depth (m)');
        title(ax, sprintf('%s Profile | Lat: %.2f° | Time: %s', ...
            plot_title, xsec.lat(1), datestr(xsec.time(t), 'mmm dd, yyyy HH:MM')));
        colorbar(ax);
        colormap(ax, jet);
        axis tight;
        clim([min(plot_data(:)) max(plot_data(:))]);
        hold on;

        % Optional: add vertical lines at lon locations for reference
        unique_lons = unique(xsec.lon(1, :));
        for i = 1:length(unique_lons)
            plot([unique_lons(i), unique_lons(i)], ylim(ax), 'k:', 'LineWidth', 1);
        end

        % Highlight mode indicators
        if getappdata(fig, 'water_column_mode')
            selected_lon = getappdata(fig, 'fixed_lon_value');
            hl = getappdata(fig, 'highlight_line');
            if isgraphics(hl)
                delete(hl);
            end
            hl = line(gca, [selected_lon selected_lon], ylim(ax), ...
                'Color', 'magenta', 'LineWidth', 2, 'LineStyle', '--');
            setappdata(fig, 'highlight_line', hl);
        end

        if getappdata(fig, 'depth_column_mode')
            selected_depth = getappdata(fig, 'fixed_depth_value');
            hl = getappdata(fig, 'highlight_line');
            if isgraphics(hl)
                delete(hl);
            end
            hl = line(gca, xlim(ax), [selected_depth selected_depth], ...
                'Color', 'cyan', 'LineWidth', 2, 'LineStyle', '--');
            setappdata(fig, 'highlight_line', hl);
        end
    end

    function plotSelectedPoints(fig, lon_values, depth_fine)
        selected_points = getappdata(fig, 'selected_points');
        if ~isempty(selected_points)
            ax = gca;
            plot(ax, selected_points(:, 1), selected_points(:, 2), 'ko', 'MarkerSize', 8, 'LineWidth', 1.5);
        end
    end

    function selected_points = finalizePlot(fig, lon_values, depth_fine, data_interp, contour_levels, Cmin, Cmax, plot_title, xsec, t)
        selected_points = getappdata(fig, 'selected_points');
        clf(fig);

        plotMode = getappdata(fig, 'plot_mode');

        if strcmp(plotMode, "interpolation")
            ax=plotContour(fig, lon_values, depth_fine, data_interp, contour_levels, Cmin, Cmax, plot_title, xsec, t);
        else
            ax=plotScatter(fig, plot_data, plot_title, xsec, t);
        end

        addKmAxis(ax, xsec.lon(1,:), xsec.lat);
        if ~isempty(selected_points)

            selected_points = unique(selected_points, 'rows');
        end

        hold on;
        for i = 1:size(selected_points, 1)
            lon = selected_points(i, 1);
            depth = selected_points(i, 2);
            plot(lon, depth, 'ko', 'MarkerSize', 8, 'LineWidth', 1.5);
            text(lon, depth, sprintf('%.2f°,%.2f m', lon, depth), ...
                'VerticalAlignment', 'bottom', ...
                'HorizontalAlignment', 'left', ...
                'FontSize', 9, 'Color', 'k');
        end
        title(sprintf('%s Profile | Lat: %.2f° | Time: %s', ...
            plot_title, xsec.lat(1), datestr(xsec.time(t), 'mmm dd, yyyy HH:MM')));
        hold off;
    end

    function saveSelectedPoints(selected_points)
        if ishandle(gcf)
            choice = questdlg('Save selected points?', 'Save Selection', 'Yes', 'No', 'Yes');
            if strcmp(choice, 'Yes')
                [save_filename, save_filepath] = uiputfile('*.mat', 'Save Selected Data Points');
                if save_filename ~= 0
                    save(fullfile(save_filepath, save_filename), 'selected_points');
                    disp(['Saved to ', fullfile(save_filepath, save_filename)]);
                else
                    disp('Save canceled.');
                end
            end
        else
            disp('Figure closed. Data not saved.');
        end
    end

    function onClick(fig)
        ax = gca;
        pt = get(ax, 'CurrentPoint');
        lon_click = pt(1, 1);
        depth_click = pt(1, 2);

        % Retrieve relevant data from appdata
        xsec = getappdata(fig, 'xsec');
        depth_column_mode = getappdata(fig, 'depth_column_mode');
        water_column_mode = getappdata(fig, 'water_column_mode');
        fixed_depth_value = getappdata(fig, 'fixed_depth_value');
        fixed_lon_value = getappdata(fig, 'fixed_lon_value');

        % Determine selected point based on mode
        if depth_column_mode && ~isempty(fixed_depth_value)
            % Depth Column Mode: fix depth, choose longitude from click
            lon_idx = findClosestIndex(xsec.lon(1, :), lon_click);
            actual_depths = xsec.depth(:, lon_idx);
            depth_idx = findClosestIndex(actual_depths, fixed_depth_value);
            lon = xsec.lon(1, lon_idx);
            depth = actual_depths(depth_idx);

        elseif water_column_mode && ~isempty(fixed_lon_value)
            % Water Column Mode: fix longitude, choose depth from click
            lon_idx = findClosestIndex(xsec.lon(1, :), fixed_lon_value);
            depth_vals = xsec.depth(:, lon_idx);
            depth_idx = findClosestIndex(depth_vals, depth_click);
            lon = xsec.lon(1, lon_idx);
            depth = depth_vals(depth_idx);

        else
            % Free selection: choose nearest existing (lon, depth)
            lon_idx = findClosestIndex(xsec.lon(1, :), lon_click);
            depth_vals = xsec.depth(:, lon_idx);
            depth_idx = findClosestIndex(depth_vals, depth_click);
            lon = xsec.lon(1, lon_idx);
            depth = depth_vals(depth_idx);
        end

        selected_points = getappdata(fig, 'selected_points');

        % Save selected point if not already selected
        new_point = [lon, depth];
        if isempty(selected_points) || ~ismember(new_point, selected_points, 'rows')
            selected_points = [selected_points; new_point];
            setappdata(fig, 'selected_points', selected_points);
        end

        % Plot marker on selection
        hold on;
        plot(ax, lon, depth, 'ko', 'MarkerSize', 10, 'LineWidth', 2);
        disp(['Selected: Lon = ', num2str(lon, '%.4f'), '°, Depth = ', num2str(depth), ' m']);
    end


    function onKeyPress(~, event)
        fig = gcf;
        time_skip_current = getappdata(fig, 'time_skip_current');
        contour_levels = getappdata(fig, 'contour_levels');

        switch event.Key
            case 'q'
                setappdata(fig, 'stop_flag', true);
                disp('Stopped by user.');

            case 'rightarrow'
                time_skip_current = min(xsec.nt, max(1, time_skip_current * 5));
                setappdata(fig, 'time_skip_current', time_skip_current);
                disp(['Increased time step to ', num2str(time_skip_current)]);

            case 'leftarrow'
                time_skip_current = max(1, round(time_skip_current / 5));
                setappdata(fig, 'time_skip_current', time_skip_current);
                disp(['Decreased time step to ', num2str(time_skip_current)]);

            case 'uparrow'
                contour_levels = min(50, contour_levels + 5);
                setappdata(fig, 'contour_levels', contour_levels);
                disp(['Contour levels increased to ', num2str(contour_levels)]);

            case 'downarrow'
                contour_levels = max(5, contour_levels - 5);
                setappdata(fig, 'contour_levels', contour_levels);
                disp(['Contour levels decreased to ', num2str(contour_levels)]);

            case 'd'
                current_mode = getappdata(fig, 'depth_column_mode');
                if current_mode
                    setappdata(fig, 'depth_column_mode', false);
                    setappdata(fig, 'fixed_depth_value', []);
                    disp('Exited Depth Column Mode.');
                else
                    % Disable water column mode if active
                    if getappdata(fig, 'water_column_mode')
                        setappdata(fig, 'water_column_mode', false);
                        setappdata(fig, 'fixed_lon_value', []);
                        hl = getappdata(fig, 'highlight_line');
                        if isgraphics(hl)
                            delete(hl);
                        end
                        setappdata(fig, 'highlight_line', []);
                        disp('Water Column Mode OFF');
                    end

                    prompt = {'Enter a fixed depth value (m):'};
                    dlgtitle = 'Depth Column Mode';
                    dims = [1 50];
                    definput = {num2str(floor(mean(depth_fine)))};
                    answer = inputdlg(prompt, dlgtitle, dims, definput);
                    if ~isempty(answer)
                        fixed_depth = str2double(answer{1});
                        if isnan(fixed_depth) || fixed_depth < min(depth_fine) || fixed_depth > max(depth_fine)
                            warndlg('Invalid depth. Must be within depth range.', 'Invalid Input');
                        else
                            setappdata(fig, 'depth_column_mode', true);
                            setappdata(fig, 'fixed_depth_value', fixed_depth);
                            disp(['Entered Depth Column Mode at Depth = ', num2str(fixed_depth), ' m']);
                        end
                    end
                end

            case 'w'
                water_mode = getappdata(fig, 'water_column_mode');

                if ~water_mode
                    % Disable depth column mode if active
                    if getappdata(fig, 'depth_column_mode')
                        setappdata(fig, 'depth_column_mode', false);
                        setappdata(fig, 'fixed_depth_value', []);
                        disp('Depth Column Mode OFF');
                    end

                    [sel_idx, ok] = listdlg('PromptString', 'Select a longitude for Water Column Mode:', ...
                        'SelectionMode', 'single', ...
                        'ListString', lon_strings, ...
                        'Name', 'Water Column Mode', ...
                        'ListSize', [200 300]);

                    if ok
                        selected_lon = unique_lons(sel_idx);
                        setappdata(fig, 'fixed_lon_value', selected_lon);
                        setappdata(fig, 'water_column_mode', true);
                        disp(['Water Column Mode ON at Lon = ', num2str(selected_lon, '%.4f')]);

                        ax = gca;
                        ylims = get(ax, 'YLim');
                        hl = line(ax, [selected_lon selected_lon], ylims, ...
                            'Color', 'magenta', 'LineWidth', 2, 'LineStyle', '--');
                        setappdata(fig, 'highlight_line', hl);
                    else
                        disp('Water Column Mode entry canceled.');
                    end

                else
                    setappdata(fig, 'water_column_mode', false);
                    setappdata(fig, 'fixed_lon_value', []);
                    disp('Water Column Mode OFF');

                    hl = getappdata(fig, 'highlight_line');
                    if isgraphics(hl)
                        delete(hl);
                    end
                    setappdata(fig, 'highlight_line', []);
                end

            case 'i'  % Interpolation mode
                setappdata(fig, 'plot_mode', 'interpolation');
                disp('Switched to Interpolation mode.');
            case 's'  % Scatter mode
                setappdata(fig, 'plot_mode', 'scatter');
                disp('Switched to Scatter mode.');

        end
    end

    function idx = findClosestIndex(vec, val)
        [~, idx] = min(abs(vec - val));
    end
end

function addKmAxis(ax, lon_values, lat)
% ax: axis handle of your main plot
% lon_values: longitude values of the section
% lat: latitude of the section (assumed constant)

% --- Compute km conversion ---
lat_rad    = deg2rad(lat);
km_per_deg = 110.84 * cos(lat_rad);
lon0       = lon_values(1);
dist_km    = (lon_values - lon0) * km_per_deg;

% --- Adjust main axis position to make room for km axis label ---
axPos = ax.Position;
shiftUp = 0.06;  % amount to shift main axis up
shrinkH = 0.06;  % amount to shrink height of main axis
ax.Position = [axPos(1), axPos(2)+shiftUp, axPos(3), axPos(4)-shrinkH];

% --- Create secondary axis below main axis ---
ax2 = axes('Position', [axPos(1), axPos(2)-0.05, axPos(3), 0.001], ...
    'XAxisLocation', 'bottom', ...
    'YAxisLocation', 'right', ...
    'Color', 'none', ...
    'XColor', 'k', 'YColor', 'none', ...
    'HitTest', 'off', ...
    'HandleVisibility', 'off');

% Set limits/ticks for km scale
ax2.XLim = [min(dist_km) max(dist_km)];
xticks   = linspace(min(dist_km), max(dist_km), 6);
ax2.XTick = xticks;

% Format tick labels as integers (no decimals)
ax2.XTickLabel = arrayfun(@(x) sprintf('%d', round(x)), xticks, 'UniformOutput', false);

xlabel(ax2, 'Distance (km)');

% Link y-axes
linkaxes([ax ax2], 'y');

% Restore focus to main axis so title stays correct
axes(ax);
end


