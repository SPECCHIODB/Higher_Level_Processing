function srf=prepare_srf_lognormal(band)

    %if strcmp(band.mode_type, 'gaussian')

    %sigma = 0.8493218 * band.fwhm/2;
    %range = 3*sigma;
    
    %x = linspace(-range, +range, 100);
    
    x = linspace(0, 40, 1001);
    
    %srf_values = 1/(sqrt(2*pi)*sigma)* exp(-0.5*(x/sigma).^2);
    srf_values = lognormal(x, band.mu, band.sigma, band.type);
    
    [srf_values_max, srf_values_max_i] = max(srf_values);
    x_where_srf_max = x(srf_values_max_i);
    
    % Finding range of peak across the x
    % srf_values_peak_range = srf_values > 0.00001
    
    %peak_subset = srf_values(srf_values_peak_range)
    
    %peak_subset_midpoint =
    
    srf.coeff = srf_values;
    %srf.wvl = x - x_max + band.centre_wvl; % shift SRF to the centre wavelength
    srf.wvl = x - x_where_srf_max + band.centre_wvl;
    %srf.sigma = sigma;
    
    %end
    

end