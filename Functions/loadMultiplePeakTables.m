function [masterTable, fileNames] = loadMultiplePeakTables()
    [files, path] = uigetfile('*.mat', 'Select .mat files', 'MultiSelect', 'on');

    if isequal(files, 0)
        disp('No files selected.');
        masterTable = [];
        fileNames = {};
        return;
    end

    if ischar(files)
        files = {files};  % Handle single file case
    end

    masterTable = [];
    fileNames = {};
    allTimeframes = [];

    for k = 1:numel(files)
        filePath = fullfile(path, files{k});
        data = load(filePath);

        if isfield(data, 'peakTable') && istable(data.peakTable)
            % Check if Timeframe column exists
            if ~ismember('Timeframe', data.peakTable.Properties.VariableNames)
                warning('File "%s" does not contain a "Timeframe" column. Skipped.', files{k});
                continue;
            end

            % Get unique timeframe(s) in this table
            tf = unique(data.peakTable.Timeframe);
            if numel(tf) > 1
                warning('File "%s" contains multiple timeframes. Skipped.', files{k});
                continue;
            end

            allTimeframes{end+1} = tf{1};  % Store the single timeframe string
            masterTable = [masterTable; data.peakTable];
            fileNames{end+1} = files{k};
        else
            warning('File "%s" does not contain a valid peakTable. Skipped.', files{k});
        end
    end

    % Final check that all timeframes match
    if isempty(masterTable)
        masterTable = [];
        fileNames = {};
        return;
    end

    if ~all(strcmp(allTimeframes, allTimeframes{1}))
        errordlg('Selected files contain mismatched Timeframes. Please use files with the same Timeframe.', 'Timeframe Mismatch');
        masterTable = [];
        fileNames = {};
        return;
    end

    fprintf('Loaded %d files with matching Timeframe: %s\n', numel(fileNames), allTimeframes{1});
end

