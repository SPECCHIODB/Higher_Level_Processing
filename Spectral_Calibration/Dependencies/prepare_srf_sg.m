function srf=prepare_srf_sg(band)

    %if strcmp(band.mode_type, 'gaussian')

    
    if (band.nargin < 7)
        %disp('running gaussian')
        sigma = 0.8493218 * band.fwhm/2;
        range = 3*sigma;
    
        x = linspace(-range, +range, 100);
    
        srf_values = 1/(sqrt(2*pi)*sigma)* exp(-0.5*(x/sigma).^2);
    
        srf.coeff = srf_values;
        srf.wvl = x + band.centre_wvl; % shift SRF to the centre wavelength
        %srf.sigma = sigma;
    
    end
    
    if (band.nargin == 7)
        %disp('running super gaussian')
        w = band.w;
        k = band.k;
        range = 3*w;
        
        x = linspace(-range, +range, 100);
        
        srf_values = super_gaussian(x,w,k);
        
        srf.coeff = srf_values;
        srf.wvl = x + band.centre_wvl;
        
    end

    if (band.nargin > 7)
       % disp('running asymmetric super gaussian')
        
        w = band.w;
        k = band.k;
        range = 3*w;
        aw = band.aw;
        ak = band.ak;
        
        x = linspace(-range, +range, 100);
        
        srf_values = super_gaussian(x,w,k,aw,ak);
        
        srf.coeff = srf_values;
        srf.wvl = x + band.centre_wvl;
        
        
    end
    
    
end