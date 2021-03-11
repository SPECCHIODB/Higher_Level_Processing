function srf=prepare_srf(band)

    %if strcmp(band.mode_type, 'gaussian')

    sigma = 0.8493218 * band.fwhm/2;
    range = 3*sigma;
    
    x = linspace(-range, +range, 100);
    
    srf_values = 1/(sqrt(2*pi)*sigma)* exp(-0.5*(x/sigma).^2);
    
    srf.coeff = srf_values;
    srf.wvl = x + band.centre_wvl; % shift SRF to the centre wavelength
    %srf.sigma = sigma;
    


    plot(srf.wvl, srf.coeff);
    %hold off
    %end
    %x

end