function iotest(varargin)
%
% Created by WA, Fall, 2006
% Last Modified 12/14/2007  --WA
% Last Modified 2/24/2014 --ER (to display voltage for multiple channels)
% Last Modified 2/27/2014 --ER (to display voltage in XY)
% Last Modified 2/27/2014 --ER (to dynamically display 1:n channels as chosen by the user)
% Last Modified 2/28/2014 --ER (to dynamically set the figure window's layout and data matrices based on the type of iotest being performed)

fig = findobj('tag', 'iotestfigure');
if ~isempty(fig) && ~isempty(varargin),
    close(fig); %allow to re-initialize with new DAQ parameters
    fig = [];
end
    
if isempty(fig),
    
    DaqData = varargin{1};
    subsystypes = {'AnalogInput' 'AnalogOutput' 'DigitalIO'};
    subsystype = find(strcmpi(DaqData.SubSystemName, subsystypes));

    if isempty(subsystype),
        error('Unrecognized subsystem type %s', DaqData.SubSystemName);
        return
    end
    
    % create the figure window where to put all the controls
    figure

    % start determining the user's display dimensions in order to properly
    % position the layout of this new figure window.
    
    scrnsz = get(0, 'screensize');
    sx = scrnsz(3);
    sy = scrnsz(4);

    % Different i/o test types require unique figure windows
    % and coordinates of interior controls.

    if subsystype == 1, %Analog Input
        

        xs = 1150;      % width of the figure window
        ys = 400;       % height of the figure window
        xbase = 910;    % x offset of the control label
        ybase = 300;    % y offset of the control label

        %initialize the data matrix before creating the subplots
        numpoints = 300;
        numchannels = length(DaqData.Channel);

        v = 1:numpoints;
        w = zeros(1, numpoints);
        x = [];
        y = [];
        for i=1:numchannels
            x = [x;v];
            y = [y;w];
        end

        % create first graph (XY Plot)
        subplot('position', [0.03 0.06 0.33 0.85], 'YGrid','on', 'XGrid','on')
        set(gca, 'xlim', [-6 6]);% add an extra volt of space
        set(gca, 'ylim', [-5 6]);% add an extra volt of space
        %xlabel(gca, 'Channel 0 Volts');
        %ylabel(gca, 'Channel 1 Volts ');
        title(gca, 'Voltage XY') 
        set(gca, 'nextplot', 'add', 'tag', 'ioplotXY', 'color', [0.2 0.2 0.2]);
        xyData = line(x', y'); %notice that the transpose is critical
        set(xyData, 'markersize', 3, 'tag', 'plotterXY', 'color', [0 1 0]);

        % create second graph (yT Plot)
        subplot('position', [0.37 0.06 0.33 0.85], 'YGrid','on');
        set(gca, 'ylim', [-6 6]);  % add an extra volt of space
        set(gca,'yaxislocation','right');
        xlabel(gca, 'samples');
        ylabel(gca, 'volts');
        title(gca, 'Voltage Change (yT)') 
        set(gca, 'nextplot', 'add', 'tag', 'ioplot', 'xtick', [], 'color', [0.2 0.2 0.2]);
        h = line(x', y'); %notice that the transpose is critical
        %forces all channels to be plotted in the same green color.
        %set(h, 'markersize', 3, 'tag', 'plotter', 'color', [0 1 0]);
        set(h, 'markersize', 3, 'tag', 'plotter');

    elseif subsystype == 2, %Analog Output

        xs = 700;
        ys = 400;
        xbase = 460;
        ybase = 300;
        % create second graph (yT Plot) ONLY
      	subplot('position', [0.05 0.05 0.5 0.9])
    	set(gca, 'nextplot', 'add', 'tag', 'ioplot', 'xtick', [], 'color', [0 0 0], 'ylim', [-0.1 1.1]);
    	h = plot(0, 0);
    	set(h, 'markersize', 3, 'tag', 'plotter', 'color', [0 1 0]);
 
    elseif subsystype == 3, %Digital IO
       
        xs = 700;
        ys = 400;
        xbase = 460;
        ybase = 300;
        % create second graph (yT Plot) ONLY
       	subplot('position', [0.05 0.05 0.5 0.9])
    	set(gca, 'nextplot', 'add', 'tag', 'ioplot', 'xtick', [], 'color', [0 0 0], 'ylim', [-0.1 1.1]);
    	h = plot(0, 0);
    	set(h, 'markersize', 3, 'tag', 'plotter', 'color', [0 1 0]);

    end
        
    set(gcf, 'position', [0.5*(sx - xs) 0.5*(sy - ys) xs ys], 'doublebuffer', 'on', 'tag', 'iotestfigure', 'numbertitle', 'off', 'name', 'I/O Test', 'menubar', 'none');
    set(gcf, 'closerequestfcn', 'set(findobj(''tag'', ''stopiotest''), ''userdata'', 2)');

    % create the control label (start, stop, quit, and potentially others
    fbg = [0.75 0.7 0.77];  % color of the control label
    uicontrol('style', 'frame', 'position', [xbase-30 10 250 380], 'backgroundcolor', get(gcf, 'color'));
    uicontrol('style', 'frame', 'position', [xbase-20 ybase 230 80], 'backgroundcolor', fbg);
    uicontrol('style', 'text', 'position', [xbase-10 ybase+50 210 20], 'string', sprintf('Testing: %s', DaqData.BoardName), 'backgroundcolor', fbg, 'fontsize', 10);
    uicontrol('style', 'text', 'position', [xbase ybase+30 190 21], 'string', sprintf('Subsystem: %s', subsystypes{subsystype}), 'backgroundcolor', fbg, 'fontsize', 10);
    if isfield(DaqData, 'Channel'),
        uicontrol('style', 'text', 'position', [xbase ybase+10 190 20], 'string', sprintf('Channel: %i', DaqData.Channel), 'backgroundcolor', fbg, 'fontsize', 10, 'tag', 'channelheader');
    else
        uicontrol('style', 'text', 'position', [xbase ybase+10 190 20], 'string', sprintf('Port: %i', DaqData.Port), 'backgroundcolor', fbg, 'fontsize', 10);
    end
    uicontrol('style', 'pushbutton', 'position', [xbase+35 260 120 30], 'string', 'Start Test', 'tag', 'startiotest', 'callback', 'iotest', 'userdata', 0);
    uicontrol('style', 'pushbutton', 'position', [xbase+35 220 120 30], 'string', 'Stop Test', 'tag', 'stopiotest', 'callback', 'iotest', 'enable', 'off');
    uicontrol('style', 'pushbutton', 'position', [xbase+35 20 120 30], 'string', 'Reset DAQ & Quit', 'tag', 'closeiotest', 'callback', 'iotest');
    
    numpoints = 200;
    if subsystype == 1, %Analog Input

        wform = [];
        
    elseif subsystype == 2, %Analog Output

        wform = cos(0:(2*pi)/numpoints:((2*pi)-(2*pi/numpoints))); %sine wave
        wform = 5*(-wform+1)/2; %new range 0 to 1
        set(findobj(gcf, 'tag', 'startiotest'), 'string', 'Sine Wave Test');
        
        DaqData.AO = eval(DaqData.Constructor);
        h = daqhwinfo(DaqData.AO);
        DaqData.Channels = h.ChannelIDs;
        addchannel(DaqData.AO, DaqData.Channels);
        
        chanstr = num2str(DaqData.Channels);
        set(findobj(gcf, 'tag', 'channelheader'), 'string', sprintf('Channels: %s', chanstr));
        
        xbase = 455;
        uicontrol('style', 'frame', 'position', [xbase 60 200 150], 'backgroundcolor', fbg);
        uicontrol('style', 'pushbutton', 'position', [xbase+75 75 110 50], 'string', 'Test Pulse', 'tag', 'pulse', 'callback', 'iotest');
        uicontrol('style', 'text', 'position', [xbase+80 172 100 20], 'string', 'Pulse Duration', 'backgroundcolor', fbg);
        uicontrol('style', 'text', 'position', [xbase+100 132 60 20], 'string', 'milliseconds', 'backgroundcolor', fbg);
        uicontrol('style', 'edit', 'position', [xbase+100 155 60 20], 'backgroundcolor', [1 1 1], 'tag', 'pulseduration', 'callback', 'iotest', 'string', '100', 'userdata', 50);
        uicontrol('style', 'listbox', 'position', [xbase+20 73 40 110], 'string', DaqData.Channels, 'max', 2, 'backgroundcolor', [1 1 1], 'tag', 'aolines');
        uicontrol('style', 'text', 'position', [xbase+10 185 60 15], 'string', 'Channel(s)', 'backgroundcolor', fbg, 'horizontalalignment', 'center');
        
        f = find(DaqData.Channels == DaqData.Channel);
        if ~isempty(f),
            set(findobj(gcf, 'tag', 'aolines'), 'value', f);
        else
            set(findobj(gcf, 'tag', 'aolines'), 'value', 1);
        end
        
    elseif subsystype == 3, %Digital IO

        numpoints1 = round(0.6*numpoints);
        numpoints2 = round(0.4*numpoints);
        wform = cat(2, ones(1, numpoints1), zeros(1, numpoints2)); %square wave
        set(findobj(gcf, 'tag', 'startiotest'), 'string', 'Square Wave Test');
        
        xbase = 455;
        uicontrol('style', 'frame', 'position', [xbase 60 200 150], 'backgroundcolor', fbg);
        uicontrol('style', 'pushbutton', 'position', [xbase+75 75 110 50], 'string', 'Test Pulse', 'tag', 'pulse', 'callback', 'iotest');
        uicontrol('style', 'text', 'position', [xbase+80 172 100 20], 'string', 'Pulse Duration', 'backgroundcolor', fbg);
        uicontrol('style', 'text', 'position', [xbase+100 132 60 20], 'string', 'milliseconds', 'backgroundcolor', fbg);
        uicontrol('style', 'edit', 'position', [xbase+100 155 60 20], 'backgroundcolor', [1 1 1], 'tag', 'pulseduration', 'callback', 'iotest', 'string', '100', 'userdata', 50);
        uicontrol('style', 'listbox', 'position', [xbase+20 73 40 110], 'string', DaqData.Line, 'max', 2, 'backgroundcolor', [1 1 1], 'tag', 'diolines');
        uicontrol('style', 'text', 'position', [xbase+20 185 40 15], 'string', 'Line(s)', 'backgroundcolor', fbg, 'horizontalalignment', 'center');

        DaqData.DIO = eval(DaqData.Constructor);
        try
            addline(DaqData.DIO, DaqData.Line, DaqData.Port, 'out');
        catch
            error('Unable to initialize digital output lines: This port may be read-only');
        end
    
    end

    set(gcf, 'userdata', DaqData);
    TestData.SubSystemType = subsystype;
    TestData.WaveForm = wform;
    set(findobj(gcf, 'tag', 'ioplot'), 'userdata', TestData);
    
elseif ismember(gcbo, get(fig, 'children')),
    
    callertag = get(gcbo, 'tag');
    
    switch callertag,
        
        case 'startiotest',
            
            DaqData = get(gcf, 'userdata');
            TestData = get(findobj(gcf, 'tag', 'ioplot'), 'userdata');
            wform = TestData.WaveForm;
            h = findobj(gcf, 'tag', 'plotter');
         
            numpoints = 300;

            
            hstop = findobj(gcf, 'tag', 'stopiotest');
            set(hstop, 'userdata', 0);
            set(hstop, 'enable', 'on');
            set(gcbo, 'enable', 'off');
            
            set(findobj(gcf, 'tag', 'startiotest'), 'userdata', 1);
            if TestData.SubSystemType == 1, %analog input
             
            	% initialize the vector that buffers analog input data
                numchannels = length(DaqData.Channel);
                data = zeros(numchannels, numpoints);
                xyH = findobj(gcf, 'tag', 'plotterXY');
            
                daqreset;
                ai = eval(DaqData.Constructor);

                for channelNum=1:numchannels
                    addchannel(ai, DaqData.Channel(channelNum));
                end
                
                numloops = 10000;
                i = 0;
                set(ai, 'InputType', DaqData.InputType);
                %set(ai,'BufferingConfig',[1 2000]);
                while i < numloops,
                    i = i + 1;
                    smp = getsample(ai);

                    for channelNum=1:numchannels
                        data(channelNum, numpoints+1) = smp(channelNum);
                        data(channelNum,1:numpoints) = data(channelNum, 2:numpoints+1);
                    end
                    
                    %x = [1:numpoints;1:numpoints];
                    y = [];
                    for channelNum=1:numchannels
                        y = [y;data(channelNum,1:numpoints)];
                    end
                    
                    %x = num2cell(x,2);% not needed if using the simple way
                    y = num2cell(y,2);                  
                    set(h,{'ydata'},y);                 % simple new way
                    %set(h,{'xdata'},x,{'ydata'},y);    % complete new way
                    %set(h, 'ydata', data(1,1:numpoints));% old way

                    %plot vectors 1 and 2 in the XY graph
                    if (numchannels < 2)
                        
                        point = repmat(data(1,numpoints), 1, numpoints);
                        
                        if (mod(DaqData.Channel(1), 2) == 1) % even
                            set(xyH,'xdata',zeros(1,numpoints),'ydata',point); %plot as vertical
                        else
                            set(xyH,'xdata',point,'ydata',zeros(1,numpoints)); %plot as horizontal
                        end
                        
                    else
                    	set(xyH,'xdata',data(1,1:numpoints),'ydata',data(2,1:numpoints));
                    end

                    stopval = get(hstop, 'userdata');
                    if stopval,
                        i = numloops + 1;
                    end
                    drawnow;
                end

                delete(ai);
                clear ai
                if stopval > 1,
                    daqreset;
                    delete(gcf);
                end
                
            elseif TestData.SubSystemType == 2, %analog output
                        
             	set(h, 'xdata', 1:numpoints, 'ydata', zeros(1, numpoints));
            	data = zeros(1, numpoints);

				DaqData = get(gcf, 'userdata');
                aoindx = get(findobj(gcf, 'tag', 'aolines'), 'value');
                z = zeros(size(DaqData.Channels));
                aolines = z;
                aolines(aoindx) = 1;
                ptype = determine_output_fxn(DaqData);
                
                numcycles = 10;
                wform = repmat(wform, 1, numcycles);
                wlength = length(wform);
                
                i = 0;
                while i < wlength,
                    tic;
                    i = i + 1;
                    if ptype == 1,
                        putsample(DaqData.AO, aolines*wform(i));
                    else
                        putdata(DaqData.AO, aolines*wform(i));
                    end
                    data(numpoints+1) = wform(i);
                    data = data(2:numpoints+1);
                    set(h, 'ydata', data);
                    stopval = get(hstop, 'userdata');
                    if stopval,
                        if ptype == 1,
                            putsample(DaqData.AO, aolines*wform(i)),
                        else
                            putdata(DaqData.AO, z);
                        end
                        i = wlength + 1;
                    end
                    drawnow;
                    while toc*1000 < 5, end
                end
                
                if stopval > 1,
                    daqreset;
                    delete(gcf);
                end
                
            elseif TestData.SubSystemType == 3, %digital io

                set(h, 'xdata', 1:numpoints, 'ydata', zeros(1, numpoints));
           		data = zeros(1, numpoints);
				
				DaqData = get(gcf, 'userdata');
                dioindx = get(findobj(gcf, 'tag', 'diolines'), 'value');
                z = zeros(size(DaqData.Line))';
                diolines = z;
                diolines(dioindx) = 1;
                
                numcycles = 10;
                wform = repmat(wform, 1, numcycles);
                wlength = length(wform);
                
                i = 0;
                while i < wlength,
                    tic;
                    i = i + 1;
                    if i == 1 || wform(i) ~= wform(i - 1),
                        if wform(i),
                            putvalue(DaqData.DIO, diolines);
                        else
                            putvalue(DaqData.DIO, z);
                        end
                    end
                    indx = numpoints + 1;
                    data(indx) = wform(i);
                    data = data(2:indx);
                    set(h, 'ydata', data);
                    stopval = get(hstop, 'userdata');
                    if stopval,
                        putvalue(DaqData.DIO, z);
                        i = wlength + 1;
                    end
                    drawnow;
                    while toc*1000 < 5, end
                end
                
                if stopval > 1,
                    daqreset;
                    delete(gcf);
                end
                
            end
                        
            set(findobj(gcf, 'tag', 'startiotest'), 'userdata', 0);
            set(gcbo, 'enable', 'on');
            
        case 'stopiotest',
            
            set(gcbo, 'userdata', 1);
       
            hstop = findobj(gcf, 'tag', 'startiotest');
            set(hstop, 'enable', 'on');
            set(gcbo, 'enable', 'off');
            
        case 'pulseduration',
            
            str = get(gcbo, 'string');
            n = str2double(str);
            if isempty(n) || isnan(n),
                set(gcbo, 'string', num2str(get(gcbo, 'userdata')));
            else
                set(gcbo, 'userdata', n);
            end
            
        case 'pulse',
            
            TestData = get(findobj(gcf, 'tag', 'ioplot'), 'userdata');
            dur = get(findobj(gcf, 'tag', 'pulseduration'), 'userdata');
            DaqData = get(gcf, 'userdata');
            col_gray = get(gcbo, 'backgroundcolor');
            col_green = [.5 .75 .5];
            set(gcbo, 'backgroundcolor', col_green);
            set(gcf, 'CurrentAxes', findobj(gcf, 'tag', 'ioplot'));
            h = plot(mean(get(gca, 'xlim')), mean(get(gca, 'ylim')), 'o');
            set(h, 'markersize', 50, 'markerfacecolor', col_green/3, 'markeredgecolor', col_green, 'linewidth', 7);
            drawnow;

            if TestData.SubSystemType == 2, %analog output

                aoindx = get(findobj(gcf, 'tag', 'aolines'), 'value');
                z = zeros(size(DaqData.Channels));
                aolines = z;
                aolines(aoindx) = 1;
                ptype = determine_output_fxn(DaqData);
                if ptype == 1,
                    putsample(DaqData.AO, aolines);
                else
                    putdata(DaqData.AO, aolines);
                end
                tic;
                while toc*1000 < dur, end
                if ptype == 1,
                    putsample(DaqData.AO, z);
                else
                    putdata(DaqData.AO, z);
                end
                
                
            elseif TestData.SubSystemType == 3, %Digital output
                
                dioindx = get(findobj(gcf, 'tag', 'diolines'), 'value');
                z = zeros(size(DaqData.Line))';
                diolines = z;
                diolines(dioindx) = 1;
                putvalue(DaqData.DIO, diolines);
                tic;
                while toc*1000 < dur, end
                putvalue(DaqData.DIO, z);
                
            end
            
            set(gcbo, 'backgroundcolor', col_gray);
            delete(h);
            drawnow;
            
        case 'closeiotest',
            
            if get(findobj(gcf, 'tag', 'startiotest'), 'userdata'),
                set(findobj(gcf, 'tag', 'stopiotest'), 'userdata', 2);
            else
                daqreset;
                delete(gcf);
            end
            
    end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ptype = determine_output_fxn(DaqData)

z = zeros(size(DaqData.Channels));
try
    ptype = 1;
    putsample(DaqData.AO, z);
catch
    try
        ptype = 2;
        putdata(DaqData.AO, z);
        disp('*** WARNING: This type of analog output object supported only for audio output ***');
    catch
        ptype = 0;
    end
end
if ~ptype,
    error('*** Unable to putdata or putsample into analog output object ***');
end
