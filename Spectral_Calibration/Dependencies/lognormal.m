% My lognormal: mu = center wavelength (or mean), and
% sigma = standard deviation of the variable's natural logarithm 

function y = lognormal(x,mu,sigma,type)

% fwhm = exp((mu-(sigma)^2)+sqrt(2*((sigma)^2)*log(2))) - exp((mu-(sigma)^2)-sqrt(2*((sigma)^2)*log(2)));
% FWHM of lognormal function

    if strcmp(type, 'normal')
        y1 = (1/(sqrt(2*pi)*sigma)) * (exp( (-1/2)*((log(x) - mu) / (sigma)).^2)) ./ x;
        y1(isnan(y1))=0;
        y = y1;
        
        
    elseif strcmp(type, 'reverse')
        y1 = (1/(sqrt(2*pi)*sigma)) * (exp( (-1/2)*((log(x) - mu) / (sigma)).^2)) ./ x;
        y1(isnan(y1))=0;
        
        y = fliplr(y1);
        

        
        %[m, i_min] = get_closest_wvl_index(input.wvl, multipeak_wvl_minus_FWHM) 

    end



end