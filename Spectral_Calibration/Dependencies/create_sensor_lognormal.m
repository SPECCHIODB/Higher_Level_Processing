function sensor=create_sensor_lognormal(name, start_wvl, end_wvl, no_of_bands, mu, sigma, type) 

    sensor.name = name;
    sensor.no_of_bands = no_of_bands;

    % calculate spectral sampling interval
    ssi = (end_wvl - start_wvl) / (no_of_bands-1);

    for i=1:no_of_bands
        
        band.centre_wvl = start_wvl + (i-1)*ssi;
        band.mu = mu;
        band.sigma = sigma;
        band.type = type;
        band.srf = prepare_srf_lognormal(band);
        
        sensor.bands(i) = band;
               
    end

end