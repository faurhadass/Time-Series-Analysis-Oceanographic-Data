function createInterpolatedContourPlot(xsec, depth_fine, data_interp, plot_data, plot_title, contour_levels, time_idx)
    % Create figure and set axis properties
     % Create full-screen figure
 
    clf;
    ax = axes('Parent', gcf);
    lon_levels = xsec.lon(1, :);
    contourf(lon_levels, depth_fine, data_interp, contour_levels, 'LineColor', 'none');
    Cmin = min(plot_data(:));
    Cmax = max(plot_data(:));
    clim(ax, [Cmin, Cmax]);
    set(ax, 'YDir', 'reverse');
    xlabel(ax, 'Longitude (°E)');
    ylabel(ax, 'Depth (m)');
    title(ax, [plot_title, ' Profile | Lat: ', num2str(xsec.lat(1)), '° | Time: ', datestr(xsec.time(time_idx), 'mmm dd, yyyy HH:MM')]);
    colorbar(ax);
    colormap(ax, jet);
end
