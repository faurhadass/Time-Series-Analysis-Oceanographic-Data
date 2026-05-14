function [plot_data, plot_title, data_unit] = selectParameterToPlot(xsec)
%SELECTPARAMETERTOPLOT Prompts user to select which oceanographic parameter to plot.
%
%   Inputs:
%       - xsec: structure containing fields temp, sal, u, v
%
%   Outputs:
%       - plot_data: the data corresponding to the selected parameter
%       - plot_title: a descriptive title for the plot
%       - data_unit: units of the selected data

    % Define plotting options with names
    plot_options = {'Temperature', ...
                    'Salinity', ...
                    'Eastward Current Velocity (u)', ...
                    'Northward Current Velocity (v)', ...
                    'Current Speed Magnitude'};

    % Call the user selection function and get the selected plot index
    selected_plot = getUserSelection(plot_options);
    
    % Handle case of user canceling selection
    if isempty(selected_plot)
        disp('No plot selected. Operation canceled.');
        plot_data = [];
        plot_title = '';
        data_unit = '';
        return;
    end
    
    % Assign data, title, and unit based on selection
    [plot_data, plot_title, data_unit] = assignPlotData(xsec, plot_options{selected_plot});

end

% Nested function that handles the user selection
function selected_plot = getUserSelection(plot_options)
    % This function handles the user interaction for selecting the plot option.
    [selected_plot, ~] = listdlg('ListString', plot_options, ...
                                 'SelectionMode', 'single', ...
                                 'PromptString', 'Select the data parameter you wish to plot:', ...
                                 'ListSize', [400, 300]);  % Width x Height in pixels
end