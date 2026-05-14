function concatTextFiles()
    % Select input files (any type)
    [inputFiles, inputPath] = uigetfile( ...
        {'*.*','All Files (*.*)'}, ...
        'Select files to concatenate (select IN ORDER)', ...
        'MultiSelect','on');

    if isequal(inputFiles,0)
        disp('No files selected. Exiting.');
        return;
    end

    if ischar(inputFiles)
        inputFiles = {inputFiles};
    end

    % Select output file (no restriction)
    [saveFile, savePath] = uiputfile( ...
        {'*.*','All Files (*.*)'}, ...
        'Save concatenated file as');

    if isequal(saveFile,0)
        disp('Save cancelled. Exiting.');
        return;
    end

    outputFile = fullfile(savePath, saveFile);

    % Build fully qualified file paths
    fullFiles = fullfile(inputPath, inputFiles);

    % Detect OS and build the OS command
    if ispc  % Windows
        % type file1 file2 file3 > output
        cmd = sprintf('type "%s" %s "%s"', ...
            fullFiles{1}, ...
            strjoin(strcat('"', fullFiles(2:end), '"')), ...
            outputFile);

        % On Windows you must use: type file1 file2 ... > outfile
        % but "system" doesn't handle redirection inside sprintf cleanly,
        % so we build it manually:
        filestring = strjoin(strcat('"', fullFiles, '"'));
        cmd = sprintf('type %s > "%s"', filestring, outputFile);

    else % macOS / Linux
        % cat file1 file2 file3 > output
        filestring = strjoin(strcat('"', fullFiles, '"'));
        cmd = sprintf('cat %s > "%s"', filestring, outputFile);
    end

    % Run command
    status = system(cmd);

    if status == 0
        disp(['✔ Files concatenated FAST into: ' outputFile]);
    else
        warning('OS-level concatenation failed. Command used: %s', cmd);
    end
end
