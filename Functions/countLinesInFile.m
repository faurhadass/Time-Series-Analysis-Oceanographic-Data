function nLines = countLinesInFile()
    
     % Let user select a file
    [file, path] = uigetfile({'*.*','All Files (*.*)'}, 'Select a file to count lines');
    
    if isequal(file,0)
        disp('No file selected.');
        nLines = [];
        return;
    end
    
    filename = fullfile(path, file);
    txt = fileread(filename);
    nLines = count(txt == newline);
end
