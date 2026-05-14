function interactivePeakPlotterGUI()

dataTable = loadMultiplePeakTables();

if isempty(dataTable)
    disp('Error. Exiting Analysis.')
    return;
end

axisVars = {'Frequency [cycles/hour]', 'Period [hours]', 'Amplitude', ...
    'Latitude [°]', 'Longitude [°]', 'Depth [m]'};

filterTypes = {'All Data', 'Latitude', 'Parameter', 'Segment'};
plotTypes = {'Simple 2D', 'Flexible 2D', 'Flexible 3D', 'Point Spectra'};
spectraXChoices = {'Frequency [cycles/hour]', 'Period [hours]'};

fig = uifigure('Name', 'Interactive Peak Plotter', 'Position', [100 100 550 540]);
setappdata(0, 'MainPeakGUIFigure', fig);  % store it globally (key: 'MainPeakGUIFigure')

% Initialize deletedPoints as an empty struct array
deletedPoints = struct('title', {}, 'y', {}, 'x', {});
setappdata(fig, 'deletedPoints', deletedPoints);

% Constants for layout
labelX = 20;
controlX = 120;
legendX = 300;
labelWidth = 100;
legendLabelWidth = 140;
controlWidth = 150;
legendControlWidth = 180;
controlHeight = 22;
spacingY = 30;

% Plot type dropdown
uilabel(fig, 'Position', [labelX 500 labelWidth controlHeight], 'Text', 'Plot Type:');
plotTypeDrop = uidropdown(fig, 'Items', plotTypes, ...
    'Position', [controlX 500 controlWidth controlHeight], ...
    'ValueChangedFcn', @(dd,event)updateDropdownVisibility());

% Axis dropdowns (X, Y, Z, Color)
dropdownLabels = {'X-Axis:', 'Y-Axis:', 'Z-Axis:', 'Color:'};
axisStartY = 460;

for i = 1:numel(dropdownLabels)
    uilabel(fig, 'Position', [labelX, axisStartY - (i-1)*spacingY labelWidth controlHeight], ...
        'Text', dropdownLabels{i});
    dropdownHandles(i) = uidropdown(fig, 'Items', axisVars, ...
        'Position', [controlX, axisStartY - (i-1)*spacingY controlWidth controlHeight]);
end

% X-axis choice for Point Spectra (hidden initially)
spectraXLabel = uilabel(fig, 'Position', [labelX, axisStartY labelWidth controlHeight], ...
    'Text', 'X-Axis:', 'Visible', 'off');
spectraXDrop = uidropdown(fig, 'Items', spectraXChoices, ...
    'Position', [controlX, axisStartY controlWidth controlHeight], 'Visible', 'off');

% Filter type dropdown
filterY = 300;
uilabel(fig, 'Position', [labelX, filterY labelWidth controlHeight], 'Text', 'Filter by:');
filterTypeDrop = uidropdown(fig, 'Items', filterTypes, ...
    'Position', [controlX, filterY controlWidth controlHeight], ...
    'Value', 'All Data');

% Grouping listbox (Simple 2D)
groupingY = 250;
groupingHeight = 60;
uilabel(fig, 'Position', [labelX, groupingY labelWidth controlHeight], 'Text', 'Group By:');
groupingDrop = uilistbox(fig, ...
    'Items', {'Longitude [°]', 'Latitude [°]', 'Depth [m]', 'Parameter', 'Segment'}, ...
    'Multiselect', 'on', ...
    'Position', [controlX, groupingY - groupingHeight, controlWidth, groupingHeight], ...
    'Enable', 'off');

% Legend override listbox (only for Simple 2D)
uilabel(fig, 'Position', [legendX, groupingY legendLabelWidth controlHeight], 'Text', 'Legend Fields (Override):');
legendOverrideList = uilistbox(fig, ...
    'Items', {'Longitude [°]', 'Latitude [°]', 'Depth [m]', 'Parameter', 'Segment'}, ...
    'Multiselect', 'on', ...
    'Position', [legendX, groupingY - groupingHeight, legendControlWidth, groupingHeight], ...
    'Enable', 'off');

% Plot button
uibutton(fig, 'Text', 'Plot', ...
    'Position', [controlX, groupingY - groupingHeight - 50, 100, 30], ...
    'ButtonPushedFcn', @(btn,event)plotCallback());

% Trend checkbox and degree spinner
trendCheckbox = uicheckbox(fig, ...
    'Text', 'Add Trendline', ...
    'Position', [labelX, 100, 120, 22], ...
    'Value', false);

uilabel(fig, 'Text', 'Degree:', ...
    'Position', [labelX + 130, 100, 50, 22]);

degreeSpinner = uispinner(fig, ...
    'Position', [labelX + 180, 100, 50, 22], ...
    'Limits', [1 10], ...
    'Value', 1, ...
    'Step', 1);

% Decay Fit Model label and dropdown (just below trendline controls)
uilabel(fig, ...
    'Text', 'Select Decay Fit Model:', ...
    'Position', [labelX, 70, 150, 22], ...
    'FontWeight', 'bold');

decayFitDropdown = uidropdown(fig, ...
    'Items', {'None', 'Exponential Decay', 'Power Law Decay'}, ...
    'Position', [labelX, 40, 220, 22], ...
    'Value', 'None');

% Notification label (moved to bottom)
clickInfoLabel = uilabel(fig, ...
    'Text', ' You may click on a point to delete it from the plot.', ...
    'Position', [labelX, 10, 300, 22], ...
    'FontColor', [0.85 0.33 0.1], ...
    'Visible', 'off', ...
    'FontWeight', 'bold');


updateDropdownVisibility();


    function updateDropdownVisibility()
        pType = plotTypeDrop.Value;
        switch pType
            case 'Simple 2D'
                set(dropdownHandles, {'Enable'}, {'on'; 'on'; 'off'; 'off'});
                groupingDrop.Enable = 'on';
                legendOverrideList.Enable = 'on';  % <--- Add this
                spectraXDrop.Visible = 'off';
                spectraXLabel.Visible = 'off';
                legendOverrideList.Enable = 'on';
                trendCheckbox.Enable= 'on';
                degreeSpinner.Enable= 'on';
                clickInfoLabel.Visible = 'on';
                decayFitDropdown.Enable= 'on';

            case 'Flexible 2D'
                set(dropdownHandles, {'Enable'}, {'on'; 'on'; 'off'; 'on'});
                groupingDrop.Enable = 'off';
                legendOverrideList.Enable = 'off';  % <--- Add this
                spectraXDrop.Visible = 'off';
                spectraXLabel.Visible = 'off';
                legendOverrideList.Enable = 'off';
                trendCheckbox.Enable= 'on';
                degreeSpinner.Enable= 'on';
                clickInfoLabel.Visible = 'off';
                decayFitDropdown.Enable= 'on';


            case 'Flexible 3D'
                set(dropdownHandles, {'Enable'}, {'on'; 'on'; 'on'; 'on'});
                groupingDrop.Enable = 'off';
                legendOverrideList.Enable = 'off';  % <--- Add this
                spectraXDrop.Visible = 'off';
                spectraXLabel.Visible = 'off';
                legendOverrideList.Enable = 'off';
                trendCheckbox.Enable= 'off';
                degreeSpinner.Enable= 'off';
                clickInfoLabel.Visible = 'off';
                decayFitDropdown.Enable= 'off';

            case 'Point Spectra'
                set(dropdownHandles, 'Enable', 'off');
                groupingDrop.Enable = 'off';
                legendOverrideList.Enable = 'off';  % <--- Add this
                spectraXDrop.Visible = 'on';
                spectraXLabel.Visible = 'on';
                legendOverrideList.Enable = 'off';
                trendCheckbox.Enable= 'on';
                degreeSpinner.Enable= 'on';
                clickInfoLabel.Visible = 'on';
                decayFitDropdown.Enable= 'on';
        end
    end


    function plotCallback()

        mainFig = getappdata(0, 'MainPeakGUIFigure');  % retrieve your main GUI figure
        deletedPoints = getappdata(mainFig, 'deletedPoints');
        if isempty(deletedPoints)
            deletedPoints = struct('title', {}, 'y', {}, 'x', {});
        end


        try
            pType = plotTypeDrop.Value;
            filterType = filterTypeDrop.Value;

            % Filtering
            if strcmp(filterType, 'All Data')
                groups = {''};
                groupData = {dataTable};
            else
                if strcmp(filterType, 'Latitude')
                    filterField = 'Latitude [°]';
                elseif strcmp(filterType, 'Parameter')
                    filterField = 'Parameter';  % change as appropriate to match your table
                elseif strcmp(filterType, 'Segment')
                    filterField = 'Segment';
                else
                    filterField = filterType;
                end

                colData = dataTable.(filterField);
                isNumericField = isnumeric(colData) || islogical(colData);
                groups = unique(colData);
                groupData = cell(size(groups));

                for i = 1:numel(groups)
                    if isNumericField
                        groupData{i} = dataTable(colData == groups(i), :);
                    else
                        groupData{i} = dataTable(strcmp(colData, groups{i}), :);
                    end
                end
            end


            % Plotting
            clf;

            if strcmp(pType, 'Point Spectra')
                xVar = spectraXDrop.Value;
                for g = 1:numel(groupData)
                    tbl = groupData{g};
                    [~, ~, ic] = unique(tbl(:, {'Longitude [°]', 'Depth [m]', ...
                        'Latitude [°]', 'Segment'}), 'rows');
                    nGroups = max(ic);
                    nRows = ceil(sqrt(nGroups));
                    nCols = ceil(nGroups / nRows);

                    for i = 1:nGroups
                        subplot(nRows, nCols, i);
                        subset = tbl(ic == i, :);
                        x = subset.(xVar);
                        y = subset.("Amplitude");

                        % Title with point info
                        pt = subset(1, :);
                        titleStr=       sprintf('Lat %.2f, Lon %.2f Depth %.0f m, Seg: %s', ...
                            pt.("Latitude [°]"), pt.("Longitude [°]"), ...
                            pt.("Depth [m]"), string(pt.Segment));

                        % Filter out deleted points
                        keepIdx = true(height(subset), 1);
                        for k = 1:height(subset)
                            if isPointDeleted(deletedPoints, titleStr, y(k), x(k))
                                keepIdx(k) = false;
                            end
                        end

                        x = x(keepIdx);
                        y = y(keepIdx);

                        h=scatter(x, y, 40, 'filled');
                        set(h, 'ButtonDownFcn', @(src, event)deletePointFromPlot(src, event, mainFig));
                        xlabel(xVar, 'Interpreter', 'none');
                        ylabel('Amplitude', 'Interpreter', 'none');

                        % Optional trendline
                        if trendCheckbox.Value
                            deg = degreeSpinner.Value;
                            plotTrendline(x, y, deg);
                        end

                        selectedFit = decayFitDropdown.Value;
                        plotDecayCurve(selectedFit, x, y);

                        title(titleStr, 'Interpreter', 'none');
                        grid on;
                    end

                    timeframe = unique(tbl.Timeframe);
                    if iscell(timeframe), timeframe = timeframe{1}; end

                    sgtitle(sprintf('Selected Frequency Peak Comparison for Timeframe: %s\n%s: %s', ...
                        string(timeframe), filterType, string(groups(g))), ...
                        'Interpreter', 'none');

                    if g < numel(groupData)
                        figure;
                    end
                end
                return;
            end


            % Other plot types
            xVar = dropdownHandles(1).Value;
            yVar = dropdownHandles(2).Value;
            zVar = dropdownHandles(3).Value;
            colorVar = dropdownHandles(4).Value;

            nPlots = numel(groups);
            nRows = ceil(sqrt(nPlots));
            nCols = ceil(nPlots / nRows);

            for i = 1:nPlots
                tbl = groupData{i};
                if isempty(tbl), continue; end
                subplot(nRows, nCols, i);

                titleStr= sprintf('Selected Frequency Peak Comparison for %s %s: %s', ...
                    string(unique(tbl.Timeframe)), filterType, string(groups(i)));

                % Filter out deleted points (same approach as first snippet)
                keepIdx = true(height(tbl), 1);
                for k = 1:height(tbl)
                    if isPointDeleted(deletedPoints, titleStr, tbl.(yVar)(k), tbl.(xVar)(k))
                        keepIdx(k) = false;
                    end
                end
                tbl = tbl(keepIdx, :); % Keep only non-deleted points

                switch pType
                    case 'Simple 2D'
                        % Get selected grouping fields
                        if ~isempty(legendOverrideList.Value)
                            groupFields = legendOverrideList.Value;  % manual override
                        else
                            groupFields = groupingDrop.Value;  % default grouping
                        end

                        % Combine selected grouping fields into a single composite group label
                        if isempty(groupFields)
                            groupLabels = repmat("Ungrouped", height(tbl), 1);
                        else
                            groupLabels = string(tbl.(groupFields{1}));
                            for k = 2:length(groupFields)
                                field = groupFields{k};
                                groupLabels = groupLabels + " | " + string(tbl.(field));
                            end
                        end

                        % Convert to categorical with consistent order
                        groupCat = categorical(groupLabels, unique(groupLabels), 'Ordinal', true);

                        % Plot using gscatter
                        h = gscatter(tbl.(xVar), tbl.(yVar), groupCat, [], '.', 20);
                        set(h, 'ButtonDownFcn', @(src, event)deletePointFromPlot(src, event, mainFig));

                        if trendCheckbox.Value
                            deg = degreeSpinner.Value;
                            plotTrendline(tbl.(xVar), tbl.(yVar), deg);
                        end

                        selectedFit = decayFitDropdown.Value;
                        plotDecayCurve(selectedFit, tbl.(xVar), tbl.(yVar));
                     
                        xlabel(xVar, 'Interpreter', 'none');
                        ylabel(yVar, 'Interpreter', 'none');

                    case 'Flexible 2D'
                        h = scatter(tbl.(xVar), tbl.(yVar), 40, tbl.(colorVar), 'filled');
                        colorbar; colormap(jet);
                        xlabel(xVar); ylabel(yVar);

                        if trendCheckbox.Value
                            deg = degreeSpinner.Value;
                            plotTrendline(tbl.(xVar), tbl.(yVar), deg);
                        end

                         selectedFit = decayFitDropdown.Value;
                         plotDecayCurve(selectedFit, tbl.(xVar), tbl.(yVar));

                    case 'Flexible 3D'
                        h = scatter3(tbl.(xVar), tbl.(yVar), tbl.(zVar), 40, tbl.(colorVar), 'filled');
                        colorbar; colormap(jet);
                        xlabel(xVar); ylabel(yVar); zlabel(zVar); view(3);
                end

                title(titleStr, 'Interpreter', 'none');
                grid on;
            end

        catch ME
            uialert(fig, sprintf('Plotting failed:\n%s', ME.message), 'Plot Error');
        end
    end

    function plotTrendline(x, y, degree)
        % Remove NaNs
        validIdx = ~isnan(x) & ~isnan(y);
        x = x(validIdx);
        y = y(validIdx);

        if numel(x) < degree + 1
            warning('Not enough points to fit a polynomial of degree %d.', degree);
            return;
        end

        % Fit polynomial
        p = polyfit(x, y, degree);
        xFit = linspace(min(x), max(x), 200);
        yFit = polyval(p, xFit);

        hold on;
        plot(xFit, yFit, 'k-', 'LineWidth', 1.5, 'DisplayName', 'Trendline');

        % Format polynomial equation string (helper function below)
        eqStr = formatPolyEquation(p);

        % Position the equation text on the plot
        ax = gca;
        xPos = ax.XLim(1) + 0.05 * range(ax.XLim);
        yPos = ax.YLim(2) - 0.1 * range(ax.YLim);

        % Display equation with proper formatting
        text(xPos, yPos, eqStr, 'FontSize', 10, ...
            'BackgroundColor', 'w', 'EdgeColor', 'k', 'Margin', 2, ...
            'Interpreter', 'tex');
    end

% Helper function to format polynomial equation string nicely
    function eqStr = formatPolyEquation(p)
        degree = length(p) - 1;
        terms = cell(1, degree+1);

        for k = 1:length(p)
            coeff = p(k);
            power = degree - (k - 1);

            % Skip near-zero coefficients to clean up the equation
            if abs(coeff) < 1e-6
                terms{k} = '';
                continue;
            end

            % Format coefficient (abs, rounded)
            coeffAbs = abs(coeff);
            coeffStr = sprintf('%.2f', coeffAbs);

            % Format term according to power
            if power > 1
                term = [coeffStr 'x^{' num2str(power) '}'];
            elseif power == 1
                term = [coeffStr 'x'];
            else
                term = coeffStr;
            end

            % Add plus/minus sign, no leading plus
            if k == 1
                if coeff < 0
                    terms{k} = ['- ' term];
                else
                    terms{k} = term;
                end
            else
                if coeff < 0
                    terms{k} = [' - ' term];
                else
                    terms{k} = [' + ' term];
                end
            end
        end

        % Combine all non-empty terms into one string
        eqStr = ['y = ' strjoin(terms(~cellfun('isempty', terms)), '')];
    end

    function deletePointFromPlot(src, ~, mainFig)
        % Get axes
        ax = ancestor(src, 'axes');

        % Get mouse click position
        clickPos = ax.CurrentPoint(1, 1:2);

        % Get subplot title
        titleText = get(get(ax, 'Title'), 'String');
        if iscell(titleText)
            titleText = strjoin(titleText, ' ');
        end

        % Get current data
        xData = src.XData;
        yData = src.YData;

        % Find closest point to the click
        distances = hypot(xData - clickPos(1), yData - clickPos(2));
        [~, idx] = min(distances);

        % Ask for confirmation
        choice = questdlg(sprintf('Delete point at (%.2f, %.2f) in "%s"?', ...
            xData(idx), yData(idx), titleText), ...
            'Confirm Deletion', 'Yes', 'No', 'No');

        if strcmp(choice, 'Yes')
            % Get deletedPoints from appdata or initialize if empty
            deletedPoints = getappdata(mainFig, 'deletedPoints');
            if isempty(deletedPoints)
                deletedPoints = struct('title', {}, 'y', {}, 'x', {});
            end

            % Add to deleted points list
            deletedPoints(end+1).title = titleText;
            deletedPoints(end).y = yData(idx);
            deletedPoints(end).x = xData(idx);
            setappdata(mainFig, 'deletedPoints', deletedPoints);

            % Remove point from plot
            xData(idx) = [];
            yData(idx) = [];
            set(src, 'XData', xData, 'YData', yData);
        end
    end


    function isDeleted = isPointDeleted(deletedPoints, titleStr, y, x)
        isDeleted = false;
        for i = 1:numel(deletedPoints)

            if strcmp(deletedPoints(i).title, titleStr) && ...
                    abs(deletedPoints(i).y - y) < 1e-6 && ...
                    abs(deletedPoints(i).x - x) < 1e-6
                isDeleted = true;
                return;
            end
        end
    end

    function resetDeletedPoints(mainFig)
        % Clear the deletedPoints appdata
        setappdata(mainFig, 'deletedPoints', struct('title', {}, 'y', {}, 'x', {}));
        uialert(mainFig, 'Deleted points have been cleared.', 'Reset Complete');
    end

    function [modelFun, params] = fitExponentialDecay(x, y)
        % Fits an exponential decay model of the form y = a*exp(-b*x) + c
        % Returns a function handle to the fitted model and the fitted parameters.

        % Define the model type
        expFitType = fittype('a*exp(-b*x) + c', ...
            'independent', 'x', ...
            'coefficients', {'a','b','c'});

        % Fit the model using initial guesses for a, b, and c
        fitResult = fit(x, y, expFitType, 'StartPoint', [1, 1, 0]);

        % Extract fitted parameters
        params = [fitResult.a, fitResult.b, fitResult.c];

        % Define the model function using the fitted parameters
        modelFun = @(x) params(1) * exp(-params(2) * x) + params(3);
    end

    function [modelFun, params] = fitPowerLawDecay(x, y)
        % Ensure column vectors
        x = x(:);
        y = y(:);

        % Define and fit power-law model
        powerFitType = fittype('a*x.^(-b) + c', ...
            'independent', 'x', ...
            'coefficients', {'a','b','c'});

        fitResult = fit(x, y, powerFitType, 'StartPoint', [1, 1, 0]);

        % Extract parameters and model function
        params = [fitResult.a, fitResult.b, fitResult.c];
        modelFun = @(x) params(1) * x.^(-params(2)) + params(3);

        % Display equation
        fprintf('Power-Law Fit: y = %.4f * x^(-%.4f) + %.4f\n', ...
            params(1), params(2), params(3));
    end

    function plotDecayCurve(selectedFit, x, y)

          switch selectedFit
                            case 'Exponential Decay'
                                [modelFun, params] = fitExponentialDecay(x, y);

                                % Generate smooth x values for plotting
                                xFit = linspace(min(x), max(x), 200);
                                yFit = modelFun(xFit);

                                % Plot the fitted curve
                                hold on;
                                plot(xFit, yFit, 'r-', 'LineWidth', 2, 'DisplayName', 'Exponential Fit');

                                % Format the equation string
                                eqStr = sprintf('y = %.2f * e^{-%.2f x} + %.2f', params(1), params(2), params(3));

                                % Choose position for the text (top-left corner of the plot)
                                xPos = min(x) + 0.05 * range(x);
                                yPos = max(y) - 0.1 * range(y);

                                % Add the equation text on the plot
                                text(xPos, yPos, eqStr, 'FontSize', 12, 'Color', 'red', 'BackgroundColor', 'white', 'EdgeColor', 'black');

                            case 'Power Law Decay'
                                [modelFun, params] = fitPowerLawDecay(x,y);

                                % Generate smooth x values for plotting
                                xFit = linspace(min(x), max(x), 200);
                                yFit = modelFun(xFit);

                                % Plot the fitted curve
                                hold on;
                                plot(xFit, yFit, 'r-', 'LineWidth', 2, 'DisplayName', 'Exponential Fit');

                                % Format the equation string
                                eqStr = sprintf('y = %.2f * x^{-%.2f} + %.2f', params(1), params(2), params(3));

                                % Choose position for the text (top-left corner of the plot)
                                xPos = min(x) + 0.05 * range(x);
                                yPos = max(y) - 0.1 * range(y);

                                % Add the equation text on the plot
                                text(xPos, yPos, eqStr, 'FontSize', 12, 'Color', 'red', 'BackgroundColor', 'white', 'EdgeColor', 'black');
              otherwise
          end
    end


end
