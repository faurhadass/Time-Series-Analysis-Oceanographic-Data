% Main Analysis Script

clc; clear;
% Make sure the 'Functions' folder is added to the MATLAB path
addpath(fullfile(pwd, 'Functions'));

%% --- Load Dataset ---

% Prompt user to select data loading method
choice = questdlg( ...
    'Select how you would like to load the latitude cross-section dataset. Click Cancel if it''s already loaded.', ...
    'Load Latitude Dataset', ...
    'Load from existing .mat file', ...
    'Import from formatted .txt file', ...
    'Cancel', ...
    'Cancel');

% Handle the user's choice
switch choice
    case 'Load from existing .mat file'
        loadLatitudeDatasetFromMat();

    case 'Import from formatted .txt file'
        file_path = saveLatitudeDatasetToMat();
        if ~isempty(file_path)
            loadLatitudeDatasetFromMat(file_path);
        end

    case 'Cancel'
        disp('Operation canceled. No new data loaded into the workspace.');
end

% Validate dataset existence
if ~exist('xsec', 'var') || isempty(xsec)
    disp('No data was loaded. Please check the file and try again.');
    return;
end

%% --- Select Data Points for Analysis ---

selected_points = chooseDataPointsToAnalyzeGUI(xsec);

if isempty(selected_points)
    disp('No points selected. Ending script.');
    return;
end

% Ask user how to sort
choice = questdlg('Sort selected points by:', 'Sorting Option', ...
    'Longitude', 'Depth', 'Bottom Depth', 'Longitude');

switch choice
    case 'Longitude'
        selected_points = sortrows(selected_points, 1); % column 1 = longitude
    case 'Depth'
        selected_points = sortrows(selected_points, 2); % column 2 = latitude
    case 'Bottom Depth'
       selected_points = sortrows(selected_points, 3); % column 3 = bottom depth
    otherwise
        disp('No sorting applied.');
end


%%  --- Generate Plot ---

% Define available plot options
plot_options = { ...
    'Depth Profile', ...
    'Time Series', ...
    'Time Series - Correlation', ... 
    'Fourier Transform', ...
    'Compare Frequency Peaks', ...
    'PSD', ...
    'Time-Frequency Domain' ...
};

% Prompt user to choose plot type
[choice, ok] = listdlg( ...
    'PromptString', 'Select the type of plot you want to create:', ...
    'ListString', plot_options, ...
    'SelectionMode', 'single', ...
    'ListSize', [300, 200]);

% Handle cancel
if ~ok || isempty(choice)
    disp('No selection made. Exiting plot menu.');
    return;
end

% Check if chosen option requires dataset and selected points
requires_data = ismember(choice, [1, 2, 4, 6, 7]); % indices of options that need data
if requires_data
    if ~exist('xsec', 'var') || isempty(xsec)
        disp('Cross-section data is missing. Cannot proceed.');
        return;
    end

    if ~exist('selected_points','var') || isempty(selected_points)
        msgbox('Please select points before analyzing.', 'Missing Points', 'warn');
        return;
    end
end

% --- Plot Logic ---
switch choice
    case 1  % Depth Profiles
        [plot_data, plot_title, plot_unit] = selectParameterToPlot(xsec);
        DepthProfilesPlot(xsec, plot_data, plot_title, plot_unit, selected_points);

    case 2  % Time Series
        TimeSeriesPlotGUI(xsec, selected_points);
    
    case 3
        CorrelationPlot(xsec, selected_points);

    case 4  % Fourier Transform
        FourierPlotGUI(xsec, selected_points);

    case 5  % Compare Frequency Peaks
        h = msgbox('Please select frequency peak files of the same timeframe for analysis.', ...
                   'File Selection Required', 'warn');
        uiwait(h); % Wait until user clicks OK
        interactivePeakPlotterGUI();

    case 6  % PSD
        PSDPlotGUI(xsec, selected_points); 

    case 7  % Time-Frequency Domain Plots
        FreqTimePlotGUI(xsec, selected_points);

    otherwise
        disp('Invalid plot selection.');
end
