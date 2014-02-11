function SigTransform = xycalibrate(varargin)
global MLHELPER_OFF
%
%
% Created by WA 7/06
% modified 2/25/08 -WA (to include voltage indicator and use task's background color)
% modified 4/09/08 -VY (to fix bug preventing digital reward delivery)
% modified 9/11/08 -WA (to fix aspect ratio and center fixation points properly)
% modified 9/19/08 -SM (to allow inverted reward polarity)

fig = findobj('tag', 'xycalibrate');
SigTransform = [];

if isempty(fig),
    if isempty(varargin),
        disp('*** XY-Calibrate must be called from the MonkeyLogic menu or during task performance with appropriate parameters ***');
        return
    end
    figure;
    ScreenInfo = varargin{1};
    targetlist = varargin{2};
    BasicData.ScreenInfo = ScreenInfo;
    BasicData.IO = varargin{3};
    if length(varargin) > 3,
        BasicData.SigTransform = varargin{4};
    else
        BasicData.SigTransform = [];
    end
    if length(varargin) > 4,
        MLHELPER_OFF = varargin{5};
    else
        MLHELPER_OFF = 0;
    end
    if isstruct(BasicData.SigTransform),
        cp = tforminv(BasicData.SigTransform, targetlist);
    else
        cp = targetlist;
    end
    BasicData.EyeOrJoy = ScreenInfo.EyeOrJoy;
    BasicData.FixSpot = ScreenInfo.FixationPoint;
    BasicData.ControlPoints = cp;
    set(gcf, 'userdata', BasicData);

    cpsize = 200;
    xs = 800;
    ys = 600;
    xd = xs/ScreenInfo.PixelsPerDegree;
    yd = ys/ScreenInfo.PixelsPerDegree;
    
    xrescale = ScreenInfo.Xsize/xs;
    yrescale = ScreenInfo.Ysize/xs;
    if xrescale >= yrescale,
        xd = xd*xrescale;
        yd = yd*xrescale;
    else
        xd = xd*yrescale;
        yd = yd*yrescale;
    end
    
    hxd = xd/2;
    hyd = yd/2;

    ss = get(0, 'ScreenSize');
    cx = ss(3);
    cy = ss(4);
    wxp = (cx - xs - cpsize)/2;
    wyp = (cy - ys)/2;

    inputtypestring = '';
    if ScreenInfo.EyeOrJoy == 1,
        inputtypestring = 'Eye Signal';
    elseif ScreenInfo.EyeOrJoy == 2,
        inputtypestring = 'Joystick';
    end
    set(gcf, 'position', [wxp wyp xs+cpsize ys], 'name', ['MonkeyLogic Input Calibration: ' inputtypestring], 'tag', 'xycalibrate', 'menubar', 'none', 'backingstore', 'off', 'resize', 'off', 'numbertitle', 'off', 'doublebuffer', 'on');
    bg = get(gcf, 'color');
    
    subplot('position', [cpsize/xs 0 xs/(xs+cpsize) 1]);
    set(gca, 'color', [0 0 0], 'xlim', [-hxd hxd], 'ylim', [-hyd hyd], 'nextplot', 'add', 'xtick', [], 'ytick', [], 'tag', 'monitor', 'userdata', [xs ys ScreenInfo.PixelsPerDegree], 'buttondownfcn', 'xycalibrate(''selectpoint'');');

    xy = plot(0,0, 'o');
    tgt = plot(0,0, 'o');
    set(xy, 'markerfacecolor', [0.5 0.5 0.5], 'markeredgecolor', [1 1 1], 'linewidth', 2, 'markersize', 7, 'erasemode', 'xor', 'tag', 'xy');
    set(tgt, 'markerfacecolor', 'none', 'markeredgecolor', [1 1 1], 'linewidth', 2, 'markersize', 30, 'erasemode', 'xor', 'tag', 'tgt');

    uicontrol('style', 'pushbutton', 'position', [50 ys-35 150 25], 'string', 'Start Calibration', 'tag', 'startcal', 'callback', 'xycalibrate;');
    
    ys2 = ys+3;
    uicontrol('style', 'frame', 'position', [20 ys2-260 210 172], 'backgroundcolor', bg);
    uicontrol('style', 'text', 'position', [70 ys2-103 110 20], 'string', 'Transform & Targets', 'backgroundcolor', bg);
    uicontrol('style', 'popupmenu', 'position', [60 ys2-121 125 20], 'string', {'Affine', 'Projective', 'Polynomial'}', 'tag', 'ttype', 'backgroundcolor', [1 1 1], 'value', 2, 'enable', 'inactive');
    h = uicontrol('style', 'listbox', 'position', [60 ys2-229 125 100], 'backgroundcolor', [1 1 1], 'tag', 'targetlist', 'fontsize', 10, 'callback', 'xycalibrate;');  
    uicontrol('style', 'text', 'position', [60 ys2-257 50 18], 'string', 'Edit:', 'backgroundcolor', bg, 'horizontalalignment', 'left');
    uicontrol('style', 'edit', 'position', [83 ys2-254 100 20], 'backgroundcolor', [1 1 1], 'tag', 'editbox', 'callback', 'xycalibrate;');
    targetstring = cell(size(targetlist, 1), 1);
    for i = 1:size(targetlist, 1),
        targetstring{i} = sprintf('%i:  [%i     %i]', i, targetlist(i, 1), targetlist(i, 2));
    end
    targetstring{i+1} = 'Add...';
    set(h, 'string', targetstring, 'userdata', targetlist);
    
    ys2 = ys+3;
    uicontrol('style', 'frame', 'position', [20 ys2-347 210 70], 'backgroundcolor', bg);
    uicontrol('style', 'toggle', 'position', [45 ys2-290 160 23], 'string', 'No Reward', 'value', 0, 'tag', 'givereward', 'backgroundcolor', [.8 .6 .6], 'callback', 'xycalibrate;');
    uicontrol('style', 'text', 'position', [30 ys2-320 80 20], 'string', 'Pulse Duration', 'backgroundcolor', bg, 'horizontalalignment', 'left');
    pdur = [25 50 75 100 125 150 200 250 500 1000]';
    uicontrol('style', 'popupmenu', 'position', [105 ys2-320 50 25], 'string', num2str(pdur), 'userdata', pdur, 'backgroundcolor', [1 1 1], 'tag', 'pulseduration', 'value', 1, 'enable', 'off');
    uicontrol('style', 'text', 'position', [160 ys2-320 60 20], 'string', 'milliseconds', 'backgroundcolor', bg, 'horizontalalignment', 'left');
    pnum = [1 2 3 4 5]';
    uicontrol('style', 'text', 'position', [60 ys2-345 120 20], 'string', 'Number of Pulses', 'backgroundcolor', bg, 'horizontalalignment', 'left');
    uicontrol('style', 'popupmenu', 'position', [150 ys2-341 40 20], 'string', num2str(pnum), 'userdata', pnum, 'value', 3, 'backgroundcolor', [1 1 1], 'tag', 'numpulses', 'enable', 'off');
    
    uicontrol('style', 'text', 'position', [30 ys-370 120 18], 'string', 'N: Next Target', 'backgroundcolor', bg, 'horizontalalignment', 'left');
    uicontrol('style', 'text', 'position', [160 ys-370 80 18], 'string', 'P: Previous Target', 'backgroundcolor', bg, 'horizontalalignment', 'left');
    uicontrol('style', 'text', 'position', [30 ys-383 120 18], 'string', 'Space: Process Target', 'backgroundcolor', bg,'horizontalalignment', 'left');
    uicontrol('style', 'text', 'position', [160 ys-383 80 18], 'string', 'Q: Quit', 'backgroundcolor', bg, 'horizontalalignment', 'left');

    uicontrol('style', 'pushbutton', 'position', [50 ys-70 150 25], 'string', 'Exit', 'tag', 'savequit', 'callback', 'xycalibrate;', 'enable', 'on');
        
    rx = cpsize/xs;
    rxy = (xs+cpsize)/ys;
    subplot('position', [0.1*rx 0.1*rx 0.8*rx 0.8*rx*rxy]);
    set(gca, 'tag', 'matrix', 'box', 'on', 'xcolor', [1 1 1], 'ycolor', [1 1 1]);
    updategrid(cp, targetlist);
    
    if BasicData.EyeOrJoy == 1,
        CalibrationRewardSettings = get(findobj('tag', 'useraw'), 'userdata');
    else
        CalibrationRewardSettings = get(findobj('tag', 'userawjoy'), 'userdata');
    end
    if isfield(CalibrationRewardSettings, 'GiveReward'),
        if CalibrationRewardSettings.GiveReward,
            set(findobj(gcf, 'tag', 'givereward'), 'value', 1, 'backgroundcolor', [.6 .8 .6], 'string', 'Give Reward');
        end
        rewarddurlist = get(findobj(gcf, 'tag', 'pulseduration'), 'userdata');
        val = find(rewarddurlist == CalibrationRewardSettings.RewardDuration);
        if isempty(val),
            val = 1;
        end
        set(findobj(gcf, 'tag', 'pulseduration'), 'value', val, 'enable', 'on');
        numpulselist = get(findobj(gcf, 'tag', 'numpulses'), 'userdata');
        val = find(numpulselist == CalibrationRewardSettings.RewardNumber);
        if isempty(val),
            val = 1;
        end
        set(findobj(gcf, 'tag', 'numpulses'), 'value', val, 'enable', 'on');
    end
    
    if ScreenInfo.IsActive,
        mlvideo('showcursor', ScreenInfo.Device, 1);
    end

elseif ~isempty(varargin),
    
    if strcmp(varargin{1}, 'selectpoint'),
       
        set(gcf, 'CurrentAxes', findobj(gcf, 'tag', 'monitor'));
        hxdd = get(gca, 'xlim');
        hxd = max(hxdd);
        hydd = get(gca, 'ylim');
        hyd = max(hydd);
        xvals = floor(-hxd):ceil(hxd);
        yvals = floor(-hyd):ceil(hyd);
        vlines = line([xvals; xvals], [floor(-hyd)*ones(size(xvals)); ceil(hyd)*ones(size(xvals))]);
        hlines = line([floor(-hxd)*ones(size(yvals)); ceil(hxd)*ones(size(yvals))], [yvals; yvals]);
        set([hlines' vlines'], 'color', [0.4 0.4 0.4], 'hittest', 'off', 'linewidth', 1);
        
        rspace = 5;
        maxhref = rspace * (1+ceil(hxd/rspace));
        maxvref = rspace * (1+ceil(hyd/rspace));
        xvals = -maxhref:rspace:maxhref;
        yvals = -maxvref:rspace:maxvref;
        vref = line([xvals; xvals], [-maxhref*ones(size(maxhref)); maxhref*ones(size(maxhref))]);
        href = line([-maxvref*ones(size(maxvref)); maxvref*ones(size(maxvref))], [yvals; yvals]);
        set([href' vref'], 'color', [.8 .8 .8], 'linewidth', 1, 'hittest', 'off');
        
        v0 = line([0 0], [-hyd hyd]);
        h0 = line([-hxd hxd], [0 0]);
        set([h0 v0], 'color', [0.8 0.8 0.8], 'linewidth', 3, 'hittest', 'off');
        
        x = Inf; y = Inf;
        while x < hxdd(1) || x > hxdd(2) || y < hydd(1) || y > hydd(2),
            [x y] = ginput(1);
        end
        %fprintf('Compare: (%f,%f) to limits for x (%f - %f) and y (%f - %f)\n',x,y,hxdd(1),hxdd(2),hydd(1),hydd(2));
        
        h = plot(x, y, '.');
        set(h, 'markersize', 30, 'markerfacecolor', [.8 .5 .5], 'markeredgecolor', [.8 .5 .5]);
        thandle = findobj(gcf, 'tag', 'targetlist');
        tval = get(thandle, 'value');
        tlist = get(thandle, 'userdata');
        tstring = get(thandle, 'string');
        tlist(tval, 1:2) = [x y];
        tstring{tval} = sprintf('%i:  [%2.1f     %2.1f]', tval, x, y);
        if tval == length(tstring),
            tstring{tval+1} = 'Add...';
        end
        set(thandle, 'string', tstring, 'userdata', tlist, 'value', tval+1);
        updategrid(tlist, tlist);
        drawnow;
        pause(0.3);
        colfraction = 0.92;
        for i = 1:30,
            col = get(h, 'markeredgecolor');
            set(h, 'markeredgecolor', colfraction*col);
            col = get(hlines(1), 'color');
            set([hlines' vlines'], 'color', colfraction*col);
            col = get(href(1), 'color');
            set([href' vref'], 'color', colfraction*col);
            col = get(h0, 'color');
            set([h0 v0], 'color', colfraction*col);
            drawnow;
        end
        delete([h hlines' vlines' href' vref' h0 v0]);
        
    end
    
elseif ismember(gcbo, get(fig, 'children')),
    
    callertag = get(gcbo, 'tag');
    BasicData = get(gcf, 'userdata');
    DAQ = BasicData.IO;
    ScreenInfo = BasicData.ScreenInfo;
    cp = BasicData.ControlPoints;
    
    switch callertag,

        case 'startcal',
            
            maxduration = 600000; %continue in 60 seconds if no input
            u = get(gca, 'userdata');
            xs = u(1); %#ok<NASGU>
            ys = u(2); %#ok<NASGU>
            pixperdeg = u(3);
            
            xy = findobj(gcf,'tag', 'xy');
            tgt = findobj(gcf, 'tag', 'tgt');
            
            if isfield(DAQ, 'EyeX'), %i.e., DAQ is uninitialized
                resetDAQflag = 1;
                mlkbd('init');
                [DAQ DaqError] = initio(DAQ);
                if ~isempty(DaqError),
                    for i = 1:length(DaqErrror),
                        disp(DaqError{i})
                    end
                    error('*** I/O Initialization Error ***');
                end
                if BasicData.EyeOrJoy == 1,
                    if isempty(DAQ.EyeSignal),
                        error('*** No eye signal inputs defined ***');
                    end
                    xchan = DAQ.EyeSignal.XChannelIndex;
                    ychan = DAQ.EyeSignal.YChannelIndex;
                elseif BasicData.EyeOrJoy == 2,
                    if isempty(DAQ.Joystick),
                        error('*** No joystick inputs defined ***');
                    end
                    xchan = DAQ.Joystick.XChannelIndex;
                    ychan = DAQ.Joystick.YChannelIndex;
                end
            else
                resetDAQflag = 0;
                if BasicData.EyeOrJoy == 1,
                    xchan = DAQ.EyeSignal.XChannelIndex;
                    ychan = DAQ.EyeSignal.YChannelIndex;
                elseif BasicData.EyeOrJoy == 2,
                    xchan = DAQ.Joystick.XChannelIndex;
                    ychan = DAQ.Joystick.YChannelIndex;
                end
            end
            ms_to_take = 250;
            ms_to_use = 100; %when user presses space, take -250:-150 ms of data
            samples_to_take = round(DAQ.AnalogInput.SampleRate * ms_to_take/1000);
            samples_to_use = round(DAQ.AnalogInput.SampleRate * ms_to_use/1000);
            
            if ~ScreenInfo.IsActive, %initialize I/O and Video
                try
                    mlvideo('init');
                    mlvideo('initdevice', ScreenInfo.Device);
                    mlvideo('setmode', ScreenInfo.Device, ScreenInfo.Xsize, ScreenInfo.Ysize, ScreenInfo.BytesPerPixel, ScreenInfo.RefreshRate, ScreenInfo.BufferPages);
                    pause(1);
                    mlvideo('clear', ScreenInfo.Device, ScreenInfo.BackgroundColor);
                    mlvideo('flip', ScreenInfo.Device);
                    mlvideo('showcursor', ScreenInfo.Device, 0);
                    
                catch %#ok<CTCH>
                    mlvideo('showcursor', ScreenInfo.Device, 1);
                    mlvideo('restoremode', ScreenInfo.Device)
                    mlvideo('releasedevice', ScreenInfo.Device);
                    mlvideo('release');
                    
                    disp('*** Error initializing Video ***')
                    lasterr %#ok<LERR>
                    return
                end
            end
            
            disable_cursor;
            %create fixation spot:
            fixspot = BasicData.FixSpot;
            modval = 16;
            [fixspot xis yis xisbuf yisbuf] = pad_image(fixspot, modval);
            FixBuffer = mlvideo('createbuffer', ScreenInfo.Device, xisbuf, yisbuf, ScreenInfo.BytesPerPixel);
            mlvideo('copybuffer', ScreenInfo.Device, FixBuffer, fixspot);
            FixXsize = xis;
            FixYsize = yis;
            
            set(gcf, 'CurrentAxes', findobj('tag', 'monitor'));
            targetlist = get(findobj(gcf, 'tag', 'targetlist'), 'userdata');
            numtargets = size(targetlist, 1);
            
            if isempty(BasicData.SigTransform),
                SigTransform = updategrid(cp, targetlist);
            else
                SigTransform = BasicData.SigTransform;
            end
            
            quitflag = 0;
            i = 1;
                        
            givereward = get(findobj('tag', 'givereward'), 'value');
            if givereward,
                if isempty(DAQ.AnalogOutput) && isempty(DAQ.Reward),
                    givereward = 0;
                    set(findobj('tag', 'givereward'), 'value', 0);
                    disp('*** Warning: No reward output identified ***')
                else
                    rewarddurlist = get(findobj(gcf, 'tag', 'pulseduration'), 'userdata');
                    rewardduration = rewarddurlist(get(findobj(gcf, 'tag', 'pulseduration'), 'value'));
                    numpulselist = get(findobj(gcf, 'tag', 'numpulses'), 'userdata');
                    numreward = numpulselist(get(findobj(gcf, 'tag', 'numpulses'), 'value'));
                    pausetime = 50;
                    if strcmpi(DAQ.Reward.Subsystem, 'analog'),
                        rewardtype = 1;
                        triggervolts = 5;
                        ao_channels = DAQ.AnalogOutput.Channel.Index;
                        reward_off = zeros(size(ao_channels))';
                        rewardindex = DAQ.Reward.ChannelIndex;
                        if BasicData.IO.Reward.Polarity == -1,
                            triggervolts = 0;
                            reward_off = reward_off+5;
                        end
                        reward_on = reward_off;
                        reward_on(rewardindex) = triggervolts;
                    else %digital
                        rewardtype = 2;
                    end
                end
            end
            
            if isempty(findobj(gcf, 'tag', 'xytxt')),
                %xlim = get(gca, 'xlim');
                ylim = get(gca, 'ylim');
                h = text(0, 0.9*min(ylim), 'Last Input: X= ---- V   Y= ---- V');
                set(h, 'fontname', 'courier', 'fontsize', 12, 'color', [0.5 1 0.5], 'tag', 'xytxt');
            end
            
            start(DAQ.AnalogInput);
            while ~DAQ.AnalogInput.SamplesAvailable, end
            
            while quitflag == 0,
                
                set(findobj(gcf, 'tag', 'targetlist'), 'value', i);
                
                xfix = targetlist(i, 1);
                yfix = targetlist(i, 2);
                set(tgt, 'xdata', xfix, 'ydata', yfix);
                            
                xp = round((ScreenInfo.Xsize/2) + (xfix*pixperdeg)) - FixXsize/2;
                yp = round((ScreenInfo.Ysize/2) - (yfix*pixperdeg)) - FixYsize/2;
                mlvideo('clear', ScreenInfo.Device, ScreenInfo.BackgroundColor);
                mlvideo('blit', ScreenInfo.Device, FixBuffer, xp, yp, FixXsize, FixYsize);
                mlvideo('flip', ScreenInfo.Device);
                dotison = 1;

                tic;
                t2 = 0;
                while t2 < maxduration,
                    data = getsample(DAQ.AnalogInput);
                    xv = data(xchan);
                    yv = data(ychan);
                    [xp yp] = tformfwd(SigTransform, xv, yv);
                    set(xy, 'xdata', xp, 'ydata', yp);
                    drawnow;
                    t2 = toc*1000;
                    kb = mlkbd('getkey');
                    if ~isempty(kb),
                        maxduration = maxduration + t2;
                        if kb == 57 && dotison, %space: process target
                            samplesavailable = DAQ.AnalogInput.SamplesAvailable;
                            if samplesavailable,
                                data = getdata(DAQ.AnalogInput, DAQ.AnalogInput.SamplesAvailable);
                                [numsamples numchans] = size(data);
                                if numsamples < samples_to_take,
                                    data = cat(1, NaN*zeros(samples_to_take - numsamples, numchans), data);
                                end
                                firstsample = numsamples - samples_to_take;
                                lastsample = firstsample + samples_to_use;
                                xv = data(firstsample:lastsample, xchan);
                                yv = data(firstsample:lastsample, ychan);
                                xv = nanmean(xv);
                                yv = nanmean(yv);
                                cp(i, 1:2) = [xv yv];
                                SigTransform = updategrid(cp, targetlist);
                                [xp yp] = tformfwd(SigTransform, xv, yv);
                                set(xy, 'xdata', xp, 'ydata', yp, 'markerfacecolor', [1 .3 .3]);
                                xystr = sprintf('Last Input: X= %2.1f V   Y= %2.1f V', xv, yv);
                                set(findobj(gcf, 'tag', 'xytxt'), 'string', xystr);
                                drawnow;
                                if givereward,
                                    for nreward = 1:numreward,
                                        if rewardtype == 1,
                                            putsample(DAQ.AnalogOutput, reward_on);
                                        else
                                            putvalue(DAQ.Reward.DIO, 1);
                                        end
                                        rt1 = toc*1000;
                                        rt2 = rt1;
                                        while rt2-rt1 < rewardduration,
                                            rt2 = toc*1000;
                                        end
                                        if rewardtype == 1,
                                            putsample(DAQ.AnalogOutput, reward_off);
                                        else
                                            putvalue(DAQ.Reward.DIO, 0);
                                        end
                                        if nreward < numreward, %add gaps only between rewards
                                            rt1 = toc*1000;
                                            rt2 = rt1;
                                            while rt2-rt1 < pausetime,
                                                rt2 = toc*1000;
                                            end
                                        end
                                    end
                                end
                            else
                                disp('No data available... Must re-try')
                            end
                            mlvideo('clear', ScreenInfo.Device, ScreenInfo.BackgroundColor);
                            mlvideo('flip', ScreenInfo.Device);
                            dotison = 0;
                            pause(0.25);
                            set(xy, 'markerfacecolor', [0.5 0.5 0.5]);
                            set(tgt, 'xdata', ScreenInfo.OutOfBounds, 'ydata', ScreenInfo.OutOfBounds);
                        elseif kb == 25, %p for previous
                            t2 = maxduration;
                            i = i - 1;
                            if i < 1,
                                i = numtargets;
                            end
                        elseif kb == 49, %n for next
                            t2 = maxduration;
                            i = i + 1;
                            if i > numtargets,
                                i = 1;
                            end
                        elseif kb == 16 || kb == 1, %esc or q for quit
                            stop(DAQ.AnalogInput);
                            quitflag = 1;
                            t2 = maxduration;
                        end
                    end
                end
            end

            BasicData.SigTransform = SigTransform;
            BasicData.ControlPoints = cp;
            set(gcf, 'userdata', BasicData);
            set(findobj(gcf, 'tag', 'savequit'), 'backgroundcolor', [0.5 0.8 0.5], 'string', 'Save and Exit', 'enable', 'on');

            if resetDAQflag,
                mlkbd('release');
                delete(DAQ.AnalogInput);
                clear DAQ
                daqreset;
            end

            if ~ScreenInfo.IsActive,
                mlvideo('releasebuffer', ScreenInfo.Device, FixBuffer);
                mlvideo('showcursor', ScreenInfo.Device, 1);
                mlvideo('restoremode', ScreenInfo.Device);
                mlvideo('releasedevice', ScreenInfo.Device);
                mlvideo('release');
                
            end
            enable_cursor;

        case 'ttype',



            %         case 'targetlist',
            %
            %             tval = get(gcbo, 'value');
            %             tstring = get(gcbo, 'string');
            %
            %             if tval == length(tstring),
            %                 t_item = '[  ]';
            %             else
            %                 t_item = tstring{tval};
            %                 cln = find(t_item == ':');
            %                 t_item = t_item((cln+1):length(t_item));
            %             end
            %             set(findobj(gcf, 'tag', 'editbox'), 'string', t_item, 'userdata', t_item);

        case 'givereward',

            if get(gcbo, 'value'),
                set(gcbo, 'backgroundcolor', [.6 .8 .6], 'string', 'Give Reward');
                set(findobj(gcf, 'tag', 'numpulses'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'pulseduration'), 'enable', 'on');
            else
                set(gcbo, 'backgroundcolor', [.8 .6 .6], 'string', 'No Reward');
                set(findobj(gcf, 'tag', 'numpulses'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'pulseduration'), 'enable', 'off');
            end

        case 'targetlist',

            targetlist = get(gcbo, 'userdata');
            tval = get(findobj(gcf, 'tag', 'targetlist'), 'value');
            if tval <= length(targetlist),
                coords = targetlist(tval, :);
                set(findobj(gcf, 'tag', 'editbox'), 'userdata', coords, 'string', ['[ ' num2str(coords) ' ]']);
            end
            
        case 'editbox',

            targetlist = get(findobj(gcf, 'tag', 'targetlist'), 'userdata');
            tstring = get(findobj(gcf, 'tag', 'targetlist'), 'string');
            tval = get(findobj(gcf, 'tag', 'targetlist'), 'value');
            t_item = get(gcbo, 'string');
            numtargets = size(targetlist, 1);

            if isempty(t_item) && tval < length(tstring) && numtargets > 4,
                targetlist = targetlist(1:numtargets ~= tval, :);
                numtargets = size(targetlist, 1);
                for i = 1:numtargets,
                    tstring{i} = sprintf('%i:  [%2.1f     %2.1f]', i, targetlist(i, 1), targetlist(i, 2));
                end
                tstring{i+1} = 'Add...';
                tstring = tstring(1:i+1);
                set(findobj(gcf, 'tag', 'targetlist'), 'string', tstring, 'userdata', targetlist);
                return
            elseif isempty(t_item) && tval == length(tstring),
                return
            end
            
            if tval < length(tstring),
                oldcoords = targetlist(tval, :);
                set(gcbo, 'userdata', oldcoords);
            end
            coords = str2num(t_item); %#ok<ST2NM>
            if length(coords) == 1,
                coords = [coords coords];
            elseif isempty(coords) || length(coords) > 2,
                set(gcbo, 'string', ['[ ' num2str(get(gcbo, 'userdata')) ' ]']);
                return
            end

            set(gcbo, 'string', ['[ ' num2str(coords) ' ]']);
            if tval == length(tstring),
                tstring{tval+1} = 'Add...';
            end
            targetlist(tval, 1:2) = coords;
            tstring{tval} = sprintf('%i:  [%i     %i]', tval, targetlist(tval, 1), targetlist(tval, 2));

            set(findobj(gcf, 'tag', 'targetlist'), 'string', tstring, 'userdata', targetlist);
            set(gcbo, 'userdata', t_item);
            BasicData = get(gcf, 'userdata');
            BasicData.ControlPoints = targetlist;
            set(gcf, 'userdata', BasicData);
            updategrid(targetlist, targetlist);

        case 'savequit',

            BasicData = get(gcf, 'userdata');
            SigTransform = BasicData.SigTransform;
            if ~isempty(SigTransform),
                targetlist = get(findobj(gcf, 'tag', 'targetlist'), 'userdata');
                rewarddurlist = get(findobj(gcf, 'tag', 'pulseduration'), 'userdata');
                rewardduration = rewarddurlist(get(findobj(gcf, 'tag', 'pulseduration'), 'value'));
                numpulselist = get(findobj(gcf, 'tag', 'numpulses'), 'userdata');
                numreward = numpulselist(get(findobj(gcf, 'tag', 'numpulses'), 'value'));
                RewardCalibrationSettings.GiveReward = get(findobj('tag', 'givereward'), 'value');
                RewardCalibrationSettings.RewardDuration = rewardduration;
                RewardCalibrationSettings.RewardNumber = numreward;
                if BasicData.EyeOrJoy == 1,
                    set(findobj('tag', 'calbutton'), 'userdata', SigTransform, 'foregroundcolor', [0 0.5 0]);
                    set(findobj('tag', 'eyecaltext'), 'userdata', targetlist);
                    set(findobj('tag', 'useraw'), 'value', 0, 'userdata', RewardCalibrationSettings);
                    set(findobj('tag', 'savebutton'), 'enable', 'on');
                elseif BasicData.EyeOrJoy == 2,
                    set(findobj('tag', 'joycalbutton'), 'userdata', SigTransform, 'foregroundcolor', [0 0.5 0]);
                    set(findobj('tag', 'joycaltext'), 'userdata', targetlist);
                    set(findobj('tag', 'userawjoy'), 'value', 0, 'userdata', RewardCalibrationSettings);
                    set(findobj('tag', 'savebutton'), 'enable', 'on');
                end
            end
            close(gcf);

    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tform = updategrid(cp, targetlist)

set(gcf, 'CurrentAxes', findobj('tag', 'matrix'));
cla;
numtargets = size(targetlist, 1);
maxtick = max(max(abs(targetlist)));
xticks = -maxtick:maxtick;
[X Y] = meshgrid(xticks);
tval = get(findobj(gcf, 'tag', 'ttype'), 'value');
tstring = get(findobj(gcf, 'tag', 'ttype'), 'string');
ttype = tstring{tval};
if tval == 3, %polynomial
    if numtargets >= 12,
        porder = 4;
    elseif numtargets == 10 || numtargets == 11,
        porder = 3;
    elseif numtargets >= 6 && numtargets < 10,
        porder = 2;
    else
        set(findobj('tag', 'ttype'), 'value', 2);
        ttype = 'projective';
        porder = [];
        disp('*** Warning: Not enough target points for polynomial fit ***');
    end
    if ~isempty(porder),
        tform = cp2tform(cp, targetlist, ttype, porder);
    else
        tform = cp2tform(cp, targetlist, ttype);
    end
    if isempty(tform.forward_fcn),
        tform.forward_fcn = tform.inverse_fcn;
    end
else
    tform = cp2tform(cp, targetlist, ttype);
end
[xm ym] = tformfwd(tform, X, Y);
hline = plot(xm, ym);
hold on;
hline2 = plot(xm', ym');
hline3 = plot(xm, ym, '.');
hline = cat(1, hline, hline2, hline3);
set(hline, 'color', [1 1 1]);
h = plot(cp(:, 1), cp(:, 2), 'r.');
set(h, 'markersize', 15);
set(gca, 'color', [0 0 0], 'xtick', [], 'ytick', [], 'tag', 'matrix');
drawnow;
set(gcf, 'CurrentAxes', findobj('tag', 'monitor'));

function disable_cursor
global MLHELPER_OFF
if MLHELPER_OFF,
    return
end
thisfig = get(0,'CurrentFigure');
if ~isempty(thisfig)
    set(thisfig,'PointerShapeCData',nan(16));
    set(thisfig,'Pointer','custom');
end
dirs = getpref('MonkeyLogic', 'Directories');
system(sprintf('%smlhelper --cursor-disable',dirs.BaseDirectory));

function enable_cursor
global MLHELPER_OFF
if MLHELPER_OFF,
    return
end
thisfig = get(0,'CurrentFigure');
if ~isempty(thisfig)
    set(thisfig,'Pointer','arrow');
end
dirs = getpref('MonkeyLogic', 'Directories');
system(sprintf('%smlhelper --cursor-enable',dirs.BaseDirectory));