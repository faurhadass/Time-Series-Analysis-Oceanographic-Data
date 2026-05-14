function [plot_data, plot_title, data_unit] = assignPlotData(xsec, selected_plot_name)
    % This function assigns plot data, title, and unit based on the selected plot name.
    switch selected_plot_name
        case 'Temperature'
            plot_data = xsec.temp;
            plot_title = 'Temperature';
            data_unit = '[°C]';
        case 'Salinity'
            plot_data = xsec.sal;
            plot_title = 'Salinity';
            data_unit = '[psu]';
        case 'Eastward Current Velocity (u)'
            plot_data = xsec.u;
            plot_title = 'Eastward Current Velocity (u)';
            data_unit = '[m/s]';
        case 'Northward Current Velocity (v)'
            plot_data = xsec.v;
            plot_title = 'Northward Current Velocity (v)';
            data_unit = '[m/s]';
        case 'Current Speed Magnitude'
            plot_data = sqrt(xsec.u.^2 + xsec.v.^2);
            plot_title = 'Current Speed';
            data_unit = '[m/s]';
        otherwise
            % Default case to handle invalid selections
            plot_data = [];
            plot_title = '';
            data_unit = '';
    end
end