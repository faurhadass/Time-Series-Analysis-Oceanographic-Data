function peaks = internalWaveKnownSpectralPeaks(lat)
% internalWaveKnownSpectralPeaks - Returns expected internal wave spectral peaks
%
% INPUT:
%   lat   - Latitude in degrees (for inertial frequency)
%
% OUTPUT:
%   peaks - struct with fields:
%       .name       - cell array of peak names
%       .period_hr  - array of periods in hours
%       .freq_cph   - array of frequencies in cycles per hour

    % Inertial frequency calculation
    Omega = 7.2921159e-5; % rad/s
    lat_rad = deg2rad(lat);
    f_rad_s = 2 * Omega * sin(lat_rad);
    f_cph = f_rad_s * 3600 / (2*pi); % cycles per hour
    inertial_period_hr = 1 / f_cph;

    % Define tidal constituents (name, period in hours)
    
    % Long Period
    long_period = {
        %'Mm', 661.31;
        'Ssa', 4383.05;
        'Sa', 8766.15265;
        %'Msf', 354.3670666;
        'Mf', 327.85
    };

    % Diurnal
    diurnal = {
        'K1', 23.93447213;
        %'O1', 25.81933871;
        %'Q1', 26.86835;
        %'P1', 24.06588766
    };

    % Semi-Diurnal
    semidiurnal = {
        'M2', 12.4206012;
        %'S2', 12.00;
        %'N2', 12.65834751;
        %'K2', 11.96723606
    };

    % Higher Harmonics
    harmonics = {
        'M4', 6.210300601;
        'M6', 4.140200401;
        'M3', 8.280400802;
    };

    % Inertial frequency (latitude-dependent)
    inertial = {'f', inertial_period_hr};

    % Combine all into single arrays
    all_names = [long_period(:,1); diurnal(:,1); semidiurnal(:,1); harmonics(:,1); inertial(1);];
    all_periods = [cell2mat(long_period(:,2)); cell2mat(diurnal(:,2)); cell2mat(semidiurnal(:,2)); cell2mat(harmonics(:,2)); inertial{2};];
    all_freqs = 1 ./ all_periods;

    % Output struct
    peaks.name = all_names;
    peaks.period_hr = all_periods;
    peaks.freq_cph = all_freqs;
end
