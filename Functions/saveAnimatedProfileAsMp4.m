function saveAnimatedProfileAsMp4(xsec, contour_levels, time_skip)
% saveAnimatedProfileAsMp4 Generates and saves an MP4 animation of an interpolated
% vertical profile of an oceanographic parameter over time.
%
% INPUTS:
%   xsec            - Struct with fields: lon, lat, depth, time, nt, nx
%   contour_levels  - Number of contour levels for plotting
%   time_skip       - Time step interval for skipping frames
%
% NOTES:
%   - Requires selectParameterToPlot(xsec) to return:
%       plot_data: 3D matrix (depth x nx x nt)
%       plot_title: string for the plot title
%       data_unit: string (optional)
%   - Output is an MP4 video chosen by the user via file dialog

    % Prompt user for filename and location
    uiwait(msgbox('Please choose the filename and location to save the animation.'));
    [video_file, video_path] = uiputfile('*.mp4', 'Save animation as');
    if isequal(video_file, 0)
        disp('Video save canceled. Exiting...');
        return;
    end
    video_filename = fullfile(video_path, video_file);
    disp(['Saving animation to: ', video_filename]);

    % Set up video writer
    v = VideoWriter(video_filename, 'MPEG-4');
    v.FrameRate = 25;
    open(v);

    % Generate fine vertical grid for interpolation
    depth_fine = linspace(min(xsec.depth(:)), max(xsec.depth(:)), 39);

    % Select parameter to animate
    [plot_data, plot_title, ~] = selectParameterToPlot(xsec);

    % Create figure for capturing frames
    fig = figure;
    set(fig, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);

    % Loop through time steps and write each frame
    for time_step = 1:time_skip:xsec.nt

        % Interpolate vertically for each longitude
        data_interp = nan(length(depth_fine), xsec.nx);
        for j = 1:xsec.nx
            depth_col = xsec.depth(:, j);
            data_col = plot_data(:, j, time_step);
            data_interp(:, j) = interp1(depth_col, data_col, depth_fine, 'linear');
        end

        % Plot current time step
        createInterpolatedContourPlot(xsec, depth_fine, data_interp, plot_data, plot_title, contour_levels, time_step);

        % Capture and write frame to video
        frame = getframe(gcf);
        writeVideo(v, frame);
    end

    % Finalize and close video file
    close(v);
    disp(['Animation saved successfully to: ', video_filename]);
end
