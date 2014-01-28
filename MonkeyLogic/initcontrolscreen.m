function output = initcontrolscreen(procnum, ScreenInfo, varargin)
%
% Created by WA 7/06
% Modified 1/22/08 -WA
% Modified 2/21/08 -WA (Added button/lever indicators & fixed scaling bug found by DJF)
% Modified 9/11/08 -WA (fixed aspect ratio bug when using wide-screen monitors)
% Modified 6/01/12 -WA (to show max latency, rather than min cycle rate)
% Modified 7/19/12 -WA (to keep control-screen background black, regardless of subject screen bg color)

persistent hxd hyd rtext wtext warnings user_text %screen dimension +/- hxd & hyd, in degrees

output = [];

tx1 = 0.25;
tx2 = 0.28;
ty1 = 0.05;
ty2 = 0.90;

if procnum == 1, %create window

    fig = findobj('tag', 'mlmonitor');
    if ~isempty(fig),
        close(fig);
    end

    MLConfig = varargin{1};

    xs = 800;
    ys = 600;
    xratio = xs/ScreenInfo.Xsize; %these are needed to scale objects
    yratio = ys/ScreenInfo.Ysize;
        
    xd = ScreenInfo.Xdegrees;
    yd = ScreenInfo.Ydegrees;
    if xd >= yd,
        yd = (3/4)*xd;
    else
        xd = (4/3)*yd;
    end
    hxd = xd/2;
    hyd = yd/2;

    cpsize = 200;
    cp2size = 200; %150
    cp3size = 200;
    cp4size = 10;

    ss = get(0, 'ScreenSize');
    cx = ss(3);
    cy = ss(4);
    wxp = (cx - xs - cpsize - cp3size - cp4size)/2;
    wyp = (cy - ys - cp2size)/1.5;

    csh = figure;
    fbgc = [0.9 0.9 0.85];
    figcol = [.7 .7 .85];
    set(csh, 'position', [wxp wyp xs+cpsize+cp3size ys+cp2size+cp4size], 'name', sprintf('MonkeyLogic     %s', datestr(date)), 'tag', 'mlmonitor', 'userdata', [xratio yratio], 'menubar', 'none', 'backingstore', 'off', 'resize', 'off', 'numbertitle', 'off', 'doublebuffer', 'on', 'color', figcol, 'renderer', 'painters');
    framevsize = 350;

    misc(1) = uicontrol('style', 'frame', 'position', [xs+10+cp3size ys+cp2size-framevsize cpsize-20 framevsize], 'backgroundcolor', fbgc);
    h(1) = uicontrol('style', 'text', 'position', [xs+80+cp3size ys-40+cp2size+cp4size 40 20], 'string', 'Block', 'backgroundcolor', fbgc, 'horizontalalignment', 'center');
    misc(2) = uicontrol('style', 'frame', 'position', [xs+74+cp3size ys-55+cp2size+cp4size 52 22], 'backgroundcolor', [0 0 0], 'foregroundcolor', [1 1 1]);
    h(2) = uicontrol('style', 'text', 'position', [xs+75+cp3size ys-53+cp2size+cp4size 50 18], 'string', '', 'tag', 'blockno', 'backgroundcolor', [0 0 0], 'foregroundcolor', [1 1 1], 'fontsize', 11, 'fontweight', 'bold', 'horizontalalignment', 'center');
    h(3) = uicontrol('style', 'text', 'position', [xs+133+cp3size ys-40+cp2size+cp4size 50 20], 'string', 'Condition', 'backgroundcolor', fbgc, 'horizontalalignment', 'center');
    misc(3) = uicontrol('style', 'frame', 'position', [xs+132+cp3size ys-55+cp2size+cp4size 52 22], 'backgroundcolor', [0 0 0], 'foregroundcolor', [1 1 1]);
    h(4) = uicontrol('style', 'text', 'position', [xs+133+cp3size ys-53+cp2size+cp4size 50 18], 'string', '', 'tag', 'condno', 'backgroundcolor', [0 0 0], 'foregroundcolor', [1 1 1], 'fontsize', 11', 'fontweight', 'bold', 'horizontalalignment', 'center');
    h(5) = uicontrol('style', 'text', 'position', [xs+22+cp3size ys-40+cp2size+cp4size 40 20], 'string', 'Trial', 'backgroundcolor', fbgc, 'horizontalalignment', 'center');
    misc(4) = uicontrol('style', 'frame', 'position', [xs+16+cp3size ys-55+cp2size+cp4size 52 22], 'backgroundcolor', [0 0 0], 'foregroundcolor', [1 1 1]);
    h(6) = uicontrol('style', 'text', 'position', [xs+17+cp3size ys-53+cp2size+cp4size 50 18], 'string', '', 'backgroundcolor', [0 0 0], 'foregroundcolor', [1 1 1], 'horizontalalignment', 'center', 'tag', 'trialno', 'fontsize', 11, 'fontweight', 'bold');

    h(7) = uicontrol('style', 'text', 'position', [xs+35+cp3size ys-95+cp2size+cp4size 90 30], 'string', 'Number of trials played this block', 'backgroundcolor', fbgc, 'horizontalalignment', 'right');
    misc(5) = uicontrol('style', 'frame', 'position', [xs+131+cp3size ys-89+cp2size+cp4size 52 22], 'backgroundcolor', [0 0 0], 'foregroundcolor', [1 1 1]);
    h(8) = uicontrol('style', 'text', 'position', [xs+132+cp3size ys-87+cp2size+cp4size 50 18], 'string', '', 'tag', 'trialsthisblock', 'backgroundcolor', [0 0 0], 'foregroundcolor', [1 1 1], 'horizontalalignment', 'center', 'fontsize', 11, 'fontweight', 'bold');
    h(9) = uicontrol('style', 'text', 'position', [xs+35+cp3size ys-130+cp2size+cp4size 90 30], 'string', 'Total number of blocks completed', 'backgroundcolor', fbgc, 'horizontalalignment', 'right');
    misc(6) = uicontrol('style', 'frame', 'position', [xs+131+cp3size ys-124+cp2size+cp4size 52 22], 'backgroundcolor', [0 0 0], 'foregroundcolor', [1 1 1]);
    h(10) = uicontrol('style', 'text', 'position', [xs+132+cp3size ys-122+cp2size+cp4size 50 18], 'string', '', 'tag', 'numblocksplayed', 'backgroundcolor', [0 0 0], 'foregroundcolor', [1 1 1], 'horizontalalignment', 'center', 'fontsize', 11, 'fontweight', 'bold');
    h(11) = uicontrol('style', 'text', 'position', [xs+35+cp3size ys-165+cp2size+cp4size 90 30], 'string', 'Total number of correct trials', 'backgroundcolor', fbgc, 'horizontalalignment', 'right');
    misc(7) = uicontrol('style', 'frame', 'position', [xs+131+cp3size ys-159+cp2size+cp4size 52 22], 'backgroundcolor', [0 0 0], 'foregroundcolor', [1 1 1]);
    h(12) = uicontrol('style', 'text', 'position', [xs+132+cp3size ys-157+cp2size+cp4size 50 18], 'string', '', 'tag', 'numcorrect', 'backgroundcolor', [0 0 0], 'foregroundcolor', [1 1 1], 'horizontalalignment', 'center', 'fontsize', 11, 'fontweight', 'bold');

    h(13) = uicontrol('style', 'text', 'position', [xs+20+cp3size ys-190+cp2size+cp4size cpsize-40 20], 'string', 'Current timing function', 'backgroundcolor', fbgc, 'horizontalalignment', 'center');
    misc(8) = uicontrol('style', 'frame', 'position', [xs+17+cp3size ys-208+cp2size+cp4size cpsize-31 23], 'backgroundcolor', [0.3 0.3 0.5], 'foregroundcolor', [1 1 1]);
    h(14) = uicontrol('style', 'text', 'position', [xs+18+cp3size ys-206+cp2size+cp4size cpsize-34 18], 'string', '', 'tag', 'tfile', 'backgroundcolor', [0.3 0.3 0.5], 'foregroundcolor', [1 1 1], 'fontsize', 9, 'fontweight', 'normal', 'horizontalalignment', 'center');

    h(15) = uicontrol('style', 'frame', 'position', [xs+21+cp3size ys-166+cp2size+cp4size 7 100], 'backgroundcolor', [1 0 0], 'foregroundcolor', [0 0 0], 'tag', 'deadtimemarker');

    blankstring = '-';
    blankstring = repmat(blankstring, 1, 26); %number of zeros which can fit on this line
    misc(2) = uicontrol('style', 'text', 'position', [xs+15+cp3size ys-225+cp2size cpsize-30 20], 'string', 'Recent Trial-Errors: All Conditions', 'backgroundcolor', fbgc);
    misc(3) = uicontrol('style', 'frame', 'position', [xs+16+cp3size ys-247+cp2size cpsize-30 25], 'backgroundcolor', [0 0 0], 'foregroundcolor', [1 1 1]);
    h(5) = uicontrol('style', 'text', 'position', [xs+20+cp3size ys-246+cp2size cpsize-40 20], 'string', blankstring, 'tag', 'errorlist', 'backgroundcolor', [0 0 0], 'foregroundcolor', [1 1 1], 'horizontalalignment', 'right');
    misc(4) = uicontrol('style', 'text', 'position', [xs+15+cp3size ys-274+cp2size cpsize-30 20], 'string', 'Recent Trial-Errors: This Condition', 'backgroundcolor', fbgc);
    misc(5) = uicontrol('style', 'frame', 'position', [xs+16+cp3size ys-296+cp2size cpsize-30 25], 'backgroundcolor', [0 0 0], 'foregroundcolor', [1 1 1]);
    h(6) = uicontrol('style', 'text', 'position', [xs+20+cp3size ys-295+cp2size cpsize-40 20], 'string', blankstring, 'tag', 'conderrors', 'backgroundcolor', [0 0 0], 'foregroundcolor', [1 1 1], 'horizontalalignment', 'right', 'userdata', blankstring);

%     h(20) = uicontrol('style', 'text', 'position', [xs+cp3size+20 ys+cp2size-322 90 20], 'string', 'Run-time priority:', 'backgroundcolor', fbgc);
%     misc(6) = uicontrol('style', 'frame', 'position', [xs+cp3size+20, ys+cp2size-343 86 25], 'foregroundcolor', [0 0 0]);
%     h(21) = uicontrol('style', 'text', 'position', [xs+cp3size+22 ys+cp2size-341 83 20], 'string', '', 'foregroundcolor', [1 1 1], 'fontweight', 'bold', 'fontsize', 11, 'horizontalalignment', 'center');
    
    h(20) = uicontrol('style', 'text', 'position', [xs+cp3size+20 ys+cp2size-322 90 20], 'string', 'Max Latency:', 'backgroundcolor', fbgc);
    uicontrol('style', 'frame', 'position', [xs+cp3size+20, ys+cp2size-343 86 25], 'foregroundcolor', [0 0 0], 'tag', 'mincyclerateframe', 'backgroundcolor', [.3 .3 .3]);
    h(21) = uicontrol('style', 'text', 'position', [xs+cp3size+22 ys+cp2size-341 83 20], 'string', ' ---- ms', 'tag', 'mincyclerate', 'foregroundcolor', [1 1 1], 'fontweight', 'bold', 'fontsize', 10, 'horizontalalignment', 'center', 'backgroundcolor', [.3 .3 .3]);
%     switch MLConfig.Priority,
%         case 1,
%             set(misc(6), 'backgroundcolor', [0 1 0]);
%             set(h(21), 'string', 'Normal', 'backgroundcolor', [0 1 0]);
%         case 2,
%             set(misc(6), 'backgroundcolor', [1 1 0]);
%             set(h(21), 'string', 'High', 'backgroundcolor', [1 1 0], 'foregroundcolor', [0.6 0.6 0.6]);
%         case 3,
%             set(misc(6), 'backgroundcolor', [1 0 0]);
%             set(h(21), 'string', 'Highest', 'backgroundcolor', [1 0 0]);
%     end

    uicontrol('style', 'text', 'position', [xs+cp3size+111 ys+cp2size-322 70 20], 'string', 'Cycle-Rate:', 'backgroundcolor', fbgc);
    uicontrol('style', 'frame', 'position', [xs+cp3size+111, ys+cp2size-343 74 25], 'foregroundcolor', [0 0 0], 'tag', 'cyclerateframe', 'backgroundcolor', [.3 .3 .3]);
    uicontrol('style', 'text', 'position', [xs+cp3size+113 ys+cp2size-341 71 20], 'string', ' ---- Hz', 'tag', 'cyclerate', 'foregroundcolor', [1 1 1], 'fontweight', 'bold', 'fontsize', 10, 'horizontalalignment', 'center', 'backgroundcolor', [.3 .3 .3]);
    
    h(4) = uicontrol('style', 'frame', 'position', [25 cp2size+10 cp3size-50 cp2size-26], 'backgroundcolor', fbgc);
    te_descrip = {'Trial Error Codes:' '0 = Correct' '1 = No Response' '2 = Late Response' '3 = Break Fixation' '4 = No Fixation' '5 = Early Response' '6 = Incorrect Response' '7 = Lever Break' '8 = Ignored' '9 = Aborted'};
    h(7) = uicontrol('style', 'text', 'position', [40 2*cp2size-13*length(te_descrip)-27 120 13*length(te_descrip)+2], 'string', te_descrip, 'horizontalalignment', 'left', 'backgroundcolor', fbgc, 'fontsize', 8);  %[40 17 120 110]
    
    %User text box.  Fits 20 chars per line on 12 lines.
    h(22) = uicontrol('style', 'frame', 'position', [25 10 cp3size-50 cp2size-26], 'backgroundcolor', fbgc);
    user_text = {'','','','','','','','','','','',''};
    h(23) = uicontrol('style', 'text', 'position', [40 cp2size-13*length(user_text)-27 120 13*length(user_text)+2], 'tag', 'usertext', 'string', user_text, 'horizontalalignment', 'left', 'backgroundcolor', fbgc);
    
    %screen replica
    subplot('position', [cp3size/(xs+cpsize+cp3size) cp2size/(ys+cp2size+cp4size) xs/(xs+cpsize+cp3size) ys/(ys+cp2size+cp4size)]);
    replicacol = [0 0 0];
    set(gca, 'color', replicacol, 'xlim', [-hxd hxd], 'ylim', [-hyd hyd], 'nextplot', 'add', 'xtick', [], 'ytick', [], 'drawmode', 'fast', 'tag', 'replica');

    if MLConfig.ControlScreenGridCartesian,
        xvals = floor(-hxd):ceil(hxd);
        yvals = floor(-hyd):ceil(hyd);
        vlines = line([xvals; xvals], [floor(-hyd)*ones(size(xvals)); ceil(hyd)*ones(size(xvals))]);
        hlines = line([floor(-hxd)*ones(size(yvals)); ceil(hxd)*ones(size(yvals))], [yvals; yvals]);
        col = MLConfig.ControlScreenGridCartesianBrightness;
        set([hlines' vlines'], 'color', [col col col], 'handlevisibility', 'off');
    end
    
    if MLConfig.ControlScreenGridPolar,
        numsteps = 1000;
        stepsize = 2*pi/numsteps;
        theta = 0:stepsize:(2*pi);
        hc = [];
        for r = 1:max([hxd hyd]),
            xvals = r*cos(theta);
            yvals = r*sin(theta);
            hc(length(hc)+1) = plot(xvals, yvals); %#ok<AGROW>
        end
        r = 2*max([hxd hyd]);
        for theta = 0:(pi/6):(pi-.001),
            xvals = r*cos(theta);
            yvals = r*sin(theta);
            hc(length(hc)+1) = line([-xvals xvals], [-yvals yvals]); %#ok<AGROW>
        end
        col = MLConfig.ControlScreenGridPolarBrightness;
        set(hc, 'color', [col col col], 'handlevisibility', 'off');
    end

    x1 = ceil(min(get(gca, 'xlim'))) + 0.5;
    x2 = x1 + 1;
    y1 = 0.93*min(get(gca, 'ylim'));
    y2 = y1;
    legendcol = [0.5 0.5 0.5];
    hline(1) = plot([x1 x2], [y1 y2]);
    hline(2) = plot([x1 x1], [y1+0.2 y1-0.2]);
    hline(3) = plot([x2 x2], [y1+0.2 y1-0.2]);
    set(hline, 'color', legendcol);
    set(hline(1), 'linewidth', 2);
    htext = text(x2+0.2, y1, ' 1 degree');
    set(htext, 'color', legendcol);
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% REWARD
%     rtext = text(x1, y1+0.8, 'Reward Duration: --'); %WAS NOT UPDATING PROPERLY
%     set(rtext, 'color', legendcol, 'tag', 'rewarddurationtxt');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% WARNINGS
    warnings = {};
    wtext = text(x1, 0.93*max(get(gca, 'ylim')), '');
    set(wtext, 'color', [1 0 0]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    set([hline htext rtext wtext], 'handlevisibility', 'off');

    %over-all behavior axis
    subplot('position', [cp3size/(xs+cpsize+cp3size) (cp2size* 30/40)/(ys+cp2size+cp4size) xs/(xs+cpsize+cp3size) (cp2size/10)/(ys+cp2size+cp4size)]);
    set(gca, 'tag', 'overallchart', 'xlim', [0 1], 'ylim', [0 1]);
    patch([0 1 1 0], [0 0 1 1], [0 0 0]);
    axis off;
    h(8) = uicontrol('style', 'text', 'position', [(cp3size-100+xs/2) cp2size*69/80 200 20], 'string', 'Performance Over-all', 'backgroundcolor', figcol, 'fontsize', 10, 'fontweight', 'bold');

    %this block behavior axis
    subplot('position', [cpsize/(xs+cpsize+cp3size) (cp2size*21/40)/(ys+cp2size+cp4size) xs/(xs+cpsize+cp3size) (cp2size/10)/(ys+cp2size+cp4size)]);
    set(gca, 'tag', 'blockchart', 'xlim', [0 1], 'ylim', [0 1]);
    patch([0 1 1 0], [0 0 1 1], [0 0 0]);
    axis off;
    h(9) = uicontrol('style', 'text', 'position', [(cp3size-100+xs/2) cp2size*51/80 200 20], 'string', 'Performance this Block', 'backgroundcolor', figcol, 'fontsize', 10, 'fontweight', 'bold');

    %this cond behavior axis
    subplot('position', [cp3size/(xs+cpsize+cp3size) (cp2size*12/40)/(ys+cp2size+cp4size) xs/(xs+cpsize+cp3size) (cp2size/10)/(ys+cp2size+cp4size)]);
    set(gca, 'tag', 'conditionchart', 'xlim', [0 1], 'ylim', [0 1]);
    patch([0 1 1 0], [0 0 1 1], [0 0 0]);
    axis off;
    h(10) = uicontrol('style', 'text', 'position', [(cp3size-100+xs/2) cp2size*33/80 200 20], 'string', 'Performance this Condition', 'backgroundcolor', figcol, 'fontsize', 10, 'fontweight', 'bold');
   
    %recent behavior axis
    subplot('position', [cp3size/(xs+cpsize+cp3size) (cp2size*3/40)/(ys+cp2size+cp4size) xs/(xs+cpsize+cp3size) (cp2size/10)/(ys+cp2size+cp4size)]);
    set(gca, 'tag', 'recentchart', 'xlim', [0 1], 'ylim', [0 1]);
    patch([0 1 1 0], [0 0 1 1], [0 0 0]);
    axis off;
    h(11) = uicontrol('style', 'text', 'position', [(cp3size-100+xs/2) cp2size*15/80 200 20], 'string', 'Recent Performance', 'backgroundcolor', figcol, 'fontsize', 10, 'fontweight', 'bold');

    h(12) = uicontrol('style', 'frame', 'position', [cp3size+xs+20 (cp2size*30/40)+1 cpsize-40 cp2size/10], 'backgroundcolor', [0 0 0], 'foregroundcolor', [1 1 1]);
    h(13) = uicontrol('style', 'frame', 'position', [cp3size+xs+20 (cp2size*21/40)+1 cpsize-40 cp2size/10], 'backgroundcolor', [0 0 0], 'foregroundcolor', [1 1 1]);
    h(14) = uicontrol('style', 'frame', 'position', [cp3size+xs+20 (cp2size*12/40)+1 cpsize-40 cp2size/10], 'backgroundcolor', [0 0 0], 'foregroundcolor', [1 1 1]);
    h(15) = uicontrol('style', 'frame', 'position', [cp3size+xs+20 (cp2size*3/40)+1 cpsize-40 cp2size/10], 'backgroundcolor', [0 0 0], 'foregroundcolor', [1 1 1]);
    h(16) = uicontrol('style', 'text', 'position', [cp3size+xs+25 (cp2size*30/40)+2 cpsize-50 cp2size/12], 'backgroundcolor', [0 0 0], 'foregroundcolor', [1 1 1], 'tag', 'overallcorrect', 'string', '% correct', 'fontsize', 10, 'fontweight', 'bold');
    h(17) = uicontrol('style', 'text', 'position', [cp3size+xs+25 (cp2size*21/40)+2 cpsize-50 cp2size/12], 'backgroundcolor', [0 0 0], 'foregroundcolor', [1 1 1], 'tag', 'blockcorrect', 'string', '% correct', 'fontsize', 10, 'fontweight', 'bold');
    h(18) = uicontrol('style', 'text', 'position', [cp3size+xs+25 (cp2size*12/40)+2 cpsize-50 cp2size/12], 'backgroundcolor', [0 0 0], 'foregroundcolor', [1 1 1], 'tag', 'condcorrect', 'string', '% correct', 'fontsize', 10, 'fontweight', 'bold');
    h(19) = uicontrol('style', 'text', 'position', [cp3size+xs+25 (cp2size*3/40)+2 cpsize-50 cp2size/12], 'backgroundcolor', [0 0 0], 'foregroundcolor', [1 1 1], 'tag', 'recentcorrect', 'string', '% correct', 'fontsize', 10, 'fontweight', 'bold');

    %timeline axis
    fcolor = [0.5 0.5 0.7];
    %subplot('position', [(cp3size/20)/(cp3size+xs+cpsize) cp2size/(cp2size+ys+cp4size) (cp3size*18/20)/(cp3size+xs+cpsize) ys/(cp2size+ys+cp4size)]);
    subplot('position', [(cp3size/20)/(cp3size+xs+cpsize) 2*cp2size/(cp2size+ys+cp4size) (cp3size*18/20)/(cp3size+xs+cpsize) (ys-cp2size)/(cp2size+ys+cp4size)]);
    set(gca, 'tag', 'timeline', 'xlim', [0 1], 'ylim', [0 1], 'box', 'on', 'xtick', [], 'ytick', [], 'color', fcolor);
    htext = text(0.5, 0.97, 'Time Line');
    set(htext, 'color', [1 1 1], 'horizontalalignment', 'center', 'fontweight', 'bold', 'fontsize', 11);
    h(20) = patch([tx1 tx2 tx2 tx1], [ty1 ty1 ty2 ty2], [1 1 1]);

    %RT graphs
    subplot('position', [(cp3size+xs)/(cp3size+xs+cpsize)+(cpsize*1/20)/(cp3size+xs+cpsize) cp2size/(cp2size+ys+cp4size)+(cp2size*1/10)/(cp2size+ys+cp4size) (cpsize*0.89)/(cp3size+xs+cpsize) (ys*0.38)/(cp2size+ys+cp4size)]);
    set(gca, 'tag', 'rtgraph', 'color', fcolor, 'ylim', [-1 1], 'box', 'on', 'xtick', [], 'ytick', []);
    htext = text(mean(get(gca, 'xlim')), 0.9, 'Reaction Times');
    set(htext, 'color', [1 1 1], 'horizontalalignment', 'center', 'fontweight', 'bold', 'fontsize', 11);

    set(gcf, 'CurrentAxes', findobj(gcf, 'tag', 'replica'));
    output = csh; %return figure window handle

elseif procnum == 2, %update window with task objects

    fig = findobj('tag', 'mlmonitor');
    set(0, 'CurrentFigure', fig);
    xyratio = get(gcf, 'userdata');
    delete(get(gca, 'children'));

    TaskObject = varargin{1};
    numobjects = length(TaskObject);
    for obnum = 1:numobjects,
        Ob = TaskObject(obnum);
        if Ob.Modality == 1 || Ob.Modality == 2, %visual (static image or movie)
            x = Ob.XPos(1);
            y = Ob.YPos(1);
            xsize = Ob.Xsize(1);
            ysize = Ob.Ysize(1);
            [mx where] = max([xsize ysize]);
            xyr = xyratio(where);
            msize = mx*xyr/ScreenInfo.PixelsPerPoint;
            h = plot(x, y, 'square');
            if max(Ob.ControlObjectColor) > 1,
                Ob.ControlObjectColor = Ob.ControlObjectColor/255;
            end
            set(h, 'markeredgecolor', Ob.ControlObjectColor, 'markersize', msize, 'markerfacecolor', 'none', 'tag', sprintf('Object %i', obnum), 'linewidth', 2, 'erasemode', 'xor');
            set(h, 'xdata', ScreenInfo.OutOfBounds, 'ydata', ScreenInfo.OutOfBounds); %off screen
            TaskObject(obnum).ControlObjectHandle = h;
            if Ob.Modality == 2, %movie,
                set(h, 'linewidth', 4, 'markeredgecolor', [0 1 0]);
            end
        elseif Ob.Modality == 4 || Ob.Modality == 5, %analog stimulation or TTL
            if Ob.Modality == 5,
                obcol = [1 0.6 0.6];
            else
                obcol = [1 1 0.4];
            end
            TaskObject(obnum).XPos = 0.5*hxd;
            TaskObject(obnum).YPos = 0.8*hyd;
            h = text(ScreenInfo.OutOfBounds, ScreenInfo.OutOfBounds, Ob.Name);
            set(h, 'color', obcol, 'fontweight', 'bold', 'fontsize', 20, 'horizontalalignment', 'center', 'erasemode', 'xor');
            TaskObject(obnum).ControlObjectHandle = h;
        end
    end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% REWARD
    loadbutton = findobj('tag', 'loadbutton');
    VV = get(loadbutton, 'userdata');
    reward_dur = VV.reward_dur;
    set(rtext, 'String', sprintf('Reward Duration: %i',reward_dur));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% WARNINGS
    if isempty(warnings),
        wstr = '';
    elseif length(warnings)==1,
        wstr = sprintf('Warning: %s',warnings{1});
    else
        wstr = sprintf('Warnings {%i}: %s',length(warnings),warnings{end});
    end
    set(wtext, 'String', wstr);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %create joystick target circle:
    for pnum = 1:numobjects,
        h(pnum) = plot(0, 0, 'o');
    end
    set(h, 'markeredgecolor', ScreenInfo.JoyTargetColor, 'markersize', 20, 'linewidth', ScreenInfo.JoyTargetLinewidth, 'markerfacecolor', 'none', 'tag', 'target', 'erasemode', 'xor');
    set(h, 'xdata', ScreenInfo.OutOfBounds, 'ydata', ScreenInfo.OutOfBounds);

    %create joystick trace
    h = plot(0, 0, '.');
    set(h, 'color', ScreenInfo.JoyTraceColor, 'markersize', ScreenInfo.JoyTraceSize, 'tag', 'trace', 'erasemode', 'xor');
    set(h, 'xdata', ScreenInfo.OutOfBounds, 'ydata', ScreenInfo.OutOfBounds);

    %create eye fix circle:
    for pnum = 1:numobjects,
        h(pnum) = plot(0, 0, 'o');
    end
    set(h, 'markeredgecolor', ScreenInfo.EyeTargetColor, 'markersize', 20, 'linewidth', ScreenInfo.EyeTargetLinewidth, 'markerfacecolor', 'none', 'tag', 'fixcircle', 'erasemode', 'xor');
    set(h, 'xdata', ScreenInfo.OutOfBounds, 'ydata', ScreenInfo.OutOfBounds);

    %create eye trace
    h = plot(0, 0, '.');
    set(h, 'color', ScreenInfo.EyeTraceColor, 'markersize', ScreenInfo.EyeTraceSize, 'tag', 'eyetrace', 'erasemode', 'xor');
    set(h, 'xdata', ScreenInfo.OutOfBounds, 'ydata', ScreenInfo.OutOfBounds);
    
    %create button indicators
    numbuttons = 5; %max, for now at least
    hline = zeros(numbuttons, 1);
    hbutton = zeros(numbuttons, 1);
    hthresh = zeros(numbuttons, 1);
    hx = [0 0];
    ymin = -0.4*ScreenInfo.Ydegrees;
    ymax = -0.2*ScreenInfo.Ydegrees;
    for i = 1:numbuttons,
        hline(i) = line([0 0], [ymin ymax]);
        hbutton(i) = plot(0, 0, 'o');
        hthresh(i) = plot(0, 0, 'diamond');
    end
    set(hline, 'tag', 'ButtonLine', 'linewidth', 3, 'color', [.5 0 0], 'xdata', hx+ScreenInfo.OutOfBounds, 'erasemode', 'xor');
    set(hbutton, 'tag', 'ButtonCircle', 'markersize', 15, 'linewidth', 2, 'markerfacecolor', [0.7 0 0], 'markeredgecolor', [1 0 0], 'xdata', ScreenInfo.OutOfBounds, 'ydata', ScreenInfo.OutOfBounds, 'erasemode', 'xor');
    set(hthresh, 'tag', 'ButtonThresh', 'markersize', 10, 'linewidth', 3, 'markerfacecolor', [0 0.7 0], 'markeredgecolor', [0 1 0], 'xdata', ScreenInfo.OutOfBounds, 'ydata', ScreenInfo.OutOfBounds, 'erasemode', 'xor');
    
    %set(gca, 'color', [0 0 0]);
    output = TaskObject; %return expanded TrialObject structure

elseif procnum == 3, %update performance bars

    perf = ScreenInfo; %expected to be three column vectors with trial-errors 0 through n; first column is over-all, second is this block, third this condition
    colororder = [0 1 0; 0 1 1; 1 1 0; 0 0 1; 0.5 0.5 0.5; 1 0 1; 1 0 0; .3 .7 .5; .7 .2 .5; .5 .5 1; .75 .75 .5];
    numcolors = size(colororder, 1);
    shadestep = 0.12;

    set(gcf, 'CurrentAxes', findobj('tag', 'overallchart'));
    cla;
    if isnan(perf(1, 1)),
        col = [1 1 1];
        for j = 0:shadestep:(1-shadestep),
            thiscol = col * (1-abs(0.5 - j));
            h = patch([0 1 1 0], [j j j+shadestep j+shadestep], thiscol);
            set(h, 'edgecolor', 'none');
        end
    else
        left = 0;
        for i = 1:size(perf, 1),
            if perf(i, 1) > 0,
                cnum = rem(i, numcolors);
                if cnum == 0,
                    cnum = numcolors;
                end
                col = colororder(cnum, :);
                for j = 0:shadestep:(1-shadestep),
                    thiscol = col * (1 - abs(0.5 - j));
                    h = patch([left left+perf(i, 1) left+perf(i, 1) left], [j j j+shadestep j+shadestep], thiscol);
                    if left > 0,
                        d = patch([left left left left], [j j j+shadestep j+shadestep], 'black');
                    end
                    set(h, 'edgecolor', 'none');
                end
                midx = ((2*left) + perf(i, 1))/2;
                t = text(midx, 0.5, num2str(i-1));
                set(t, 'fontsize', 10, 'color', [1 1 1], 'fontweight', 'bold');
                left = left + perf(i, 1);
            end
        end
    end
    
    set(gcf, 'CurrentAxes', findobj('tag', 'blockchart'));
    cla;
    if isnan(perf(1, 2)),
        col = [1 1 1];
        for j = 0:shadestep:(1-shadestep),
            thiscol = col * (1-abs(0.5 - j));
            h = patch([0 1 1 0], [j j j+shadestep j+shadestep], thiscol);
            set(h, 'edgecolor', 'none');
        end
    else
        left = 0;
        for i = 1:size(perf, 1),
            if perf(i, 2) > 0
                cnum = rem(i, numcolors);
                if cnum == 0,
                    cnum = numcolors;
                end
                col = colororder(cnum, :);
                for j = 0:shadestep:(1-shadestep),
                    thiscol = col * (1 - abs(0.5 - j));
                    h = patch([left left+perf(i, 2) left+perf(i, 2) left], [j j j+shadestep j+shadestep], thiscol);
                    if left > 0,
                        d = patch([left left left left], [j j j+shadestep j+shadestep], 'black');
                    end
                    set(h, 'edgecolor', 'none');
                end
                midx = ((2*left) + perf(i, 2))/2;
                t = text(midx, 0.5, num2str(i-1));
                set(t, 'fontsize', 10, 'color', [1 1 1], 'fontweight', 'bold');
                left = left + perf(i, 2);
            end
        end
    end

    set(gcf, 'CurrentAxes', findobj('tag', 'conditionchart'));
    cla;
    if isnan(perf(1, 3)),
        col = [1 1 1];
        for j = 0:shadestep:(1-shadestep),
            thiscol = col * (1-abs(0.5 - j));
            h = patch([0 1 1 0], [j j j+shadestep j+shadestep], thiscol);
            set(h, 'edgecolor', 'none');
        end
    else
        left = 0;
        for i = 1:size(perf, 1),
            if perf(i, 3) > 0,
                cnum = rem(i, numcolors);
                if cnum == 0,
                    cnum = numcolors;
                end
                col = colororder(cnum, :);
                for j = 0:shadestep:(1-shadestep),
                    thiscol = col * (1 - abs(0.5 - j));
                    h = patch([left left+perf(i, 3) left+perf(i, 3) left], [j j j+shadestep j+shadestep], thiscol);
                    if left > 0,
                        d = patch([left left left left], [j j j+shadestep j+shadestep], 'black');
                    end
                    set(h, 'edgecolor', 'none');
                end
                midx = ((2*left) + perf(i, 3))/2;
                t = text(midx, 0.5, num2str(i-1));
                set(t, 'fontsize', 10, 'color', [1 1 1], 'fontweight', 'bold');
                left = left + perf(i, 3);
            end
        end
    end
    
    set(gcf, 'CurrentAxes', findobj('tag', 'recentchart'));
    cla;
    if isnan(perf(1, 4)),
        col = [1 1 1];
        for j = 0:shadestep:(1-shadestep),
            thiscol = col * (1-abs(0.5 - j));
            h = patch([0 1 1 0], [j j j+shadestep j+shadestep], thiscol);
            set(h, 'edgecolor', 'none');
        end
    else
        left = 0;
        for i = 1:size(perf, 1),
            if perf(i, 4) > 0,
                cnum = rem(i, numcolors);
                if cnum == 0,
                    cnum = numcolors;
                end
                col = colororder(cnum, :);
                for j = 0:shadestep:(1-shadestep),
                    thiscol = col * (1 - abs(0.5 - j));
                    h = patch([left left+perf(i, 4) left+perf(i, 4) left], [j j j+shadestep j+shadestep], thiscol);
                    if left > 0,
                        d = patch([left left left left], [j j j+shadestep j+shadestep], 'black');
                    end
                    set(h, 'edgecolor', 'none');
                end
                midx = ((2*left) + perf(i, 4))/2;
                t = text(midx, 0.5, num2str(i-1));
                set(t, 'fontsize', 10, 'color', [1 1 1], 'fontweight', 'bold');
                left = left + perf(i, 4);
            end
        end
    end

    set(gcf, 'CurrentAxes', findobj(gcf, 'tag', 'replica'));

elseif procnum == 4, %update timeline

    set(gcf, 'CurrentAxes', findobj('tag', 'timeline'));
    delete(findobj(gca, 'tag', 'eventobject'));

    Bcodesandtimes = ScreenInfo;
    BehavioralCodes = varargin{1};
    trialinfo = varargin{2};
    trialnumber = trialinfo(1);
    conditionnumber = trialinfo(2);

    Bcodes = Bcodesandtimes(:, 1);
    Btimes = Bcodesandtimes(:, 2);
    numcodes = length(Bcodes);
    if numcodes > 0 && max(Btimes) > 0,
        maxtime = max(Btimes);
        axrange = ty2-ty1;
        vpos1 = ty2 - axrange*(Btimes/maxtime);
        vpos1 = vpos1';
        vpos2 = vpos1;
        xpos1 = tx1 - 0.01;
        xpos1 = ones(size(vpos1)) * xpos1;
        xpos2 = tx2 + 0.02;
        xpos2 = ones(size(vpos2)) * xpos2;

        tiks = 0:500:maxtime;
        vtik1 = ty2 - axrange*(tiks/maxtime);
        vtik2 = vtik1;
        xtik1 = ones(size(vtik1)) * tx1;
        xtik2 = ones(size(vtik1)) * tx2;
        htik = line([xtik1; xtik2], [vtik1; vtik2]);
        set(htik, 'tag', 'eventobject', 'color', [0.5 0.5 0.7], 'linewidth', 2);

        hline = line([xpos1; xpos2], [vpos1; vpos2]);
        set(hline, 'tag', 'eventobject', 'color', [1 0 0], 'linewidth', 4);

        if ~isempty(BehavioralCodes),
            [flg indx] = ismember(Bcodes, BehavioralCodes.CodeNumbers);
            if any(~flg),
                indx(~flg) = numcodes + 1;
                BehavioralCodes.CodeNames(numcodes+1) = {'Undefined'};
            end
            CodeDescriptions = BehavioralCodes.CodeNames(indx);
            htext2 = text(xpos2+0.04, vpos1, CodeDescriptions);
            set(htext2, 'tag', 'eventobject', 'color', [1 1 1], 'fontsize', 8);
        end
        htext1 = text(xpos1-0.04, vpos1, num2str(Btimes));
        htext3 = text(0.5, 0.94, sprintf('Trial # %i   Condition # %i', trialnumber, conditionnumber));
        set(htext1, 'tag', 'eventobject', 'color', [1 1 1], 'fontsize', 8, 'horizontalalignment', 'right');
        set(htext3, 'tag', 'eventobject', 'color', [1 1 1], 'fontsize', 8, 'horizontalalignment', 'center');
    end
    set(gcf, 'CurrentAxes', findobj('tag', 'replica'));

elseif procnum == 5, %update RT graphs
    
    rtg = findobj('tag', 'rtgraph');
    set(gcf, 'CurrentAxes', rtg);
    userplot = ischar(ScreenInfo);
    if userplot,
        fxn = ScreenInfo;
        TrialRecord = varargin{1};
        try
            feval(fxn, TrialRecord);
            set(rtg,'tag','rtgraph');
        catch ME
            fprintf('Warning: Error encountered in User-Plot function:\n%s\n',getReport(ME));
        end
    else
        cla;
        RTall = ScreenInfo;
        RTcond = varargin{1};
        if isnan(RTall),
            rtmax = 500;
        else
            rtmax = max(RTall);
            if rtmax < 250,
                rtmax = 250;
            end
        end
        xbins = 0:25:rtmax;
        if ~isempty(RTall) && any(~isnan(RTall)),
            [nall xall] = hist(RTall, xbins);
            barwidth = 1.0;
            h(1) = bar(xall, nall, barwidth);
            set(h(1), 'facecolor', [1 1 0]);
            if ~isempty(RTcond) && any(~isnan(RTcond)),
                [ncond xcond] = hist(RTcond, xbins);
                ncond = ncond * max(nall)/max(ncond);
                hold on
                h(2) = bar(xcond, -ncond, barwidth);
                set(h(2), 'facecolor', [.8 .8 .3]);
            end
            set(h, 'linewidth', 2);
            ymax = 1.25*max(nall);
            if ymax == 0,
                ymax = 1;
            end
            xmin = min(xall)-10;
            xmax = max(xall)+10;
            possticks = [25 50 75 100 150 200 250 500 750 1000 1500 2000 2500 5000 10000];
            [what where] = min(abs((xmax/4) - possticks));
            ticksize = possticks(where);
            set(gca, 'ytick', [], 'color', [0.5 .5 0.7], 'xlim', [xmin xmax], 'ylim', [-0.9*ymax ymax], 'xtick', 0:ticksize:xmax, 'tag', 'rtgraph');
            htext(1) = text(mean([xmin xmax]), 0.9*ymax, 'Reaction Times');
            set(htext, 'horizontalalignment', 'center', 'color', [1 1 1], 'fontsize', 10, 'fontweight', 'bold');
            htext(2) = text(0.95*xmax, ymax/2, 'All Conditions');
            htext(3) = text(0.95*xmax, -ymax/2, 'This Condition');
            set(htext([2 3]), 'horizontalalignment', 'center', 'rotation', 90, 'color', [1 1 1], 'fontsize', 8, 'fontweight', 'bold');
        end
    end

    set(gcf, 'CurrentAxes', findobj('tag', 'replica'));

elseif procnum == 6, %update user text
    
    new_user_text = varargin{1};
    for i = length(user_text):-1:2,
        user_text{i} = user_text{i-1};
    end
    user_text{1} = new_user_text;
    ut = findobj('tag','usertext');
    set(ut, 'string', user_text);
    
elseif procnum == 7, %update warning text
    
    if isempty(varargin) && ~isempty(warnings),
        warnings=warnings(1:end-1);
    elseif ~isempty(varargin),
        warnings{end+1} = varargin{1};
    end
    
%     if isempty(warnings),
%         wstr = '';
%     elseif length(warnings)==1,
%         wstr = sprintf('Warning: %s',warnings{1});
%     else
%         wstr = sprintf('Warnings (%i): %s',length(warnings),warnings{end});
%     end
%     set(wtext, 'String', wstr);
    
end

return
%%%%%%%%%%%%%%%%%%%%%%%%%%%% SCREEN DRAW TEST
ScreenInfo.Xsize = 800; %#ok<UNRCH>
ScreenInfo.Ysize = 600;
ScreenInfo.Xdegrees = 20;
ScreenInfo.Ydegrees = 16;
ScreenInfo.PixelsPerDegree = 37;
MLConfig.ControlScreenGridCartesian = 1;
MLConfig.ControlScreenGridCartesianBrightness = 0.2;
MLConfig.ControlScreenGridPolar = 1;
MLConfig.ControlScreenGridPolarBrightness = 0.25;
MLConfig.Priority = 1;
initcontrolscreen(1, ScreenInfo, MLConfig);
perf = [.5 .6 .2 .5; 0 0 0 0; 0 0 0 0; .1 .1 .1 .1; .05 .05 .05 .05; .05 .05 .05 .05; .3 .2 .6 .3];
initcontrolscreen(3, perf);

%%%%%%%%%%%%%%%%%%%%%%%%%%%% SCREEN SPEED TEST
set(gcf, 'CurrentAxes', findobj(gcf, 'tag', 'replica'))
t = 0:pi/20:2*pi;
y = exp(sin(t));
h = plot(t,y,'YDataSource','y');
count = 0;
z = zeros(length(1:.1:10), 1);
for k = 1:.1:10,
    count = count + 1;
	y = exp(sin(t.*k));
	refreshdata(h,'caller') % Evaluate y in the function workspace
    tic
	drawnow;
    z(count) = toc;
end
mean(z)

