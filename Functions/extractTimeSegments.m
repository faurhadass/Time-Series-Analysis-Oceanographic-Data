function segments = extractTimeSegments(xsec, plot_data, selected_lon, selected_depth, timeFrame, samples_per_year)
    % extractTimeSegments - Extracts the time series segments for a given point and time frame.
    %
    % Inputs:
    %   xsec            - Struct with latitude dataset fields: lon, depth, lat, timeRes
    %   plot_data       - The data to extract from
    %   selected_lon    - Longitude of the selected point
    %   selected_depth  - Depth of the selected point
    %   timeFrame       - Time segmentation option ('3 Years', '1 Year', 'Seasonal')
    %   samples_per_year - The number of samples per year in the dataset
    %
    % Outputs:
    %   segments        - Cell array containing the segmented data

    % Find the closest longitude and depth indices in the dataset
    [~, lon_idx] = min(abs(xsec.lon(1, :) - selected_lon));
    [~, depth_idx] = min(abs(xsec.depth(:, lon_idx) - selected_depth));

    % Extract the time series for the selected point
    full_series = squeeze(plot_data(depth_idx, lon_idx, :));

    % Segment the data based on the chosen time frame
    if strcmpi(timeFrame, '3 Years')
        segments = {full_series};  % Use the full series for 3 years
    elseif strcmpi(timeFrame, '1 Year')
        % Split data into 3 years, each year containing samples_per_year data points
        segments = {
            full_series(1:samples_per_year);  % Year 1
            full_series(samples_per_year+1:2*samples_per_year);  % Year 2
            full_series(2*samples_per_year+1:end)  % Year 3
        };
    elseif strcmpi(timeFrame, 'Seasonal')
        % Split the year into 4 seasons and average across the 3 years
        sp_season = floor(samples_per_year / 4);  % Samples per season (quarter of the year)
        segments = cell(1, 4);  % Preallocate cell array for seasons

        % Loop through each season and extract the data for the selected years
        for s = 1:4
            % Initialize a matrix to store season data across 3 years
            season_data = zeros(sp_season, 3);

            % Loop through each year (3 years)
            for y = 1:3
                % Calculate the start and end indices for the current season in the current year
                idx_start = (y-1)*samples_per_year + (s-1)*sp_season + 1;
                idx_end = idx_start + sp_season - 1;

                % Extract the data for the current season and year
                season_data(:, y) = full_series(idx_start:idx_end);
            end

            % Average the data across the 3 years for the current season
            segments{s} = mean(season_data, 2);
        end
    else
        error('Invalid timeFrame: Use ''3 Years'', ''1 Year'', or ''Seasonal''.');
    end
end
