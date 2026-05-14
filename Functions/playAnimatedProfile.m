function playAnimatedProfile(xsec, contour_levels, time_skip)
% playAnimatedProfile Animates a vertical profile of a selected oceanographic parameter.
%
% INPUTS:
%   xsec            - Struct containing fields: temp/sal/u/v, depth, lon, lat, time, nx, nt, nz
%   contour_levels  - Number of contour levels to display
%   time_skip       - Time step interval for skipping frames in the animation
%
% This function interpolates data to a finer vertical resolution and creates
% an animated contour plot over time showing how the selected parameter evolves
% across longitude and depth.

    % Select which parameter to visualize
    [plot_data, plot_title, ~] = selectParameterToPlot(xsec);

    % Create full-screen figure for animation
    fig = figure;
    set(fig, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);

    % Define fine vertical depth grid for interpolation
    depth_fine = linspace(min(xsec.depth(:)), max(xsec.depth(:)), xsec.nz);

    % Loop through time steps with defined skip interval
    for time_step = 1:time_skip:xsec.nt

        % Interpolate each longitude column to finer vertical grid
        data_interp = nan(length(depth_fine), xsec.nx);
        for j = 1:xsec.nx
            depth_col = xsec.depth(:, j);
            data_col = plot_data(:, j, time_step);
            data_interp(:, j) = interp1(depth_col, data_col, depth_fine, 'linear');
        end

        % Create and display contour plot for this time step
        createInterpolatedContourPlot(xsec, depth_fine, data_interp, plot_data, plot_title, contour_levels, time_step);

        % Update figure
        drawnow;
        pause(0.03);
    end
end
