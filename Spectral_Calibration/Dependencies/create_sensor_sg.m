function sensor=create_sensor_sg(name, start_wvl, end_wvl, no_of_bands, fwhm, w, k, aw, ak)

    sensor.name = name;
    sensor.no_of_bands = no_of_bands;

    % calculate spectral sampling interval
    ssi = (end_wvl - start_wvl) / (no_of_bands-1);

    for i=1:no_of_bands
        
        band.centre_wvl = start_wvl + (i-1)*ssi;
        band.nargin = nargin;
        band.fwhm = fwhm;
        
        if nargin > 5
            
            band.w = w;
            band.k = k;
            
        end     
        
        if nargin > 7
            
            band.aw = aw;
            band.ak = ak;
        
        end     


        band.srf = prepare_srf_sg(band);
        
        sensor.bands(i) = band;
               
    end

end