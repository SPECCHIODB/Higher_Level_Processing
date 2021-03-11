function sensor=create_sensor(name, start_wvl, end_wvl, no_of_bands, fwhm) %, mode_type, mode_parameters)

    sensor.name = name;
    sensor.no_of_bands = no_of_bands;

    % calculate spectral sampling interval
    ssi = (end_wvl - start_wvl) / (no_of_bands-1);

    figure
    hold on
    
    for i=1:no_of_bands
        
        band.centre_wvl = start_wvl + (i-1)*ssi;
        band.fwhm = fwhm;
        %band.mode_type = mode_type;
        %band.mode_parameters = mode_parameters;
        band.srf = prepare_srf(band);
        
        sensor.bands(i) = band;
               
    end

    hold off
    ssi
    
end