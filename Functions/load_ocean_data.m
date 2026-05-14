function dataStruct = load_ocean_data(filename, nz, nx, nt, latitude, start_time, time_resolution)
% LOAD_OCEAN_DATA Loads latitude (Y) cross-section oceanographic data from
% POM text file output with columns [long depth temp salinity u v] 
%
% Inputs:
%   filename        - path to the data file (e.g., 'xsec_south.txt')
%   nx              - number of longitude (X) points
%   nz              - number of depth levels (Z)
%   nt              - number of time steps (hours)
%   latitude        - latitude (Y) of the cross-section (e.g., '31.8', '32.4', etc.)
%   start_time      - the starting time as a datetime object (e.g., datetime(2017,8,1,13,0,0))
%   time_resolution - time resolution between steps (numeric, e.g., 1 for hourly data)
%
% Output:
%   dataStruct      - struct containing temperature, salinity, velocity fields, and coordinate info
%                     for each (Z, X, Time) point in the given latitude cross-section.

% Load the raw data
raw = readmatrix(filename);  % size: [nx * nz * nt, 6]

% Check that the data length matches the expected number of time steps
if size(raw, 1) ~= nx * nz * nt
    error('Data length does not match nx*nz*nt. Check input values.');
end

% Preallocate 3D arrays: [nz, nx, nt]
temperature = zeros(nz, nx, nt);
salinity    = zeros(nz, nx, nt);
u           = zeros(nz, nx, nt);
v           = zeros(nz, nx, nt);
depth       = zeros(nz, nx);  % 2D, does not change over time steps
lon         = zeros(nz, nx);  % 2D, does not change over time steps

% Loop over each time step to populate the 3D matrices for temp, sal, u, and v
for t = 1:nt
    idx_start = (t-1)*nx*nz + 1;
    idx_end   = t*nx*nz;

    frame = raw(idx_start:idx_end, :);  % [nz*nx, 6]

    % Reshape data into [nz, nx] for each parameter
    temperature(:,:,t) = reshape(frame(:,3), nz, nx);
    salinity(:,:,t)    = reshape(frame(:,4), nz, nx);
    u(:,:,t)           = reshape(frame(:,5), nz, nx);
    v(:,:,t)           = reshape(frame(:,6), nz, nx);

    if t == 1 % depth and longitude don't change from frame to frame
        depth = reshape(frame(:,2), nz, nx);
        lon   = reshape(frame(:,1), nz, nx);
    end
end

% Generate time vector using the given start time and time resolution
time_vec = start_time + hours(0:time_resolution:(nt-1)*time_resolution);

% --- Adjust for leap years across multi-year datasets ---
if time_resolution == 1  % Only valid for hourly data
    % Find all Feb 29ths at 00:00 in the time vector
    is_feb29 = (month(time_vec) == 2) & (day(time_vec) == 29) & (hour(time_vec) == 0);
    idx_feb29 = find(is_feb29);

    remove_indices = [];

    for i = 1:length(idx_feb29)
        idx_start = idx_feb29(i);
        idx_end = idx_start + 23;  % Next 24 hours
        if idx_end <= length(time_vec)
            remove_indices = [remove_indices, idx_start:idx_end];
        end
    end

    % Remove identified indices
    if ~isempty(remove_indices)
        temperature(:,:,remove_indices) = [];
        salinity(:,:,remove_indices)    = [];
        u(:,:,remove_indices)           = [];
        v(:,:,remove_indices)           = [];
        time_vec(remove_indices)        = [];
        nt = size(temperature, 3);      % Update nt after removal
    end
end


% Package the data into an output struct
dataStruct.temp = temperature;
dataStruct.sal  = salinity;
dataStruct.u    = u;
dataStruct.v    = v;
dataStruct.depth = depth;
dataStruct.lon  = lon;
dataStruct.time = time_vec;

% Add metadata for reference
dataStruct.lat = latitude;  % Latitude is constant for all time, depth, and longitude points
dataStruct.nx  = nx;
dataStruct.nz  = nz;
dataStruct.nt  = nt;
dataStruct.timeRes=time_resolution;

end

% Structure and Indexing Explanation:
%
% The 'dataStruct' structure contains the following fields:
%
% - dataStruct.temp: A 3D matrix for temperature, indexed as [depth, longitude, time].
%     - dataStruct.temp(i, j, t) gives the temperature at depth index 'i', longitude index 'j', and time index 't'.
%
% - dataStruct.sal: A 3D matrix for salinity, indexed similarly to dataStruct.temp.
%     - dataStruct.sal(i, j, t) gives the salinity at depth 'i', longitude 'j', and time 't'.
%
% - dataStruct.u: A 3D matrix for eastward velocity ('u'), indexed as [depth, longitude, time].
%     - dataStruct.u(i, j, t) gives the eastward velocity at depth 'i', longitude 'j', and time 't'.
%
% - dataStruct.v: A 3D matrix for northward velocity ('v'), indexed similarly to dataStruct.u.
%     - dataStruct.v(i, j, t) gives the northward velocity at depth 'i', longitude 'j', and time 't'.
%
% - dataStruct.depth: A 2D matrix for depth, indexed as [depth, longitude]. Depth does not change over time.
%     - dataStruct.depth(i, j) gives the depth at depth index 'i' and longitude index 'j'.
%
% - dataStruct.lon: An array for longitude, indexed as [depth, longitude]. Longitude is constant over time.
%     - dataStruct.lon(i,j) gives the longitude at depth index 'i' and longitude index 'j.' 
%
% - dataStruct.time: A 1D array of datetime objects for each time step.
%     - dataStruct.time(t) gives the timestamp for the 't'-th time step.
%
% - dataStruct.lat: The latitude value for the cross-section, constant across time, depth, and longitude points.
%
% Example usage:
% - Access temperature at depth 5, longitude 10, and time 1:
%     temp_at_depth_5_lon_10_time_1 = dataStruct.temp(5, 10, 1);
%
% - Access salinity at depth 3 and longitude 15 for all time steps:
%     sal_at_depth_3_lon_15 = dataStruct.sal(3, 15, :);
%
% - Get the time for the first time step:
%     time_1 = dataStruct.time(1);
