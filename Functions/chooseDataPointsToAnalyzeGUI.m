function selected_points = chooseDataPointsToAnalyzeGUI(xsec)
%CHOOSEDATAPOINTSTOANALYZE Allows the user to either load selected points from a
% saved MATLAB file or manually select the coordinates (longitude, depth) to analyze,
% and then choose which subset of those points to analyze.
%
%   Outputs:
%       - selected_points: Nx2 array of selected (longitude, depth) coordinates.

    selected_points = [];  % Initialize output in case of early exit

    % Prompt user to choose how they want to select coordinates using listdlg
    options = {'Load coordinates from file', 'Select coordinates manually'};
    [choice_idx, ok] = listdlg('PromptString', 'Select how to load coordinates:', ...
                               'SelectionMode', 'single', ...
                               'ListString', options, ...
                               'Name', 'Coordinate Selection', ...
                               'ListSize', [400, 300]);

    if ~ok || isempty(choice_idx)
        disp('No selection made. Exiting...');
        return;
    end

    switch choice_idx
        case 1  % Load coordinates from file
            [filename, filepath] = uigetfile('*.mat', 'Select the selected points file');
            if isequal(filename, 0) || isequal(filepath, 0)
                disp('No file selected. Exiting...');
                return;
            end
            full_filename = fullfile(filepath, filename);
            disp(['Selected file: ', full_filename]);
            loaded = load(full_filename, '-mat');
            if isfield(loaded, 'selected_points')
                selected_points = loaded.selected_points;
                disp('Loaded points (Lon, Depth):');
                disp(selected_points);
            else
                disp('Error: The variable "selected_points" was not found in the selected file.');
                return;
            end

        case 2  % Select coordinates visually
            selected_points = select_data_points_by_animated_profile(xsec);
            
    end

end
