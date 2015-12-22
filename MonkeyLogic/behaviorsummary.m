function behaviorsummary(varargin)
%SYNTAX:
%        behaviorsummary
%    or
%        behaviorsummary(datafile)
%
% Plots behavioral summary.  Datafile is optional.
%
% Original behaviorgraph by WA, 9/06
% Overhauled into behaviorsummary 9/21/07 --WA
% Modified 7/25/08 -WA (fixed behaviorgraph for small trial numbers)
% Modified 8/16/08 -WA (added playback of movie and translating stimuli)
% Modified 9/13/08 -WA (fixed aspect ratio problem with wide-screen
% displays)

f = findobj('tag', 'BehaviorSummary');
localcallback = 0;
if ~isempty(f),
    set(0, 'CurrentFigure', f);
    localcallback = ~isempty(gcbo) && (ismember(gcbo, get(gcf, 'children')) || ismember(gcbo, get(gca, 'children')));
end

if ~localcallback,
    if ~ispref('MonkeyLogic', 'Directories'),
        success = set_ml_directories;
        if ~success,
            return
        end
    end
    MLPrefs.Directories = getpref('MonkeyLogic', 'Directories');
    if isempty(varargin),
        [fname pname] =  uigetfile([MLPrefs.Directories.ExperimentDirectory '*.bhv'], 'Choose BHV file');
        if fname(1) == 0,
            return
        end
        inputfile = [pname fname];
    else
        inputfile = varargin{1};
        if strcmp(inputfile, 'CurrentFile'),
            mlmainmenu = findobj('tag', 'monkeylogicmainmenu');
            if isempty(mlmainmenu),
                return
            end
            inputfile = get(findobj(mlmainmenu, 'tag', 'datafile'), 'userdata');
            if ~exist(inputfile, 'file'),
                return
            end
        end
        if isempty(inputfile == filesep),
            inputfile = [MLPrefs.Directories.ExperimentDirectory inputfile];
        end
    end

    pname = fileparts(inputfile);
    MLPrefs.Directories.ExperimentDirectory = [pname filesep];
    setpref('MonkeyLogic', 'Directories', MLPrefs.Directories);

    f = findobj('name', 'Behavior Summary');
    for i = 1:length(f),
        bhv = get(f(i), 'userdata');
        if strcmp(fname, bhv.DataFileName),
            set(0, 'CurrentFigure', f(i));
            return
        end
    end

    bhv = bhv_read(inputfile);

    figure
    figbg = [.65 .70 .80];
    scrnsz = get(0, 'screensize');
    xfig = scrnsz(3)-50;
    xleft = (scrnsz(3)-xfig)/2;
    yfig = 750;
    ybottom = (scrnsz(4)-yfig)/2;
    set(gcf, 'color', figbg, 'position', [xleft ybottom xfig yfig], 'numbertitle', 'off', 'name', 'Behavior Summary', 'menubar', 'none', 'userdata', bhv, 'tag', 'BehaviorSummary');

    embedded_behaviorgraph(bhv);

    xbase = 40;
    xw = 455;
    ybase = 30;
    ymax = 320;
    textspacing = 22;
    fbg = 0.8*figbg;
    uicontrol('style', 'frame', 'position', [xbase ybase xw ymax], 'backgroundcolor', fbg, 'foregroundcolor', 0.6*figbg);
    h(1) = uicontrol('style', 'text', 'position', [xbase+2 ybase+ymax-(1*textspacing)-5 xw-4 18], 'string', sprintf('Experiment: %s   Subject: %s', bhv.ExperimentName, bhv.SubjectName));
    h(2) = uicontrol('style', 'text', 'position', [xbase+2 ybase+ymax-(2*textspacing)-5 xw-4 18], 'string', sprintf('Created on %s', bhv.StartTime));
    filedur = datevec(datenum(bhv.FinishTime) - datenum(bhv.StartTime));
    filehrs = filedur(4);
    filemns = filedur(5);
    filesec = filedur(6);
    if filehrs == 1,
        hstr = 'hour';
    else
        hstr = 'hours';
    end
    if filemns == 1,
        mstr = 'minute';
    else
        mstr = 'minutes';
    end
    if filesec == 1,
        sstr = 'second';
    else
        sstr = 'seconds';
    end
    h(3) = uicontrol('style', 'text', 'position', [xbase+2 ybase+ymax-(3*textspacing)-5 xw-4 18], 'string', sprintf('Ran %i total trials over %2.0f %s %2.0f %s %2.0f %s', length(bhv.TrialNumber), filehrs, hstr, filemns, mstr, filesec, sstr));
    numblocks = sum(abs(diff(bhv.BlockNumber)) > 0)+1;
    if numblocks > 1,
        h(4) = uicontrol('style', 'text', 'position', [xbase+2 ybase+ymax-(4*textspacing)-5 xw-4 18], 'string', sprintf('Completed %i correct trials over %i blocks', sum(bhv.TrialError == 0), numblocks));
    else
        h(4) = uicontrol('style', 'text', 'position', [xbase+2 ybase+ymax-(4*textspacing)-5 xw-4 18], 'string', sprintf('Completed %i correct trials over %i block', sum(bhv.TrialError == 0), numblocks));
    end
    set(h, 'backgroundcolor', fbg, 'foregroundcolor', [1 1 1], 'horizontalalignment', 'center', 'fontsize', 10);

    ybase = ybase + 53;
    uicontrol('style', 'listbox', 'position', [xbase+10 ybase+10 55 150], 'tag', 'trialselector', 'string', num2str(bhv.TrialNumber), 'value', 1, 'backgroundcolor', [1 1 1], 'callback', 'behaviorsummary');
    uicontrol('style', 'frame', 'position', [xbase+75 ybase+10 180 150], 'backgroundcolor', [1 1 1]);
    uicontrol('style', 'text', 'position', [xbase+85 ybase+130 100 18], 'string', 'Condition Number:', 'backgroundcolor', [1 1 1], 'horizontalalignment', 'right');
    uicontrol('style', 'text', 'position', [xbase+185 ybase+130 50 18], 'string', '', 'tag', 'condnumberbox', 'fontweight', 'bold', 'backgroundcolor', [1 1 1]);
    uicontrol('style', 'text', 'position', [xbase+85 ybase+110 100 18], 'string', 'Block Number:', 'backgroundcolor', [1 1 1], 'horizontalalignment', 'right');
    uicontrol('style', 'text', 'position', [xbase+185 ybase+110 50 18], 'string', '', 'tag', 'blocknumberbox', 'fontweight', 'bold', 'backgroundcolor', [1 1 1]);
    uicontrol('style', 'text', 'position', [xbase+115 ybase+85 100 18], 'string', 'Trial Error', 'backgroundcolor', [1 1 1], 'horizontalalignment', 'center');
    uicontrol('style', 'frame', 'position', [xbase+100 ybase+62 135 25], 'tag', 'trialerrorframe', 'backgroundcolor', [.3 .3 .3]);
    uicontrol('style', 'text', 'position', [xbase+105 ybase+64 125 18], 'string', '', 'tag', 'trialerrorbox', 'backgroundcolor', [.3 .3 .3], 'foregroundcolor', [1 1 1], 'fontweight', 'bold');
    uicontrol('style', 'text', 'position', [xbase+85 ybase+33 100 18], 'string', 'Reaction Time:', 'backgroundcolor', [1 1 1], 'horizontalalignment', 'center');
    uicontrol('style', 'text', 'position', [xbase+185 ybase+33 50 18], 'string', '', 'tag', 'reactiontimebox', 'fontweight', 'bold', 'backgroundcolor', [1 1 1]);
    uicontrol('style', 'listbox', 'position', [xbase+265 ybase+10 180 150], 'string', '', 'tag', 'codesbox', 'backgroundcolor', [1 1 1], 'max', 5);
    uicontrol('style', 'pushbutton', 'position', [xbase+40 ybase-40 100 30], 'string', 'Timeline', 'tag', 'timelinebutton', 'callback', 'behaviorsummary');
    uicontrol('style', 'toggle', 'position', [xbase+470 ybase-70 130 30], 'string', 'Play at Full Resolution', 'tag', 'fullrestoggle', 'callback', 'behaviorsummary', 'backgroundcolor', [.7 .5 .5], 'value', 0);
    uicontrol('style', 'toggle', 'position', [xbase+618 ybase-70 130 30], 'string', 'Make AVI Movie', 'tag', 'makemovie', 'callback', 'behaviorsummary', 'backgroundcolor', [.7 .5 .5], 'value', 0);
    uicontrol('style', 'frame', 'position', [xbase+760 ybase-70 85, 30], 'backgroundcolor', figbg);
    uicontrol('style', 'text', 'position', [xbase+763 ybase-68 30 20], 'string', 'FPS', 'backgroundcolor', figbg, 'fontsize', 10, 'fontweight', 'bold');
    uicontrol('style', 'edit', 'position', [xbase+798 ybase-65 40 20], 'string', '25', 'userdata', 25, 'tag', 'fps', 'callback', 'behaviorsummary', 'backgroundcolor', [1 1 1], 'enable', 'off');

    h = uicontrol('style', 'pushbutton', 'position', [xbase+165 ybase-40 100 30], 'string', 'Play', 'tag', 'playcondition', 'callback', 'behaviorsummary');
    numloops = 1000000;
    tic
    for i = 1:numloops, end;
    t = toc;
    maxval = ceil(numloops * (.005/t));
    minval = ceil(maxval / 10);
    initval = 0.75*maxval;
    h(2) = uicontrol('style', 'slider', 'position', [xbase+285 ybase-40 140 22], 'tag', 'speedslider', 'min', minval, 'max', maxval, 'value', initval, 'backgroundcolor', [1 1 1]);
    uicontrol('style', 'text', 'position', [xbase+285 ybase-20 140 20], 'string', 'Playback Speed', 'horizontalalignment', 'center', 'foregroundcolor', [1 1 1], 'fontsize', 10, 'backgroundcolor', fbg);
    if ~isfield(bhv, 'ObjectStatusRecord') || isempty(bhv.ObjectStatusRecord),
        set(h, 'enable', 'off');
    end

    gleft = (xbase+xw)/xfig;
    gw = 1-gleft;
    gypix = 0.4*yfig;
    gxpix = (4*gypix)/3;
    gax = gxpix/xfig;
    gbx = 0.85*(gw-gax);
    subplot('position', [1.02*gleft 0.065 .95*gax .4]);
    xlim = 0.5*bhv.ScreenXresolution/bhv.PixelsPerDegree;
    ylim = 0.5*bhv.ScreenYresolution/bhv.PixelsPerDegree;
    if xlim >= ylim,
        ylim = (3/4)*xlim;
    else
        xlim = (4/3)*ylim;
    end
    if isfield(bhv, 'ScreenBackgroundColor'),
        sbc = bhv.ScreenBackgroundColor;
    else
        sbc = [0 0 0];
    end
    set(gca, 'color', sbc, 'tag', 'screenrepresentation', 'xtick', [], 'ytick', [], 'xlim', [-xlim xlim], 'ylim', [-ylim ylim], 'nextplot', 'add', 'drawmode', 'fast');

    subplot('position', [1.05*(gleft+gax) 0.065 gbx .4]);
    set(gca, 'box', 'on', 'tag', 'rtgraph', 'color', fbg, 'nextplot', 'add');
    embedded_rtgraph(bhv);

    update_trialdata(1, bhv);
else
    bhv = get(gcf, 'userdata');
    switch get(gcbo, 'tag'),
        case 'trialselector',
            update_trialdata(get(gcbo, 'value'), bhv);

        case 'behaviorpatch',
            trial = get(gca, 'currentpoint');
            trial = round(trial(1));
            update_trialdata(trial, bhv);
            set(findobj(gcf, 'tag', 'trialselector'), 'value', trial);

        case 'playcondition',
            bhvfig = gcf;
            usebiggerscreen = get(findobj(gcf, 'tag', 'fullrestoggle'), 'value');

            makemovie = get(findobj(gcf, 'tag', 'makemovie'), 'value');
            if makemovie,
                fps = get(findobj(gcf, 'tag', 'fps'), 'userdata');
                interframeinterval = round(1000/fps);
                mcount = 0;
                d = getpref('MonkeyLogic', 'Directories');
                fname = sprintf('%s%s Movie.avi', d.ExperimentDirectory, bhv.ExperimentName);
                [fname pname] = uiputfile(fname, 'Choose AVI File to Write...');
                if ~fname,
                    return
                end
                if ~strcmp(pname(length(pname)), filesep),
                    pname = [pname filesep];
                end
                moviefilename = [pname fname];
            end

            hinvisible = get(findobj(bhvfig, 'tag', 'behaviorovertime'), 'children');
            set(hinvisible, 'visible', 'off');
            trial = get(findobj(bhvfig, 'tag', 'trialselector'), 'value');
            set(gcf, 'CurrentAxes', findobj(bhvfig, 'tag', 'screenrepresentation'));
            hobject = get(gca, 'userdata');
            set(hobject, 'visible', 'off');
            delete(findobj(gca, 'tag', 'eyetrace'));
            delete(findobj(gca, 'tag', 'joytrace'));
            ct = bhv.CodeTimes{trial};
            obstat = bhv.ObjectStatusRecord(trial);
            adata = bhv.AnalogData{trial};
            if isfield(adata, 'EyeSignal'),
                eyex = adata.EyeSignal(:, 1);
                eyey = adata.EyeSignal(:, 2);
                numeyepoints = length(eyex);
            else
                eyex = [];
                eyey = [];
                numeyepoints = 0;
            end
            if isfield(adata, 'Joystick'),
                joyx = adata.Joystick(:, 1);
                joyy = adata.Joystick(:, 2);
                numjoypoints = length(joyx);
            else
                joyx = [];
                joyy = [];
                numjoypoints = 0;
            end

            if isfield(adata, 'TouchSignal'),
                touchx = adata.TouchSignal(:, 1);
                touchy = adata.TouchSignal(:, 2);
                numtouchpoints = length(touchx);
            else
                touchx = [];
                touchy = [];
                numtouchpoints = 0;
            end
            
            if isfield(adata, 'MouseSignal'),
                mousex = adata.MouseSignal(:, 1);
                mousey = adata.MouseSignal(:, 2);
                nummousepoints = length(mousex);
            else
                mousex = [];
                mousey = [];
                nummousepoints = 0;
            end

            if isfield(bhv, 'AnalogInputFrequency') && bhv.AnalogInputFrequency ~= 1000,
                ystep = 1000/bhv.AnalogInputFrequency;
                if numeyepoints,
                    totalms = round(numeyepoints*ystep);
                    yi = 1:ystep:2*ystep*numeyepoints;
                    yi = yi(1:numeyepoints);
                    eyex = interp1(eyex, yi, 1:totalms);
                    eyey = interp1(eyey, yi, 1:totalms);
                end
                if numjoypoints,
                    totalms = round(numjoypoints*ystep);
                    yi = 1:ystep:2*ystep*numeyepoints;
                    yi = yi(1:numjoypoints);
                    joyx = interp1(joyx, yi, 1:totalms);
                    joyy = interp1(joyy, yi, 1:totalms);
                end
            end

            if isfield(bhv, 'EyeTraceColor'),
                eyecolor = bhv.EyeTraceColor;
            else
                eyecolor = [.8 .8 .5];
            end
            if isfield(bhv, 'JoyTraceColor'),
                joycolor = bhv.JoyTraceColor;
            else
                joycolor = [.8 .5 .5];
            end

            maxadata = max([numeyepoints numjoypoints]);
            maxtime = max([max(ct) max(obstat.Time)]);
            if maxadata < maxtime,
                dd = maxtime - maxadata;
                eyex = cat(1, eyex, NaN*ones(dd, 1));
                eyey = cat(1, eyey, NaN*ones(dd, 1));
                joyx = cat(1, joyx, NaN*ones(dd, 1));
                joyy = cat(1, joyy, NaN*ones(dd, 1));
            elseif maxadata > maxtime,
                maxtime = maxadata;
            end
            if length(joyx) < length(eyex),
                joyx = cat(1, joyx, NaN*ones(length(eyex), 1));
                joyy = cat(1, joyy, NaN*ones(length(eyex), 1));
            elseif length(joyx) > length(eyex),
                eyex = cat(1, eyex, NaN*ones(length(joyx), 1));
                eyey = cat(1, eyey, NaN*ones(length(joyx), 1));
            end

            if isfield(bhv, 'RewardRecord') && ~isempty(bhv.RewardRecord),
                rstat = bhv.RewardRecord(trial);
            else
                rstat.RewardOnTime = -1;
                rstat.RewardOffTime = -1;
            end

            ylim = get(gca, 'ylim');
            xlim = get(gca, 'xlim');

            %             showelapsedtime = 1;
            %             if showelapsedtime,
            %                 het = text(0, min(ylim) + 0.5, '0');
            %                 set(het, 'horizontalalignment', 'center', 'fontsize', 14, 'color', [.5 .5 .5], 'tag', 'elapsedtime');
            %             end

            if usebiggerscreen,
                hlist = get(gca, 'children');
                b = get(0, 'screensize');
                xs = bhv.ScreenXresolution;
                ys = bhv.ScreenYresolution;
                soffsetx = round((b(3)-xs)/2);
                soffsety = round((b(4)-ys)/2);
                if soffsetx < 1,
                    soffsetx = 1;
                end
                if soffsety < 1,
                    soffsety = 1;
                end
                ffig = findobj('tag', 'mlbiggerscreenfig');
                if isempty(ffig),
                    figure
                    set(gcf, 'position', [soffsetx soffsety b(3)-(2*soffsetx) b(4)-(2*soffsety)], 'color', [.3 .3 .3], 'tag', 'mlbiggerscreenfig', 'menubar', 'none', 'numbertitle', 'off', 'name', sprintf('Playing Trial #%i', trial));
                else
                    set(0, 'CurrentFigure', 'ffig');
                end
                hax = axes;
                set(hax, 'nextplot', 'add', 'box', 'on', 'color', [0 0 0], 'xlim', xlim, 'ylim', ylim, 'xtick', [], 'ytick', [], 'position', [0 0 1 1]);
                hobject = copyobj(hlist, hax);
                %                 het = findobj(gcf, 'tag', 'elapsedtime');
            end

            rewardindicator = text(0, 0.8*ylim(1), 'Reward');
            set(rewardindicator, 'color', [0 1 0], 'fontsize', 12, 'fontweight', 'bold', 'horizontalalignment', 'center', 'visible', 'off');

            heye = plot(0, 0, '.');
            hjoy = plot(0, 0, '.');
            set(heye, 'markerfacecolor', eyecolor, 'markeredgecolor', eyecolor, 'markersize', 15);
            set(hjoy, 'markerfacecolor', joycolor, 'markeredgecolor', joycolor, 'markersize', 15);
            skipnum = 20;
            hspeed = findobj(bhvfig, 'tag', 'speedslider');
            idlesteps = get(hspeed, 'max') - get(hspeed, 'value');

            codesbox = findobj(bhvfig, 'tag', 'codesbox');
            codetimes = get(codesbox, 'userdata');
            codeselection = get(codesbox, 'value');
            mintime = codetimes(codeselection(1)) - 100;
            mintime = max([mintime 1]);
            fcount = 0;
            for t = mintime:maxtime,
                fcount = fcount + 1;
                if t/skipnum == round(t/skipnum),
                    set(heye, 'xdata', eyex(t), 'ydata', eyey(t));
                    set(hjoy, 'xdata', joyx(t), 'ydata', joyy(t));
                end
                statmatch = any(obstat.Time == t);
                if statmatch,
                    f = find(obstat.Time == t);
                    for fcount = 1:length(f),
                        ff = f(fcount);
                        stat = obstat.Status{ff};
                        for itemnumber = 1:length(stat),
                            if stat(itemnumber) == 0,
                                set(hobject(itemnumber), 'visible', 'off');
                            elseif stat(itemnumber) == 1,
                                set(hobject(itemnumber), 'visible', 'on');
                            elseif stat(itemnumber) == 2, %reposition object
                                xpos = obstat.Data{ff}(1);
                                ypos = obstat.Data{ff}(2);
                                imdata = get(hobject(itemnumber), 'cdata');
                                ysize = size(imdata, 1);
                                xsize = size(imdata, 2);
                                ydeg = ysize/bhv.PixelsPerDegree;
                                xdeg = xsize/bhv.PixelsPerDegree;
                                xpos = xpos - (0.5*xdeg);
                                ypos = ypos - (0.5*ydeg);
                                set(hobject(itemnumber), 'xdata', [xpos xpos+xdeg], 'ydata', [ypos ypos+ydeg]);
                            elseif stat(itemnumber) == 3, %movie object
                                fnum = obstat.Data{ff, 1}(itemnumber); %framenumber in Data{1}
                                M = get(hobject(itemnumber), 'userdata'); %userdata contains all the frames of the movie
                                if fnum > length(M), %as may happen when only the first frame of the movie has been saved
                                    fnum = mod(fnum, length(M))+1;
                                end
                                imdata = M{fnum};
                                xypos = obstat.Data{ff, 2}; %Position [x; y] in Data{2}
                                xypos = reshape(xypos, size(xypos, 1)/2, 2);
                                try
                                    xpos = xypos(itemnumber, 1);
                                    ypos = xypos(itemnumber, 2);
                                catch
                                    keyboard
                                end
                                ysize = size(imdata, 1);
                                xsize = size(imdata, 2);
                                ydeg = ysize/bhv.PixelsPerDegree;
                                xdeg = xsize/bhv.PixelsPerDegree;
                                xpos = xpos - (0.5*xdeg);
                                ypos = ypos - (0.5*ydeg);
                                set(hobject(itemnumber), 'cdata', imdata/255, 'xdata', [xpos xpos+xdeg], 'ydata', [ypos ypos+ydeg], 'visible', 'on');
                            end
                        end
                    end
                end
                reward_on_match = any(rstat.RewardOnTime == t);
                reward_off_match = any(rstat.RewardOffTime == t);
                if reward_on_match || reward_off_match,
                    if reward_on_match,
                        set(rewardindicator, 'visible', 'on');
                    else
                        set(rewardindicator, 'visible', 'off');
                    end
                end
                codematch = any(ct == t);
                if codematch,
                    f = find(ct == t);
                    set(findobj(bhvfig, 'tag', 'codesbox'), 'value', f);
                end
                %                 if showelapsedtime,
                %                     set(het, 'string', int2str(t));
                %                 end
                drawnow;
                if makemovie && ~mod(t-1, interframeinterval),
                    mcount = mcount + 1;
                    mframe(mcount) = getframe(gca);  %#ok<AGROW>
                    if fcount == 1, %preallocate memory for remaining frames
                        expectedframes = ceil((maxtime-mintime+1)/interframeinterval);
                        mframe(2:expectedframes) = mframe(1);
                    end
                else
                    for i = 1:idlesteps, end
                end
            end

            delete([heye hjoy rewardindicator]);
            if makemovie,
                h = text(0, 0, 'Writing AVI File...');
                set(h, 'horizontalalignment', 'center', 'fontsize', 14, 'color', [1 1 1]);
                drawnow;
                movie2avi(mframe, moviefilename, 'fps', fps, 'keyframe', fps, 'quality', 100);
                delete(h);
                disp(sprintf('Generated an AVI containing %i frames over %i milliseconds', mcount, t))
            end
            set(hinvisible, 'visible', 'on');
            set(codesbox, 'value', codeselection);

            if usebiggerscreen,
                h = text(0, -3, 'Click to Close');
                set(h, 'horizontalalignment', 'center', 'fontsize', 14, 'color', [1 1 1]);
                set([gca h], 'buttondownfcn', 'delete(gcf)');
            end

        case 'fullrestoggle',

            if get(gcbo, 'value'),
                set(gcbo, 'backgroundcolor', [.5 .7 .5]);
            else
                set(gcbo, 'backgroundcolor', [.7 .5 .5]);
            end

        case 'makemovie',

            if get(gcbo, 'value'),
                set(gcbo, 'backgroundcolor', [.5 .7 .5]);
                set(findobj(gcf, 'tag', 'fps'), 'enable', 'on');
            else
                set(gcbo, 'backgroundcolor', [.7 .5 .5]);
                set(findobj(gcf, 'tag', 'fps'), 'enable', 'off');
            end

        case 'fps',

            str = get(gcbo, 'string');
            fps = str2double(str);
            if isnan(fps) || fps < 1 || fps > 100,
                set(gcbo, 'string', num2str(get(gcbo, 'userdata')));
            else
                set(gcbo, 'userdata', fps);
            end

        case 'timelinebutton',

            trial = get(findobj(gcf, 'tag', 'trialselector'), 'value');
            S = bhv.ObjectStatusRecord;
            obstat = S(trial);
            rstat = bhv.RewardRecord(trial);
            numobjects = length(obstat.Status{1});
            ct = bhv.CodeTimes{trial};
            cn = bhv.CodeNumbers{trial};
            cnumberlist = bhv.CodeNumbersUsed;
            cnamelist = bhv.CodeNamesUsed;
            mintime = 1;
            maxtime = max([max(ct) max(obstat.Time)]);

            tmatrix = zeros(numobjects+1, maxtime);
            for t = mintime:maxtime,
                statmatch = any(obstat.Time == t);
                if statmatch,
                    f = find(obstat.Time == t);
                    for fcount = 1:length(f),
                        ff = f(fcount);
                        stat = obstat.Status{ff};
                        for itemnumber = 1:length(stat),
                            if stat(itemnumber) == 0,
                                tmatrix(itemnumber, t:maxtime) = 0;
                            elseif stat(itemnumber) == 1,
                                tmatrix(itemnumber, t:maxtime) = 1;
                            elseif stat(itemnumber) == 2, %reposition object
                                tmatrix(itemnumber, t) = 2;
                            elseif stat(itemnumber) == 3, %movie
                                tmatrix(itemnumber, t) = 3;
                            end
                        end
                    end
                end
            end

            rmatrix = zeros(1, maxtime);
            for t = mintime:maxtime,
                reward_on_match = any(rstat.RewardOnTime == t);
                reward_off_match = any(rstat.RewardOffTime == t);
                if reward_on_match || reward_off_match,
                    if reward_on_match,
                        rmatrix(t:maxtime) = 1;
                    else
                        rmatrix(t:maxtime) = 0;
                    end
                end
            end
            ron = find(diff(rmatrix) == 1);
            roff = find(diff(rmatrix) == -1);

            screensize = get(0, 'screensize');
            xpos = 50;
            xsize = screensize(3)-(2*xpos);
            ypos = 80;
            ysize = screensize(4)-(2*ypos);

            figure
            set(gcf, 'position', [xpos ypos xsize ysize], 'color', [0.55 0.6 0.7]);
            set(gcf, 'numbertitle', 'off', 'name', sprintf('Time-Line: Trial #%i', trial), 'menubar', 'none', 'tag', 'timeline');
            aspace = 0.15;
            xmin = mintime-(aspace*maxtime);
            xmax = maxtime;
            ymin = -aspace*numobjects;
            ymax = numobjects + 1;
            xt = 0:500:maxtime;
            axpos = [.05 .08 .9 .8];
            set(gca, 'xlim', [xmin xmax], 'ylim', [ymin ymax], 'color', [.22 .22 .22], 'nextplot', 'add' ,'ytick', [], 'position', axpos, 'xcolor', [1 1 1], 'box', 'on', 'xtick', xt);
            h = text(0, 0, 'Milliseconds');
            set(h, 'position', [mean(get(gca, 'xlim')) (-.24*numobjects) 0], 'fontsize', 14, 'color', [1 1 1], 'horizontalalignment', 'center');
            patch([xmin 0 0 xmin], [ymin+0.01 ymin+0.01 ymax ymax], bhv.ScreenBackgroundColor');
            for i = 1:length(ron),
                patch([ron(i) roff(i) roff(i) ron(i)], [ymin+0.01 ymin+0.01 ymax ymax], [0 .5 0]);
            end
            h = zeros(length(xt), 1);
            for i = 1:length(xt),
                h(i) = line([xt(i) xt(i)], [ymin ymax]);
            end
            set(h, 'color', [.3 .3 .3]);
            h = zeros(numobjects, 1);
            for obnum = 1:numobjects,
                h(obnum) = line([0 xmax], [obnum obnum]);
                thisob = tmatrix(obnum, :);
                onset_times = find(diff(thisob) == 1) + 1;
                offset_times = find(diff(thisob) == -1) + 1;
                if min(offset_times) < min(onset_times),
                    onset_times = cat(2, 1, onset_times);
                end
                if max(onset_times) > max(offset_times),
                    offset_times = cat(2, offset_times, maxtime);
                end
                hob = zeros(1, length(onset_times));
                for i = 1:length(onset_times),
                    hob(i) = line([onset_times(i) offset_times(i)], [obnum obnum]);
                end
                set(hob, 'linewidth', 8, 'color', [.9 .4 .4]);

                f2 = find(thisob == 2);
                h2 = plot(f2, ones(size(f2))*obnum, 'r.');
                set(h2, 'markersize', 25);

                f3 = find(thisob == 3);
                h3 = plot(f3, ones(size(f3))*obnum, 'gs');
                set(h3, 'markersize', 15);
            end
            set(h, 'color', [.8 .8 .8]);

            adata = bhv.AnalogData{trial};
            if isfield(adata, 'EyeSignal'),
                xeye = adata.EyeSignal(:, 1);
                yeye = adata.EyeSignal(:, 2);
                numeyepoints = length(xeye);
            else
                xeye = 0;
                yeye = 0;
                numeyepoints = 0;
            end
            if isfield(adata, 'Joystick'),
                xjoy = adata.Joystick(:, 1);
                yjoy = adata.Joystick(:, 2);
                numjoypoints = length(xjoy);
            else
                xjoy = 0;
                yjoy = 0;
                numjoypoints = 0;
            end

            if isfield(adata, 'TouchSignal'),
                xtouch = adata.TouchSignal(:, 1);
                ytouch = adata.TouchSignal(:, 2);
                numtouchpoints = length(xtouch);
            else
                xtouch = 0;
                ytouch = 0;
                numtouchpoints = 0;
            end
            
            if isfield(adata, 'MouseSignal'),
                xmouse = adata.MouseSignal(:, 1);
                ymouse = adata.MouseSignal(:, 2);
                nummousepoints = length(xmouse);
            else
                xmouse = 0;
                ymouse = 0;
                nummousepoints = 0;
            end

            if isfield(bhv, 'AnalogInputFrequency') && bhv.AnalogInputFrequency ~= 1000,
                ystep = 1000/bhv.AnalogInputFrequency;
                if numeyepoints,
                    totalms = round(numeyepoints*ystep);
                    yi = 1:ystep:2*ystep*numeyepoints;
                    yi = yi(1:numeyepoints);
                    xeye = interp1(xeye, yi, 1:totalms);
                    yeye = interp1(yeye, yi, 1:totalms);
                end
                if numjoypoints,
                    totalms = round(numjoypoints*ystep);
                    yi = 1:ystep:2*ystep*numeyepoints;
                    yi = yi(1:numjoypoints);
                    xjoy = interp1(xjoy, yi, 1:totalms);
                    yjoy = interp1(yjoy, yi, 1:totalms);
                end
            end


            vmax = max([max(xeye) max(yeye) max(xjoy) max(yjoy)]);
            vmin = min([min(xeye) min(yeye) min(xjoy) min(yjoy)]);
            vrange = vmax - vmin;
            vscale = 0.5*aspace*numobjects/vrange;
            vshift = -0.5*(aspace*numobjects);
            xeye = vscale*xeye + vshift;
            yeye = vscale*yeye + vshift;
            xjoy = vscale*xjoy + vshift;
            yjoy = vscale*yjoy + vshift;
            if ~isempty(vmax),
                hxe = plot(xeye);
                hye = plot(yeye);
                hxj = plot(xjoy);
                hyj = plot(yjoy);
            end
            lw = 3;
            set(hxe, 'color', bhv.EyeTraceColor, 'linewidth', lw);
            set(hye, 'color', 0.7*bhv.EyeTraceColor, 'linewidth', lw);
            set(hxj, 'color', bhv.JoyTraceColor, 'linewidth', lw);
            set(hyj, 'color', 0.7*bhv.JoyTraceColor, 'linewidth', lw);

            for i = 1:length(ct),
                hline = line([ct(i) ct(i)], [ymin ymax]);
                f = find(cn(i) == cnumberlist);
                if isempty(f),
                    str = 'n/a';
                else
                    str = cnamelist(f);
                end
                htext = text(ct(i), ymax+(0.001*(ymax-ymin)), str);
                set(hline, 'color', [.6 .6 .2], 'linewidth', 1);
                set(htext, 'color', [1 1 1], 'rotation', 90, 'fontsize', 8);
            end

            set(gca, 'handlevisibility', 'off');
            axis off;
            tob = bhv.TaskObject(bhv.ConditionNumber(trial), :);
            ylim = [-aspace 1];
            xlim = [0 (1+aspace)/aspace];
            set(gca, 'xlim', xlim, 'ylim', ylim, 'nextplot', 'add', 'position', axpos);
            ysep = 1/(numobjects+1);
            axratio = range(ylim)/range(xlim);
            for i = 1:numobjects,
                ob = tob{i};
                if ~isempty(ob),
                    imdata = make_object(ob, bhv);
                    if iscell(imdata),
                        imdata = imdata{1};
                    end
                    h = image(imdata/255);
                    ysize = size(imdata, 1);
                    xsize = size(imdata, 2);

                    picfit = 0.8;
                    yheight = picfit*ysep;
                    xyscale = yheight/ysize;
                    xwidth = picfit*xsize*xyscale/axratio;

                    if xwidth > picfit,
                        xwidth = picfit;
                        xyscale = xwidth/xsize;
                        yheight = ysize*xyscale*axratio/picfit;
                    end

                    xleft = (1-xwidth)/2;
                    ybottom = (i*ysep) - (0.5*yheight);
                    set(h, 'xdata', [xleft xleft+xwidth], 'ydata', [ybottom ybottom+yheight]);
                end
            end
            set(gca, 'ylim', ylim, 'xlim', xlim, 'color', [1 1 1]);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function update_trialdata(trialnumber, bhv)

ffig = findobj(gcf, 'tag', 'mlbiggerscreenfig');
if ~isempty(ffig),
    delete(ffig);
end
set(findobj(gcf, 'tag', 'condnumberbox'), 'string', bhv.ConditionNumber(trialnumber));
set(findobj(gcf, 'tag', 'blocknumberbox'), 'string', bhv.BlockNumber(trialnumber));
set(findobj(gcf, 'tag', 'codesbox'), 'value', 1);
te = bhv.TrialError(trialnumber);
colororder = get_colororder;
testrings = {'[0]  Correct' '[1]  No Response' '[2]  Late Response' '[3]  Break Fixation' '[4]  No Fixation' '[5]  Early Response' '[6]  Incorrect' '[7]  Lever Break' '[8]  Ignored' '[9]  Aborted'};
set(findobj(gcf, 'tag', 'trialerrorbox'), 'string', testrings{te+1}, 'backgroundcolor', colororder(te+1, :));
set(findobj(gcf, 'tag', 'trialerrorframe'), 'backgroundcolor', colororder(te+1, :));
rt = bhv.ReactionTime(trialnumber);
if isnan(rt),
    str = 'n/a';
else
    str = [num2str(rt) ' ms'];
end
set(findobj(gcf, 'tag', 'reactiontimebox'), 'string', str);

%auto-shift listbox
tsh = findobj(gcf, 'tag', 'trialselector');
boxtop = get(tsh, 'listboxtop');
valthresh = 10;
if trialnumber - boxtop >= valthresh,
    set(tsh, 'listboxtop', boxtop + 1);
elseif trialnumber == boxtop && trialnumber > 1,
    set(tsh, 'listboxtop', boxtop - 1);
end

%behavioral codes, times, and descriptions
cn = bhv.CodeNumbers{trialnumber};
ct = bhv.CodeTimes{trialnumber};
numcodes = length(cn);
cd = cell(numcodes, 1);
for i = 1:numcodes,
    f = find(bhv.CodeNumbersUsed == cn(i));
    if isempty(f),
        str = 'n/a';
    else
        str = bhv.CodeNamesUsed{f};
    end
    cd{i} = sprintf('%i  [%i]  %s', ct(i), cn(i), str);
end
set(findobj(gcf, 'tag', 'codesbox'), 'string', cd, 'userdata', ct);

%line on behavior-over-time plot
bot = findobj(gcf, 'tag', 'behaviorovertime');
if ~isempty(bot),
    set(gcf, 'CurrentAxes', bot);
    h = findobj(gca, 'tag', 'thistrialmarker');
    if isempty(h),
        h = plot([trialnumber trialnumber], [0 1]);
        set(h, 'linewidth', 4, 'color', [0 0 0], 'tag', 'thistrialmarkerbg');
        h = plot([trialnumber trialnumber], [0 1]);
        set(h, 'linewidth', 1, 'color', [1 1 1], 'tag', 'thistrialmarker');
    else
        set(h, 'xdata', [trialnumber trialnumber]);
        set(findobj(gca, 'tag', 'thistrialmarkerbg'), 'xdata', [trialnumber trialnumber]);
    end
end

%screen representation
tob = bhv.TaskObject(bhv.ConditionNumber(trialnumber), :);
numobjects = length(tob);
set(gcf, 'CurrentAxes', findobj(gcf, 'tag', 'screenrepresentation'));
cla;
for i = numobjects:-1:1,
    ob = tob{i};
    if ~isempty(ob),
        [imdata xpos ypos] = make_object(ob, bhv);
        if iscell(imdata),
            M = imdata;
            imdata = M{1};
        else
            M = [];
        end
        h(i) = image(imdata/255);
        ysize = size(imdata, 1);
        xsize = size(imdata, 2);
        ydeg = ysize/bhv.PixelsPerDegree;
        xdeg = xsize/bhv.PixelsPerDegree;
        xpos = xpos - (0.5*xdeg);
        ypos = ypos - (0.5*ydeg);
        set(h(i), 'xdata', [xpos xpos+xdeg], 'ydata', [ypos ypos+ydeg]);
        if ~isempty(M),
            set(h(i), 'userdata', M);
        end
    end
end
set(gca, 'userdata', h);

%add eye, joystick, touchscreen, and mouse traces
adata = bhv.AnalogData{trialnumber};
if isfield(adata, 'EyeSignal'),
    if isfield(bhv, 'EyeTraceColor'),
        eyecolor = bhv.EyeTraceColor;
    else
        eyecolor = [.8 .8 .5];
    end
    h = plot(adata.EyeSignal(:, 1), adata.EyeSignal(:, 2));
    set(h, 'color', eyecolor, 'linewidth', 1.5, 'tag', 'eyetrace');
end
if isfield(adata, 'Joystick'),
    if isfield(bhv, 'JoyTraceColor'),
        joycolor = bhv.JoyTraceColor;
    else
        joycolor = [.8 .5 .5];
    end
    h = plot(adata.Joystick(:, 1), adata.Joystick(:, 2));
    set(h, 'color', joycolor, 'linewidth', 1.5, 'tag', 'joytrace');
end
if isfield(adata, 'TouchSignal'),
    if isfield(bhv, 'TouchTraceColor'),
        touchcolor = bhv.TouchTraceColor;
    else
        touchcolor = [.8 .5 .5];
    end
    h = plot(adata.TouchSignal(:, 1), adata.TouchSignal(:, 2));
    set(h, 'color', touchcolor, 'linewidth', 1.5, 'tag', 'touchtrace');
end

if isfield(adata, 'MouseSignal'),
    if isfield(bhv, 'MouseTraceColor'),
        mousecolor = bhv.MouseTraceColor;
    else
        mousecolor = [.8 .5 .5];
    end
    h = plot(adata.MouseSignal(:, 1), adata.MouseSignal(:, 2));
    set(h, 'color', mousecolor, 'linewidth', 1.5, 'tag', 'mousetrace');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function embedded_behaviorgraph(bhv)

te = bhv.TrialError;
lte = length(te);
if lte < 2,
    return
end
bnum = bhv.BlockNumber;
bswitch = find(diff(bnum));
set(gca, 'color', (get(gcf, 'color')), 'xlim', [1 lte], 'ylim', [0 1], 'position' ,[0.05 0.53 .92 .4], 'box', 'on', 'tag', 'behaviorovertime');
hold on;

colororder = get_colororder;
corder(1, 1:11, 1:3) = colororder(1:11, 1:3);

ht = title(bhv.DataFileName);
set(ht, 'fontsize', 14, 'fontweight', 'bold');
xlabel('Trial number');
ylabel('Fraction correct');

smoothwin = 10;
if length(te) < 5*smoothwin,
    x = 1:length(te);
    for tenumber = 0:9,
        y = zeros(size(x));
        y(te == tenumber) = 1;
        h = bar(x, y, 1);
        set(h, 'facecolor', colororder(tenumber+1, :), 'edgecolor', [1 1 1]);
    end
    set(gca, 'xlim', [0.5 length(te)+0.5]);
    return
end

yarray1 = zeros(lte, 12);
for i = 0:10,
    r = smooth(double(te == i), smoothwin, 'gauss');
    yarray1(1:lte, i+2) = yarray1(1:lte, i+1) + r;
end
xarray1 = (1:lte)';
xarray1 = repmat(xarray1, 1, 12);

xarray2 = flipud(xarray1);
yarray2 = flipud(yarray1);

x = cat(1, xarray1(:, 1:11), xarray2(:, 2:12));
y = cat(1, yarray1(:, 1:11), yarray2(:, 2:12));

warning off
h = patch(x, y, corder);
set(h, 'tag', 'behaviorpatch', 'buttondownfcn', 'behaviorsummary');
hline(1) = line([0 lte], [0.5 0.5]);
set(hline(1), 'color', [0.7 0.7 0.7], 'linewidth', 2);
hline(2) = line([0 lte], [0.25 0.25]);
hline(3) = line([0 lte], [0.75 0.75]);
set(hline([2 3]), 'color', [0.7 0.7 0.7], 'linewidth', 1);
h = zeros(length(bswitch), 1);
ht = h;
texty = 0.05;
for i = 1:length(bswitch),
    x1 = bswitch(i);
    h(i) = line([x1 x1], [0 1]);
    if i > 1,
        x2 = bswitch(i-1);
    else
        x2 = 0;
    end
    xm = (x1 + x2)/2;
    ht(i) = text(xm, texty, num2str(bhv.BlockOrder(i)));
end
if ~isempty(h),
    xm = (bswitch(i) + length(bhv.TrialNumber))/2;
    ht(i+1) = text(xm, texty, num2str(bhv.BlockOrder(i+1)));
    set(h, 'color', [1 1 1], 'linewidth', 2);
else
    xm = length(bhv.TrialNumber)/2;
    ht = text(xm, texty, num2str(bhv.BlockOrder));
end
set(ht, 'horizontalalignment', 'center', 'color', [1 1 1], 'fontweight', 'bold', 'fontsize', 14);

warning on

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function embedded_rtgraph(bhv)

set(gcf, 'CurrentAxes', findobj(gcf, 'tag', 'rtgraph'));
if any(~isnan(bhv.ReactionTime)),
    binsize = max(bhv.ReactionTime)/20;
    [n x] = hist(bhv.ReactionTime, 0:binsize:max(bhv.ReactionTime+binsize));
    maxbins = max(x);
    maxval = max(n);
    h = bar(x, n, 1);
    set(h, 'facecolor', [1 1 0], 'edgecolor', [.8 .8 .8], 'linewidth', 0.5);
    set(gca, 'xlim', [0 maxbins], 'ylim', [0 1.1*maxval]);
else
    h = text(mean(get(gca, 'xlim')), mean(get(gca, 'ylim')), 'No Reaction Time Data Available');
    set(h, 'fontsize', 14, 'color', [.3 0 0], 'fontweight', 'bold', 'horizontalalignment', 'center');
end
xlabel('Reaction Time (ms)');
ylabel('Number of Trials');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function colororder = get_colororder

colororder = [0 1 0; 0 1 1; 1 1 0; 0 0 1; 0.5 0.5 0.5; 1 0 1; 1 0 0; .3 .7 .5; .7 .2 .5; .5 .5 1; .75 .75 .5];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [imdata, xpos, ypos] = make_object(ob, bhv)

obtype = lower(ob(1:3));
op = find(ob == '(');
cp = find(ob == ')');
attributes = ob(op+1:cp-1);
att = parse_object(attributes, ',');
if strcmp(obtype, 'pic'),
    picname = att{1};
    xpos = str2double(att{2});
    ypos = str2double(att{3});
    PIC = bhv.Stimuli.PIC;
    for k = 1:length(PIC),
        if strcmp(picname, PIC(k).Name),
            imdata = PIC(k).Data;
        end
    end

elseif strcmp(obtype, 'mov'),
    movname = att{1};
    xpos = str2double(att{2});
    ypos = str2double(att{3});
    MOV = bhv.Stimuli.MOV;
    for k = 1:length(MOV),
        if strcmp(movname, MOV(k).Name),
            imdata = MOV(k).Data;
        end
    end

elseif strcmp(obtype, 'crc'),
    diameter = bhv.PixelsPerDegree*str2double(att{1});
    rgb = eval(att{2});
    fillflag = str2double(att{3});
    xpos = str2double(att{4});
    ypos = str2double(att{5});
    imdata = ceil(255*makecircle(diameter, rgb, fillflag));

elseif strcmp(obtype, 'sqr'),
    diameter = bhv.PixelsPerDegree*str2num(att{1}); %#ok<ST2NM>
	rgb = eval(att{2});
    fillflag = str2double(att{3});
    xpos = str2double(att{4});
    ypos = str2double(att{5});
    imdata = ceil(255*makesquare(diameter, rgb, fillflag));

elseif strcmp(obtype, 'fix'),
    diameter = 5;
    rgb = [1 1 1];
    fillflag = 1;
    xpos = str2double(att{1});
    ypos = str2double(att{2});
    imdata = ceil(255*makecircle(diameter, rgb, fillflag));

elseif strcmp(obtype, 'snd'),
    imdata = imread('soundicon.jpg');
    xpos = 0;
    ypos = -5;

elseif strcmp(obtype, 'stm'),
    imdata = imread('stimulationicon.jpg');
    xpos = 0;
    ypos = -5;

elseif strcmp(obtype, 'ttl'),
    imdata = imread('ttlicon.jpg');
    xpos = 0;
    ypos = -5;

elseif strcmp(obtype, 'gen'),
    imdata = imread('genicon.jpg');
    xpos = str2double(att{2});
    ypos = str2double(att{3});

elseif strcmp(obtype, 'mov'),
    imdata = imread('movieicon.jpg');
    xpos = str2double(att{2});
    ypos = str2double(att{3});

else
    imdata = [0 0 0; 0 0 0; 0 0 0];
    imdata = repmat(imdata, [1 1 3]);
    xpos = 0;
    ypos = 0;

end

if ~isempty(imdata),
    for iplane = 1:size(imdata, 3),
        imdata(:, :, iplane) = flipud(imdata(:, :, iplane));
    end
end
