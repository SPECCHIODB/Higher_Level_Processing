function output=convolve(sensor, input)
 
      
    % Repeating the input matrix to create 3d matrix 
    % Always wvl first then spectrum - my brain would prefer these to be
    % columnar vectors stacked side by side
    %input_2d = [input.wvl', input.spectrum'];
    
    %input_3d = repmat(input_2d, [1,1, sensor.no_of_bands]);
    
    % Building sensor matrix in the same pattern
    % For now this is a for loop - will need to be changed in create_sensor
    % and doesn't include the resampling for the moment
    
    %sensor_3d = zeros(100, 2, sensor.no_of_bands);
    
    % Pre-allocating sensor_3d and input_3d
     %out_wvl = zeros(sensor.no_of_bands,1);
   % out_spectrum = zeros(sensor.no_of_bands,1);
   
   %sensor_3
    
    parfor i = 1:sensor.no_of_bands
        
       %sensor_wvl_vector = sensor.bands(i).srf.wvl;
       %sensor_coeff_vector = sensor.bands(i).srf.coeff;  
         
        band_start = sensor.bands(i).srf.wvl(1);
        band_end = sensor.bands(i).srf.wvl(end);
        
        input_wvl_start = ismembertol(input.wvl, band_start, 0.000001);
        input_wvl_end = ismembertol(input.wvl, band_end, 0.000001);
        
        wvl_ind_start = find(input_wvl_start == 1);
        wvl_ind_end = find(input_wvl_end ==1);
        
        % get wvl range of input spectrum for this band
        %wvl_ind = input.wvl >= band_start & input.wvl <= band_end;
        
        %size(wvl_ind)sen
       
        %sensor_wvl_vector_ip = input.wvl(wvl_ind);
        sensor_wvl_vector_ip = input.wvl(wvl_ind_start:wvl_ind_end);
        sensor_coeff_vector_ip = interp1(sensor.bands(i).srf.wvl, sensor.bands(i).srf.coeff, sensor_wvl_vector_ip, 'linear', 'extrap');
 
        sensor_2d = [sensor_wvl_vector_ip', sensor_coeff_vector_ip'];
        sensor_3d(:, :, i) = sensor_2d;
       
        input_2d = [input.wvl(wvl_ind_start:wvl_ind_end)', input.spectrum(wvl_ind_start:wvl_ind_end)'];
        input_3d(:, :,i) = input_2d;
                
    end    
    

    % Creating convoluted output 
    
    conv_out = sum(input_3d(:,2,:).*sensor_3d(:,2,:))./sum(sensor_3d(:,2,:));
    output.spectrum = squeeze(conv_out(1,1,:));
    output.wvl = extractfield(sensor.bands, 'centre_wvl')';
        

end
