function [f, psd] = computePSD(data, data2, nfft, fs, method, window, overlap, seg_length, p)
% computePSD calculates the Power Spectral Density using a specified method
% Inputs:
%   data     - input time series
%   fs       - sampling frequency
%   method   - 'periodogram', 'welch'
%   window   - string, e.g., 'hamming', 'hann', 'blackman', etc.
%   overlap  - percent overlap for segments (welch)
%   seg_length - seg length as percentage of signal's total length (welch)
%   p     - AR order (number of poles)
%
% Outputs:
%   f        - frequency axis
%   psd      - power spectral density

N = length(data);

% Create window function from string
if isa(window, 'char') || isa(window, 'string')
    if strcmpi(window, 'rectangular')
        win = ones(length(data), 1);
    else
        winFunc = str2func(lower(window));
        win = winFunc(length(data));
    end
else
    error('Window must be a string like ''hamming'', ''hann'', ''rectangular'', etc.');
end

switch lower(method)
    case 'periodogram' % Compute PSD using periodogram
        if isempty(nfft) || nfft < N
            nfft = N;  % Use data length if empty or too small
        end
        [psd, f] = periodogram(data, win, nfft, fs);
    case 'welch'
        % --- Validate Segment Length ---
        segmentLength = round(seg_length / 100 * N);
        segmentLength = max(2, min(segmentLength, N));  % At least 2, at most N

        % --- Validate Overlap ---
        overlapSamples = round(overlap / 100 * segmentLength);
        overlapSamples = min(overlapSamples, segmentLength - 1);  % Must be < segmentLength

        % --- Validate nfft ---
        if isempty(nfft) || nfft < segmentLength
            nfft = segmentLength;  % Must be ≥ segment length
        end

        % --- Compute Welch PSD ---
        [psd, f] = pwelch(data, win, overlapSamples, nfft, fs);
    case 'parametric'

        % --- Validate nfft ---
        if isempty(nfft) || nfft < N
            nfft = N;  % Use data length if empty or too small
        end

        % --- Compute parmetric AR PSD ---
        [psd,f] = pyulear(data,p,nfft,fs);

    case 'cross psd'
        % Validate segment length
        segmentLength = round(seg_length / 100 * N);
        segmentLength = max(2, min(segmentLength, N));

        % Validate overlap
        overlapSamples = round(overlap / 100 * segmentLength);
        overlapSamples = min(overlapSamples, segmentLength - 1);

        % Validate nfft
        if isempty(nfft) || nfft < segmentLength
            nfft = segmentLength;
        end

        % Compute Cross Power Spectral Density using pwelch
        [psd, f] = cpsd(data, data2, win, overlapSamples, nfft, fs);
    otherwise
        error('Unknown method: %s', method);
end

end
