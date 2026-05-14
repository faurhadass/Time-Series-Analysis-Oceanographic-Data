function full_save_filename = saveLatitudeDatasetToMat()
% saveLatitudeDatasetToMat
% Interactively loads oceanographic latitude cross-section data from a file
% and saves it as a MATLAB structure (.mat) for future use.

disp('Oceanographic Cross-Section Data Loader');

full_save_filename = [];

% --- Prompt user for dataset parameters ---
prompt = {
    'Latitude (e.g., 31.8):', ...
    'Number of longitude points (e.g., 23):', ...
    'Number of depth levels (e.g., 39):', ...
    'Number of time steps (e.g., 8760):', ...
    'Time resolution in hours (e.g., 1):', ...
    'Start time [yyyy mm dd hh mm ss] (e.g., 2017 7 1 13 0 0):'
};
dlg_title = 'Enter Cross-Section Parameters of Latitude Data Set Text File to be Loaded';
default_vals = {'31.8', '23', '39', '26304', '1', '2016 1 1 13 0 0'};

answer = inputdlg(prompt, dlg_title, [1, length(dlg_title) + 22], default_vals);

if isempty(answer)
    disp('User canceled. Exiting...');
    return;
end

% --- Convert and validate input ---
latitude          = str2double(answer{1});
num_long_points   = str2double(answer{2});
num_depth_points  = str2double(answer{3});
num_time_steps    = str2double(answer{4});
time_res          = str2double(answer{5});
start_time_vec    = str2num(answer{6}); %#ok<ST2NM>

if length(start_time_vec) ~= 6
    error('Start time must be a 6-element vector: [yyyy mm dd hh mm ss]');
end

start_time = datetime(start_time_vec);

% --- File selection for loading data ---
uiwait(msgbox('You will now be asked to select the oceanographic data file to load containing the latitude cross section dataset (e.g., .txt format).'));
[filename, filepath] = uigetfile('*', 'Select the oceanographic data file');

if filename == 0
    disp('No file selected. Exiting...');
    return;
end

full_filename = fullfile(filepath, filename);
disp(['Loading file: ', full_filename]);

% --- Add Functions directory to path ---
addpath(fullfile(pwd, 'Functions'));  % Ensure 'load_ocean_data' can be called

% --- Load data using helper function ---
xsec = load_ocean_data(full_filename, num_depth_points, num_long_points, ...
    num_time_steps, latitude, start_time, time_res);

disp('Data successfully loaded.');

% --- Save data as .mat file ---
uiwait(msgbox('You will now be asked to save the loaded data as a MATLAB variable in a specified location.'));
[save_filename, save_filepath] = uiputfile('*.mat', 'Save the loaded data as');

if isequal(save_filename, 0) || isequal(save_filepath, 0)
    disp('User canceled saving. Exiting...');
    return;
end

full_save_filename = fullfile(save_filepath, save_filename);
save(full_save_filename, 'xsec');
disp(['File successfully saved to: ', full_save_filename]);
disp('To load this data again later, use the "load" function in MATLAB.');
end
