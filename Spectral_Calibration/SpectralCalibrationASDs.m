%

%%
%   SPECCCHIO Interactive Data Selection Sandbox
%
%   Interactive software for the selection of data from SPECCHIO using the
%   data hierarchy browser.
%   Direct connection to the SPECCHIO spectral database V3.1 or higher required.
%   Assumes that a static defintion of the SPECCHIO jar file exists in
%   classpath.txt. See the SPECCHIO Matlab Guide on how to define the
%   classpath; otherwise this code will not work!
%   Alternatively, use the javaaddpath command as commented below.
%   For details on how to setup Matlab in connection with SPECCHIO see the
%   online programming guide:  
%   ftp://v473.vanager.de/ProgrammingCourse/Matlab_accessing_SPECCHIO_V3.pdf
%   
%   Further dependencies: 
%   This code requires the jcontrol package. Get it from either:
%   https://sourceforge.net/projects/waterloo/files/s
%   https://uk.mathworks.com/matlabcentral/fileexchange/15580-using-java-swing-components-in-matlab
%
%   (c) 2014 ahueni, RSL, University of Zurich
%       2017-04-18, ahueni: updated the passing of user data for the
%       databrowser component
%
%

% Setting dynamic java class path
javaaddpath ({'/Users/kmason/SPECCHIO/SPECCHIO.app/Contents/Java/specchio-client.jar'});

specchio_interactive_sandbox_GUI()

function specchio_interactive_sandbox_GUI()

    import ch.specchio.client.*;
    import ch.specchio.queries.*;
    import ch.specchio.gui.*;
    
    font_size = 13;
    
    no_box_height = 0.02;
    no_box_x_pos = 0.51;
    no_box_y_pos_1 = 0.97;
    no_box_y_pos_2 = no_box_y_pos_1 - no_box_height*1.1;
    no_box_y_pos_3 = no_box_y_pos_2 - no_box_height*1.1;
    txt_y_offset_from_axis = 0.08;

    % create new window
    user_data.window_h = figure('Units', 'normalized', 'Position', [0 0 0.7 0.7], 'Name', 'SPECCHIO V3 - Matlab Sandbox', 'Color', [0.9 0.9 0.9]);

    set(user_data.window_h,'Toolbar','figure');

    % create client and load server descriptors
    user_data.cf = SPECCHIOClientFactory.getInstance();
    user_data.db_descriptor_list = user_data.cf.getAllServerDescriptors();
    
    % Prepare container for data browser
    user_data.scrollpane=jcontrol(user_data.window_h, 'javax.swing.JScrollPane', 'Position', [0 0.5 0.3 0.45]);

    
    % database connection combo box
    user_data.db_conn_combo = uicontrol('Style', 'popup',...
        'Units', 'normalized',...
        'FontSize', font_size, ...
        'Position', [0 0.93 0.3 0.06],  'Callback', @DBConn);

    con_string{1} = 'Please select DB connection from the list below ...';

    for i=0:user_data.db_descriptor_list.size()-1

        con_string{i+2} = char(user_data.db_descriptor_list.get(i).toString());
    end

    set(user_data.db_conn_combo,'String',con_string);
    
    
    % other GUI elements ...
    uicontrol(user_data.window_h,'Style','text',...
                'String','SPECCHIO Instrument Name:',...
                'Units', 'normalized','FontSize', font_size,...
                'Position',[0 0.43 0.15 no_box_height], 'BackgroundColor', [0.9 0.9 0.9]);   
 
    user_data.InstrumentInDB = uicontrol(user_data.window_h,'Style','text',...
                'String','',...
                'Units', 'normalized','FontSize', font_size,...
                'Position',[0.15 0.43-no_box_height 0.15 no_box_height*2], 'BackgroundColor', [0.8 0.9 0.9]);              
    


    user_data.TotalSpectraText = uicontrol(user_data.window_h,'Style','text',...
        'String','Total # of selected spectra:',...
        'Units', 'normalized','FontSize', font_size,...
        'Position',[0.31 no_box_y_pos_1 0.18 no_box_height], 'BackgroundColor', [0.9 0.9 0.9]);


    user_data.TotalSpectra = uicontrol(user_data.window_h,'Style','text',...
        'String','0',...
        'Units', 'normalized','FontSize', font_size,...
        'Position',[no_box_x_pos no_box_y_pos_1 0.05 no_box_height], 'BackgroundColor', [0.8 0.9 0.9]);
    
    
    user_data.SpaceText = uicontrol(user_data.window_h,'Style','text',...
        'String','Spectral Space Selector:',...
        'Units', 'normalized','FontSize', font_size,...
        'Position',[0.31 no_box_y_pos_3 0.18 no_box_height], 'BackgroundColor', [0.9 0.9 0.9]);
    
    user_data.CurrSpaceText = uicontrol(user_data.window_h,'Style','text',...
        'String','of 0 Space(s)',...
        'Units', 'normalized','FontSize', font_size,...
        'Position',[no_box_x_pos+0.01 no_box_y_pos_3 0.18 no_box_height], 'BackgroundColor', [0.9 0.9 0.9]);
    
    
    % buttons
    gbutton=jcontrol(user_data.window_h, javax.swing.JButton('Sandbox'), 'Position', [0.57 0.96 0.1 0.03]);
    set(gbutton, 'MouseClickedCallback', @SPECCHIO_Sandbox); 
    
    
    % buttons
    gbutton=jcontrol(user_data.window_h, javax.swing.JButton('auto_select'), 'Position', [0.67 0.96 0.1 0.03]);
    set(gbutton, 'MouseClickedCallback', @auto_select); 
    
    % buttons
    gbutton=jcontrol(user_data.window_h, javax.swing.JButton('linearity_select'), 'Position', [0.77 0.96 0.1 0.03]);
    set(gbutton, 'MouseClickedCallback', @linearity_select); 
    
    % buttons
    gbutton=jcontrol(user_data.window_h, javax.swing.JButton('spectral_cal'), 'Position', [0.87 0.96 0.1 0.03]);
    set(gbutton, 'MouseClickedCallback', @spectral_cal); 
     
    
    % space selector
    
    user_data.spinner_model = javax.swing.SpinnerNumberModel;
    user_data.spinner_model.setMaximum(java.lang.Integer(1));
    user_data.spinner_model.setMinimum(java.lang.Integer(1));
    
    jSpinner = javax.swing.JSpinner(user_data.spinner_model);
    
    user_data.space_spinner = jcontrol(user_data.window_h, jSpinner, 'Position', [no_box_x_pos no_box_y_pos_3 0.05 no_box_height*1.2]);
    set(user_data.space_spinner, 'StateChangedCallback', @SpaceSelection); 
    

    % plotting panel
    % data display axes and panels
    col1_pos = 0.35;
    col2_pos = 0.68;
    axes_width = 0.3;
    axes_height = 0.4;
    row1_pos = 0.9 - axes_height;
    row2_pos = 0.59 - axes_height;
    
    user_data.spectral_plot = axes('Parent',user_data.window_h,'Position',[col1_pos row1_pos axes_width axes_height]);  
    


    % store data in figure
    set(user_data.window_h, 'UserData', user_data);


end


function SpaceSelection(hObject, EventData)

    fh = ancestor(hObject.hghandle, 'figure');    
    user_data = get(fh, 'UserData');
    
    

    plot_space(user_data);

end

function auto_select(hObject, EventData)  % NEW button in Sandbox interface! try to get 1) plot the mean of measurements at 300 W for every instrument and 2) get the instrument names

    fh = ancestor(hObject.hghandle, 'figure');    
    user_data = get(fh, 'UserData');
  
    import ch.specchio.queries.*;    
    
    disp('starting ...');
    
    query = Query('spectrum');
    query.setQueryType(Query.SELECT_QUERY);

    query.addColumn('spectrum_id')

    cond = SpectrumQueryCondition('spectrum', 'measurement_unit_id');
    cond.setValue('2');
    cond.setOperator('=');
    query.add_condition(cond);

    cond = EAVQueryConditionObject('eav', 'spectrum_x_eav', 'Keyword', 'string_val');
    cond.setValue('300W standard CAL');
    cond.setOperator('like');
    query.add_condition(cond);

    user_data.ids = user_data.specchio_client.getSpectrumIdsMatchingQuery(query);
    
    % put arguments to 0 to sort by instrument
    user_data.spaces = user_data.specchio_client.getSpaces(user_data.ids, 0, 0, 'Acquisition Time');
    figure

    if user_data.ids.size <= 1000
       
               
       for  i = 1:length(user_data.spaces) % where 1 is first value of i, colon operator is for unit-spaced vector and user_data.size is the max value of i (4 in this case <=> 4 instruments) 
     
            space = user_data.spaces(i);
           
            space = user_data.specchio_client.loadSpace(space);

            spectra.vectors = space.getVectorsAsArray();
            spectra.wvl = space.getAverageWavelengths();
            spectra.unit = char(space.getMeasurementUnit.getUnitName);
            spectra.instrument = space.getInstrument();

            spectra.ids = space.getSpectrumIds(); % get them sorted by 'Acquisition Time' (sequence as they appear in space)

            
            avg_spectrum = mean(spectra.vectors);
    
            stddev = std(spectra.vectors);
       

            subplot(2,1,1)   
            hold on
            plot(spectra.wvl, avg_spectrum)
         
            plotnames{i} = char(spectra.instrument.getInstrumentNumber)
           
            subplot(2,1,2)
            hold on
            plot(spectra.wvl, stddev)
            
       end
       
       subplot(2,1,1) 
       legend(plotnames)   
       
       subplot(2,1,2) 
       legend(plotnames)        
       
       figure(3)
       hold on

       for  j = 1:length(user_data.spaces) % where 1 is first value of i, colon operator is for unit-spaced vector and user_data.size is the max value of i (4 in this case <=> 4 instruments) 
   

            space = user_data.spaces(j);
           
            space = user_data.specchio_client.loadSpace(space);

            spectra.vectors = space.getVectorsAsArray();
            spectra.wvl = space.getAverageWavelengths();
            spectra.unit = char(space.getMeasurementUnit.getUnitName);
            spectra.instrument = space.getInstrument();

            spectra.ids = space.getSpectrumIds();
            
            stddev = std(spectra.vectors);
         
            plot(spectra.wvl, stddev)
            plotnames{j} = char(spectra.instrument.getInstrumentNumber)
             
       end
       
       legend(plotnames)
       
  else
            
            msgbox('Data not loaded as more than 1000 spectra are selected');
            
    end
 
end


function linearity_select(hObject, EventData)  % NEW button in Sandbox interface! try to get 1) plot linearity response for every instrument + delta 2) get the instrument names

    fh = ancestor(hObject.hghandle, 'figure');    
    user_data = get(fh, 'UserData');
  
    import ch.specchio.queries.*;    
    
    disp('starting ...');
    
    query = Query('spectrum');
    query.setQueryType(Query.SELECT_QUERY);

    query.addColumn('spectrum_id')

    cond = SpectrumQueryCondition('spectrum', 'measurement_unit_id');
    cond.setValue('5');              % 5 for DNs, 2 for radiance (check with "Build Query" in Specchio, select Measurement Unit, then click "run query" then right-click in "Matching spectrum identifiers" and select "copy Matlab ready query to clipboard")
    cond.setOperator('=');
    query.add_condition(cond);

    cond = EAVQueryConditionObject('eav', 'spectrum_x_eav', 'Keyword', 'string_val');
    cond.setValue('300W IT-gains var CAL');
    cond.setOperator('like');
    query.add_condition(cond);

    user_data.ids = user_data.specchio_client.getSpectrumIdsMatchingQuery(query);
    
    % put arguments to 0 to sort by instrument
    user_data.spaces = user_data.specchio_client.getSpaces(user_data.ids, 0, 0, 'Acquisition Time');

    if user_data.ids.size <= 1000
                
       for  i = 1:length(user_data.spaces) % where 1 is first value of i, colon operator is for unit-spaced vector and user_data.size is the max value of i (4 in this case <=> 4 instruments) 

        
            space = user_data.spaces(i);
           
            space = user_data.specchio_client.loadSpace(space);


            spectra.vectors = space.getVectorsAsArray();
            spectra.wvl = space.getAverageWavelengths(); % centre wavelengths
            spectra.unit = char(space.getMeasurementUnit.getUnitName);
            spectra.instrument = space.getInstrument();

            spectra.ids = space.getSpectrumIds(); % get them sorted by 'Acquisition Time' (sequence as they appear in space)

            group_collection = user_data.specchio_client.sortByAttributes(spectra.ids, 'Integration Time');
            groups = group_collection.getSpectrum_id_lists;
              
              
            IntegrationTimes = user_data.specchio_client.getMetaparameterValues(spectra.ids, 'Integration Time');
              
            IntegrationTimes = IntegrationTimes.get_as_double_array;
              
            ind_of_8 = IntegrationTimes == 8;
            IntegrationTimes(ind_of_8) = 8.5; % true value here, but ASD cannot write something else than an integer in the IT attribute!
            % we have the following integration times: 136 ms, 68 ms, 
            % 34 ms, 17 ms, 8.5 ms (taken in that order, since L is cst) 

       
           for j = 1:length(spectra.wvl)
              
               if spectra.wvl(j) == 800
                   
                   figure
                   hold on
                   title(char(spectra.instrument.getInstrumentNumber))
                   plot(IntegrationTimes, spectra.vectors(:,j), '*') % reminder: plot(abscissa_first, ordinate_second, 'visualstyle_third')
                   
%                  polynomial fit (regression) of the above:
                   [c, S] = polyfit(IntegrationTimes, spectra.vectors(:,j), 1); % 1 is for first order, replace as needed
                   [fit, delta] = polyval(c, IntegrationTimes, S);
                   
                   plot(IntegrationTimes,fit,'r')
                  
                   figure                 
                   plot(IntegrationTimes,delta,'o')
                   title(char(spectra.instrument.getInstrumentNumber))
                  
                  
                   own_delta = spectra.vectors(:,j) - fit;
                  
                   figure
                   plot(IntegrationTimes,own_delta,'o') % 30 measurements per integration time
                   title(char(spectra.instrument.getInstrumentNumber))
                  
%                   Results seem to indicate a "U" shaped delta over IT,
%                   at 800 nm
                  
%                   rmse(j) = rmse(spectra.vectors(:,j), fit);
                  
                  
                  
                   % rmse bias due to own_delta deformed by fit which has a
                   % offset; try redo the same but with fit having no
                   % offset - mathworks documentation on linear regression
               end
               
                [c, S] = polyfit(IntegrationTimes, spectra.vectors(:,j), 1); % 1 is for first order, replace as needed
                [fit, delta] = polyval(c, IntegrationTimes, S);
               
                rmse_(j) = rmse(spectra.vectors(:,j), fit); % done for every wavelength, but meaningful only in VNIR since for detector in SWIR we didn't vary by IT, but by gains (relationship with IT TBD) 
               
           end

           figure
           hold on
           plot(spectra.wvl,rmse_)
           title(char(spectra.instrument.getInstrumentNumber))

            
       end
                                                                  
       
  else
            
            msgbox('Data not loaded as more than 1000 spectra are selected');
            
  end
 

end


function spectral_cal(hObject, EventData)  % NEW button in Sandbox interface! both centre wavelength and FWHM determination for notable cal lamp spectral features (peaks)

    fh = ancestor(hObject.hghandle, 'figure');    
    user_data = get(fh, 'UserData');
  
    import ch.specchio.queries.*;    

    disp('starting ...');
    
    query = Query('spectrum');
    query.setQueryType(Query.SELECT_QUERY);
    
    query.addColumn('spectrum_id')
    
    cond = SpectrumQueryCondition('spectrum', 'measurement_unit_id');
    cond.setValue('5'); 								% 5 for DNs, 2 for radiance (check with "Build Query" in Specchio, select Measurement Unit, then click "run query" then right-click in "Matching spectrum identifiers" and select "copy Matlab ready query to clipboard")
    cond.setOperator('=');
    query.add_condition(cond);
    
    cond = EAVQueryConditionObject('eav', 'spectrum_x_eav', 'Keyword', 'string_val');
    cond.setValue('ASD_Spectral_cal_data');
    cond.setOperator('like');
    query.add_condition(cond);
    
    cond = EAVQueryConditionObject('eav', 'spectrum_x_eav', 'Keyword', 'string_val');
    cond.setValue('LowAmp');
    cond.setOperator('!=');
    query.add_condition(cond);
    
    
    user_data.ids = user_data.specchio_client.getSpectrumIdsMatchingQuery(query);
   
    user_data.ids = user_data.specchio_client.filterSpectrumIdsByNotHavingAttribute(user_data.ids, 'Garbage Flag')
    
    disp('displaying user ids:');
    disp(user_data.ids);
    
    % put arguments to 0 to sort by instrument
    user_data.spaces = user_data.specchio_client.getSpaces(user_data.ids, 0, 0, 'Acquisition Time');
    
    if user_data.ids.size <= 1000
        
        x = 1;
              
        for  i = 1:length(user_data.spaces) % more generic for loop for
            %when we add in functionality for multiple instruments
            % where 1 is first value of i, colon operator is for
            % unit-spaced vector and user_data.size is the max value of i
            % (4 in this case <=> 4 instruments)
            
         disp('size of user_data.spaces');
         disp(size(user_data.spaces));
            
            space = user_data.spaces(i); % takes every
            % instrument in a directory using the for loop commented out
            % above
            
            %{ 
            For now using instrument ids to distinguish between different
            instument serial codes:
                - id 3 = 16006 (i = 1)
                - id 4 = 16007 (i = 3)
                - id 9 = 18130 (i = 2)
                - id 15 = 18140 (i = 4) 
            %}
            
           % getting instrument_id
            instrument_id = space.getInstrumentId
            
            % Setting instrument serial based on instrument id
            if instrument_id == 3
                instrument_serial = 16006
            elseif instrument_id == 4
                instrument_serial = 16007
            elseif instrument_id == 9
                instrument_serial = 18130
            elseif instrument_id == 15
                instrument_serial = 18140
            else 
                instrument_serial = 'NULL'
            end
            
            % Set which instruments are to be run
            instruments_to_be_run_list = [16006, 16007, 18130, 18140];
            
            % Skipping all peaks for a given instrument if not found in
            % instruments_to_be_run_list
            if ismember(instrument_serial, instruments_to_be_run_list)
               disp(['running peaks for this instrument: ', num2str(instrument_serial)])
               
            else
                disp(['not running peaks for this instrument: ', num2str(instrument_serial)])
                continue
                
            end
           
            
                
            % defining lamps with peak information
            
            lamps(1).name = 'Hg_cal_data';            
            lamps(1).peaks = [435.83350, 546.07500, 1013.975, 1128.71, 1395.055, 1529.582, 1813.038, 1970.017, 2325.942]; % Removed outlier: 2249.942
            lamps(1).FWHM = [0.05, 0.015, 0.10, 0.10, 0.10, 0.10, 0.15, 0.15, 0.15];
            lamps(1).u_cw = [0.00010, 0.00010, 0.005, 0.04, 0.020, 0.020, 0.020, 0.020, 0.011];
            lamps(1).references = {'uncertainty CW (NIST) 0.00010 nm; FWHM (derived from Z. Gavare, 2003) 0.05 nm',
               'uncertainty CW (NIST) 0.00010 nm; FWHM (derived from Craig J. Sansonetti, 1996) 0.015 nm',
               'uncertainty CW (NIST) 0.005 nm; FWHM 0.10 nm',
               'uncertainty CW (NIST) 0.04 nm; FWHM 0.10 nm',
               'uncertainty CW (NIST) 0.020 nm; FWHM 0.10 nm',
               'uncertainty CW (NIST) 0.020 nm; FWHM 0.10 nm',
               'uncertainty CW (NIST) 0.020 nm; FWHM 0.15 nm',
               'uncertainty CW (NIST) 0.020 nm; FWHM 0.15 nm',
               'uncertainty CW (NIST) 0.011 nm; FWHM 0.15 nm'}
            lamps(1).flag = [0, 0, 0, 0, 0, 0, 1, 1, 1]; %flag 0 (normal peak) or 1 (valid for ASD 4s only)
            lamps(1).alreadyrunflag = [0, 0, 0, 0, 0, 0, 0, 0, 0]; % Peak can be skipped if set to 1 
            
            %{
            lamps(1).multipeaks = {[365.01580, 365.48420, 366.28870, 366.32840], 
                                    [404.65650, 407.78370, 410.8054],
                                    [404.65650, 407.78370],
                                    [576.96100, 578.969, 579.067, 580.3782],
                                    [1117.682, 1128.71]; % already exists as single peak at 1128, comparison
                                    [1350.558, 1357.021, 1367.351]};
            lamps(1).multipeaks_I = {[9000, 3000, 500, 2000], 
                                    [12000, 1000, 70], 
                                    [12000, 1000],
                                    [1000, 30, 900, 400],
                                    [10, 1000],
                                    [200, 200, 300]}; 
            %}
            
            lamps(2).name = 'Ne_cal_data';
            lamps(2).peaks = [703.24128, 724.51665, 743.88981, 837.76070, 1523.07144, 2395.7931, 2364.2934]; % Removed two outliers: 650.65277, 692.94672
            lamps(2).FWHM = [0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015]; % check final 2 FWHMs
            lamps(2).u_cw = [0.00004, 0.00004, 0.00004, 0.00010, 0.00017, 0.0003, 0.0003];
            lamps(2).references = {'uncertainty CW (NIST) 0.00004 nm; FWHM 0.015 nm',
                'uncertainty CW (NIST) 0.00004 nm; FWHM 0.015 nm',
                'uncertainty CW (NIST) 0.00004 nm; FWHM 0.015 nm',
                'uncertainty CW (NIST) 0.00010 nm; FWHM 0.015 nm',
                'uncertainty CW (NIST) 0.00017 nm; FWHM 0.015 nm',
                'uncertainty CW (NIST) 0.0003 nm; FWHM 0.015 nm', 
                'uncertainty CW (NIST) 0.0003 nm; FWHM 0.015 nm'}
            lamps(2).flag = [0, 0, 0, 0, 0, 0, 1];
            lamps(2).alreadyrunflag = [0, 0, 0, 0, 0, 0, 0];
            
            %{
            lamps(2).multipeaks = {[650.65277, 653.28824], 
                                    [659.89528, 660.29007],
                                    [702.40500, 703.24128, 705.12922, 705.91079],
                                    [1514.00981, 1517.43113, 1518.97238, 1519.06122, 1519.09319, 1519.26365, 1523.07144]};
            lamps(2).multipeaks_I = {[15000, 1000],
                                    [10000, 1000],
                                    [34000, 85000, 2200, 10000],
                                    [350, 32, 63, 99, 270, 48, 5300]};
            %}
                  
            lamps(3).name = 'Xe_cal_data';
            lamps(3).peaks = [711.9598, 764.2024, 881.94106, 916.26520, 1365.648, 1473.238, 1541.801, 1672.8158, 1732.5798, 1878.8146, 2026.7774, 2319.80]; % removed outlier: 1174.2236
            lamps(3).FWHM = [0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015];
            lamps(3).u_cw = [0.002, 0.001, 0.00005, 0.00005, 0.010, 0.010, 0.010, 0.0008, 0.0009, 0.0012, 0.0011, 0.08];
            lamps(3).references = {'uncertainty CW (NIST) 0.002 nm; FWHM 0.015 nm',
                'uncertainty CW (NIST) 0.001 nm; FWHM 0.015 nm',
                'uncertainty CW (NIST) 0.00005 nm; FWHM 0.015 nm',
                'uncertainty CW (NIST) 0.00005 nm; FWHM 0.015 nm',
                'uncertainty CW (NIST) 0.010 nm; FWHM 0.015 nm',
                'uncertainty CW (NIST) 0.010 nm; FWHM 0.015 nm',
                'uncertainty CW (NIST) 0.010 nm; FWHM 0.015 nm',
                'uncertainty CW (NIST) 0.0008 nm; FWHM 0.015 nm',
                'uncertainty CW (NIST) 0.0009 nm; FWHM 0.015 nm',
                'uncertainty CW (NIST) 0.0012 nm; FWHM 0.015 nm',
                'uncertainty CW (NIST) 0.0011 nm; FWHM 0.015 nm',
                'uncertainty CW (NIST) 0.08 nm; FWHM 0.015 nm'}
            lamps(3).flag = [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0];
            lamps(3).alreadyrunflag = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
            
            %{
            lamps(3).multipeaks = {[711.9598, 713.6570],
                                    [764.2024, 764.3910],
                                    [1075.886, 1083.834, 1089.5324],
                                    [2137.8892, 2147.5961],
                                    [2307.98, 2311.16, 2319.80, 2325.91, 2328.59],
                                    [2470.90, 2478.30, 2483.22],
                                    [2478.30, 2483.22]};
            lamps(3).multipeaks_I = {[500, 15],
                                    [500, 100],
                                    [100, 1000, 870],
                                    [26, 140],
                                    [45, 8, 10, 35, 100],
                                    [60, 30, 20],
                                    [30, 20]};
             %}
            
             for lamp_no = 1:length(lamps)
                % looping over each instrument by number of lamps
                 
                query = Query('spectrum');
                query.setQueryType(Query.SELECT_QUERY);
                
                query.addColumn('spectrum_id')
                
                cond = SpectrumQueryCondition('spectrum', 'measurement_unit_id');
                cond.setValue('5');
                cond.setOperator('=');
                query.add_condition(cond);
                
                cond = SpectrumQueryCondition('spectrum', 'sensor_id');
                cond.setValue('0');
                cond.setOperator('=');
                query.add_condition(cond);
                
                cond = SpectrumQueryCondition('spectrum', 'instrument_id');
                cond.setValue(num2str(space.getInstrumentId));
                cond.setOperator('=');
                query.add_condition(cond);
                
                cond = SpectrumQueryCondition('spectrum', 'calibration_id');
                cond.setValue('0');
                cond.setOperator('=');
                query.add_condition(cond);
                
                cond = EAVQueryConditionObject('eav', 'spectrum_x_eav', 'Keyword', 'string_val');
                cond.setValue(lamps(lamp_no).name);
                cond.setOperator('like');
                query.add_condition(cond);
                
                ids = user_data.specchio_client.getSpectrumIdsMatchingQuery(query);
                
                lamp_spaces = user_data.specchio_client.getSpaces(ids, 0, 0, 'Acquisition Time');
                
                lamp_space = lamp_spaces(1);
                
                lamp_space = user_data.specchio_client.loadSpace(lamp_space);
                
                spectra.vectors = lamp_space.getVectorsAsArray();
                
                user_data.current_spectra.wvl = lamp_space.getAverageWavelengths;
                
                % We have 30 measurements for each peak
                mean_vector = mean(spectra.vectors); % takes the mean of different spectrum ids

                std_spectra_vectors = std(user_data.current_spectra.vectors);
                
                % loop over all peaks per current lamp
                
                for peak = 1:length(lamps(lamp_no).peaks)
                    
                    peak_type = 'singlepeak'
                    
                    % skipping peak if it is only valid for instruments:
                    % 18130 and 18140
                    if lamps(lamp_no).flag(peak) == 1 && (instrument_serial == 16006 || instrument_serial == 16007)
                        disp('skipping peak for this instrument')
                        continue
                    end
                    
                    % Similarly skipping peak if it has already been run
                    if lamps(lamp_no).alreadyrunflag(peak) == 1
                        disp('already run this peak')
                        x = x+1;
                        continue
                    end
                   

                    disp(['Doing peak ',  num2str(lamps(lamp_no).peaks(peak))])
                    
                    % defining detector based on input peak wavelength
                    if lamps(lamp_no).peaks(peak) <= 1000
                        detector_name = 'VNIR'
                    elseif lamps(lamp_no).peaks(peak) > 1000 & lamps(lamp_no).peaks(peak) <= 1800
                        detector_name = 'SWIR1'
                    elseif lamps(lamp_no).peaks(peak) > 1800 & lamps(lamp_no).peaks(peak) <= 2500
                        detector_name = 'SWIR2'
                    else
                        disp('Peak is outside detector range!');
                    end
                    
                    initial_peak_wvl =  lamps(lamp_no).peaks(peak);
                    initial_peak_fwhm = lamps(lamp_no).FWHM(peak);
                    u_cw = lamps(lamp_no).u_cw(peak);
                                       
                    % do the retrieval for current peak (just add as many calls of function below as required)
                    cal_output = analyse_peak(peak_type, initial_peak_wvl, initial_peak_fwhm, u_cw, mean_vector, std_spectra_vectors, user_data, detector_name, instrument_id, instrument_serial, lamps(lamp_no).name);
                    cal_output.lamp_info = lamps(lamp_no);
                    cal_output.peak_type = peak_type;
                    
                    % saves final spectral cal output
                    %spectralcal_output(x) = cal_output;
                    %save('spectralcal_output_16006_normalised.mat', 'spectralcal_output');
                    
                    x = x+1;

                    
                end
                
                %{
                % Running through cal output for multipeaks
                for multipeak_set = 1:length(lamps(lamp_no).multipeaks)
                   
                    peak_type = 'multipeak'
                    
                    disp(['Doing multi peak set ', num2str(lamps(lamp_no).multipeaks{multipeak_set})])
                    
                    % calculating the average wvl of the multipeaks
                    
                    % resetting total each time we have a new set of
                    % multipeaks
                    
                    running_total = 0
                
                    for m = 1:length(lamps(lamp_no).multipeaks{multipeak_set})
                        sum_m = lamps(lamp_no).multipeaks{multipeak_set}(m)*lamps(lamp_no).multipeaks_I{multipeak_set}(m)
                        running_total = running_total + sum_m
                    
                    end
                    
                    av_multipeak_wvl = running_total/sum(lamps(lamp_no).multipeaks_I{multipeak_set}, 'all')

                    % using this to determine the detector
                    
                    if av_multipeak_wvl <= 1000
                        detector_name = 'VNIR'
                    elseif av_multipeak_wvl > 1000 & av_multipeak_wvl <= 1800
                        detector_name = 'SWIR1'
                    elseif av_multipeak_wvl > 1800 & av_multipeak_wvl <= 2500
                        detector_name = 'SWIR2'
                    else
                        disp('Peak is outside detector range!');
                    end
                    
                    initial_peak_wvl = av_multipeak_wvl;
                    initial_peak_fwhm = 0.02;
                    
                    
                    cal_output = analyse_peak(peak_type, initial_peak_wvl, initial_peak_fwhm, mean_vector, std_spectra_vectors, user_data, detector_name, instrument_id, instrument_serial, lamps(lamp_no).name, lamps(lamp_no).multipeaks{multipeak_set}, lamps(lamp_no).multipeaks_I{multipeak_set});
 
                    cal_output.lamp_info = lamps(lamp_no);
                    cal_output.peak_type = peak_type
                    
                    % saves final spectral cal output
                    spectralcal_output(x) = cal_output;
                    save('spectralcal_output.mat', 'spectralcal_output');
                    
                    x = x+1;
                    
                end    
    
                %}
             end
            
        end 
        
        else
            
            msgbox('Data not loaded as more than 1000 spectra are selected'); 
        
    end
       
end



function cal_output = analyse_peak(peak_type, initial_peak_wvl, initial_peak_fwhm, u_cw, spectrum, std_spectra_vectors, user_data, detector_name, instrument_id, instrument_serial, lamp_name, multipeaks, multipeaks_I)
    
    %% User inputs %%

    % Setting input file name and folder name
    input_file_name_suffix = '';
    input_file_folder_name = 'monte_carlo';

    % Setting output file name and folder name
    output_file_name_suffix = "";
    output_file_folder_name = 'monte_carlo';
    
    % Modes to be run
    modes_to_be_run = {'gaussian', 'symmetric super gaussian', 'asymmetric super gaussian', 'lognormal normal', 'lognormal reverse'};
    
    % Run monte carlo?
    run_monte_carlo = 1;
    
    % Number of monte carlo realisations
    monte_carlo_N = 5;
    
    % Input file loaded? 1 = yes, 0 = no
    load_file = 1;
    
    % Skip initial fitting - skips initial mode fitting, reads in input
    % file and runs monte carlo
    skip_initial_fitting = 0;
    
    %% End of user inputs %%
    
    % Configuring input file info
    input_file_name_stem = strcat('spectralcal_output_', num2str(instrument_serial));

    if strcmp(input_file_name_suffix, "")
        input_file_name = input_file_name_stem;
    else
        input_file_name = strcat(input_file_name_stem, '_', input_file_name_suffix);
    end   
    
    input_file_dir_stem = '/Volumes/Areion/SpectralCal/';
    input_file_dir_string = strcat(input_file_dir_stem, '/', input_file_folder_name)
    
    
    % Configuring output file info
    output_file_name_stem = strcat('spectralcal_output_', num2str(instrument_serial));

    if strcmp(output_file_name_suffix, "")
        output_file_name = output_file_name_stem;
    else
        output_file_name = strcat(output_file_name_stem, '_', output_file_name_suffix);
    end   
    
    output_file_dir_stem = '/Volumes/Areion/SpectralCal/';
    output_file_dir_string = strcat(output_file_dir_stem, '/', output_file_folder_name)
 
    % Creating output file directory if not exists
    
    if ~exist(output_file_dir_string, 'dir')
       mkdir(output_file_dir_string)
    end
      
    % If load_file is 1 then code will load spectralcal_output file below 
               
    if load_file == 1
        disp('Loading input file')
        load(strcat(input_file_dir_string, '/', input_file_name));
        spectralcal_loaded = spectralcal_output
        clearvars spectralcal_output
        
    end
        
    if exist('spectralcal_loaded', 'var')
            file_loaded = 1;
    else
            file_loaded = 0;
    end
    
    % Setting initial peak FWHM
    initial_peak_fwhm = 0.01;
               
    % Calculating the centre wavelength shift from NIST expected centre wavelength to measured
    % spectrum centre wavelength
    wvl_minus_5nm = initial_peak_wvl - 5; 
    wvl_plus_5nm = initial_peak_wvl + 5;
     
    [m, i_min] = get_closest_wvl_index(user_data.current_spectra.wvl, wvl_minus_5nm);
    [m, i_max] = get_closest_wvl_index(user_data.current_spectra.wvl, wvl_plus_5nm);
   
    max_spectrum = max(spectrum(i_min:i_max));
        
    actual_max_wvl = user_data.current_spectra.wvl(spectrum == max_spectrum);
 
    % represents the shift in centre wavelength which will be applied
    % to the input top hat signals
    max_wvl_difference = initial_peak_wvl - actual_max_wvl

    % Calculating new (reduced) wvl ranges for the input vector - this enables convolution to run more efficiently
      
    sensor_range = 50;
    input_range = sensor_range + 60; % has to be slightly wider than sensor to encompass bigger range output by prepare_srf
              
    input_wvl_lower = round(initial_peak_wvl) - input_range;
    input_wvl_upper = round(initial_peak_wvl) + input_range; 
                
    % splitting what happens in the code between single peak and multi
    % peak scenarios
    if strcmp(peak_type, 'singlepeak')
        disp('single peak scenario')
        
        % Creating top hat range which now includes applying centre wavelength shift
        single_peak_wvl_minus_FWHM = initial_peak_wvl - initial_peak_fwhm - max_wvl_difference; 
        single_peak_wvl_plus_FWHM = initial_peak_wvl + initial_peak_fwhm - max_wvl_difference;
        
        n = ((input_wvl_upper - input_wvl_lower) / initial_peak_fwhm) + 1; 
   
        input.wvl = linspace(input_wvl_lower,input_wvl_upper,n); % Now at reduced range
        input.spectrum = zeros(size(input.wvl));
        
        [m, i_min] = get_closest_wvl_index(input.wvl, single_peak_wvl_minus_FWHM) 
        [m, i_max] = get_closest_wvl_index(input.wvl, single_peak_wvl_plus_FWHM) 
        
        input.spectrum(i_min:i_max) = 1;  %light injection :) very narrow top-hat signal ("Dirac" style)
        
    end    

    % Difference is that multi peak scenario has multiple 'let there be
    % light's during input creation
    %{
    if strcmp(peak_type, 'multipeak')
        disp('multi peak scenario')
        
        length(multipeaks);
        
        n = ((input_wvl_upper - input_wvl_lower) / initial_peak_fwhm) + 1;
        
        input.wvl = linspace(input_wvl_lower,input_wvl_upper,n); % Now at reduced range
        input.spectrum = zeros(size(input.wvl));
        
        for multipeak = 1:length(multipeaks) 
            
            % In a multipeak scenario, the centre wavelength shift is
            % applied to each of the contributing peaks
            multipeak_wvl_minus_FWHM = multipeaks(multipeak) - initial_peak_fwhm - max_wvl_difference 
            multipeak_wvl_plus_FWHM = multipeaks(multipeak) + initial_peak_fwhm - max_wvl_difference
       
            [m, i_min] = get_closest_wvl_index(input.wvl, multipeak_wvl_minus_FWHM) 
            [m, i_max] = get_closest_wvl_index(input.wvl, multipeak_wvl_plus_FWHM) 
   
            input.spectrum(i_min:i_max) = 1*multipeaks_I(multipeak)/1000
        end
        
    end    
    %}

   % Aim: Simulating instrument response to incoming light in cal lamp peak region
   % we need to define a high res spectrum around the peak
   
   % Simulation: create high res vector at 546.07500 nm, with a resolution (FWHM) of 0.015 nm
   
   % need to generate linearly spaced vector (linspace - see MathWorks),
   % which gives following equation:
   
   % Res = (2500 - 350) / (n - 1)
   % hence n = ((2500 - 350) / Res) - 1 
   % we have: Res = 0.015 nm
   
   % n = ((2500 - 350) / 0.015) - 1 = 1.4333e+05 number of points (equally spaced indices)
   
   % [m, i] = get_closest_wvl_index(wvl_vector, wvl) use this where m is
   % the distance to considered point and i is the index (for which we're establishing the relationship to wavelength)
   
   % use twice for plus and minus FWHM
   
   % Now we know where to inject a simulated light that will eventually
   % lead to a simulated peak, which we will fit to the measured peak
   
   % Confining limits of sensor to small range around input peak
   sensor_lower = round(initial_peak_wvl) - sensor_range;
   sensor_upper = round(initial_peak_wvl) + sensor_range;
   sensor_range_diff = sensor_upper - sensor_lower +1;
   
   sim_sensor = create_sensor('ASD_Sim', sensor_lower, sensor_upper, sensor_range_diff, 5); 
   
   % output is where sim sensor function is applied to top hat
   output = convolve(sim_sensor,input);
   
   % the output from sim sensor is the convolution of the input (top-hat signal) 
   % with the sensor response (assumed to be Gaussian though that is only approximately true)
   
   % got the instrument response function! see create_sensor (then prepare_srf) for the def of srf
   % all simulation until now, no measured data used yet

   % as a reminder, "spectrum" here contains the DNs
   % current refers to what is selected inside the GUI
   
   % now we want to scale our output spectrum (simulated instrument response) to the actual measured spectrum
   % need to define region where we will look for the max of functions
   % scaling here is more for plot comparison than anything else
   
   
   % Scaling spectrum so spectrum is normalised to 1
   spectrum = spectrum/max_spectrum;
   
   % And scaling the standard deviations by the same amount
   std_spectra_vectors = std_spectra_vectors/max_spectrum
   
   
    if isequal(detector_name,'VNIR')
        wvl_minus = initial_peak_wvl - 10; 
        wvl_plus = initial_peak_wvl + 10;
    else
        wvl_minus = initial_peak_wvl - 15; 
        wvl_plus = initial_peak_wvl + 15;
    end
    
    % This is the range we are using for max finding
    [m, i_min2] = get_closest_wvl_index(output.wvl, wvl_minus_5nm); 
    [m, i_max2] = get_closest_wvl_index(output.wvl, wvl_plus_5nm);
    
    % Testing here a different range based on detector
    [m, i_min3] = get_closest_wvl_index(output.wvl, wvl_minus);
    [m, i_max3] = get_closest_wvl_index(output.wvl, wvl_plus);
   
    % narrowing to spectral feature of measurement (you need a gaussian fit of it too)
    To_be_fitted_spectrum = zeros(size(output.wvl));
   
    spectrum_lower = sensor_lower - 350 + 1;
    spectrum_upper = sensor_upper - 350 + 1;
    
    spectrum_peak = spectrum(spectrum_lower:spectrum_upper);
        
    To_be_fitted_spectrum(i_min2:i_max2) = spectrum_peak(i_min2:i_max2); % 'spectrum' is selected spectrum and 'to be fitted' is about the region of interest
    % you tell your artificial spectrum to take on the shape of the
    % measured spectrum in the (i_min2;i_max2) region 
   
    % Taking broad range and looking to find where is >10% max
    min10_fitted_spectrum = zeros(size(output.wvl));
    
    min10_fitted_spectrum(i_min3:i_max3) = spectrum_peak(i_min3:i_max3);
    
    I_min10 = min10_fitted_spectrum > max(min10_fitted_spectrum)*0.1;
    
    min10_list = min10_fitted_spectrum(I_min10);
    
    min10_first = min10_list(1);
    min10_last = min10_list(end);
    
    min10_wvl_min = output.wvl(min10_fitted_spectrum == min10_first);
    min10_wvl_max = output.wvl(min10_fitted_spectrum == min10_last);
    
    I_min10_min = find(output.wvl == min10_wvl_min);
    I_min10_max = find(output.wvl == min10_wvl_max);
    
    % Check whether file is loaded and whether we are using these
    % parameters to constrain k and w - only for VNIR this time as we have changed the SWIR1 and SWIR2 ranges. 
   
    if file_loaded == 1
        
           initial_peak_i = find(extractfield(spectralcal_loaded, 'initial_peak_wvl') == initial_peak_wvl);
            
           rmse_summary = spectralcal_loaded(initial_peak_i).rmse_summary;
           rmse_loop_table = spectralcal_loaded(initial_peak_i).rmse_detail;
       
    elseif file_loaded == 0
       
        if isequal(detector_name, 'VNIR')
           
            w_min = 1;
            w_max = 16;
            
            k_min = 1.5
            k_max = 2.5
            

        elseif isequal(detector_name, 'SWIR1')
        
            w_min = 5;
            w_max = 8.5;
        
            k_min = 1.5
            k_max = 2.5
        
        elseif isequal(detector_name, 'SWIR2')
       
            w_min = 6;
            w_max = 10.5;
        
            k_min = 1.5
            k_max = 2.5
        
         end
        
        
        initial_peak_wvl_field = [];
        initial_peak_i = 0;
        
    end     
    
    
    % SECTION TO SKIP INITIAL FITTING IF CALOUTPUT IS LOADED
       
    if initial_peak_i > 0 & skip_initial_fitting == 1   
       
        disp('Skipping initial fitting for peak')   
        rmse_summary = spectralcal_loaded(initial_peak_i).rmse_summary;
        rmse_loop_table = spectralcal_loaded(initial_peak_i).rmse_detail;
       
    else
       
        disp('Running fitting for peak')
  
    end
    

   
   % First we will narrow down the best w for the gaussian (ie. k == 2) and then use
   % this range to look at super gauss
   
   % j is a counter used for populating rmse_detail, it indexes all mode
   % and parameter combinations run below
   j = 1
   
   %% GAUSSIAN FITTING %%
   
   % k is always 2 in gaussian case
    k = 2;
   
   % Interval now 0.01 
    
  	for w = w_min:0.01:w_max
      
      disp(['Running gaussian for w: ', num2str(w)]);
              
      sim_sensor = create_sensor_sg('ASD_Sim', sensor_lower, sensor_upper, sensor_range_diff, 5, w, k);
           
      output = convolve(sim_sensor, input);
           
      simulated_spectra(j,:) = output.spectrum; % .spectrum otherwise output is just a structure
       
      max_output = max(output.spectrum(i_min2:i_max2));
        
      max_spectrum = max(spectrum_peak(i_min2:i_max2));
   
      ratio_maxSpectrum_over_maxOutput = (max_spectrum / max_output);
        
      scaled_simulated_spectra(j,:) = simulated_spectra(j,:) * ratio_maxSpectrum_over_maxOutput;
           
      % finding indexes of scaled simulated spectra not equal to zero, to
      % use these for comparison with original spectra
        
      reshaped_scaled_simulated_spectra = reshape(scaled_simulated_spectra(j,:), [length(scaled_simulated_spectra(j,:)), 1]);
        
      rmse_tbl = table(output.wvl, reshape(spectrum_peak, [length(spectrum_peak),1]), reshaped_scaled_simulated_spectra);
        
      rmse_tbl = rmse_tbl(I_min10_min:I_min10_max, :);
      rmse_tbl.Properties.VariableNames = {'wvl', 'original_spectra', 'simulated_spectra'};
      rmse_tbl.diff_sqrd = (rmse_tbl{:,2} - rmse_tbl{:,3}).^2;
        
      rmse_calc = sqrt((sum(rmse_tbl.diff_sqrd))/length(rmse_tbl.diff_sqrd));
           
      rmse_all(j) = rmse_calc;
           
      w_vector(j) = w;
      k_vector(j) = k;
      aw_vector(j) = 0;
      ak_vector(j) = 0;
      ln_sigma(j) = NaN; % lognormal sigma and mu are null
      ln_mu(j) = NaN;
      ln_isnormal(j)= NaN;
            
      j = j+1; 
       
   end
   
   % plotting RMSE vs w
      
   figure
   plot(w_vector, rmse_all)
   hold on
   xlabel('w')
   ylabel('RMSE')
   title('Gaussian fitting')
   hold off
  
   %% SYMMETRIC SUPER GAUSSIAN FITTING %%
   
   % now we use the above results to narrow down range for w and
   % start varying k for the symmetric super gaussian
   
   [w_rmse_best, w_index] = min(rmse_all);
   w_best = w_vector(w_index);
   
   w_min_refined = w_best - 0.5;
   w_max_refined = w_best + 0.5;
   
   % Running symmetrical gaussian
   
   j_start_sym = j;
     
   for k = k_min:0.01:k_max
       
       % We don't need to run k = 2 again - already done in previous loop
       if k == 2
          continue 
       end
       
       for w = w_min_refined:0.01:w_max_refined
            disp(['Symmetric super gaussian for w: ', num2str(w)]);
            disp(['and k: ', num2str(k)]);
        
            sim_sensor = create_sensor_sg('ASD_Sim', sensor_lower, sensor_upper, sensor_range_diff, 5, w, k);
           
            output = convolve(sim_sensor, input);
           
            simulated_spectra(j,:) = output.spectrum; % .spectrum otherwise output is just a structure
       
            max_output = max(output.spectrum(i_min2:i_max2));
        
            max_spectrum = max(spectrum_peak(i_min2:i_max2));
   
           ratio_maxSpectrum_over_maxOutput = (max_spectrum / max_output);
        
           scaled_simulated_spectra(j,:) = simulated_spectra(j,:) * ratio_maxSpectrum_over_maxOutput;
           
           % finding indexes of scaled simulated spectra not equal to zero, to
           % use these for comparison with original spectra
        
           reshaped_scaled_simulated_spectra = reshape(scaled_simulated_spectra(j,:), [length(scaled_simulated_spectra(j,:)), 1]);
        
           rmse_tbl = table(output.wvl, reshape(spectrum_peak, [length(spectrum_peak),1]), reshaped_scaled_simulated_spectra);
        
           rmse_tbl = rmse_tbl(I_min10_min:I_min10_max, :);
           rmse_tbl.Properties.VariableNames = {'wvl', 'original_spectra', 'simulated_spectra'};
           rmse_tbl.diff_sqrd = (rmse_tbl{:,2} - rmse_tbl{:,3}).^2;
        
           rmse_calc = sqrt((sum(rmse_tbl.diff_sqrd))/length(rmse_tbl.diff_sqrd));
           
           rmse_all(j) = rmse_calc;
           
           w_vector(j) = w;
           k_vector(j) = k;
           aw_vector(j) = 0;
           ak_vector(j) = 0;
           ln_sigma(j) = NaN; % lognormal sigma and mu are null
           ln_mu(j) = NaN;
           ln_isnormal(j)= NaN;
           
           j = j+1;

       end
   end  
   
   % Looking at how RMSE varies with k and w
   %{
   figure
   hold on
   h = gscatter(w_vector(j_start_sym:end), rmse_all(j_start_sym:end), k_vector(j_start_sym:end));
   xlabel('w');
   ylabel('RMSE');
   title('Symmetric super gaussian fitting');
   set(h,'LineStyle','-');
   hold off
   %}
   
   %% ASYMMETRIC SUPER GAUSSIAN FITTING %%
   
   % Refining the range of k
   
   [k_rmse_best, k_index] = min(rmse_all);
   k_best = k_vector(k_index);
  
   k_min_refined = k_best - 0.1;
   k_max_refined = k_best + 0.1;
   
   % Using refined w and k running asymmetric super gaussian - and we don't
   % need to run ak = 0  & aw = 0 case because this has already been run
   % in loop above

   % Setting ranges for asymmetric parameters aw and ak which will have steps of 0.1

   aw_min = -1; 
   aw_max = 1;   
   
   ak_min = -0.7;
   ak_max = 0.7;

   j_start_asym = j;
   
   for k = k_min_refined:0.1:k_max_refined
        
       for w = w_min_refined:0.1:w_max_refined
            
           disp(['Asymmetric super gaussian for w: ', num2str(w)]);
           disp(['k: ', num2str(k)]);
           
           for ak = ak_min:0.1:ak_max
           
              for aw = aw_min:0.1:aw_max
                    
                  % We don't need to run this case again
                  if ak == 0 && aw == 0
                      continue
                  end
                  
                  sim_sensor = create_sensor_sg('ASD_Sim', sensor_lower, sensor_upper, sensor_range_diff, 5, w, k, aw, ak);   
                   
                  output = convolve(sim_sensor, input);
           
                  simulated_spectra(j,:) = output.spectrum; % .spectrum otherwise output is just a structure
       
                  max_output = max(output.spectrum(i_min2:i_max2));
        
                  max_spectrum = max(spectrum_peak(i_min2:i_max2));
   
                  ratio_maxSpectrum_over_maxOutput = (max_spectrum / max_output);
        
                  scaled_simulated_spectra(j,:) = simulated_spectra(j,:) * ratio_maxSpectrum_over_maxOutput;
           
                  % finding indexes of scaled simulated spectra not equal to zero, to
                  % use these for comparison with original spectra
        
                  reshaped_scaled_simulated_spectra = reshape(scaled_simulated_spectra(j,:), [length(scaled_simulated_spectra(j,:)), 1]);
        
                  rmse_tbl = table(output.wvl, reshape(spectrum_peak, [length(spectrum_peak),1]), reshaped_scaled_simulated_spectra);
        
                  rmse_tbl = rmse_tbl(I_min10_min:I_min10_max, :);
                  rmse_tbl.Properties.VariableNames = {'wvl', 'original_spectra', 'simulated_spectra'};
                  rmse_tbl.diff_sqrd = (rmse_tbl{:,2} - rmse_tbl{:,3}).^2;
        
                  rmse_calc = sqrt((sum(rmse_tbl.diff_sqrd))/length(rmse_tbl.diff_sqrd));
                  rmse_all(j) = rmse_calc;
           
                  w_vector(j) = w;
                  k_vector(j) = k;
                  aw_vector(j) = aw;
                  ak_vector(j) = ak;
                  ln_sigma(j) = NaN; % lognormal sigma and mu are null
                  ln_mu(j) = NaN;
                  ln_isnormal(j) = NaN;
               
                  j = j+1;
                  
                  
              end
               
           end
            
        end
        
   end
   
  % Narrowing down range and running asymmetric again
  
  % RMSE indexing
    
  [rmse_best, rmse_index] = min(rmse_all);
  k_asym_best = k_vector(rmse_index);
  w_asym_best = w_vector(rmse_index);
  ak_asym_best = ak_vector(rmse_index);
  aw_asym_best = aw_vector(rmse_index);
  
  % New mins and max
  
  k_asym_refined_min = k_asym_best - 0.05;
  k_asym_refined_max = k_asym_best + 0.05;
  
  w_asym_refined_min = w_asym_best - 0.05;
  w_asym_refined_max = w_asym_best + 0.05;
   
  ak_asym_refined_min = ak_asym_best - 0.2;
  ak_asym_refined_max = ak_asym_best + 0.2;
   
  aw_asym_refined_min = aw_asym_best - 0.2;
  aw_asym_refined_max = aw_asym_best + 0.2;
  
  for k = k_asym_refined_min:0.01:k_asym_refined_max
        
       for w = w_asym_refined_min:0.01:w_asym_refined_max
            
           disp(['Refined asymmetric super gaussian for w: ', num2str(w)]);
           disp(['k: ', num2str(k)]);
           
           for ak = ak_asym_refined_min:0.1:ak_asym_refined_max
           
              for aw = aw_asym_refined_min:0.1:aw_asym_refined_max
                    
                  % We don't need to run this case again
                  if ak == 0 && aw == 0
                      continue
                  end
                  
                  sim_sensor = create_sensor_sg('ASD_Sim', sensor_lower, sensor_upper, sensor_range_diff, 5, w, k, aw, ak);   
                   
                  output = convolve(sim_sensor, input);
           
                  simulated_spectra(j,:) = output.spectrum; % .spectrum otherwise output is just a structure
       
                  max_output = max(output.spectrum(i_min2:i_max2));
        
                  max_spectrum = max(spectrum_peak(i_min2:i_max2));
   
                  ratio_maxSpectrum_over_maxOutput = (max_spectrum / max_output);
        
                  scaled_simulated_spectra(j,:) = simulated_spectra(j,:) * ratio_maxSpectrum_over_maxOutput;
           
                  % finding indexes of scaled simulated spectra not equal to zero, to
                  % use these for comparison with original spectra
        
                  reshaped_scaled_simulated_spectra = reshape(scaled_simulated_spectra(j,:), [length(scaled_simulated_spectra(j,:)), 1]);
        
                  rmse_tbl = table(output.wvl, reshape(spectrum_peak, [length(spectrum_peak),1]), reshaped_scaled_simulated_spectra);
        
                  rmse_tbl = rmse_tbl(I_min10_min:I_min10_max, :);
                  rmse_tbl.Properties.VariableNames = {'wvl', 'original_spectra', 'simulated_spectra'};
                  rmse_tbl.diff_sqrd = (rmse_tbl{:,2} - rmse_tbl{:,3}).^2;
        
                  rmse_calc = sqrt((sum(rmse_tbl.diff_sqrd))/length(rmse_tbl.diff_sqrd));
                  rmse_all(j) = rmse_calc;
           
                  w_vector(j) = w;
                  k_vector(j) = k;
                  aw_vector(j) = aw;
                  ak_vector(j) = ak;
                  ln_sigma(j) = NaN; % lognormal sigma and mu are null
                  ln_mu(j) = NaN;
                  ln_isnormal(j) = NaN;
               
                  j = j+1;
                  
                  
              end
               
           end
            
        end
        
  end
  
   %% LOGNORMAL FITTING %% 
  
   % Lognormal-normal and lognormal-reverse takes two parameters: mu and
   % sigma
      
   ln_mu_min = 1;
   ln_mu_max = 3.5;
   ln_mu_step = 0.1;
   
   ln_sigma_min = 0.01;
   ln_sigma_max = 0.35;
   ln_sigma_step = 0.01;
   
   % Setup for parfor - step must be an integer
   
   mu_n = (ln_mu_max - ln_mu_min)/ln_mu_step
   mu_trials = linspace(ln_mu_min, ln_mu_max, (mu_n + 1))
   
   
   for mu = ln_mu_min:ln_mu_step:ln_mu_max
   
       for sigma = ln_sigma_min:ln_sigma_step:ln_sigma_max

            disp(['Lognormal cases for sigma: ', num2str(sigma), ' and mu: ', num2str(mu)]);
           % create_sensor_lognormal takes a 'type' argument which is either
           % 'normal' or 'reversed'. We will run through both types for each 
           % value of sigma

           sim_sensor = create_sensor_lognormal('ASD_Sim', sensor_lower, sensor_upper, sensor_range_diff, mu, sigma, 'normal');   

           output = convolve(sim_sensor, input);

           simulated_spectra(j,:) = output.spectrum; % .spectrum otherwise output is just a structure

           max_output = max(output.spectrum(i_min2:i_max2));

           max_spectrum = max(spectrum_peak(i_min2:i_max2));

           ratio_maxSpectrum_over_maxOutput = (max_spectrum / max_output);

           scaled_simulated_spectra(j,:) = simulated_spectra(j,:) * ratio_maxSpectrum_over_maxOutput;

           % finding indexes of scaled simulated spectra not equal to zero, to
           % use these for comparison with original spectra

           reshaped_scaled_simulated_spectra = reshape(scaled_simulated_spectra(j,:), [length(scaled_simulated_spectra(j,:)), 1]);

           rmse_tbl = table(output.wvl, reshape(spectrum_peak, [length(spectrum_peak),1]), reshaped_scaled_simulated_spectra);

           rmse_tbl = rmse_tbl(I_min10_min:I_min10_max, :);
           rmse_tbl.Properties.VariableNames = {'wvl', 'original_spectra', 'simulated_spectra'};
           rmse_tbl.diff_sqrd = (rmse_tbl{:,2} - rmse_tbl{:,3}).^2;

           rmse_calc = sqrt((sum(rmse_tbl.diff_sqrd))/length(rmse_tbl.diff_sqrd));
           rmse_all(j) = rmse_calc;

           w_vector(j) = NaN;
           k_vector(j) = NaN;
           aw_vector(j) = NaN;
           ak_vector(j) = NaN;
           ln_sigma(j) = sigma; 
           ln_mu(j) = mu;
           ln_isnormal(j) = true;

           j = j+1;

           % Now running the reverse case

           sim_sensor = create_sensor_lognormal('ASD_Sim', sensor_lower, sensor_upper, sensor_range_diff, mu, sigma, 'reverse');   

           output = convolve(sim_sensor, input);

           simulated_spectra(j,:) = output.spectrum; % .spectrum otherwise output is just a structure

           max_output = max(output.spectrum(i_min2:i_max2));

           max_spectrum = max(spectrum_peak(i_min2:i_max2));

           ratio_maxSpectrum_over_maxOutput = (max_spectrum / max_output);

           scaled_simulated_spectra(j,:) = simulated_spectra(j,:) * ratio_maxSpectrum_over_maxOutput;

           % finding indexes of scaled simulated spectra not equal to zero, to
           % use these for comparison with original spectra

           reshaped_scaled_simulated_spectra = reshape(scaled_simulated_spectra(j,:), [length(scaled_simulated_spectra(j,:)), 1]);

           rmse_tbl = table(output.wvl, reshape(spectrum_peak, [length(spectrum_peak),1]), reshaped_scaled_simulated_spectra);

           rmse_tbl = rmse_tbl(I_min10_min:I_min10_max, :);
           rmse_tbl.Properties.VariableNames = {'wvl', 'original_spectra', 'simulated_spectra'};
           rmse_tbl.diff_sqrd = (rmse_tbl{:,2} - rmse_tbl{:,3}).^2;

           rmse_calc = sqrt((sum(rmse_tbl.diff_sqrd))/length(rmse_tbl.diff_sqrd));
           rmse_all(j) = rmse_calc;

           w_vector(j) = NaN;
           k_vector(j) = NaN;
           aw_vector(j) = NaN;
           ak_vector(j) = NaN;
           ln_sigma(j) = sigma; 
           ln_mu(j) = mu;
           ln_isnormal(j) = false;  % isnormal = false means that we're running the reverse case here

           j = j+1;

       end    

   end
   %}
   
   
   % NB: here ln_sigma, ln_mu and ln_isnormal are only relevant to the lognormal cases
   rmse_loop_table_asg = table(rmse_all', k_vector', w_vector', ak_vector', aw_vector', ln_sigma', ln_mu', ln_isnormal');
   rmse_loop_table_asg.Properties.VariableNames = {'RMSE' 'k' 'w' 'ak' 'aw' 'ln_sigma' 'ln_mu' 'ln_isnormal'};

   rmse_loop_table = [rmse_loop_table; rmse_loop_table_asg];
   
   % Creating rmse summary table:
   mode_list = {'gaussian', 'symmetric super gaussian', 'asymmetric super gaussian', 'lognormal normal', 'lognormal reverse'};
   mode_i = 1;
     
   for mode_i =1:length(mode_list)
       
       mode = char(mode_list(mode_i))
       
       % insert conditions here
            if isequal(mode,'gaussian')
                indexes = find(rmse_loop_table.k==2 & rmse_loop_table.ak==0 & rmse_loop_table.aw==0);    
                
            elseif isequal(mode,'symmetric super gaussian')
                indexes = find(rmse_loop_table.aw==0 & rmse_loop_table.ak ==0 & rmse_loop_table.k ~=2);
                
            elseif isequal(mode,'asymmetric super gaussian')
                indexes = find(rmse_loop_table.aw ~= 0 & rmse_loop_table.ak ~= 0 & ~isnan(rmse_loop_table.aw) & ~isnan(rmse_loop_table.ak));
                
            elseif isequal(mode,'lognormal normal')
                indexes = find(isnan(rmse_loop_table.k) & rmse_loop_table.ln_isnormal ==1)
                
            elseif isequal(mode,'lognormal reverse')
                indexes = find(isnan(rmse_loop_table.k) & rmse_loop_table.ln_isnormal ==0)
                
            end
            
       [rmse_best, sub_index] = min(rmse_loop_table.RMSE(indexes));
       best_index = indexes(sub_index);
       
       rmse_summary(mode_i).rmse = rmse_best;
       rmse_summary(mode_i).mode = mode;
       rmse_summary(mode_i).parameters = rmse_loop_table(best_index, 2:8);
   
       mode_i = mode_i+1;
       
   end    
 
   % Plotting 
   
   figure
   hold on
   
   xlabel('Wavelength')
   ylabel('Spectrum')
   title(['Peak ',num2str(initial_peak_wvl)])
   
   plot(output.wvl, spectrum_peak, 'b',  'DisplayName', 'measured')
   
   
   for r = 1:length(rmse_summary)
   
       mode = rmse_summary(r).mode;
       parameters = rmse_summary(r).parameters;
       max_spectrum = max(spectrum_peak(i_min2:i_max2));
       
       if isequal(mode,'gaussian')
            
           sim_sensor_for_plot = create_sensor_sg('ASD_Sim', sensor_lower, sensor_upper, sensor_range_diff, 5, parameters.w, parameters.k);
           output_for_plot = convolve(sim_sensor_for_plot, input);
           
           max_output = max(output_for_plot.spectrum(i_min2:i_max2));

           ratio_maxSpectrum_over_maxOutput = (max_spectrum / max_output);
           scaled_simulated_spectra = output_for_plot.spectrum * ratio_maxSpectrum_over_maxOutput;
           
           plot(output.wvl, scaled_simulated_spectra, 'm', 'DisplayName', mode)
       
       elseif isequal(mode, 'symmetric super gaussian')
       
           sim_sensor_for_plot = create_sensor_sg('ASD_Sim', sensor_lower, sensor_upper, sensor_range_diff, 5, parameters.w, parameters.k);
           output_for_plot = convolve(sim_sensor_for_plot, input);
           
           max_output = max(output_for_plot.spectrum(i_min2:i_max2));

           ratio_maxSpectrum_over_maxOutput = (max_spectrum / max_output);
           scaled_simulated_spectra = output_for_plot.spectrum * ratio_maxSpectrum_over_maxOutput;
           
           plot(output.wvl, scaled_simulated_spectra, 'g', 'DisplayName', mode)
           
        elseif isequal(mode, 'asymmetric super gaussian')
       
           sim_sensor_for_plot = create_sensor_sg('ASD_Sim', sensor_lower, sensor_upper, sensor_range_diff, 5, parameters.w, parameters.k, parameters.aw, parameters.ak);
           output_for_plot = convolve(sim_sensor_for_plot, input);
           
           max_output = max(output_for_plot.spectrum(i_min2:i_max2));

           ratio_maxSpectrum_over_maxOutput = (max_spectrum / max_output);
           scaled_simulated_spectra = output_for_plot.spectrum * ratio_maxSpectrum_over_maxOutput;
           
           plot(output.wvl, scaled_simulated_spectra, 'k', 'DisplayName', mode)
       
       elseif isequal(mode, 'lognormal normal')
           
           sim_sensor_for_plot = create_sensor_lognormal('ASD_Sim', sensor_lower, sensor_upper, sensor_range_diff, parameters.ln_mu, parameters.ln_sigma, 'normal');
           output_for_plot = convolve(sim_sensor_for_plot, input);
           
           max_output = max(output_for_plot.spectrum(i_min2:i_max2));

           ratio_maxSpectrum_over_maxOutput = (max_spectrum / max_output);
           scaled_simulated_spectra = output_for_plot.spectrum * ratio_maxSpectrum_over_maxOutput;
           
           plot(output.wvl, scaled_simulated_spectra, 'r', 'DisplayName', mode)      
                  
        elseif isequal(mode, 'lognormal reverse')
           
           sim_sensor_for_plot = create_sensor_lognormal('ASD_Sim', sensor_lower, sensor_upper, sensor_range_diff, parameters.ln_mu, parameters.ln_sigma, 'reverse');
           output_for_plot = convolve(sim_sensor_for_plot, input);
           
           max_output = max(output_for_plot.spectrum(i_min2:i_max2));

           ratio_maxSpectrum_over_maxOutput = (max_spectrum / max_output);
           scaled_simulated_spectra = output_for_plot.spectrum * ratio_maxSpectrum_over_maxOutput;
           
           plot(output.wvl, scaled_simulated_spectra, 'c', 'DisplayName', mode)      
           
       end
   
       
   end

   legend
   hold off
    
   % Saving new lognormal data
   %{
   spectralcal_loaded(initial_peak_i).rmse_summary = rmse_summary;
   spectralcal_loaded(initial_peak_i).rmse_detail = rmse_loop_table;
   
   spectralcal_output = spectralcal_loaded;
   
   save('spectralcal_output_16006_normalised.mat', 'spectralcal_output');  
   %}
   
   %% MONTE CARLO %%
   
   % 1. Shifting input top hat by increment based on centre_wvl_delta
   % - gaussian distribution around centre wvl delta
   
   % 2. Shifting measured spectra by increment based on noise
   % - Noise is the std of mean vectors and == sigma
      
   % 3. Fitting using for loops around the best for each mode found
   % previously
   
   % Testing gaussian realisations for centre_wvl_delta
    
   if run_monte_carlo == 1
   
    mode_list = {'gaussian', 'symmetric super gaussian', 'asymmetric super gaussian', 'lognormal normal', 'lognormal reverse'};
    sigma_cw = u_cw;
    mu_cw = 0;
    N = monte_carlo_N;
   
   % Letting it automatically calculate random numbers
    
    [centre_wvl_realisations, ~] = get_realisations_gauss_dist(N, mu_cw, sigma_cw);
   
    figure
    hold on
   
    n = ((input_wvl_upper - input_wvl_lower) / initial_peak_fwhm) + 1; 
   
    % Plotting all input realisations
    for i = 1: size(centre_wvl_realisations, 2)
       % Creating input with jitter
        cw_jitter = centre_wvl_realisations(i);
        % Creating top hat range which now includes applying centre wavelength shift
        
        single_peak_wvl_minus_FWHM = initial_peak_wvl - initial_peak_fwhm - max_wvl_difference + cw_jitter; 
        single_peak_wvl_plus_FWHM = initial_peak_wvl + initial_peak_fwhm - max_wvl_difference + cw_jitter;
            
        input(i).wvl = linspace(input_wvl_lower,input_wvl_upper,n); % Now at reduced range
        input(i).spectrum = zeros(size(input(i).wvl));
        
        [m, i_min] = get_closest_wvl_index(input(i).wvl, single_peak_wvl_minus_FWHM); 
        [m, i_max] = get_closest_wvl_index(input(i).wvl, single_peak_wvl_plus_FWHM) ;
        
        input(i).spectrum(i_min:i_max) = 1;  %light injection :) very narrow top-hat signal ("Dirac" style)
        
        plot(input(i).wvl, input(i).spectrum)
    end
   
    hold off
   
    % Gaussian realisations using std - need a noise value for each N
    std_matrix = [std_spectra_vectors(spectrum_lower:spectrum_upper)', output.wvl];
        
    %[DN_realisations, DN_rand] = get_realisations_gauss_dist(N, 0, std_matrix(:, 1));

    % Gaussian realisations using a different noise value for each
    % wavelength
    
    len_spectra_vectors = size(std_spectra_vectors(spectrum_lower:spectrum_upper)', 1);
    
    DN_realisations = zeros(len_spectra_vectors, N);
    
    DN_realisations = get_realisations_gauss_dist(N, spectrum_peak', std_matrix(:, 1))

    j = 1;
    
    for i = 1:N
        
        disp(['Realisation number: ', num2str(N)]);               
        
        % Creating input of light with jitter
     
        cw_jitter = centre_wvl_realisations(i);
        % Creating top hat range which now includes applying centre wavelength shift
        
        single_peak_wvl_minus_FWHM = initial_peak_wvl - initial_peak_fwhm - max_wvl_difference + cw_jitter; 
        single_peak_wvl_plus_FWHM = initial_peak_wvl + initial_peak_fwhm - max_wvl_difference + cw_jitter;
            
        new_input.wvl = linspace(input_wvl_lower,input_wvl_upper,n); % Now at reduced range
        new_input.spectrum = zeros(size(new_input.wvl));
        
        [m, i_min] = get_closest_wvl_index(new_input.wvl, single_peak_wvl_minus_FWHM); 
        [m, i_max] = get_closest_wvl_index(new_input.wvl, single_peak_wvl_plus_FWHM) ;
        
        new_input.spectrum(i_min:i_max) = 1;  %light injection :) very narrow top-hat signal ("Dirac" style)
                
        % Shifting spectrum
        new_spectrum_peak = DN_realisations(:, i);
        
        % Running through modes with smaller interval based on rmse_summary
        % best
       
         for mode_i = 1:length(mode_list)
            
             mode = char(mode_list(mode_i));
                         
             mode_parameters = rmse_summary(mode_i).parameters;
             
             if isequal(mode,'gaussian')
                
             k = 2;
             
             w_min = mode_parameters.w - 0.05;
             w_max = mode_parameters.w + 0.05;
             
             for w = w_min:0.01:w_max
      
                disp(['Running gaussian for w: ', num2str(w)]);
              
                sim_sensor = create_sensor_sg('ASD_Sim', sensor_lower, sensor_upper, sensor_range_diff, 5, w, k);
           
                output = convolve(sim_sensor, new_input);
           
                simulated_spectra(j,:) = output.spectrum; % .spectrum otherwise output is just a structure
                max_output = max(output.spectrum(i_min2:i_max2));
        
                max_spectrum = max(new_spectrum_peak(i_min2:i_max2));
   
                ratio_maxSpectrum_over_maxOutput = (max_spectrum / max_output);
        
                scaled_simulated_spectra(j,:) = simulated_spectra(j,:) * ratio_maxSpectrum_over_maxOutput;
           
                % finding indexes of scaled simulated spectra not equal to zero, to
                % use these for comparison with original spectra
        
                reshaped_scaled_simulated_spectra = reshape(scaled_simulated_spectra(j,:), [length(scaled_simulated_spectra(j,:)), 1]);
        
                rmse_tbl = table(output.wvl, reshape(new_spectrum_peak, [length(new_spectrum_peak),1]), reshaped_scaled_simulated_spectra);
        
                rmse_tbl = rmse_tbl(I_min10_min:I_min10_max, :);
                rmse_tbl.Properties.VariableNames = {'wvl', 'original_spectra', 'simulated_spectra'};
                rmse_tbl.diff_sqrd = (rmse_tbl{:,2} - rmse_tbl{:,3}).^2;
        
                rmse_calc = sqrt((sum(rmse_tbl.diff_sqrd))/length(rmse_tbl.diff_sqrd));
           
                rmse_all(j) = rmse_calc;
           
                w_vector(j) = w;
                k_vector(j) = k;
                aw_vector(j) = 0;
                ak_vector(j) = 0;
                ln_sigma(j) = NaN; % lognormal sigma and mu are null
                ln_mu(j) = NaN;
                ln_isnormal(j)= NaN;
                monte_carlo_idx(j) = i;
                SRF_mode{j} = mode;
                
                j = j+1; 
       
             end
             
             elseif isequal(mode,'symmetric super gaussian')
                 
             k_min = mode_parameters.k - 0.05;
             k_max = mode_parameters.k + 0.05;
             
             w_min = mode_parameters.w - 0.05;
             w_max = mode_parameters.w + 0.05; 
                 
             for k = k_min:0.01:k_max
       
               % In this case, keeping k = 2 still running

               for w = w_min:0.01:w_max
                   
                    disp(['Symmetric super gaussian for w: ', num2str(w)]);
                    disp(['and k: ', num2str(k)]);

                    sim_sensor = create_sensor_sg('ASD_Sim', sensor_lower, sensor_upper, sensor_range_diff, 5, w, k);

                    output = convolve(sim_sensor, new_input);

                    simulated_spectra(j,:) = output.spectrum; % .spectrum otherwise output is just a structure
                    max_output = max(output.spectrum(i_min2:i_max2));

                    max_spectrum = max(new_spectrum_peak(i_min2:i_max2));

                    ratio_maxSpectrum_over_maxOutput = (max_spectrum / max_output);

                    scaled_simulated_spectra(j,:) = simulated_spectra(j,:) * ratio_maxSpectrum_over_maxOutput;

                    % finding indexes of scaled simulated spectra not equal to zero, to
                    % use these for comparison with original spectra

                    reshaped_scaled_simulated_spectra = reshape(scaled_simulated_spectra(j,:), [length(scaled_simulated_spectra(j,:)), 1]);

                    rmse_tbl = table(output.wvl, reshape(new_spectrum_peak, [length(new_spectrum_peak),1]), reshaped_scaled_simulated_spectra);

                    rmse_tbl = rmse_tbl(I_min10_min:I_min10_max, :);
                    rmse_tbl.Properties.VariableNames = {'wvl', 'original_spectra', 'simulated_spectra'};
                    rmse_tbl.diff_sqrd = (rmse_tbl{:,2} - rmse_tbl{:,3}).^2;

                    rmse_calc = sqrt((sum(rmse_tbl.diff_sqrd))/length(rmse_tbl.diff_sqrd));

                    rmse_all(j) = rmse_calc;

                    w_vector(j) = w;
                    k_vector(j) = k;
                    aw_vector(j) = 0;
                    ak_vector(j) = 0;
                    ln_sigma(j) = NaN; % lognormal sigma and mu are null
                    ln_mu(j) = NaN;
                    ln_isnormal(j)= NaN;
                    monte_carlo_idx(j) = i;
                    SRF_mode{j} = mode;
                   
                    j = j+1;


               end
               
             end
                 
             elseif isequal(mode, 'asymmetric super gaussian')    
                 
             k_min = mode_parameters.k - 0.05;
             k_max = mode_parameters.k + 0.05;
             
             w_min = mode_parameters.w - 0.05;
             w_max = mode_parameters.w + 0.05;     
                 
             ak_min = mode_parameters.ak - 0.05;
             ak_max = mode_parameters.ak + 0.05;
             
             aw_min = mode_parameters.aw - 0.05;
             aw_max = mode_parameters.aw + 0.05;    
             
                for k = k_min:0.01:k_max

                   for w = w_min:0.01:w_max

                       disp(['Asymmetric super gaussian for w: ', num2str(w)]);
                       disp(['k: ', num2str(k)]);
                       
                       
                       for ak = ak_min:0.01:ak_max

                          for aw = aw_min:0.01:aw_max
                       
                              sim_sensor = create_sensor_sg('ASD_Sim', sensor_lower, sensor_upper, sensor_range_diff, 5, w, k, aw, ak);   

                              output = convolve(sim_sensor, new_input);

                              simulated_spectra(j,:) = output.spectrum; % .spectrum otherwise output is just a structure
                              max_output = max(output.spectrum(i_min2:i_max2));

                              max_spectrum = max(new_spectrum_peak(i_min2:i_max2));
  
                              ratio_maxSpectrum_over_maxOutput = (max_spectrum / max_output);

                              scaled_simulated_spectra(j,:) = simulated_spectra(j,:) * ratio_maxSpectrum_over_maxOutput;

                              % finding indexes of scaled simulated spectra not equal to zero, to
                              % use these for comparison with original spectra

                              reshaped_scaled_simulated_spectra = reshape(scaled_simulated_spectra(j,:), [length(scaled_simulated_spectra(j,:)), 1]);

                              rmse_tbl = table(output.wvl, reshape(new_spectrum_peak, [length(new_spectrum_peak),1]), reshaped_scaled_simulated_spectra);

                              rmse_tbl = rmse_tbl(I_min10_min:I_min10_max, :);
                              rmse_tbl.Properties.VariableNames = {'wvl', 'original_spectra', 'simulated_spectra'};
                              rmse_tbl.diff_sqrd = (rmse_tbl{:,2} - rmse_tbl{:,3}).^2;

                              rmse_calc = sqrt((sum(rmse_tbl.diff_sqrd))/length(rmse_tbl.diff_sqrd));

                              rmse_all(j) = rmse_calc;

                              w_vector(j) = w;
                              k_vector(j) = k;
                              aw_vector(j) = aw;
                              ak_vector(j) = ak;
                              ln_sigma(j) = NaN; % lognormal sigma and mu are null
                              ln_mu(j) = NaN;
                              ln_isnormal(j) = NaN;
                              monte_carlo_idx(j) = i;
                              SRF_mode{j} = mode;
                   
                              j = j+1;


                          end

                       end

                    end

                end
               
                elseif isequal(mode, 'lognormal normal')
                    
                    ln_sigma_min = mode_parameters.ln_sigma - 0.05;
                    ln_sigma_max = mode_parameters.ln_sigma + 0.05;
                    ln_sigma_step = 0.01;
                    
                    ln_mu_min = mode_parameters.ln_mu - 0.05;
                    ln_mu_max = mode_parameters.ln_mu + 0.05;
                    ln_mu_step = 0.01;
             
                    for mu = ln_mu_min:ln_mu_step:ln_mu_max
   
                        for sigma = ln_sigma_min:ln_sigma_step:ln_sigma_max

                                disp(['Lognormal cases for sigma: ', num2str(sigma), ' and mu: ', num2str(mu)]);
                               % create_sensor_lognormal takes a 'type' argument which is either
                               % 'normal' or 'reversed'. We will run through both types for each 
                               % value of sigma

                               sim_sensor = create_sensor_lognormal('ASD_Sim', sensor_lower, sensor_upper, sensor_range_diff, mu, sigma, 'normal');   

                               output = convolve(sim_sensor, new_input);

                               simulated_spectra(j,:) = output.spectrum; % .spectrum otherwise output is just a structure

                               max_output = max(output.spectrum(i_min2:i_max2));

                               max_spectrum = max(new_spectrum_peak(i_min2:i_max2));

                               ratio_maxSpectrum_over_maxOutput = (max_spectrum / max_output);

                               scaled_simulated_spectra(j,:) = simulated_spectra(j,:) * ratio_maxSpectrum_over_maxOutput;

                               reshaped_scaled_simulated_spectra = reshape(scaled_simulated_spectra(j,:), [length(scaled_simulated_spectra(j,:)), 1]);

                               rmse_tbl = table(output.wvl, reshape(new_spectrum_peak, [length(new_spectrum_peak),1]), reshaped_scaled_simulated_spectra);

                               rmse_tbl = rmse_tbl(I_min10_min:I_min10_max, :);
                               rmse_tbl.Properties.VariableNames = {'wvl', 'original_spectra', 'simulated_spectra'};
                               rmse_tbl.diff_sqrd = (rmse_tbl{:,2} - rmse_tbl{:,3}).^2;

                               rmse_calc = sqrt((sum(rmse_tbl.diff_sqrd))/length(rmse_tbl.diff_sqrd));
                               rmse_all(j) = rmse_calc;

                               w_vector(j) = NaN;
                               k_vector(j) = NaN;
                               aw_vector(j) = NaN;
                               ak_vector(j) = NaN;
                               ln_sigma(j) = sigma; 
                               ln_mu(j) = mu;
                               ln_isnormal(j) = true;
                               monte_carlo_idx(j) = i;
                               SRF_mode{j} = mode;

                               j = j+1;

                        end
                    end
                    
                    
                elseif isequal(mode, 'lognormal reverse')    
                    
                    ln_sigma_min = mode_parameters.ln_sigma - 0.05;
                    ln_sigma_max = mode_parameters.ln_sigma + 0.05;
                    ln_sigma_step = 0.01;
                    
                    ln_mu_min = mode_parameters.ln_mu - 0.05;
                    ln_mu_max = mode_parameters.ln_mu + 0.05;
                    ln_mu_step = 0.01;
                    
                    for mu = ln_mu_min:ln_mu_step:ln_mu_max
   
                        for sigma = ln_sigma_min:ln_sigma_step:ln_sigma_max
                    
                           sim_sensor = create_sensor_lognormal('ASD_Sim', sensor_lower, sensor_upper, sensor_range_diff, mu, sigma, 'reverse');   

                           output = convolve(sim_sensor, new_input);

                           simulated_spectra(j,:) = output.spectrum; % .spectrum otherwise output is just a structure

                           max_output = max(output.spectrum(i_min2:i_max2));

                           max_spectrum = max(new_spectrum_peak(i_min2:i_max2));

                           ratio_maxSpectrum_over_maxOutput = (max_spectrum / max_output);

                           scaled_simulated_spectra(j,:) = simulated_spectra(j,:) * ratio_maxSpectrum_over_maxOutput;

                           reshaped_scaled_simulated_spectra = reshape(scaled_simulated_spectra(j,:), [length(scaled_simulated_spectra(j,:)), 1]);

                           rmse_tbl = table(output.wvl, reshape(new_spectrum_peak, [length(new_spectrum_peak),1]), reshaped_scaled_simulated_spectra);

                           rmse_tbl = rmse_tbl(I_min10_min:I_min10_max, :);
                           rmse_tbl.Properties.VariableNames = {'wvl', 'original_spectra', 'simulated_spectra'};
                           rmse_tbl.diff_sqrd = (rmse_tbl{:,2} - rmse_tbl{:,3}).^2;

                           rmse_calc = sqrt((sum(rmse_tbl.diff_sqrd))/length(rmse_tbl.diff_sqrd));
                           rmse_all(j) = rmse_calc;

                           w_vector(j) = NaN;
                           k_vector(j) = NaN;
                           aw_vector(j) = NaN;
                           ak_vector(j) = NaN;
                           ln_sigma(j) = sigma; 
                           ln_mu(j) = mu;
                           ln_isnormal(j) = false;  % isnormal = false means that we're running the reverse case here
                           monte_carlo_idx(j) = i;
                           SRF_mode{j} = mode;

                           j = j+1;
                            

                        end
                    end
                    
                    
                 
             end
             
         
         end
         
        
        
    end
    
    % Saving all the monte carlo runs above to a monte_carlo_detail tables
    monte_carlo_detail = table(rmse_all', k_vector', w_vector', ak_vector', aw_vector', ln_sigma', ln_mu', ln_isnormal', monte_carlo_idx', SRF_mode');
    monte_carlo_detail.Properties.VariableNames = {'RMSE' 'k' 'w' 'ak' 'aw' 'ln_sigma' 'ln_mu' 'ln_isnormal', 'monte_carlo_idx', 'SRF_mode'};
 
    % Creating monte carlo summary table - looping through N
    
    for i = 1:N
        
        for mode_i = 1:5
        
            mode = char(mode_list(mode_i))
            
            indexes = find(monte_carlo_detail.monte_carlo_idx == i & strcmp(monte_carlo_detail.SRF_mode, mode)); 
            
            [rmse_min, rmse_min_idx_sub] = min(monte_carlo_detail.RMSE(indexes));
            
            % Enables us to index the full monte_carlo_detail table
            rmse_min_idx = rmse_min_idx_sub + min(indexes) - 1 
            
            if isequal(mode,'gaussian')
                
                mc_gauss_rmse(i) = rmse_min;
                mc_gauss_w(i) = monte_carlo_detail.w(rmse_min_idx);
                
            elseif isequal(mode,'symmetric super gaussian')
                
                mc_symm_gauss_rmse(i) = rmse_min;
                mc_symm_gauss_k(i) = monte_carlo_detail.k(rmse_min_idx);
                mc_symm_gauss_w(i) = monte_carlo_detail.w(rmse_min_idx);
                
            elseif isequal(mode,'asymmetric super gaussian')
                
                mc_asymm_gauss_rmse(i) = rmse_min;
                mc_asymm_gauss_k(i) = monte_carlo_detail.k(rmse_min_idx);
                mc_asymm_gauss_w(i) = monte_carlo_detail.w(rmse_min_idx);
                mc_asymm_gauss_ak(i) = monte_carlo_detail.ak(rmse_min_idx);
                mc_asymm_gauss_aw(i) = monte_carlo_detail.aw(rmse_min_idx);
                
            elseif isequal(mode, 'lognormal normal')
                
                mc_ln_normal_rmse(i) = rmse_min;
                mc_ln_normal_sigma(i) = monte_carlo_detail.ln_sigma(rmse_min_idx);
                mc_ln_normal_mu(i) = monte_carlo_detail.ln_mu(rmse_min_idx);
                
            elseif isequal(mode, 'lognormal reverse')
                
                mc_ln_reverse_rmse(i) = rmse_min;
                mc_ln_reverse_sigma(i) = monte_carlo_detail.ln_sigma(rmse_min_idx);
                mc_ln_reverse_mu(i) = monte_carlo_detail.ln_mu(rmse_min_idx);
                              
            end
            
        end
        
    end
     
    N_idx = linspace(1, N, N);    
    
    monte_carlo_summary = table(N_idx', mc_gauss_rmse', mc_gauss_w', mc_symm_gauss_rmse', mc_symm_gauss_k', mc_symm_gauss_w', mc_asymm_gauss_rmse', mc_asymm_gauss_k', mc_asymm_gauss_w', mc_asymm_gauss_ak', mc_asymm_gauss_aw', mc_ln_normal_rmse', mc_ln_normal_sigma', mc_ln_normal_mu', mc_ln_reverse_rmse', mc_ln_reverse_sigma', mc_ln_reverse_mu');
    monte_carlo_summary.Properties.VariableNames = {'N_idx' 'gauss_rmse' 'gauss_w' 'symm_super_gauss_rmse' 'symm_super_gauss_k' 'symm_super_gauss_w' 'asymm_super_gauss_rmse' 'asymm_super_gauss_k' 'asymm_super_gauss_w' 'asymm_super_gauss_ak' 'asymm_super_gauss_aw' 'ln_normal_rmse' 'ln_normal_sigma' 'ln_normal_mu' 'ln_reverse_rmse' 'ln_reverse_sigma' 'ln_reverse_mu'};
    
    % Calculating standard deviation of each column 
    
    monte_carlo_std_summary = varfun(@std, monte_carlo_summary);  
    
    monte_carlo_std_summary = monte_carlo_std_summary(:, 2:end)
    
   end
    
    spectralcal_loaded(initial_peak_i).monte_carlo_detail = monte_carlo_detail;
    spectralcal_loaded(initial_peak_i).monte_carlo_summary = monte_carlo_summary;
    spectralcal_loaded(initial_peak_i).monte_carlo_std_summary = monte_carlo_std_summary;
   
    spectralcal_output = spectralcal_loaded;
    
    save(strcat(output_file_dir_string, '/', output_file_name, '.mat'), 'spectralcal_output');
    
    
   
    % get the best FWHM
    % disp('getting best FWHM by sigma minimisation');
    % [~, best_ind] = min(abs(sigma_vector - sigma_DN))
    
    % [~, best_ind] the tilde could be replace by "MinValue" which gives
    % remaining difference from measurement sigma to fitted sigma, this
    % MinValue could be of interest when looking at "error" evaluation
    % Min Value here is referring to the numerical difference of the best fit index 
    %FWHM_fitted_best_ever = FWHM_vector(best_ind);

    
    %[rmse_best_overall, rmse_best_ind] = min(rmse_loop_table.RMSE)
    
    
    
    %FWHM_ls_best = FWHM_vector(ls_best_ind)
    
    %sgtitle({['DN vs wvl for original spectrum (blue) vs scaled simulated gaussian (red)']
    %         ['Best fit SRF FWHM: '  num2str(FWHM_fitted_best_ever)]
    %         })
    
    %mu_best = mu_vector(best_ind) % best centre wavelength of the gaussian fit of the peak seen by the instrument in several bands
    
    %best_spectrum = scaled_simulated_spectra(ls_best_ind, :); % The colon here means we will take all columns of the vector 'simulated_spectra'
    
   % best_gauss = gaussian_fit(best_ind, :);
   
    %w_best = w_vector(ls_best_ind);
    %k_best = k_vector(ls_best_ind);
 
    
    %figure
    %plot(1:length(best_spectrum), best_spectrum)
    
    % simulated gaussian fit of instrument response
    %{
    sigma = 0.8493218 * FWHM_fitted_best_ever/2;
    range = 3*sigma;
    x = linspace(-range, +range, 10000);

    srf_values = 1/(sqrt(2*pi)*sigma)* exp(-0.5*(x/sigma).^2);
    
    pure_peak.coeff = srf_values;
    pure_peak.wvl = x + mu_best; % shift SRF to the centre wavelength
    
    
    % gaussian peak of input spectrum
     %}
     %{
    range = 3*sigma_DN;
    x = linspace(-range, +range, 10000);
    
    
    sigma = 0.8493218 * FWHM_fitted_best_ever/2;

    srf_values = 1/(sqrt(2*pi)*sigma)* exp(-0.5*(x/sigma).^2);
    
    input_pure_peak.coeff = srf_values;
    input_pure_peak.wvl = x + mu2; % shift SRF to the centre wavelength
    
    
    % check difference between simulated instrument response and the ideal
    % Gaussian best fit
    
    %scale input_pure_peak
    input_pure_peak.coeff = input_pure_peak.coeff * (max(best_spectrum) / max(input_pure_peak.coeff))
    
    %scale pure_peak
    pure_peak.coeff = pure_peak.coeff * (max(best_spectrum) / max(pure_peak.coeff))
    
    % scale actual measured spectrum
    ratio_maxSpectrum_over_maxPurePeak = (max_spectrum /  max(pure_peak.coeff));
    
    figure
    plot(350:2500, best_spectrum);
    hold
    plot(pure_peak.wvl, pure_peak.coeff, 'r')
    plot(user_data.current_spectra.wvl, spectrum / ratio_maxSpectrum_over_maxPurePeak, 'm')
    plot(input_pure_peak.wvl, input_pure_peak.coeff, 'g')
    

    % get correction vector
    % mu_best is in first principle wavelength space, while mu2 is in ASD
    % current spectral calibration wavelength space
    %centre_wvl_delta = mu_best - mu2;
    
    
    % define bands that are well above the noise level - those which
    % actually detect something 
    %scaled_input_spectrum = To_be_fitted_spectrum / ratio_maxSpectrum_over_maxPurePeak;
    scaled_input_spectrum = To_be_fitted_spectrum;
    
    index_of_valid_bands = scaled_input_spectrum > max(scaled_input_spectrum)*0.1; %10% or less considered to be noise
           
    bands = spectrum_lower:spectrum_upper;
    
    user_data_wvl = user_data.current_spectra.wvl(spectrum_lower:spectrum_upper);
  
    disp('Printing final values from cal_output');
    % following structures can be used in new function (e.g for interpolation of FWHMs across detector)
    cal_output.initial_peak_wvl = initial_peak_wvl;
    cal_output.cal_band_numbers = bands(index_of_valid_bands);
    cal_output.cal_band_original_wvls = user_data_wvl(index_of_valid_bands);
    %cal_output.centre_wvl_delta = centre_wvl_delta;
    cal_output.max_wvl_difference = max_wvl_difference;
    cal_output.cal_band_new_wvls = cal_output.cal_band_original_wvls + max_wvl_difference;
    %cal_output.RMSE = rmse_best;
    %cal_output.FWHM_sigma_min = FWHM_fitted_best_ever;
    %cal_output.FWHM_leastsquares_10percent = FWHM_ls_best;
    %cal_output.k_best = k_best;
    %cal_output.w_best = w_best;
    cal_output.rmse_summary = rmse_summary;
    cal_output.rmse_detail = rmse_loop_table;
    %}

    cal_output.monte_carlo_detail = monte_carlo_detail;
    cal_output.monte_carlo_summary = monte_carlo_summary;
    cal_output.monte_carlo_std_summary = monte_carlo_std_summary;
    cal_output.detector = detector_name;
    cal_output.instrument_id = instrument_id;
    cal_output.instrument_serial_no = instrument_serial;
    cal_output.lamp_name = lamp_name
    
    % 'first principle' for getting centre wavelengths per band: to do this
    % we use the 'BAND SPACE'
    
    %figure
    %plot(bands,scaled_input_spectrum);
  
    %get gauss fit of scaled DN (measured) peak in 'band space',
    %essentially defining the centre of the peak in band fractions
    % band space is virtual high res vector
    % NB: scale_input_spectrum == to be fitted spectrum
    
    %[~,mu_band_space,~]=mygaussfit(bands,scaled_input_spectrum);
    
    %range = 3*sigma_DN;
   % x = linspace(-range, +range, 10000);
    
    % digitisation of the Gaussian fit (Gaussian vector) of the measured DN spectrum 
    %input_pure_peak_band_space.coeff = 1/(sqrt(2*pi)*sigma_DN)* exp(-0.5*(x/sigma_DN).^2);
   % input_pure_peak_band_space.band = x + mu_band_space; % shift Gaussian vector to the centre band in fractional band space
    
    %input_pure_peak_band_space.coeff = input_pure_peak_band_space.coeff * (max(scaled_input_spectrum) / max(input_pure_peak_band_space.coeff))
    
    %{
    figure
    plot(bands, scaled_input_spectrum, 'm')
    hold
    plot(input_pure_peak_band_space.band, input_pure_peak_band_space.coeff, 'g')
    title('Comparison of measured DN peak and its Gaussian fit of that peak in Band Space')
    legend('measured DN', 'Gauss fit of the Measured DN (Gaussian Vector)')
    xlabel('Band as in Band Space')
    %}
    
    %x = linspace(-range, +range, 10000);
   % pure_peak_wvl = x + mu_best; % 
    
   % figure
   % plot(pure_peak_wvl, input_pure_peak_band_space.coeff, 'g')
   % title('Gaussian fit of the DN peak in Wvl Space')
   
    %figure
    %plot(input_pure_peak_band_space.band, pure_peak_wvl, 'o')
   % title('The bands versus centre wvl of the Gaussian vector and their linear fit')
    %c = polyfit(input_pure_peak_band_space.band, pure_peak_wvl, 1);
    
    %fitted_line = polyval(c, input_pure_peak_band_space.band);
    
   % hold
    %plot(input_pure_peak_band_space.band, fitted_line, 'r')
    %legend('Gaussian vector wvl', 'linear fit of wvl vs bands')
    
    %cal_output.wavelength_on_first_principle = polyval(c, cal_output.cal_band_numbers);
    
    
    % first principle versus CW_delta propagated to neighbouring bands
    
    %{
    figure
    
    bar(cal_output.cal_band_numbers', (cal_output.cal_band_new_wvls - cal_output.wavelength_on_first_principle')')
    
    figure
    bar(cal_output.cal_band_numbers', cal_output.cal_band_original_wvls - cal_output.wavelength_on_first_principle') % ASD based wvl info - first principle determined wvl
    hold
    plot(cal_output.cal_band_numbers', (cal_output.cal_band_original_wvls - cal_output.wavelength_on_first_principle') + cal_output.centre_wvl_delta, 'r')
    
    legend('differences of wvl cal errors for all bands', 'differences of wvl cal errors for all bands to single delta wvl')
    
    title('Minute differences of wvl estimation methods (actually not visible at all)')
    
    figure
    plot(cal_output.cal_band_numbers, cal_output.cal_band_new_wvls, 'o')
    hold
    plot(cal_output.cal_band_numbers, cal_output.wavelength_on_first_principle, 'r')
    %}
    %}

end


function SPECCHIO_Sandbox(hObject, EventData)

    fh = ancestor(hObject.hghandle, 'figure');    
    user_data = get(fh, 'UserData');
    
    
    %% Do whatever needs doing with the data ....
    
    
    % e.g. get the mean:
    
    avg_spectrum = mean(user_data.current_spectra.vectors);
    
    stddev = std(user_data.current_spectra.vectors);
    
    figure(1)
    
    plot(user_data.current_spectra.wvl, avg_spectrum)
    
    figure(2)
    
    plot(user_data.current_spectra.wvl, stddev)
    
end


function DataBrowserAction(hObject, EventData, window_h)

    import ch.specchio.client.*;
    import ch.specchio.queries.*;

    %window_h = getappdata(hObject,'UserData');   

    user_data = get(window_h, 'UserData');
    
    msgbox_h = msgbox('Selecting data from DB');

    % get ids of all spectra
    ids = user_data.sdb.get_selected_spectrum_ids();


    % check if data were selected
    if(ids.size() > 0)

        % store info about selected hierarchy
        user_data.selected_hierarchy_id = user_data.sdb.get_selected_hierarchy_ids();

        set(user_data.TotalSpectra, 'String', num2str(ids.size()));

%         % define query and get spectra ids: only required if other
%         conditions are added: see also 'Copy Matlab ready query' from SPECCHIO Query Browser
%         query = ch.specchio.queries.Query('spectrum');
%         query.setQueryType(Query.SELECT_QUERY);
% 
%         query.addColumn('spectrum_id')
% 
%         cond = ch.specchio.queries.QueryConditionObject('spectrum', 'spectrum_id');
%         cond.setValue(ids);
%         cond.setOperator('in');
%         query.add_condition(cond);
%         user_data.ids = user_data.specchio_client.getSpectrumIdsMatchingQuery(query);

        user_data.ids = ids;

        % get instrument info for all spectra
        user_data.instr_hash = get_instrument_hash(user_data);

        % set instrument name
        if size(user_data.instr_hash , 2) == 1

            set(user_data.InstrumentInDB, 'String', char(user_data.instr_hash.instr.getInstrumentName()));
            
        elseif size(user_data.instr_hash , 2) == 0

            set(user_data.InstrumentInDB, 'String', 'No instrument is set');

        else

            set(user_data.InstrumentInDB, 'String', 'Attention: Multiple Instruments!');

        end
        
        
        % create spaces
        user_data.spaces = user_data.specchio_client.getSpaces(ids, 1, 1, 'Acquisition Time');
        
        set(user_data.CurrSpaceText, 'String', ['of ' num2str(size(user_data.spaces, 1)) ' Space(s)']);
        
        
        % set spinner model accoring to number of spaces      
        user_data.spinner_model.setMaximum(java.lang.Integer(size(user_data.spaces, 1)));
        user_data.spinner_model.setValue(java.lang.Integer(1));
        
        plot_space(user_data);

        % store data in figure
        set(user_data.window_h, 'UserData', user_data);

    end

    close(msgbox_h);

end



function plot_space(user_data)

        if user_data.ids.size <= 1000
            
            
            
            space = user_data.spaces(user_data.spinner_model.getValue());   
            space = user_data.specchio_client.loadSpace(space);


            spectra.vectors = space.getVectorsAsArray();
            spectra.wvl = space.getAverageWavelengths();
            spectra.unit = char(space.getMeasurementUnit.getUnitName);
            spectra.instrument = space.getInstrument();

            spectra.ids = space.getSpectrumIds(); % get them sorted by 'Acquisition Time' (sequence as they appear in space)

            %spectra.capture_times = get_acquisition_times(specchio_client, spectra.ids);
            
            user_data.current_spectra = spectra;


            plot_2d(user_data.spectral_plot,  spectra, 'Spectral Plot');
            
            % store data in figure
            set(user_data.window_h, 'UserData', user_data);
            
            
        else
            
            msgbox('Data not loaded as more tdoinhan 1000 spectra are selected');
            
        end
        
        
end


function DBConn(hObject, EventData)

    import ch.specchio.gui.*;


    % get user data
    fh = ancestor(hObject, 'figure');
    user_data = get(fh, 'UserData');

    index = get(hObject,'Value');

    % check if not the first entry string was chosen ... (no valid
    % connection string but user info)
    if index > 1
        
        % create client for current description and generate spectral data
        % browser

        user_data.specchio_client = user_data.cf.createClient(user_data.db_descriptor_list.get(index-2));   % zero index & ignore user info line

        user_data.sdb = SpectralDataBrowser(user_data.specchio_client, true);
        user_data.sdb.build_tree();
        user_data.sdb.set_view_restriction(0); % restrict view to current user (other data cannot be processed anyway)

        user_data.scrollpane.setViewportView(user_data.sdb);
        
        hTree = handle(user_data.sdb.tree, 'CallbackProperties');
        set(hTree, 'MousePressedCallback', {@DataBrowserAction, user_data.window_h});         
        
        %set(user_data.sdb.tree, 'UserData', user_data.window_h); % ensure that we got a link from the event to the figure

        % store data in figure
        set(user_data.window_h, 'UserData', user_data);

    end


end



function instr_hash = get_instrument_hash(user_data)

    instr_hash = [];

    instr_ids = user_data.specchio_client.getInstrumentIds(user_data.ids);
       
    ids = zeros(instr_ids.size(), 1);
    
    for i=0:instr_ids.size()-1
        ids(i+1) = instr_ids.get(i); % get the ids into a matlab array for easier processing       
    end
    
    % reduce to unique ids
    unique_ids = unique(ids);

    
    if unique_ids ~= 0 % catches the case when no instrument is set ...

        for i=1:size(unique_ids,1)
            instruments(i) = user_data.specchio_client.getInstrument(unique_ids(i));
            instr_hash(i).id = unique_ids(i);
            instr_hash(i).instr = instruments(i);
        end
    
    end

end


