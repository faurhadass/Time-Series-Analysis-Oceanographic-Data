function loadLatitudeDatasetFromMat(filepath)
%LOADLATITUDEDATASETFROMMAT Prompts the user to select a .mat file containing latitude dataset as 'xsec' struct and loads it into the calling workspace.
%
%   This function either accepts a filepath as input or prompts the user to select
%   a `.mat` file containing oceanographic data. The data is loaded into the calling workspace.
%   
%   Usage:
%       Call this function from a script to load oceanographic data:
%           loadLatitudeDatasetFromMat();  % To prompt user for file selection
%           loadLatitudeDatasetFromMat('C:\path\to\file.mat');  % To directly load from specified path
%
%   Note:
%       - The function does not return any output.
%       - It assumes the .mat file contains struct(s) with predefined names,
%         such as 'xsec', which will become available in the script after calling.

    % Check if filepath is provided, otherwise prompt user to select file
    if nargin == 0
        % If no filepath is passed, open file selection dialog
        [filename, filepath] = uigetfile('*.mat', 'Select the oceanographic .mat data file');
        
        if filename == 0
            disp('No file selected. Exiting...');
            return;
        end
        
        % Construct full path
        full_filename = fullfile(filepath, filename);
        disp(['Selected file: ', full_filename]);
    else
        % If filepath is provided, use it directly
        if exist(filepath, 'file') ~= 2
            disp('File does not exist. Exiting...');
            return;
        end
        full_filename = filepath;
        disp(['Using provided file: ', full_filename]);
    end
    
    % Load file contents into temporary structure
    temp = load(full_filename, '-mat');
    
    % Assign each loaded variable into the caller's workspace
    var_names = fieldnames(temp);
    for i = 1:numel(var_names)
        assignin('caller', var_names{i}, temp.(var_names{i}));
    end

    disp("Latitude dataset loaded successfully.")
end
