function [contour_levels, time_skip] = getUserAnimationSettings()
    % getUserAnimationSettings - Prompt user for animation settings
    % Returns default values (30, 10) if input is invalid or canceled.

    prompt = {'Enter number of contour levels:', 'Enter time index skip for animation:'};
    dlg_title = 'Animation Settings';
    num_lines = [1 50];
    defaultans = {'30', '10'};

    answer = inputdlg(prompt, dlg_title, num_lines, defaultans);

    % Fallback defaults
    contour_levels = 30;
    time_skip = 10;

    % Validate user input
    if isempty(answer)
        disp('User canceled. Using defaults: contour_levels = 30, time_skip = 10.');
        return;
    end

    user_contour_levels = str2double(answer{1});
    user_time_skip = str2double(answer{2});

    if ~isnan(user_contour_levels) && user_contour_levels > 0
        contour_levels = round(user_contour_levels);
    else
        disp('Invalid contour level input. Using default: 30.');
    end

    if ~isnan(user_time_skip) && user_time_skip > 0
        time_skip = round(user_time_skip);
    else
        disp('Invalid time skip input. Using default: 10.');
    end
end
