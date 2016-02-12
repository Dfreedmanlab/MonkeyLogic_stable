function mlmenu(varargin)

% MonkeyLogic main menu
%
% Created by WA, July, 2006
% Modified 7/28/08 -WA (to include "User Plot" button)
% Modified 8/13/08 -WA (to include display of movies in stimulus menu)
% Modified 8/27/08 -WA (to allow pre-processing of visual stimuli)
% Modified 9/08/08 -SM (to use appropriate analog input-type when testing those inputs)
% Modified 2/01/12 -WA (to remove overwrite_hardware_cfg subfunction - had broken the ability to write new cfg files when none present)
% Modified 2/28/14 -ER (to allow the user to select multiple analog channels for I/O testing)
% Modified 3/20/14 -ER (started looking into modifying the DAQ toolbox function calls to handle 64 bit Windows/Matlab)
% Modified 10/01/15 -ER (added touchscreen/mouse controllers)

lastupdate = 'February 2016';
currentversion = '02-12-2016 build 1.1.35';
logger = mllog('mlmenu.log');

mlf = findobj('tag', 'monkeylogicmainmenu');
if ~isempty(mlf) && isempty(gcbo),
    set(0, 'CurrentFigure', mlf);
end

if ~ispref('MonkeyLogic', 'Directories'),
    success = set_ml_preferences;
    if ~success,
        return
    end
end
MLPrefs.Directories = getpref('MonkeyLogic', 'Directories');

validxsize =  [ 320   320    640   768    800    1024   1024  1152  1152   1280     1280   1280   1366   1400    1440   1600   1680     1920     1920   2048  2048  2560       2560    2560    2560    3840    4096];
validysize =  [ 200   240    480   576    600    600    768   768   864    720      960    1024   768    1050    900    1200   1050     1080     1200   1080  1536  1440       1600    1920    2048    2160    3072];
validlabels = {'CGA' 'QVGA' 'VGA' 'PAL'  'SVGA' 'WSVGA' 'XGA' '3:2' '4:3'  'HD720'  '4:3'  '5:4'  'HDTV' 'SXGA+' '8:5'  'UGA' 'WSXGA+' 'HD1080' 'WUXGA' '2K'  'QXGA' 'HD1440' 'WQXGA'  '5MEG' 'QSXGA' 'UHDTV'  '4K'};
validrefresh = [60 72 75 85 100 120 240];

numvalidsizes = length(validxsize);
validsizestrings = cell(1, numvalidsizes);
for i = 1:numvalidsizes,
    validsizestrings{i} = sprintf('%i x %i   %s', validxsize(i), validysize(i), validlabels{i});
end
validrefreshstrings = cellstr(num2str(validrefresh'));

reloadcondfile = 0;
cfgfile = [];
if ~isempty(varargin),
    if isnumeric(varargin{1}),
        if varargin{1} == -1,
            reloadcondfile = 1;
        end
    elseif ischar(varargin{1}),
        cfgfile = varargin{1};
        [pname fname ext] = fileparts(cfgfile);
        if isempty(pname),
            cfgfile = [MLPrefs.Directories.ExperimentDirectory cfgfile];
        else
            MLPrefs.Directories.ExperimentDirectory = [pname filesep];
        end
        if isempty(ext),
            cfgfile = [cfgfile '.txt'];
        end
    end
end

if isempty(cfgfile),
    cfgfile = [MLPrefs.Directories.ExperimentDirectory 'default_cfg.mat'];
end

associated_figures = {'monkeylogicmainmenu' 'mlmonitor' 'lineselectfig' 'iotestfigure' 'xycalibrate' 'chartblocksfigure' 'sampleeye'};
hcount = 0;
h = [];
for i = 1:length(associated_figures),
    f = findobj('tag', associated_figures{i});
    if ~isempty(f),
        hcount = hcount + 1;
        h(hcount) = f; %#ok<AGROW>
    end
end
set(0, 'userdata', h);

if isempty(mlf),
    fprintf('\r\n\r\n\r\n');

    logger.logMessage(sprintf('<<< MonkeyLogic >>> Revision : %s', currentversion))
    chknewupdates(lastupdate);
    envOS = getenv('OS');
    envCN = getenv('COMPUTERNAME');
    envUSER = getenv('USERNAME');
    envNOP = getenv('NUMBER_OF_PROCESSORS');
    envPRC = getenv('PROCESSOR_ARCHITECTURE');
    if isempty(envPRC),
        envPRC = getenv('CPU');
    end
    if ~isempty(envOS),
        logger.logMessage(sprintf('<<< MonkeyLogic >>> Operating System: %s...', envOS))
    end
    if usejava('jvm'),
        logger.logMessage('<<< MonkeyLogic >>> *** JAVA Virtual Machine is Running ***');
    end
    if ~isempty(envCN),
        logger.logMessage(sprintf('<<< MonkeyLogic >>> Computer Name: %s...', envCN))
    end
    if ~isempty(envUSER),
        logger.logMessage(sprintf('<<< MonkeyLogic >>> Logged in as "%s"...', envUSER))
    else
        envUSER = 'Investigator';
    end
    if ~isempty(envNOP),
        envNOP = str2double(envNOP);
        if envNOP > 1,
            logger.logMessage(sprintf('<<< MonkeyLogic >>> Detected %i "%s" processors...', envNOP, envPRC))
        else
            logger.logMessage(sprintf('<<< MonkeyLogic >>> Detected only %i "%s" processor...', envNOP, envPRC))
        end
    end
    envMVER = version;
    logger.logMessage(sprintf('<<< MonkeyLogic >>> Matlab version: %s...', envMVER))
    numloops = 1000;
    t = zeros(numloops, 1);
    tic;
    for i = 1:numloops,
        t(i) = toc;
    end
    mrate = 1/(mean(diff(t))*1000);
    logger.logMessage(sprintf('<<< MonkeyLogic >>> Approximate Matlab cycle rate is %4.0f kHz', mrate))
    logger.logMessage('<<< MonkeyLogic >>> Launching Menu...')
    figure;
    figbg = [.65 .70 .80];
    bgpurple = [.8 .76 .82];
    figx = 1200;
    figy = 750;
    scrnsz = get(0, 'screensize');
    scrnx = scrnsz(3);
    scrny = scrnsz(4);
    if scrnx < 1280 || scrny < 768,
        logger.logMessage('<<< MonkeyLogic >>> Warning: A primary-monitor resolution of at least 1280 x 768 is recommended...')
    end
    fxpos = 0.5 * (scrnx - figx);
    fypos = 0.5 * (scrny - figy);
    if fxpos < 0,
        fxpos = 0;
    end
    if fypos < 0,
        fypos = 0;
    end
    figsize = [fxpos fypos figx figy];
    set(gcf, 'numbertitle', 'off', 'name', 'MonkeyLogic Menu', 'menubar', 'none', 'position', figsize, 'tag', 'monkeylogicmainmenu', 'resize', 'off', 'userdata', MLPrefs.Directories, 'color', figbg);
    set(gcf, 'closerequestfcn', 'mlmenu; delete(get(0, ''userdata'')); set(0, ''userdata'', ''''); disp(''Closed MonkeyLogic.'')');
    
    mlvideo('mlinit');
    logger.logMessage('<<< MonkeyLogic >>> Initialized ML Video Graphics interface...')
    
    ybase = 550;
    uicontrol('style', 'frame', 'position', [10 ybase+22 280 80], 'backgroundcolor', 0.85*figbg, 'foregroundcolor', 0.6*figbg);
    uicontrol('style', 'text', 'position', [14 ybase+75 90 18], 'string', 'Experiment Name:', 'backgroundcolor', 0.85*figbg, 'horizontalalignment', 'right');
    uicontrol('style', 'edit', 'position', [110 ybase+78 175 20], 'backgroundcolor', [1 1 1], 'tag', 'experimentname', 'string', 'Experiment', 'callback', 'mlmenu');
    uicontrol('style', 'text', 'position', [14 ybase+50 90 18], 'string', 'Investigator(s):', 'backgroundcolor', 0.85*figbg, 'horizontalalignment', 'right');
    uicontrol('style', 'edit', 'position', [110 ybase+53 175 20], 'backgroundcolor', [1 1 1], 'tag', 'investigator', 'string', envUSER, 'callback', 'mlmenu');
    f = max(find(cfgfile == filesep)); %#ok<MXFND>
    cfgname = cfgfile(f+1:length(cfgfile));
    uicontrol('style', 'text', 'position', [14 ybase+25 92 18], 'string', 'Configuration Data:', 'backgroundcolor', 0.85*figbg, 'horizontalalignment', 'right');
    h = uicontrol('style', 'pushbutton', 'position', [110 ybase+26 175 22], 'string', cfgname, 'tag', 'configfilename', 'callback', 'mlmenu');
        set(h, 'enable', 'off');
    h = subplot('position', [9/figsize(3) (ybase+105)/figsize(4) 280/figsize(3) 83/figsize(4)]);
    image(imread('threemonkeys.jpg'));
    set(h, 'xtick', [], 'ytick', [], 'box', 'on');
    
    ybase = 150;
    fbg = [0.9255 0.9137 0.8471];
    h = uicontrol('style', 'frame', 'position', [300 ybase-47 425 225], 'backgroundcolor', fbg); %task
    fcolor = get(h, 'backgroundcolor');
    uicontrol('style', 'frame', 'position', [735 ybase-75 455 665], 'backgroundcolor', fbg, 'tag', 'ioframe'); %i/o
    fx = 745;
    fy = ybase+558;
    fw = 180;
    fh = 25;
    uicontrol('style', 'pushbutton', 'position', [fx fy fw fh], 'cdata', imread('ioheader.jpg'), 'enable', 'inactive');
    clean_borders(fx, fy, fw, fh, fbg);

    uicontrol('style', 'frame', 'position', [735 10 455 60], 'backgroundcolor', 0.85*figbg, 'foregroundcolor', 0.6*figbg);

    bbg = [.87 .85 .7];
    uicontrol('style', 'pushbutton', 'position', [743 24 67 33], 'string', 'Online Help', 'callback', 'web(''http://www.monkeylogic.net'', ''-browser'');', 'backgroundcolor', bbg, 'fontweight', 'normal');
    uicontrol('style', 'pushbutton', 'position', [1115 24 67 33], 'string', 'About...', 'backgroundcolor', bbg, 'tag', 'aboutbutton', 'fontweight', 'normal', 'callback', 'mlmenu');
    uicontrol('style', 'frame', 'position', [820 16 285 48], 'backgroundcolor', [1 1 1], 'tag', 'mlmessageframe');
    uicontrol('style', 'text', 'position', [825 18 275 41], 'backgroundcolor', [1 1 1], 'tag', 'mlmessagebox', 'fontsize', 8, 'fontweight', 'bold', 'string', '');
    
    % TASK ######################################   
    ybase = 250;
    xbase = 430;
    uicontrol('style', 'frame', 'position', [xbase-130 ybase+225 425 265], 'backgroundcolor', fbg);
    fx = 310;
    fy = ybase+448;
    fw = 90;
    fh = 30;
    uicontrol('style', 'pushbutton', 'position', [fx fy fw fh], 'cdata', imread('taskheader.jpg'), 'enable', 'inactive');
    clean_borders(fx, fy, fw, fh, fbg);

    uicontrol('style', 'pushbutton', 'position', [xbase-10 ybase+440 170 40], 'string', 'Load Conditions File', 'tag', 'condfileselect', 'callback', 'mlmenu', 'backgroundcolor', bgpurple, 'fontsize', 10);
    uicontrol('style', 'pushbutton', 'position', [xbase-10 ybase+412 170 23], 'string', 'Edit Conditions File', 'tag', 'editconds', 'callback', 'mlmenu', 'enable', 'off');
    uicontrol('style', 'pushbutton', 'position', [xbase+170 ybase+412 110 30], 'string', 'Save Settings', 'enable', 'off', 'tag', 'savebutton', 'callback', 'mlmenu');
    uicontrol('style', 'pushbutton', 'position', [xbase+170 ybase+450 110 30], 'string', 'Load Settings', 'tag', 'loadbutton', 'callback', 'mlmenu', 'userdata', struct);
    
    ybase = 260;
    xbase = 675;
    uicontrol('style', 'frame', 'position', [xbase-365 ybase+318 225 76], 'backgroundcolor', 0.9*fbg, 'foregroundcolor', 0.8*fbg);
    shadewidth = 35;
    minstep = xbase-364;
    maxstep = minstep + shadewidth;
    stepsize = 1;
    numsteps = length(minstep:stepsize:maxstep);
    shademin = 0.6;
    shademax = 0.887;
    stepnum = 0;
    for i = minstep:stepsize:maxstep,
        stepnum = stepnum + 1;
        shadefraction = stepnum/numsteps;
        fshade = fbg*(shademin + (shadefraction*(shademax - shademin)));
        uicontrol('style','frame', 'position', [i ybase+319 stepsize 74], 'backgroundcolor', fshade, 'foregroundcolor', fshade);
    end
    minstep = xbase-142;
    maxstep = minstep - shadewidth;
    stepnum = 0;
    for i = minstep:-stepsize:maxstep,
        stepnum = stepnum + 1;
        shadefraction = stepnum/numsteps;
        fshade = fbg*(shademin + (shadefraction*(shademax - shademin)));
        uicontrol('style','frame', 'position', [i ybase+319 stepsize 74], 'backgroundcolor', fshade, 'foregroundcolor', fshade);
    end
    uicontrol('style', 'text', 'position', [xbase-310 ybase+365 100 20], 'string', 'Total # of conditions:', 'backgroundcolor', 0.9*fbg);
    uicontrol('style', 'edit', 'position', [xbase-205 ybase+370 50 20], 'string', '--', 'enable', 'off', 'tag', 'totalconds');
    uicontrol('style', 'text', 'position', [xbase-322 ybase+342 112 20], 'string', 'Maximum trials to run:', 'backgroundcolor', 0.9*fbg, 'horizontalalignment', 'right');
    uicontrol('style', 'edit', 'position', [xbase-205 ybase+346 50 20], 'string', '5000', 'backgroundcolor', [1 1 1], 'tag', 'maxtrials', 'callback', 'mlmenu');
    uicontrol('style', 'text', 'position', [xbase-322 ybase+319 112 20], 'string', 'Maximum blocks to run:', 'backgroundcolor', 0.9*fbg, 'horizontalalignment', 'right');
    uicontrol('style', 'edit', 'position', [xbase-205 ybase+322 50 20], 'string', '1000', 'backgroundcolor', [1 1 1], 'tag', 'maxblocks', 'callback', 'mlmenu');
        
    ybase = 480;
    xbase = 327;
    uicontrol('style', 'frame', 'position', [xbase-17 ybase+3 320 92], 'backgroundcolor', fcolor);
    uicontrol('style', 'frame', 'position', [xbase+213 ybase+3 175 171], 'backgroundcolor', fcolor);
    uicontrol('style', 'text', 'position', [xbase+212 ybase+4 3 90], 'backgroundcolor', fcolor);
    
    uicontrol('style', 'text', 'position', [xbase+309 ybase+143 70 20], 'string', 'Blocks to run:', 'backgroundcolor', fbg);
    uicontrol('style', 'listbox', 'position', [xbase+312 ybase+38 64 108], 'enable', 'off', 'tag', 'runblocks', 'backgroundcolor', [1 1 1], 'string', '--', 'callback', 'mlmenu', 'max', 2, 'userdata', 1);
    uicontrol('style', 'pushbutton', 'position', [xbase+314 ybase+10 60 22], 'enable', 'off', 'string', 'All', 'callback', 'mlmenu', 'tag', 'allblocks');    
    uicontrol('style', 'text', 'position', [xbase+220 ybase+143 70 20], 'string', 'First block:', 'backgroundcolor', fbg);
    uicontrol('style', 'listbox', 'position', [xbase+225 ybase+100 64 45], 'enable', 'off', 'string', '--', 'backgroundcolor', [1 1 1], 'tag', 'firstblock', 'callback', 'mlmenu')
    
    uicontrol('style', 'text', 'position', [xbase-8 ybase+71 20 15], 'string', 'B', 'backgroundcolor', fcolor, 'horizontalalignment', 'center');
    uicontrol('style', 'text', 'position', [xbase-8 ybase+59 20 15], 'string', 'L', 'backgroundcolor', fcolor, 'horizontalalignment', 'center');
    uicontrol('style', 'text', 'position', [xbase-8 ybase+47 20 15], 'string', 'O', 'backgroundcolor', fcolor, 'horizontalalignment', 'center');
    uicontrol('style', 'text', 'position', [xbase-8 ybase+35 20 15], 'string', 'C', 'backgroundcolor', fcolor, 'horizontalalignment', 'center');
    uicontrol('style', 'text', 'position', [xbase-8 ybase+23 20 15], 'string', 'K', 'backgroundcolor', fcolor, 'horizontalalignment', 'center');
    uicontrol('style', 'text', 'position', [xbase-8 ybase+11 20 15], 'string', 'S', 'backgroundcolor', fcolor, 'horizontalalignment', 'center');
    uicontrol('style', 'listbox', 'position', [xbase+13 ybase+10 60 77], 'string', '--', 'enable', 'off', 'backgroundcolor', [1 1 1], 'tag', 'blocklist', 'callback', 'mlmenu', 'userdata', 1);
    
    uicontrol('style', 'text', 'position', [xbase+120 ybase+25 130 20], 'string', 'Count only correct trials:', 'backgroundcolor', fcolor);
    uicontrol('style', 'checkbox', 'position', [xbase+248 ybase+30 15 15], 'tag', 'countonlycorrect', 'value', 0, 'callback', 'mlmenu');
    %%%%%
    uicontrol('style', 'text', 'position', [xbase+80 ybase+44 170 20], 'string', 'Number of trials to run this block:', 'backgroundcolor', fcolor);
    uicontrol('style', 'edit', 'position', [xbase+248 ybase+47 40 20], 'string', '50', 'enable', 'off', 'backgroundcolor', [1 1 1], 'tag', 'trialsperblock', 'callback', 'mlmenu', 'userdata', 50);
    uicontrol('style', 'text', 'position', [xbase+80 ybase+69 170 20], 'string', 'Total # of conditions in this block:', 'backgroundcolor', fcolor);
    uicontrol('style', 'edit', 'position', [xbase+248 ybase+72 40 20], 'string', '--', 'enable', 'off', 'tag', 'condsperblock');
    uicontrol('style', 'pushbutton', 'position', [xbase+85 ybase+7 100 20], 'string', 'Chart Blocks', 'tag', 'chartblocks', 'callback', 'mlmenu', 'enable', 'off');
    uicontrol('style', 'pushbutton', 'position', [xbase+190 ybase+7 100 20], 'string', 'Apply to all', 'tag', 'applyblocknumstoall', 'callback', 'mlmenu', 'enable', 'off');   
    
    ybase = 217;
    uicontrol('style', 'frame', 'position', [558 ybase-105 157 200], 'backgroundcolor', fbg);
    uicontrol('style', 'frame', 'position', [563 ybase-6 147 90], 'foregroundcolor', 0.8*fbg, 'backgroundcolor', 0.9*fbg);
    uicontrol('style', 'text', 'position', [610 ybase+84 50 20], 'string', 'Timing', 'backgroundcolor', fbg, 'horizontalalignment', 'center', 'fontsize', 10);
    uicontrol('style', 'listbox', 'position', [568 ybase+25 137 53], 'string', '--', 'tag', 'timingfiles', 'backgroundcolor', [1 1 1], 'enable', 'off');
    uicontrol('style', 'pushbutton', 'position', [585 ybase-1 105 21], 'string', 'Edit', 'tag', 'edittimingfile', 'enable', 'off', 'callback', 'mlmenu');
    
    uicontrol('style', 'text', 'position', [565 ybase-37 145 20], 'string', 'Inter-trial interval:               ms', 'backgroundcolor', fbg);
    uicontrol('style', 'edit', 'position', [652 ybase-32 38 20], 'string', '2000', 'userdata', 2000, 'tag', 'iti', 'backgroundcolor', [1 1 1], 'callback', 'mlmenu');
    
    uicontrol('style', 'frame', 'position', [563 ybase-99 147 61], 'backgroundcolor', 0.9*fbg, 'foregroundcolor', 0.8*fbg);
    uicontrol('style', 'pushbutton', 'position', [566 ybase-66 141 24], 'string', 'MonkeyLogic Latency Test', 'tag', 'mltimetest', 'callback', 'mlmenu', 'enable', 'off');
    uicontrol('style', 'pushbutton', 'position', [566 ybase-95 141 24], 'string', 'Matlab Latency Test', 'tag', 'speedtest', 'callback', 'mlmenu');
    
    ybase = 223;
    uicontrol('style', 'frame', 'position', [300 ybase+112 222 133], 'backgroundcolor', 0.85*figbg, 'foregroundcolor', 0.6*figbg);
    uicontrol('style', 'listbox', 'position', [305 ybase+137 213 105], 'string', '--', 'tag', 'stimnames', 'backgroundcolor', [1 1 1], 'enable', 'off', 'callback', 'mlmenu');
    uicontrol('style', 'text', 'position', [325 ybase+114 180 18], 'string', 'Save Full Movies to BHV File: ', 'backgroundcolor', 0.85*figbg, 'horizontalalignment', 'left');
    uicontrol('style', 'checkbox', 'position', [475 ybase+119 15 15], 'tag', 'savefullmovies', 'value', 1, 'callback', 'mlmenu');
    h = subplot('position', [525/figx (ybase+116)/figy 125/figx 125/figy]);
    image(imread('earth.jpg'));
    set(h, 'tag', 'stimax', 'xtick', [], 'ytick', [], 'box', 'on', 'ycolor', [1 1 1], 'xcolor', [1 1 1]);
    
    uicontrol('style', 'frame', 'position', [656 ybase+112 68 133], 'backgroundcolor', 0.85*figbg, 'foregroundcolor', 0.6*figbg);
    uicontrol('style', 'text', 'position', [660 ybase+227 60 15], 'string', 'Zoom', 'backgroundcolor', 0.85*figbg);
    uicontrol('style', 'slider', 'position', [660 ybase+208 60 20], 'enable', 'off', 'tag', 'zoomslider', 'callback', 'mlmenu');
    uicontrol('style', 'text', 'position', [660 ybase+190 60 15], 'string', 'Position', 'backgroundcolor', 0.85*figbg);
    uicontrol('style', 'slider', 'position', [660 ybase+171 60 20], 'enable', 'off', 'tag', 'positionslider', 'callback', 'mlmenu');
    uicontrol('style', 'pushbutton', 'position', [660 ybase+144 60 22], 'string', 'Test', 'tag', 'viewplay', 'enable', 'off', 'callback', 'mlmenu');
    uicontrol('style', 'toggle', 'position', [660 ybase+117 60 22], 'string', 'Process', 'tag', 'preprocessimages', 'enable', 'off', 'callback', 'mlmenu');
    
    ybase = 97;
    uicontrol('style', 'frame', 'position', [310 ybase+15 240 200], 'backgroundcolor', fbg);
    uicontrol('style', 'text', 'position', [383 ybase+209 90 15], 'string', 'Trial Selection', 'backgroundcolor', fbg, 'fontsize', 10);
    
    uicontrol('style', 'frame', 'position', [315 ybase+170 230 33], 'backgroundcolor', 0.9*fbg, 'foregroundcolor', 0.8*fbg);
    uicontrol('style', 'text', 'position', [317 ybase+172 57 20], 'string', 'On error:', 'backgroundcolor', 0.9*fbg, 'horizontalalignment', 'right');
    erroroptions = {'ignore' 'repeat immediately' 'repeat delayed'}';
    uicontrol('style', 'popupmenu', 'position', [380 ybase+177 160 20], 'string', erroroptions, 'tag', 'errorlogic', 'backgroundcolor', [1 1 1], 'callback', 'mlmenu');
    
    uicontrol('style', 'frame', 'position', [315 ybase+110 230 61], 'backgroundcolor', fbg, 'foregroundcolor', 0.8*fbg);
    uicontrol('style', 'text', 'position', [317 ybase+138 57 20], 'string', 'Conditions:', 'backgroundcolor', fbg, 'horizontalalignment', 'right');
    condoptions = {'Random with replacement' 'Random w/out replacement' 'increasing', 'decreasing' 'user-defined'}';
    uicontrol('style', 'popupmenu', 'position', [380 ybase+143 160 20], 'string', condoptions, 'tag', 'condlogic', 'backgroundcolor', [1 1 1], 'callback', 'mlmenu');
    uicontrol('style', 'pushbutton', 'position', [320 ybase+115 220 20], 'string', 'n/a', 'tag', 'condselectfun', 'backgroundcolor', [1 1 1], 'enable', 'off', 'callback', 'mlmenu', 'userdata', '');
    
    uicontrol('style', 'frame', 'position', [315 ybase+50 230 61], 'backgroundcolor', 0.9*fbg, 'foregroundcolor', 0.8*fbg);
    uicontrol('style', 'text', 'position', [317 ybase+80 57 20], 'string', 'Blocks:', 'horizontalalignment' ,'right', 'backgroundcolor', 0.9*fbg);
    blockoptions = {'Random with replacement' 'Random w/out replacement' 'increasing' 'decreasing' 'user-defined'};
    uicontrol('style', 'popupmenu', 'position', [380 ybase+86 160 20], 'string', blockoptions, 'tag', 'blocklogic', 'backgroundcolor', [1 1 1], 'callback', 'mlmenu');
    uicontrol('style', 'pushbutton', 'position', [320 ybase+57 220 20], 'string', 'n/a', 'tag', 'blockselectfun', 'backgroundcolor', [1 1 1], 'enable', 'off', 'callback', 'mlmenu', 'userdata', '');
    uicontrol('style', 'frame', 'position', [315 ybase+20 230 31], 'backgroundcolor', fbg, 'foregroundcolor', 0.8*fbg);
    uicontrol('style', 'pushbutton', 'position', [320 ybase+25 220 20], 'string', 'Block Change Function', 'tag', 'blockchangefun', 'backgroundcolor', [1 1 1], 'enable', 'on', 'callback', 'mlmenu', 'userdata', '');

    f2bg = [0.9 0.9 0.6];
    ybase = 15;
    uicontrol('style', 'frame', 'position', [300 ybase-5 425 87], 'backgroundcolor', f2bg);
    uicontrol('style', 'text', 'position', [310 ybase-1 80 20], 'string', 'Data File (*.bhv): ', 'backgroundcolor', f2bg);
    uicontrol('style', 'edit', 'position', [400 ybase+2 315 20], 'string', '', 'backgroundcolor', [1 1 1], 'tag', 'datafile', 'callback', 'mlmenu');
    uicontrol('style', 'text', 'position', [310 ybase+25 80 20], 'string', 'Subject''s Name:', 'backgroundcolor', f2bg);
    uicontrol('style', 'edit', 'position', [400 ybase+28 145 20], 'string', '', 'backgroundcolor', [1 1 1], 'tag', 'subjectname', 'callback', 'mlmenu', 'userdata', '');
    uicontrol('style', 'text', 'position', [305 ybase+50 90 20], 'string', 'Run-time priority:', 'backgroundcolor', f2bg);
    uicontrol('style', 'popupmenu', 'position', [400 ybase+55 145 20], 'string', {'Normal' 'High' 'Highest'}, 'backgroundcolor', [1 1 1], 'tag', 'priority', 'callback', 'mlmenu');

    uicontrol('style', 'frame', 'position', [559 ybase+27 157 50], 'backgroundcolor', figbg, 'foregroundcolor', [.5 .5 .5]);
        pic = 'runbuttondim.jpg';
    uicontrol('style', 'pushbutton', 'position', [560 ybase+28 155 48], 'string', '', 'callback', 'mlmenu', 'tag', 'runbutton', 'backgroundcolor', [0.9 0.6 0.6], 'enable', 'inactive', 'cdata', imread(pic));
    logger.logMessage('<<< MonkeyLogic >>> Initialized Task Menu...')
    
    % VIDEO ######################################
    mlvideo('init');
    numdevices = mlvideo('devices');
    if numdevices > 1,
        logger.logMessage(sprintf('<<< MonkeyLogic >>> Found %i video devices...', numdevices))
    else
        logger.logMessage('<<< MonkeyLogic >>> Warning: Found only 1 video device...')
    end
    mlvideo('release');
    
    ybase = 150;
    uicontrol('style', 'frame', 'position', [10 ybase+111 280 309], 'backgroundcolor', fbg); %video
    fx = 15;
    fy = ybase+383;
    fw = 100;
    fh = 30;
    uicontrol('style', 'pushbutton', 'position', [fx fy fw fh], 'cdata', imread('videoheader.jpg'), 'enable', 'inactive');
    clean_borders(fx, fy, fw, fh, fbg);

    ybase = 265;
    uicontrol('style', 'text', 'position', [20 ybase+215 90 20], 'string', 'Screen resolution:', 'backgroundcolor', fbg);
    uicontrol('style', 'popupmenu', 'position', [118 ybase+220 100 20], 'backgroundcolor', [1 1 1], 'string', validsizestrings, 'tag', 'screenres', 'callback', 'mlmenu', 'value', 2, 'userdata', [validxsize' validysize']);
    uicontrol('style', 'text', 'position', [20 ybase+245 150 20], 'string', 'Video device (subject screen):', 'backgroundcolor', fbg);
    uicontrol('style', 'popupmenu', 'position', [178 ybase+250 40 20], 'string', cellstr(num2str((1:numdevices)')), 'backgroundcolor', [1 1 1], 'value', numdevices, 'tag', 'videodevice', 'callback', 'mlmenu', 'userdata', 'numdevices');
    uicontrol('style', 'frame', 'position', [225 ybase+219 55 51], 'backgroundcolor', fbg, 'foregroundcolor', 0.8*fbg);
    uicontrol('style', 'pushbutton', 'position', [230 ybase+224 45 41], 'string', 'Test', 'tag', 'videotest', 'callback', 'mlmenu');
    uicontrol('style', 'text', 'position', [20 ybase+185 100 20], 'string', 'Refresh Rate (Hz):', 'backgroundcolor', fbg, 'horizontalalignment', 'left');
    uicontrol('style', 'popupmenu', 'position', [118 ybase+190 45 20], 'string', validrefreshstrings, 'backgroundcolor', [1 1 1], 'tag', 'refreshrate', 'callback', 'mlmenu', 'value', 1, 'userdata', validrefresh);
    uicontrol('style', 'text', 'position', [173 ybase+185 80 20], 'string', 'Buffer Pages:', 'backgroundcolor', fbg, 'horizontalalignment', 'left');
    uicontrol('style', 'popupmenu', 'position', [245 ybase+190 34 20], 'string', num2str((1:3)'), 'value', 2, 'backgroundcolor', [1 1 1], 'tag', 'bufferpages', 'callback', 'mlmenu');
    
    uicontrol('style', 'frame', 'position', [18 ybase+117 264 63], 'backgroundcolor', 0.9*fbg, 'foregroundcolor', 0.8*fbg);
    uicontrol('style', 'text', 'position', [25 ybase+143 60 30], 'string', 'Diagonal size (cm)', 'backgroundcolor', 0.9*fbg);
    diagsize = 43.18; %default diagonal screen size (~17 inch 4:3 monitor)
    uicontrol('style', 'edit', 'position', [87 ybase+150 40 20], 'backgroundcolor', [1 1 1], 'string', num2str(diagsize), 'tag', 'diagsize', 'callback', 'mlmenu', 'userdata', diagsize);
    uicontrol('style', 'text', 'position', [153 ybase+143 70 30], 'string', 'Viewing distance (cm)', 'backgroundcolor', 0.9*fbg);
    viewdist = 75; %default viewing distance (~2.5ft)
    uicontrol('style', 'edit', 'position', [231 ybase+150 40 20], 'backgroundcolor', [1 1 1], 'string', num2str(viewdist), 'tag', 'viewdist', 'callback', 'mlmenu', 'userdata', viewdist);
    uicontrol('style', 'text', 'position', [75 ybase+118 100 20], 'string', 'Pixels per degree  =', 'backgroundcolor', 0.9*fbg, 'fontangle', 'italic');
    uicontrol('style', 'text', 'position', [180 ybase+118 40 20], 'backgroundcolor', 0.9*fbg, 'string', '33.4', 'tag', 'ppd', 'horizontalalignment', 'left');
    
    ybase = 270;
    uicontrol('style', 'text', 'position', [20 ybase+80 140 20], 'string', 'Photodiode trigger:', 'backgroundcolor', fbg, 'horizontalalignment', 'left');
    uicontrol('style', 'popupmenu', 'position', [120 ybase+84 85 20], 'string', {'None' 'Upper left' 'Upper right' 'Lower right' 'Lower left'}, 'callback', 'mlmenu', 'tag', 'photodiode', 'backgroundcolor', [1 1 1]);
    uicontrol('style', 'text', 'position', [215 ybase+80 30 20], 'string', 'Size:', 'backgroundcolor', fbg);
    uicontrol('style', 'edit', 'position', [250 ybase+84 30 20], 'string', '0', 'backgroundcolor', [1 1 1], 'tag', 'photodiodesize', 'callback', 'mlmenu', 'enable', 'off');
    
    uicontrol('style', 'text', 'position', [20 ybase+49 105 20], 'string', 'Fixation point image', 'backgroundcolor', fbg, 'horizontalalignment', 'left');
    uicontrol('style', 'pushbutton', 'position', [130 ybase+52 150 22], 'tag', 'fixationfilename', 'callback', 'mlmenu', 'string', '- Default -', 'userdata', 'DEFAULT');
    uicontrol('style', 'text', 'position', [20 ybase+22 105 20], 'string', 'Subject cursor image', 'backgroundcolor', fbg, 'horizontalalignment', 'left');
    uicontrol('style', 'pushbutton', 'position', [130 ybase+25 150 22], 'tag', 'cursorfilename', 'callback', 'mlmenu', 'string', '- Default -', 'userdata', 'DEFAULT');
        
    xbase = 134;
    ybase = 290;
    defaultbgcolor = [0 0 0];
    uicontrol('style', 'text', 'position', [20 ybase-27 170 20], 'string', 'Subject screen background RGB', 'backgroundcolor', fbg, 'horizontalalignment', 'left');
    uicontrol('style', 'edit', 'position', [xbase+45 ybase-22 33 20], 'string', num2str(defaultbgcolor(1)), 'userdata', defaultbgcolor(1), 'backgroundcolor', [1 1 1], 'tag', 'bgred', 'callback', 'mlmenu');
    uicontrol('style', 'edit', 'position', [xbase+78 ybase-22 33 20], 'string', num2str(defaultbgcolor(2)), 'userdata', defaultbgcolor(2), 'backgroundcolor', [1 1 1], 'tag', 'bggreen', 'callback', 'mlmenu');
    uicontrol('style', 'edit', 'position', [xbase+111 ybase-22 33 20], 'string', num2str(defaultbgcolor(3)), 'userdata', defaultbgcolor(3), 'backgroundcolor', [1 1 1], 'tag', 'bgblue', 'callback', 'mlmenu');
    logger.logMessage('<<< MonkeyLogic >>> Initialized Video Menu...')
    
    % Control Screen Options ###################################### 
    ybase = 73;
    defaultupdateinterval = 50;
    uicontrol('style', 'frame', 'position', [10 ybase+138 280 46], 'backgroundcolor', 0.85*figbg, 'foregroundcolor', 0.6*figbg);
    uicontrol('style', 'text', 'position', [15 ybase+162 270 20], 'string', '- Control Screen Options -', 'fontsize', 10, 'fontweight', 'bold', 'backgroundcolor', 0.85*figbg, 'horizontalalignment', 'center');
    uicontrol('style', 'text', 'position', [62 ybase+139 150 20], 'string', 'Refresh interval (milliseconds):', 'backgroundcolor', 0.85*figbg);
    uicontrol('style', 'edit', 'position', [216 ybase+142 30 20], 'backgroundcolor', [1 1 1], 'tag', 'updateinterval', 'string', num2str(defaultupdateinterval), 'userdata', defaultupdateinterval, 'callback', 'mlmenu');
    
    ybase = 112;
    xbase = 13;
    defaulteyesize = 15;
    defaulteyecolor = [1 1 1];
    uicontrol('style', 'text', 'position', [xbase-7 ybase-47 20 30], 'string', 'E', 'fontweight', 'bold', 'fontsize', 18, 'backgroundcolor', figbg);
    uicontrol('style', 'text', 'position', [xbase+62 ybase-33 57 20], 'string', 'Color RGB', 'backgroundcolor', figbg);
    uicontrol('style', 'edit', 'position', [xbase+50 ybase-47 28 20], 'string', num2str(defaulteyecolor(1)), 'userdata', defaulteyecolor(1), 'backgroundcolor', [1 1 1], 'tag', 'eyered', 'callback', 'mlmenu');
    uicontrol('style', 'edit', 'position', [xbase+78 ybase-47 28 20], 'string', num2str(defaulteyecolor(2)), 'userdata', defaulteyecolor(2), 'backgroundcolor', [1 1 1], 'tag', 'eyegreen', 'callback', 'mlmenu');
    uicontrol('style', 'edit', 'position', [xbase+106 ybase-47 28 20], 'string', num2str(defaulteyecolor(3)), 'userdata', defaulteyecolor(3), 'backgroundcolor', [1 1 1], 'tag', 'eyeblue', 'callback', 'mlmenu');
    uicontrol('style', 'text', 'position', [xbase+16 ybase-33 27 20], 'string', 'Size', 'backgroundcolor', figbg);
    uicontrol('style', 'edit', 'position', [xbase+16 ybase-47 30 20], 'string', num2str(defaulteyesize), 'userdata', defaulteyesize, 'backgroundcolor', [1 1 1], 'tag', 'eyesize', 'callback', 'mlmenu');
    
    defaultjoysize = 15;
    defaultjoycolor = [1 0.6 0.6];
    xbase = 157;
    uicontrol('style', 'text', 'position', [xbase-4 ybase-47 20 30], 'string', 'J', 'fontweight', 'bold', 'fontsize', 18, 'backgroundcolor', figbg);
    uicontrol('style', 'text', 'position', [xbase+62 ybase-33 57 20], 'string', 'Color RGB', 'backgroundcolor', figbg);
    uicontrol('style', 'edit', 'position', [xbase+50 ybase-47 28 20], 'string', num2str(defaultjoycolor(1)), 'userdata', defaultjoycolor(1), 'backgroundcolor', [1 1 1], 'tag', 'joyred', 'callback', 'mlmenu');
    uicontrol('style', 'edit', 'position', [xbase+78 ybase-47 28 20], 'string', num2str(defaultjoycolor(2)), 'userdata', defaultjoycolor(2), 'backgroundcolor', [1 1 1], 'tag', 'joygreen', 'callback', 'mlmenu');
    uicontrol('style', 'edit', 'position', [xbase+106 ybase-47 28 20], 'string', num2str(defaultjoycolor(3)), 'userdata', defaultjoycolor(3), 'backgroundcolor', [1 1 1], 'tag', 'joyblue', 'callback', 'mlmenu');
    uicontrol('style', 'text', 'position', [xbase+16 ybase-33 27 20], 'string', 'Size', 'backgroundcolor', figbg);
    uicontrol('style', 'edit', 'position', [xbase+16 ybase-47 30 20], 'string', num2str(defaultjoysize), 'userdata', defaultjoysize, 'backgroundcolor', [1 1 1], 'tag', 'joysize', 'callback', 'mlmenu');
    
    ybase = 127;
    uicontrol('style', 'toggle', 'position', [xbase-147 ybase-93 135 23], 'string', 'Cartesian Grid OFF', 'value', 0, 'tag', 'csgrid_cartesian', 'backgroundcolor', [.8 .7 .7], 'callback', 'mlmenu');
    uicontrol('style', 'toggle', 'position', [xbase ybase-93 135 23], 'string', 'Polar Grid OFF', 'value', 0, 'tag', 'csgrid_polar', 'backgroundcolor', [.8 .7 .7], 'callback', 'mlmenu');
    uicontrol('style', 'slider', 'position', [xbase-147 ybase-117 100 18], 'min', 0.01, 'max', 1, 'value', 0.2, 'tag', 'cartesianbrightness', 'callback', 'mlmenu', 'enable', 'off', 'sliderstep', [0.01 0.1]);
    uicontrol('style', 'slider', 'position', [xbase ybase-117 100 18], 'min', 0.01, 'max', 1, 'value', 0.2, 'tag', 'polarbrightness', 'callback', 'mlmenu', 'enable', 'off', 'sliderstep', [0.01 0.1]);
    uicontrol('style', 'edit', 'position', [xbase-42 ybase-117 30 20], 'enable', 'inactive', 'string', 'n/a', 'backgroundcolor', fbg, 'foregroundcolor', [0 0 0], 'tag', 'cartesianbrightnessvalue');
    uicontrol('style', 'edit', 'position', [xbase+105 ybase-117 30 20], 'enable', 'inactive', 'string', 'n/a', 'backgroundcolor', fbg, 'foregroundcolor', [0 0 0], 'tag', 'polarbrightnessvalue');
    uicontrol('style', 'pushbutton', 'position', [45 103 220 20], 'string', 'User Plot Function', 'tag', 'userplotfunction', 'backgroundcolor', [1 1 1], 'callback', 'mlmenu', 'userdata', '');

    mcsx = 280;
    mcsy = 80;
    h = subplot('position', [9/figx (ybase)/figy mcsx/figx mcsy/figy]);
    hxd = 10;
    hyd = (hxd/mcsx)*mcsy;
    set(h, 'layer', 'top', 'tag', 'minicontrolscreen', 'xtick', [], 'ytick', [], 'color', [0 0 0], 'box', 'on', 'nextplot', 'add', 'ycolor', [1 1 1], 'xcolor', [1 1 1], 'xlim', [-10 10], 'ylim', [-3.57 3.57]);
    
    %make cartesian grid
    xvals = floor(-hxd):ceil(hxd);
    yvals = floor(-hyd):ceil(hyd);
    vlines = line([xvals; xvals], [floor(-hyd)*ones(size(xvals)); ceil(hyd)*ones(size(xvals))]);
    hlines = line([floor(-hxd)*ones(size(yvals)); ceil(hxd)*ones(size(yvals))], [yvals; yvals]);
    set([hlines' vlines'], 'color', [.5 .5 .5], 'tag', 'cartesiangrid', 'linestyle', 'none');
    
    %make polar grid
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
    set(hc, 'color', [.5 .5 .5], 'tag', 'polargrid', 'linestyle', 'none');

    %plot eye and joystick traces & targets
    xpos = 0.6*hxd;
    h = plot(-xpos, 0, 'o');
    set(h, 'color', 0.5*defaulteyecolor, 'linewidth', 3, 'markersize', 35, 'tag', 'sample_eye_target');
    h = plot(-xpos, 0, '.');
    set(h, 'color', defaulteyecolor, 'markersize', defaulteyesize, 'tag', 'sample_eye_trace');
    h = plot(xpos, 0, 'o');
    set(h, 'color', 0.5*defaultjoycolor, 'linewidth', 3, 'markersize', 35, 'tag', 'sample_joy_target');
    h = plot(xpos, 0, '.');
    set(h, 'color', defaultjoycolor, 'markersize', defaultjoysize, 'tag', 'sample_joy_trace');
    logger.logMessage('<<< MonkeyLogic >>> Initialized Control-Screen Menu...')
    
    % INPUT / OUTPUT ######################################  
    AdaptorInfo = ioscan();
    adaptors = {AdaptorInfo(:).Name};
    
    ybase = 575;
    uicontrol('style', 'text', 'position', [790 ybase+105 100 15], 'string', 'Interface boards', 'backgroundcolor', fbg);
    uicontrol('style', 'listbox', 'position', [745 ybase-5 240 110], 'string', adaptors, 'backgroundcolor', [1 1 1], 'tag', 'daq', 'userdata', AdaptorInfo, 'callback', 'mlmenu');
    
    uicontrol('style', 'text', 'position', [995 ybase+105 80 15], 'string', 'Subsystem', 'backgroundcolor', fbg);
    uicontrol('style', 'listbox', 'position', [990 ybase-5 100 110], 'string', AdaptorInfo(1).SubSystemsNames, 'backgroundcolor', [1 1 1], 'tag', 'subsystems', 'callback', 'mlmenu');
    
    uicontrol('style', 'text', 'position', [1092 ybase+105 90 15], 'string', 'Channels / Ports', 'backgroundcolor', fbg);
    uicontrol('style', 'listbox', 'position', [1096 ybase-5 83 110], 'string', AdaptorInfo(1).AvailableChannels{1}, 'tag', 'availablechannels', 'backgroundcolor', [1 1 1],  'Min', 1, 'Max', length(AdaptorInfo(1).AvailableChannels{1}));
    
    ybase = 525;
    xbase = 745;
    uicontrol('style', 'frame', 'position', [xbase ybase-225 435 260], 'backgroundcolor', fbg);
    
    uicontrol('style', 'frame', 'position', [xbase+170 ybase-2 170 37], 'backgroundcolor', fbg);
    uicontrol('style', 'text', 'position', [xbase+171 ybase+34 168 2], 'string', '', 'backgroundcolor', fbg);
    uicontrol('style', 'pushbutton', 'position', [xbase+180 ybase+6 70 25], 'string', 'Info', 'tag', 'infodaq', 'callback', 'mlmenu');
    uicontrol('style', 'pushbutton', 'position', [xbase+260 ybase+6 70 25], 'string', 'Test', 'tag', 'testdaq', 'callback', 'mlmenu');
    
    uicontrol('style', 'pushbutton', 'position', [xbase+355 ybase+1 70 25], 'string', 'Check', 'tag', 'checkio', 'callback', 'mlmenu');
    
    iolist = {'Eye Signal X' 'Eye Signal Y' 'Joystick X' 'Joystick Y' 'Touchscreen X' 'Touchscreen Y' 'Mouse X' 'Mouse Y' 'Reward' 'Behavioral Codes' 'Codes Strobe' 'Vertical Sync' 'PhotoDiode' 'Button 1' 'Button 2' 'Button 3' 'Button 4' 'Button 5' 'General Input 1' 'General Input 2' 'General Input 3' 'Stimulation 1' 'Stimulation 2' 'Stimulation 3' 'Stimulation 4' 'TTL 1' 'TTL 2' 'TTL 3' 'TTL 4', 'TTL 5', 'TTL 6'};
    iovarnames = {'EyeX' 'EyeY' 'JoyX' 'JoyY' 'TouchX' 'TouchY' 'MouseX' 'MouseY' 'Reward' 'CodesDigOut' 'DigCodesStrobeBit' 'Vsync' 'PhotoDiode' 'Button1' 'Button2' 'Button3' 'Button4' 'Button5' 'Gen1' 'Gen2' 'Gen3' 'Stim1' 'Stim2' 'Stim3' 'Stim4' 'TTL1' 'TTL2' 'TTL3' 'TTL4' 'TTL5' 'TTL6'}';
    for i = 1: length(iovarnames),
        InputOutput.(iovarnames{i}) = struct;
        InputOutput.(iovarnames{i}).Label = iolist{i};
    end
    InputOutput.Configuration.AnalogInputDuplication = 0;
    set(findobj(gcf, 'tag', 'ioframe'), 'userdata', InputOutput);
    
    uicontrol('style', 'pushbutton', 'position', [xbase+5 ybase+1 70 25], 'string', 'Assign', 'tag', 'setio', 'callback', 'mlmenu');
    uicontrol('style', 'pushbutton', 'position', [xbase+85 ybase+1 70 25], 'string', 'Clear', 'tag', 'ioclear', 'callback', 'mlmenu');
    
    uicontrol('style', 'listbox', 'position', [xbase+10 ybase-144 150 132], 'string', iolist, 'tag', 'ioselect', 'userdata', iovarnames, 'backgroundcolor', [1 1 1], 'callback', 'mlmenu');
    uicontrol('style', 'frame', 'position', [xbase+170 ybase-73 255 62], 'backgroundcolor', bgpurple);
    uicontrol('style', 'text', 'position', [xbase+172 ybase-40 250 20], 'string', iolist(1), 'tag', 'iolabel', 'backgroundcolor', bgpurple, 'fontweight', 'bold');
    uicontrol('style', 'text', 'position', [xbase+172 ybase-72 250 30], 'string', 'Not Assigned', 'tag', 'iotext', 'backgroundcolor', bgpurple);
        
    % Analog Input Menu %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    uicontrol('style', 'frame', 'position', [xbase+170 ybase-144 255 60]);
    uicontrol('style', 'text', 'position', [xbase+250 ybase-91 80 15], 'string', 'Analog Inputs', 'horizontalalignment', 'center');
    uicontrol('style', 'togglebutton', 'position', [xbase+178 ybase-137 110 21], 'string', 'A-I Duplication OFF', 'tag', 'aiduplication', 'value', 0, 'backgroundcolor', [.8 .7 .7], 'callback', 'mlmenu');
    uicontrol('style', 'text', 'position', [xbase+178 ybase-115 60 20], 'string', 'Frequency:');
    uicontrol('style', 'edit', 'position', [xbase+238 ybase-112 50 20], 'string', 1000, 'userdata', 1000, 'tag', 'analoginputfrequency', 'callback', 'mlmenu', 'backgroundcolor', [1 1 1], 'enable', 'off');
    %look for duplicate boards
    numadaptors = length(adaptors);
    duplicateboard = zeros(numadaptors, 1);
    for i = 1:numadaptors,
        matches = strcmp(adaptors(i), adaptors);
        if sum(matches) > 1,
            f = find(matches);
            duplicateboard(i) = f(f ~= i);
        end
    end
    if ~any(duplicateboard),
        set(findobj(gcf, 'tag', 'aiduplication'), 'enable', 'off');
        logger.logMessage('<<< MonkeyLogic >>> Warning: no duplicate DAQ boards found for Analog Input duplication...')
    else
        logger.logMessage('<<< MonkeyLogic >>> Detected duplicate DAQ boards: enabling A-I duplication...')
    end
    uicontrol('style', 'pushbutton', 'position', [xbase+299 ybase-138 118 22], 'string', 'Test Analog Inputs', 'tag', 'aitest', 'enable', 'off', 'callback', 'mlmenu');
    
    itype = {'Differential'};
    uicontrol('style', 'popupmenu', 'position', [xbase+299 ybase-114 118 23], 'string', itype, 'value', 1, 'tag', 'inputtype', 'enable', 'off', 'backgroundcolor', [1 1 1], 'callback', 'mlmenu');
    
    % Digital Codes for behavior **********************
    ybase = 310;
    xbase = 755;
    uicontrol('style', 'frame', 'position', [xbase-2 ybase-4 419 67], 'backgroundcolor', 0.9*fbg, 'foregroundcolor', 0.8*fbg);
    uicontrol('style', 'text', 'position', [xbase+5 ybase+30 350 20], 'string', 'Digital codes strobe bit triggers on                        edge', 'horizontalalignment', 'left', 'backgroundcolor', 0.9*fbg);
    uicontrol('style', 'popupmenu', 'position', [xbase+175 ybase+35 60 20], 'string', {'falling' 'rising'}, 'tag', 'strobebitedge', 'enable', 'off', 'backgroundcolor', [1 1 1]);
    uicontrol('style', 'pushbutton', 'position', [xbase+290 ybase+32 120 25], 'string', 'Test Digital Codes', 'tag', 'digcodestest', 'enable', 'off', 'callback', 'mlmenu');
    uicontrol('style', 'text', 'position', [xbase ybase 135 20], 'string', 'Behavioral codes text file:', 'backgroundcolor', 0.9*fbg);
    defaultcodesfile = 'codes.txt';
    codesfile = [MLPrefs.Directories.ExperimentDirectory defaultcodesfile]; %first check for codes file in experiment directory
    if ~exist(codesfile, 'file'),
        codesfile = [MLPrefs.Directories.BaseDirectory defaultcodesfile]; %then check in base directory
    end
    if ~exist(codesfile, 'file'),
        codestr = '???';
        codesfile = 'n/a';
        enablestr = 'off';
        logger.logMessage('<<< MonkeyLogic >>> Warning: No behavioral codes description file found...')
    else
        enablestr = 'on';
        codestr = defaultcodesfile;
    end
    uicontrol('style', 'pushbutton', 'position', [xbase+137 ybase+3 215 20], 'string', codestr, 'tag', 'codesfile', 'backgroundcolor', [1 1 1], 'callback', 'mlmenu', 'userdata', codesfile);
    uicontrol('style', 'pushbutton', 'position', [xbase+360 ybase+2 50 22], 'string', 'Edit', 'tag', 'editcodesfile', 'callback', 'mlmenu', 'enable', enablestr);
        
    % Eye and Joystick Calibration Menus *********************
    targetlist = [0 0; 5 5; -5 -5; -5 5; 5 -5];
    ybase = 240;
    uicontrol('style', 'pushbutton', 'position', [862 ybase+27 168 25], 'string', 'Calibrate Eye Position', 'tag', 'calbutton', 'callback', 'mlmenu', 'userdata', []);
    uicontrol('style', 'text', 'position', [1038 ybase+25 140 20], 'string', '- or -           Use raw signal', 'backgroundcolor', fbg, 'tag', 'eyecaltext', 'userdata', targetlist);
    uicontrol('style', 'checkbox', 'position', [1078 ybase+30 20 20], 'tag', 'useraw', 'callback', 'mlmenu', 'backgroundcolor', fbg, 'userdata', []);
    uicontrol('style', 'pushbutton', 'position', [745 ybase+27 110 25], 'string', 'Import Eye Cal', 'tag', 'loadeyetransform', 'callback', 'mlmenu');

    xbase = 755;
    ybase = ybase - 32;
    uicontrol('style', 'pushbutton', 'position', [862 ybase+27 168 25], 'string', 'Calibrate Joystick Position', 'tag', 'joycalbutton', 'callback', 'mlmenu', 'userdata', []);
    uicontrol('style', 'text', 'position', [1038 ybase+25 140 20], 'string', '- or -           Use raw signal', 'backgroundcolor', fbg, 'tag', 'joycaltext', 'userdata', targetlist);
    uicontrol('style', 'checkbox', 'position', [1078 ybase+30 20 20], 'tag', 'userawjoy', 'callback', 'mlmenu', 'backgroundcolor', fbg, 'userdata', 1);
    uicontrol('style', 'pushbutton', 'position', [745 ybase+27 110 25], 'string', 'Import Joy Cal', 'tag', 'loadjoytransform', 'callback', 'mlmenu');

    % Eye Drift Correction Menu *****************
    ybase = ybase - 15;
    uicontrol('style', 'frame', 'position', [xbase-10 ybase-112 192 147], 'backgroundcolor', fbg);
    uicontrol('style', 'toggle', 'position', [xbase-1 ybase+6 174 22], 'string', 'Eye Drift Correction OFF', 'tag', 'eyeadjust', 'value', 0, 'backgroundcolor', [.8 .7 .7], 'callback', 'mlmenu');
    uicontrol('style', 'text', 'position', [xbase+5 ybase-23 160 20], 'string', 'Adjustment Magnitude:            %', 'backgroundcolor', fbg, 'horizontalalignment', 'left');
    uicontrol('style', 'edit', 'position', [xbase+117 ybase-19 30 20], 'string', '50', 'userdata', 50, 'tag', 'adjustfraction', 'backgroundcolor', [1 1 1], 'callback', 'mlmenu', 'enable', 'off');
    uicontrol('style', 'text', 'position', [xbase+62 ybase-48 115 20], 'string', 'Fix Radius:            deg', 'backgroundcolor', fbg, 'horizontalalignment', 'left');
    uicontrol('style', 'edit', 'position', [xbase+117 ybase-44 30 20], 'string', '1', 'userdata', 1, 'tag', 'fixdegrees', 'backgroundcolor', [1 1 1], 'foregroundcolor', [0 0 0], 'callback', 'mlmenu', 'enable', 'off');
    uicontrol('style', 'text', 'position', [xbase+72 ybase-73 100 20], 'string', 'Fix Time:            ms', 'backgroundcolor', fbg, 'horizontalalignment', 'left');
    uicontrol('style', 'edit', 'position', [xbase+117 ybase-69 30 20], 'string', '100', 'userdata', 100, 'tag', 'fixtime', 'backgroundcolor', [1 1 1], 'foregroundcolor', [0 0 0], 'callback', 'mlmenu', 'enable', 'off');
    uicontrol('style', 'text', 'position', [xbase+29 ybase-98 150 20], 'string', 'Smoothing Sigma:            ms', 'backgroundcolor', fbg, 'horizontalalignment', 'left');
    uicontrol('style', 'edit', 'position', [xbase+117 ybase-94 30 20], 'string', '15', 'userdata', 15, 'backgroundcolor', [1 1 1], 'tag', 'smoothsigma', 'callback', 'mlmenu', 'enable', 'off');
    uicontrol('style', 'frame', 'position', [xbase-1 ybase-72 56 50], 'backgroundcolor', fbg, 'foregroundcolor', 0.8*fbg);
    uicontrol('style', 'pushbutton', 'position', [xbase+3 ybase-67 48 40], 'string', 'Test', 'tag', 'eyeadjusttest', 'callback', 'mlmenu', 'enable', 'off');
    uicontrol('style', 'text', 'position', [xbase+17 ybase-108 110 12], 'string', 'Use First Target Only', 'horizontalalignment', 'right', 'backgroundcolor', fbg);
    uicontrol('style', 'checkbox', 'position', [xbase+133 ybase-108 12 12], 'tag', 'firsttargetonly', 'callback', 'mlmenu', 'backgroundcolor', fbg, 'userdata', 1);
  
    
    %%% REMOTE ALERTS MENU %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    ybase = 193;
    xbase = 945;
    uicontrol('style', 'frame', 'position', [xbase ybase-112 235 147], 'backgroundcolor', fbg);
    uicontrol('style', 'toggle', 'position', [xbase+30 ybase+6 174 22], 'string', 'Remote Alerts OFF', 'tag', 'alertsandupdates', 'backgroundcolor', [.8 .7 .7], 'callback', 'mlmenu');
    uicontrol('style', 'text', 'position', [xbase+20 ybase-25 80 20], 'string', 'Error Alerts:', 'backgroundcolor', fbg, 'horizontalalignment', 'left');
    uicontrol('style', 'checkbox', 'position', [xbase+85 ybase-18 15 15], 'value', 1, 'enable', 'off', 'tag', 'au_errorcheck', 'callback', 'mlmenu');
    uicontrol('style', 'text', 'position', [xbase+120 ybase-25 80 20], 'string', 'Block Updates:', 'backgroundcolor', fbg, 'horizontalalignment', 'left');
    uicontrol('style', 'checkbox', 'position', [xbase+198 ybase-18 15 15], 'value', 1, 'enable', 'off', 'tag', 'au_blockcheck', 'callback', 'mlmenu');
    uicontrol('style', 'frame', 'position', [xbase+8 ybase-76 217 50], 'backgroundcolor', 0.9*fbg, 'foregroundcolor', 0.8*fbg);
    uicontrol('style', 'text', 'position', [xbase+40 ybase-52 160 20], 'string', 'User-Defined Send Criteria:', 'backgroundcolor', 0.9*fbg, 'horizontalalignment', 'left');
    uicontrol('style', 'checkbox', 'position', [xbase+179 ybase-45 15 15], 'value', 0, 'enable', 'off', 'tag', 'au_userdefinedcheck', 'callback', 'mlmenu');
    uicontrol('style', 'pushbutton', 'position', [xbase+15 ybase-70 203 20], 'string', 'n/a', 'tag', 'au_userdefinedcritfunction', 'enable', 'off', 'backgroundcolor', [1 1 1], 'callback', 'mlmenu', 'userdata', '');
    uicontrol('style', 'pushbutton', 'position', [xbase+15 ybase-103 203 20], 'string', 'n/a', 'tag', 'au_function', 'enable', 'off', 'backgroundcolor', [1 1 1], 'callback', 'mlmenu', 'userdata', '');
    
    logger.logMessage('<<< MonkeyLogic >>> Initialized I/O Menu...')
    
    %%% PULL-DOWN MENUS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    filemenu = uimenu('label', 'File');
    uimenu(filemenu, 'label', 'Load Conditions File', 'tag', 'menubar_condfileselect', 'callback', 'mlmenu', 'accelerator', 'f');
    uimenu(filemenu, 'label', 'Load Configuration', 'tag', 'menubar_loadbutton', 'callback', 'mlmenu');
    uimenu(filemenu, 'label', 'Save Configuration', 'tag', 'menubar_savebutton', 'callback', 'mlmenu', 'enable', 'off', 'accelerator', 's');
    uimenu(filemenu, 'label', 'Directory Preferences', 'tag', 'menubar_directorypreferences', 'callback', 'set_ml_preferences', 'separator', 'on');

    editmenu = uimenu('label', 'Edit');
    uimenu(editmenu, 'label', 'Edit Conditions File', 'tag', 'menubar_editconds', 'callback', 'mlmenu', 'enable', 'off', 'accelerator', 'e');
    uimenu(editmenu, 'label', 'Edit Timing File', 'tag', 'menubar_edittimingfile', 'callback', 'mlmenu', 'enable', 'off');
    uimenu(editmenu, 'label', 'Edit Behavioral Codes File', 'tag', 'menubar_editcodesfile', 'callback', 'mlmenu');
    
    %taskmenu = uimenu('label', 'Task');
    
    %videomenu = uimenu('label', 'Video');
    
    iomenu = uimenu('label', 'I/O');
    uimenu(iomenu, 'label', 'Board Info', 'tag', 'menubar_infodaq', 'callback', 'mlmenu');
    uimenu(iomenu, 'label', 'Oscilloscope', 'tag', 'menubar_testdaq', 'accelerator', 'o', 'callback', 'mlmenu');
    uimenu(iomenu, 'label', 'Import Eye Calibration Matrix', 'tag', 'menubar_loadeyetransform', 'callback', 'mlmenu', 'separator', 'on');
    uimenu(iomenu, 'label', 'Import Joystick Calibration Matrix', 'tag', 'menubar_loadjoytransform', 'callback', 'mlmenu');
    uimenu(iomenu, 'label', 'Invert Reward Polarity', 'tag', 'menubar_rewardpolarity', 'callback', 'mlmenu', 'separator', 'on');
    
    diagnosticsmenu = uimenu('label', 'Diagnostics');
    uimenu(diagnosticsmenu, 'label', 'Video Test', 'tag', 'menubar_videotest', 'callback', 'mlmenu', 'accelerator', 'v');
    uimenu(diagnosticsmenu, 'label', 'Test Stimulus Object', 'tag', 'menubar_viewplay', 'callback', 'mlmenu', 'enable', 'off', 'accelerator', 't');
    uimenu(diagnosticsmenu, 'label', 'I/O Check', 'tag', 'menubar_checkio', 'callback', 'mlmenu', 'separator', 'on', 'accelerator', 'i');
    uimenu(diagnosticsmenu, 'label', 'Test Digital Codes', 'tag', 'menubar_digcodestest', 'callback', 'mlmenu', 'enable', 'off', 'accelerator', 'd');
    uimenu(diagnosticsmenu, 'label', 'Analog Sampling Rate Test', 'tag', 'menubar_aitest', 'callback', 'mlmenu', 'enable', 'off');
    uimenu(diagnosticsmenu, 'label', 'Eye-Drift Saccade/Fixation Detection', 'tag', 'menubar_eyeadjusttest', 'callback', 'mlmenu');
    uimenu(diagnosticsmenu, 'label', 'Remote Alerts Test', 'tag', 'menubar_alertstest', 'callback', 'mlmenu', 'separator', 'on');
    uimenu(diagnosticsmenu, 'label', 'MonkeyLogic Latency Test', 'tag', 'menubar_mltimetest', 'callback', 'mlmenu', 'separator', 'on', 'enable', 'off');
    uimenu(diagnosticsmenu, 'label', 'MATLAB Latency Test', 'tag', 'menubar_speedtest', 'callback', 'mlmenu');
    
    advancedmenu = uimenu('label', 'Advanced');
    uimenu(advancedmenu, 'label', 'Preload Video Data', 'tag', 'menubar_preload', 'callback', 'mlmenu');
    uimenu(advancedmenu, 'label', 'Enable Mouse/System Keys', 'tag', 'menubar_mlhelper', 'callback', 'mlmenu');
    uimenu(advancedmenu, 'label', 'Use Personal Hardware Settings', 'tag', 'menubar_personalhardware', 'callback', 'mlmenu', 'enable', 'off');
 
    helpmenu = uimenu('label', 'Help');
    uimenu(helpmenu, 'label', 'Online Help', 'callback', 'web(''http://www.monkeylogic.net'', ''-browser'')', 'accelerator', 'h');
    uimenu(helpmenu, 'label', 'About...', 'tag', 'menubar_aboutbutton', 'callback', 'mlmenu');
    if usejava('jvm'),
        logger.logMessage('<<< MonkeyLogic >>> Initialized drop-down menus...')
    end
    
    if exist(cfgfile, 'file'),
        loadcfg(cfgfile, logger);
        update_minicontrolscreen;
    else % if doesn't exist, create default config file...
        savecfg;
    end
    logger.logMessage('<<< MonkeyLogic >>> Ready.')
    
elseif ismember(gcbo, get(findobj('tag', 'monkeylogicmainmenu'), 'children')) || reloadcondfile || ismember(get(gcbo, 'parent'), get(findobj('tag', 'monkeylogicmainmenu'), 'children')),
   
    callertag = get(gcbo, 'tag');
    mlmessage('');
    set(gcf, 'pointer', 'arrow');
    if reloadcondfile,
        callertag = 'condfileselect';
    end
    if strfind(callertag, 'menubar'),
        callertag = callertag(9:length(callertag));
    end
    
    switch callertag,
   
        case 'condfileselect',
            
            if ~reloadcondfile,
                mlmessage('Select the text file containing the Conditions table');
                warning off
                [filename pathname] = uigetfile([MLPrefs.Directories.ExperimentDirectory '*.txt'], 'Select Conditions Text File');
                warning on
                if filename == 0,
                    mlmessage('');
                    return
                end
                fullfile = [pathname filesep filename];
            else
                fullfile = get(findobj(gcf, 'tag', 'condfileselect'), 'userdata');
            end
            [pathname filename] = fileparts(fullfile);            
                
            mlmessage('Loading conditions and configuration info...');
            set(gcf, 'pointer', 'watch');
            drawnow;
            
            MLPrefs.Directories = getpref('MonkeyLogic', 'Directories');
            MLPrefs.Directories.ExperimentDirectory = pathname;
            setpref('MonkeyLogic', 'Directories', MLPrefs.Directories);
            
            mlmessage('Reading Conditions...');
            [Conditions cerror] = load_conditions(fullfile);
            if ~isempty(cerror),
                mlmessage(['Conditions File Error: ' cerror]);
                set(gcf, 'pointer', 'arrow');
                return
            end
            
            set(findobj(gcf, 'tag', 'condfileselect'), 'string', filename, 'userdata', fullfile, 'fontweight', 'bold', 'fontsize', 11);
            cfgfile = [filename '_cfg.mat'];
            set(findobj(gcf, 'tag', 'configfilename'), 'string', cfgfile);
            
            if ~iscell(Conditions), %no userloop: regular conditions file
                userloop = 0;
                BlockSpec = cell(length(Conditions), 1);
                TFiles = cell(length(Conditions), 1);
                for i = 1:length(Conditions),
                    BlockSpec{i} = Conditions(i).CondInBlock;
                    TFiles{i} = Conditions(i).TimingFile;
                end

                set(findobj(gcf, 'tag', 'totalconds'), 'string', num2str(length(Conditions)), 'enable', 'inactive');

                [BlockTypes blocklist] = sortblocks(BlockSpec);
                numblocks = length(blocklist);
                set(findobj(gcf, 'tag', 'blocklist'), 'string', num2str(blocklist'), 'enable', 'on', 'value', 1);
                cpb = zeros(numblocks, 1);
                for i = 1:numblocks,
                    cpb(blocklist(i)) = length(BlockTypes{i});
                end
                set(findobj(gcf, 'tag', 'condsperblock'), 'string', num2str(cpb(1)), 'userdata', cpb, 'enable', 'inactive');
                set(findobj(gcf, 'tag', 'trialsperblock'), 'enable', 'on', 'userdata', 50*ones(numblocks, 1));
                set(findobj(gcf, 'tag', 'runblocks'), 'enable', 'on', 'string', num2cell(blocklist), 'userdata', blocklist, 'value', 1);
                set(findobj(gcf, 'tag', 'allblocks'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'stimnames'), 'value', 1, 'listboxtop', 1);
                set(findobj(gcf, 'tag', 'firstblock'), 'enable', 'on', 'value', 1);

                tfiles = unique(TFiles);
                set(findobj(gcf, 'tag', 'timingfiles'), 'string', tfiles, 'enable', 'on');
                set(findobj(gcf, 'tag', 'edittimingfile'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'menubar_edittimingfile'), 'enable', 'on');

                UniqueTaskObjects = sort_taskobjects(Conditions);
                obnames = {UniqueTaskObjects.Description};

                set(findobj(gcf, 'tag', 'stimnames'), 'string', obnames, 'userdata', UniqueTaskObjects, 'enable', 'on', 'value', 1);
                set(findobj(gcf, 'tag', 'viewplay'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'menubar_viewplay'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'editconds'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'menubar_editconds'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'positionslider'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'zoomslider'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'preprocessimages'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'applyblocknumstoall'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'chartblocks'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'datafile'), 'string', '', 'userdata', '');
                set(findobj(gcf, 'tag', 'mltimetest'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'menubar_mltimetest'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'runbutton'), 'backgroundcolor', [0.9 0.6 0.6], 'enable', 'inactive', 'cdata', imread('runbuttondim.jpg'));
                set(findobj(gcf, 'tag', 'errorlogic'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'condlogic'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'blocklogic'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'blockchangefun'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'firstblock'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'blocklist'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'runblocks'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'applyblocknumstoall'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'allblocks'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'chartblocks'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'trialsperblock'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'maxtrials'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'maxblocks'), 'enable', 'on');
                update_stimwindow;
            else
                userloop = 1;
            end
            
            %update settings if config file already exists...
            cfgfile = [MLPrefs.Directories.ExperimentDirectory cfgfile];
            if exist(cfgfile, 'file'),
                loadcfg(cfgfile, logger);    
            end
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'off');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'off');

            if ~isempty(get(findobj(gcf, 'tag', 'datafile'), 'userdata')),
                set(findobj(gcf, 'tag', 'runbutton'), 'enable', 'on', 'cdata', imread('runbutton.jpg'));
            end
            
            update_minicontrolscreen;
            
            if userloop, %these gui changes must happen *after* loadcfg, which may otherwise over-ride some lines below
                set(findobj(gcf, 'tag', 'stimnames'), 'string', 'User Defined', 'value', 1, 'userdata', []);
                set(findobj(gcf, 'tag', 'timingfiles'), 'string', 'User Defined', 'value', 1);
                set(findobj(gcf, 'tag', 'edittimingfile'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'edittimingfile'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'viewplay'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'menubar_viewplay'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'errorlogic'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'condlogic'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'blocklogic'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'blockchangefun'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'blockselectfun'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'condselectfun'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'firstblock'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'blocklist'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'runblocks'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'applyblocknumstoall'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'allblocks'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'chartblocks'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'trialsperblock'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'maxtrials'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'maxblocks'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'totalconds'), 'string', 'n/a');
                set(gcf, 'CurrentAxes', findobj(gcf, 'tag', 'stimax'));
                image(imread('earth.jpg'));
                set(gca, 'tag', 'stimax', 'xtick', [], 'ytick', [], 'box', 'on', 'ycolor', [1 1 1], 'xcolor', [1 1 1]);
            end
            set(gcf, 'pointer', 'arrow');
            
        case 'aboutbutton',
            
            mlmessage(sprintf('>>> Revision : %s <<<', currentversion));
            try
                f = wavread('science.wav');
                sound(f, 48000);
            catch
                logger.logMessage('');
            end
        
        case 'editconds',
            
            mlmessage('Waiting for NotePad to finish...');
            condfile = get(findobj(gcf, 'tag', 'condfileselect'), 'userdata');
            eval(['!%SystemRoot%\system32\notepad.exe ', condfile]);
            mlmessage('');
            savecfg;
            mlmenu(-1); %reload conditions file to update menu parameters with any changes
            
        case 'savebutton',
      
            savecfg;
            
        case 'configfilename',
            
            cfgfile = [MLPrefs.Directories.ExperimentDirectory get(gcbo, 'string')];
            evalstr1 = sprintf('load(''%s'')', cfgfile);
            evalstr2 = 'openvar(''MLConfig'')';
            evalin('base', evalstr1);
            evalin('base', evalstr2);
      
        case 'loadbutton',
            
            [filename pathname] = uigetfile([MLPrefs.Directories.ExperimentDirectory '*_cfg.mat']);
            if filename ~= 0,
                loadcfg([pathname filename], logger);
            end
            rbh = findobj(gcf, 'tag', 'runblocks');
            blocklist = get(rbh, 'userdata');
            set(rbh, 'value', 1:length(blocklist));
            set(findobj(gcf, 'tag', 'firstblock'), 'string', cat(1, {'Default'}, num2cell(blocklist')), 'value', 1, 'userdata', blocklist);
            update_minicontrolscreen;
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');

        case 'condlogic',
      
            val = get(gcbo, 'value');
            if val == 5, %user-defined m-file
                set(findobj(gcf, 'tag', 'condselectfun'), 'enable', 'on', 'string', 'Press to select function');
                mlmessage('Must specify a user-defined condition-selection function.');
            else
                set(findobj(gcf, 'tag', 'condselectfun'), 'enable', 'off', 'string', 'n/a', 'userdata', '');
            end
            
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');

        case 'blocklogic',
      
            val = get(gcbo, 'value');
            if get(findobj(gcf, 'tag', 'firstblock'), 'value') == 1,
                mlmessage(blockmessage);
            end

            if val == 5, %user-defined m-file
                set(findobj(gcf, 'tag', 'blockselectfun'), 'enable', 'on', 'string', 'Press to select function');
                mlmessage('Must specify a user-defined block-selection function.');
            else
                set(findobj(gcf, 'tag', 'blockchangefun'), 'backgroundcolor', [1 1 1]);
                set(findobj(gcf, 'tag', 'blockselectfun'), 'enable', 'off', 'string', 'n/a', 'userdata', '', 'backgroundcolor', [1 1 1]);
            end
                        
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');

        case 'condselectfun',
            
            mlmessage('"function nextcond = funcname(TrialRecord)"');
            [fname pname] = uigetfile([MLPrefs.Directories.ExperimentDirectory '*.m'], 'Choose Condition-Selection Function');
            if fname(1) == 0,
                mlmessage('');
                return
            end
            [pholder fname ext] = fileparts(fname); %eliminates '.m'
            set(gcbo, 'string', ['Condition Selection: ' fname], 'userdata', [pname fname ext]);
            mlmessage('>>> Condition-selection function set <<<');
            
        case 'blockselectfun',
            
            mlmessage('"function nextblock = funcname(TrialRecord)"');
            [fname pname] = uigetfile([MLPrefs.Directories.ExperimentDirectory '*.m'], 'Choose Block-Selection Function');
            if fname(1) == 0,
                mlmessage('');
                return
            end
            [pholder fname ext] = fileparts(fname); %eliminates '.m'
            set(gcbo, 'string', ['Block Selection: ' fname], 'userdata', [pname fname ext]);
            hbfxn = findobj(gcf, 'tag', 'blockchangefun');
            if get(findobj(gcf, 'tag', 'blocklogic'), 'value') == 5 && strcmpi(get(gcbo, 'userdata'), get(hbfxn, 'userdata')),
                set([gcbo hbfxn], 'backgroundcolor', [.7 .8 .7]); %to indicate a match, so block-change fxn also selects actual block #, not just switch flag
                mlmessage('>>> Block-Change function will select the next block <<<');
            else
                set([gcbo hbfxn], 'backgroundcolor', [1 1 1]);
                mlmessage('>>> Block-selection function set <<<');
            end
            
        case 'blockchangefun',
            
            mlmessage('"function switchflag = funcname(TrialRecord)" where switchflag is 1 or 0');
            [fname pname] = uigetfile([MLPrefs.Directories.ExperimentDirectory '*.m'], 'Choose Block-Change Function');
            if fname(1) == 0,
                set(findobj(gcf, 'tag', 'trialsperblock'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'applyblocknumstoall'), 'enable', 'on');
                set(gcbo, 'string', 'Block Change Function', 'userdata', '');
                mlmessage('');
            else
                [pholder fname ext] = fileparts(fname);
                set(gcbo, 'string', ['Block Change: ' fname], 'userdata', [pname fname ext]);
                set(findobj(gcf, 'tag', 'trialsperblock'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'applyblocknumstoall'), 'enable', 'off');
                mlmessage('>>> Block-change function set <<<');
            end
            hbfxn = findobj(gcf, 'tag', 'blockselectfun');
            if get(findobj(gcf, 'tag', 'blocklogic'), 'value') == 5 && strcmpi(get(gcbo, 'userdata'), get(hbfxn, 'userdata')),
                set([gcbo hbfxn], 'backgroundcolor', [.7 .8 .7]); %to indicate a match, so block-change fxn also selects actual block #, not just switch flag
                mlmessage('>>> Block-Change function will select the next block <<<');
            else
                set([gcbo hbfxn], 'backgroundcolor', [1 1 1]);
                set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            end
            
        case 'blocklist',
            
            val = get(gcbo, 'value');
            blockstr = get(gcbo, 'string');
            blocknum = str2double(blockstr(val, :));
            cpb = get(findobj('tag', 'condsperblock'), 'userdata');
            set(findobj(gcf, 'tag', 'condsperblock'), 'string', num2str(cpb(blocknum)));
            
            tpb = get(findobj('tag', 'trialsperblock'), 'userdata');
            set(findobj(gcf, 'tag', 'trialsperblock'), 'string', num2str(tpb(blocknum)));
                        
        case 'trialsperblock',
            
            blockbox = findobj(gcf, 'tag', 'blocklist');
            blockval = get(blockbox, 'value');
            blockstr = get(blockbox, 'string');
            blocknum = str2double(blockstr(blockval, :));
            
            h = findobj(gcf, 'tag', 'trialsperblock');
            tpb = get(h, 'userdata');
            oldtpb = tpb;
            try
                tpb(blocknum) = str2double(get(h, 'string'));
                set(h, 'userdata', tpb);
            catch
                set(h, 'string', oldtpb(blocknum));
                set(h, 'userdata', oldtpb);
            end
            
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');

        case 'applyblocknumstoall',
            
            blockbox = findobj(gcf, 'tag', 'blocklist');
            blockval = get(blockbox, 'value');
            blockstr = get(blockbox, 'string');
            blocknum = str2double(blockstr(blockval, :));
            
            h = findobj(gcf, 'tag', 'trialsperblock');
            tpb = get(h, 'userdata');
            oldtpb = tpb;
            try
                tpb = str2double(get(h, 'string'))*ones(size(tpb));
                set(h, 'userdata', tpb);
            catch
                set(h, 'string', oldtpb(blocknum));
                set(h, 'userdata', oldtpb);
            end
            
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            plural = 's';
            mlmessage(sprintf('>>> Each block set to run %i trial%s <<<', tpb(1), plural(tpb(1) > 1)));
            
        case 'chartblocks',
            
            condfile = get(findobj(gcf, 'tag', 'condfileselect'), 'userdata');
            chartblocks(condfile);
            
        case 'maxblocks',
            
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');

        case 'maxtrials',
            
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');

        case 'errorlogic',
            
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');

        case 'runblocks',
            
            blocklist = get(gcbo, 'userdata');
            chosenblocks = get(gcbo, 'value');
            runblocks = blocklist(chosenblocks);
            firstblocklist = get(findobj(gcf, 'tag', 'firstblock'), 'userdata');
            fbval = get(findobj(gcf, 'tag', 'firstblock'), 'value');
            if fbval > 1,
                firstblock = firstblocklist(fbval-1);
                f = find(firstblock == runblocks);
                if isempty(f),
                    f = 1;
                    mlmessage('Previous "first block" not in current group   Reset to default');
                else
                    f = f + 1;
                    mlmessage(sprintf('First block remains %i', firstblock));
                end
            else
                f = 1;
                mlmessage(blockmessage);
            end
            set(findobj(gcf, 'tag', 'firstblock'), 'string', cat(1, {'Default'}, num2cell(runblocks')), 'value', f, 'userdata', runblocks);
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');

        case 'firstblock',
            
            if get(gcbo, 'value') == 1,
                mlmessage(blockmessage);
            end
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');

        case 'allblocks',
            
            rbh = findobj(gcf, 'tag', 'runblocks');
            numvals = length(get(rbh, 'string'));
            set(rbh, 'value', 1:numvals);
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');

        case 'calbutton', 

            clear all; %need for kbd library to work...
            io = get(findobj('tag', 'ioframe'), 'userdata');
            if ~isfield(io.EyeX, 'Adaptor') && ~isfield(io.EyeY, 'Adaptor'),
                mlmessage('Warning: *** No eye signal inputs are defined ***');
                return
            end
            targetlist = get(findobj(gcf, 'tag', 'eyecaltext'), 'userdata');
            SigTransform = get(gcbo, 'userdata');
            ScreenInfo = gather_screen_params;
            ScreenInfo.FixationPoint = get_fixspot(ScreenInfo.BackgroundColor);
            ScreenInfo.IsActive = 0;
            ScreenInfo.EyeOrJoy = 1;
            io.Reward.Polarity = io.Configuration.RewardPolarity;
            mlhelperOff = strcmp(get(findobj(gcf, 'tag', 'menubar_mlhelper'), 'Checked'),'on');
            xycalibrate(ScreenInfo, targetlist, io, SigTransform, mlhelperOff);
            close(findobj('name', 'XY Calibrate: Eye Signal'));
            
        case 'loadeyetransform',
            
            mlmessage('Import eye calibration matrix from another configuration file...');
            [filename pathname] = uigetfile([MLPrefs.Directories.ExperimentDirectory '*_cfg.mat'], 'Select CFG file from which to load Eye Transform');
            if filename == 0,
                mlmessage('');
                return
            end
            cfgdata = load([pathname filename]);
            if ~isfield(cfgdata, 'MLConfig'),
                error('*** Not a valid configuration file ***');
            elseif isempty(cfgdata.MLConfig) || isempty(cfgdata.MLConfig.EyeTransform),
                set(findobj(gcf, 'tag', 'calbutton'), 'userdata', [], 'foregroundcolor', [.4 0 0], 'string', 'No Eye Calibration');
                mlmessage('*** No Eye Calibration data in this file ***');
                return
            end
            set(findobj(gcf, 'tag', 'calbutton'), 'userdata', cfgdata.MLConfig.EyeTransform, 'foregroundcolor', [0 .4 0], 'string', 'Re-calibrate Eye', 'enable', 'on');
            set(findobj(gcf, 'tag', 'useraw'), 'value', 0);
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            mlmessage('>>> Eye Calibration data loaded <<<');
            
        case 'useraw'
            
            val = get(gcbo, 'value');
            tform = get(findobj(gcf, 'tag', 'calbutton'), 'userdata');
            if val == 1,
                set(findobj(gcf, 'tag', 'calbutton'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'eyeadjust'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'fixdegrees'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'fixtime'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'smoothsigma'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'eyeadjusttest'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'menubar_eyeadjusttest'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'adjustfraction'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'loadeyetransform'), 'enable', 'off');
                if ~isempty(tform),
                    set(findobj(gcf, 'tag', 'calbutton'), 'foregroundcolor', [0.4 0 0], 'string', 'Eye Calibration Not Used');
                end
            else
                set(findobj(gcf, 'tag', 'calbutton'), 'enable', 'on');
                set(findobj(gcf, 'tag' ,'eyeadjust'), 'enable', 'on');
                val = get(findobj(gcf, 'tag', 'eyeadjust'), 'value');
                if val == 1,
                    set(findobj(gcf, 'tag', 'fixdegrees'), 'enable', 'on');
                    set(findobj(gcf, 'tag', 'fixtime'), 'enable', 'on');
                    set(findobj(gcf, 'tag', 'smoothsigma'), 'enable', 'on');
                    set(findobj(gcf, 'tag', 'eyeadjusttest'), 'enable', 'on');
                    set(findobj(gcf, 'tag', 'menubar_eyeadjusttest'), 'enable', 'on');
                    set(findobj(gcf, 'tag', 'adjustfraction'), 'enable', 'on');
                end
                set(findobj(gcf, 'tag', 'loadeyetransform'), 'enable', 'on');
                if ~isempty(tform),
                    set(findobj(gcf, 'tag', 'calbutton'), 'foregroundcolor', [0 .4 0], 'string', 'Re-calibrate Eye');
                end
            end
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            
        case 'joycalbutton',

            clear all; %need for kbd library to work...
            io = get(findobj('tag', 'ioframe'), 'userdata');
            if ~isfield(io.JoyX, 'Adaptor') && ~isfield(io.JoyY, 'Adaptor'),
                mlmessage('Warning: *** No joystick inputs are defined ***');
                return
            end
            targetlist = get(findobj(gcf, 'tag', 'joycaltext'), 'userdata');
            SigTransform = get(gcbo, 'userdata');
            ScreenInfo = gather_screen_params;
            ScreenInfo.FixationPoint = get_fixspot(ScreenInfo.BackgroundColor);
            ScreenInfo.IsActive = 0;
            ScreenInfo.EyeOrJoy = 2;
            io.Reward.Polarity = io.Configuration.RewardPolarity;
            mlhelperOff = strcmp(get(findobj(gcf, 'tag', 'menubar_mlhelper'), 'Checked'),'on');
            xycalibrate(ScreenInfo, targetlist, io, SigTransform, mlhelperOff);
            close(findobj('name', 'XY Calibrate: Joystick'));
            
        case 'loadjoytransform',
            
            mlmessage('Import joystick calibration matrix from another configuration file...');
            [filename pathname] = uigetfile([MLPrefs.Directories.ExperimentDirectory '*_cfg.mat'], 'Select CFG file from which to load Joystick Transform');
            if filename == 0,
                mlmessage('');
                return
            end
            cfgdata = load([pathname filename]);
            if ~isfield(cfgdata, 'MLConfig'),
                error('*** Not a valid configuration file ***');
            elseif isempty(cfgdata.MLConfig) || isempty(cfgdata.MLConfig.JoyTransform),
                set(findobj(gcf, 'tag', 'joycalbutton'), 'userdata', [], 'foregroundcolor', [.4 0 0], 'string', 'No Joystick Calibration');
                mlmessage('*** No Joystick Calibration data in this file ***');
                return
            end
            set(findobj(gcf, 'tag', 'joycalbutton'), 'userdata', cfgdata.MLConfig.JoyTransform, 'foregroundcolor', [0 .4 0], 'string', 'Re-calibrate Joystick', 'enable', 'on');
            set(findobj(gcf, 'tag', 'userawjoy'), 'value', 0);
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            mlmessage('>>> Joystick calibration data loaded <<<');
            
        case 'userawjoy',
            
            val = get(gcbo, 'value');
            tform = get(findobj(gcf, 'tag', 'joycalbutton'), 'userdata');
            if val == 1,
                set(findobj(gcf, 'tag', 'joycalbutton'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'loadjoytransform'), 'enable', 'off');
                if ~isempty(tform),
                    set(findobj(gcf, 'tag', 'joycalbutton'), 'foregroundcolor', [0.4 0 0], 'string', 'Joystick Calibration Not Used');
                end
            else
                set(findobj(gcf, 'tag', 'joycalbutton'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'loadjoytransform'), 'enable', 'on');
                if ~isempty(tform),
                    set(findobj(gcf, 'tag', 'joycalbutton'), 'foregroundcolor', [0 .4 0], 'string', 'Re-calibrate Joystick');
                end
            end
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            
        case 'rewardpolarity',
            
            io = get(findobj(gcf, 'tag', 'ioframe'), 'userdata');
            p = get(gcbo, 'checked');
            if strcmpi(p, 'off'),
                set(gcbo, 'checked', 'on');
                io.Configuration.RewardPolarity = -1;
            else
                set(gcbo, 'checked', 'off');
                io.Configuration.RewardPolarity = 1;
            end
            set(findobj(gcf, 'tag', 'ioframe'), 'userdata', io);
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            
        case 'preload',
            
            p = get(gcbo, 'checked');
            if strcmpi(p, 'off'),
                set(gcbo, 'checked', 'on');
            else
                set(gcbo, 'checked', 'off');
            end
            
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            
        case 'mlhelper',
            
            p = get(gcbo, 'checked');
            if strcmpi(p, 'off'),
                set(gcbo, 'checked', 'on');
            else
                set(gcbo, 'checked', 'off');
            end
            
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            
        case 'personalhardware',
            
            p = get(gcbo, 'checked');
            
            if strcmpi(p, 'off'),
                set(gcbo, 'checked', 'on');
                savecfg(1);
            else
                set(gcbo, 'checked', 'off');
                savecfg(0);
            end
            
            cfgname = get(findobj(gcf, 'tag', 'configfilename'), 'string');
            loadcfg([MLPrefs.Directories.ExperimentDirectory cfgname], logger);
            
            if strcmpi(p, 'off'),
                mlmessage('Loaded personal hardware settings.');
            else
                mlmessage('Loaded default hardware settings.');
            end
            
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            
        case 'firsttargetonly',
            
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            
        case 'eyeadjust',
            
            val = get(gcbo, 'value');
            if val,
                set(gcbo, 'string', 'Eye Drift Correction ON', 'backgroundcolor', [.7 .8 .7]);
                set(findobj(gcf, 'tag', 'fixdegrees'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'fixtime'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'smoothsigma'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'adjustfraction'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'eyeadjusttest'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'menubar_eyeadjusttest'), 'enable', 'on');
            else
                set(gcbo, 'string', 'Eye Drift Correction OFF', 'backgroundcolor', [.8 .7 .7]);
                set(findobj(gcf ,'tag', 'fixdegrees'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'fixtime'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'smoothsigma'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'adjustfraction'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'eyeadjusttest'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'menubar_eyeadjusttest'), 'enable', 'off');
            end
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');

        case 'adjustfraction',
            
            val = str2double(get(gcbo, 'string'));
            if isnan(val) || val < 1 || val > 100,
                val = get(gcbo, 'userdata');
                set(gcbo, 'string', num2str(val));
                return
            end
            set(gcbo, 'userdata', val);
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');

        case 'smoothsigma',
            
            val = str2double(get(gcbo, 'string'));
            if isnan(val) || val <= 0 || val > 100,
                val = get(gcbo, 'userdata');
                set(gcbo, 'string', num2str(val));
                return
            end
            set(gcbo, 'userdata', val);
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');

        case 'fixdegrees',
            
            val = str2double(get(gcbo, 'string'));
            if isnan(val) || val <= 0 || val > 10,
                val = get(gcbo, 'userdata');
                set(gcbo, 'string', num2str(val));
                return
            end
            set(gcbo, 'userdata', val);
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');

        case 'fixtime',
        
            val = str2double(get(gcbo, 'string'));
            if isnan(val) || val < 10 || val > 9999,
                val = get(gcbo, 'userdata');
                set(gcbo, 'string', num2str(val));
                return
            end
            set(gcbo, 'userdata', val);
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            
        case 'eyeadjusttest',
            
            tform = get(findobj(gcf, 'tag', 'calbutton'), 'userdata');
            if isempty(tform),
                mlmessage('*** Must calibrate eyes before testing this function ***');
                return
            end

            set(gco, 'hittest', 'off');
            io = get(findobj(gcf, 'tag', 'ioframe'), 'userdata');
            if isempty(fieldnames(io.EyeX)) || isempty(fieldnames(io.EyeY)),
                mlmessage('*** Must set Eye X & Y inputs to test eye drift correction settings ***');
                set(gco, 'hittest', 'on');
                return
            end
            mlmessage('Initializing eye signal inputs...');
            [daq daqerror] = initio(io);
            if ~isempty(daqerror),
                mlmessage(daqerror);
                set(gco, 'hittest', 'on');
                return
            end
            numsamples = 3*daq.AnalogInput.SampleRate;
            daq.AnalogInput.SamplesPerTrigger = numsamples;
            ix = daq.EyeSignal.XChannelIndex;
            iy = daq.EyeSignal.YChannelIndex;
            
            adjustfraction = get(findobj(gcf, 'tag', 'adjustfraction'), 'userdata');
            fixtime = get(findobj(gcf, 'tag', 'fixtime'), 'userdata');
            fixdegrees = get(findobj(gcf, 'tag', 'fixdegrees'), 'userdata');
            smoothsigma = get(findobj(gcf, 'tag', 'smoothsigma'), 'userdata');
            targetlist = get(findobj(gcf, 'tag', 'eyecaltext'), 'userdata');
            Txy = targetlist;
            Txy(1) = -99999;
            
            mlmessage('Aquiring 3 seconds of eye data...');
            start(daq.AnalogInput);
            while daq.AnalogInput.SamplesAvailable < numsamples, end
            eyedata = getdata(daq.AnalogInput);
            ex = eyedata(:, ix);
            ey = eyedata(:, iy);
            [eyedata(:, 1) eyedata(:, 2)] = tformfwd(tform, ex, ey);
            aec = adjust_eye_calibration(eyedata, Txy, daq, tform, adjustfraction, fixdegrees, fixtime, smoothsigma, targetlist);
            daqreset;

            mlmessage('Displaying data...');
            fig = figure;
            set(fig, 'position', [300 225 600 700], 'color', [0 0 0], 'menubar', 'none', 'numbertitle', 'off', 'name', 'Test Eye Signal Acquisition', 'tag', 'sampleeye', 'resize', 'off');
            
            ax1 = subplot(4, 1, 1:3);
            hold on;
            h = plot(eyedata(:, 1), eyedata(:, 2));
            set(h, 'color', [1 1 1]);
            h = plot(aec.FixPoints(:, 1), aec.FixPoints(:, 2), 'r.');
            set(h, 'markersize', 25);
            set(ax1, 'color', [.2 .2 .2]);
            h = title('Transformed X-Y Data');
            set(h, 'color', [1 1 1]);
            
            ax2 = subplot(4, 1, 4);
            xmax = length(aec.EyeVelocity);
            ymax = 1.2*max(aec.EyeVelocity);
            hold on;
            hs = zeros(1, length(aec.StartFixation));
            he = hs;
            axcol = [.3 .3 .2];
            for i = 1:length(aec.StartFixation),
                patch([aec.StartFixation(i) aec.EndFixation(i) aec.EndFixation(i) aec.StartFixation(i)], [0 0 ymax ymax], [.2 .2 .2]);
                hs(i) = line([aec.StartFixation(i) aec.StartFixation(i)], [0 ymax]);
                he(i) = line([aec.EndFixation(i) aec.EndFixation(i)], [0 ymax]);
            end
            set([hs he], 'color', [.8 .8 .5]);
            plot(aec.EyeVelocity, 'r');
            h = line([0 xmax], [aec.SaccadeThreshold aec.SaccadeThreshold]);
            set(h, 'color', [.7 .7 .7]);
            h1 = line([0 xmax], [0 0]);
            h2 = line([0 xmax], [ymax ymax]);
            set([h1 h2], 'color', [1 1 1]);
            set(ax2, 'xlim', [0 xmax], 'ylim', [0 ymax], 'color', axcol);
            h = title('Eye Velocity with Saccade Detections');
            set(h, 'color', [1 1 1]);
            
            set([ax1 ax2], 'box', 'on', 'xcolor', [1 1 1], 'ycolor', [1 1 1]);
            uicontrol('style', 'pushbutton', 'position', [200 15 200 30], 'string', 'Close Window', 'callback', 'close(gcf)');
            set(gcf, 'closerequestfcn', 'delete(gcf); set(findobj(''tag'', ''mlmessagebox''), ''string'', '''');');
            set(gco, 'hittest', 'on');
            
        case 'alertsandupdates',

            update_alertmenu;
            if get(gcbo, 'value'),
                set(findobj(gcf, 'tag', 'menubar_alertstest'), 'enable', 'on');
            else
                set(findobj(gcf, 'tag', 'menubar_alertstest'), 'enable', 'off');
            end
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            
        case 'alertstest',
            
            file = get(findobj(gcf, 'tag', 'au_function'), 'userdata');
            if isempty(file),
                mlmessage('*** No Alerts Function Specified ***');
                return
            end
            if ~exist(file, 'file'),
                mlmessage('*** Specified Alerts Function Not Found ***');
                return
            end
            mldirectories = getpref('MonkeyLogic', 'Directories');
            copyfile(file, mldirectories.RunTimeDirectory);
            addpath(mldirectories.RunTimeDirectory);
            [pname fname] = fileparts(file);
            feval(fname, 'MonkeyLogic Alerts TEST');
            rmpath(mldirectories.RunTimeDirectory);
            mlmessage('Test Message Sent');
            
        case 'au_function',

            mlmessage('This function should pass a string input to a remote device (e.g., e-mail or pager)');
            [fname pname] = uigetfile([MLPrefs.Directories.ExperimentDirectory '*.m'], 'Choose Remote Alert Function');
            if fname(1) == 0,
                mlmessage('');
                return
            end
            [pname, fname, ext] = fileparts(fname);
            if strcmpi(ext, '.html') || strcmpi(ext, '.htm'),
                set(gcbo, 'string', ['Web Template: ' fname], 'userdata', [pname fname ext]);
            else
                set(gcbo, 'string', ['Alert Function: ' fname], 'userdata', [pname fname ext]);
            end
            mlmessage('>>> Alert function set <<<');
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            
        case 'au_errorcheck',
            
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');

        case 'au_blockcheck',
            
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');

        case 'au_userdefinedcheck',
            
            aucrth = findobj(gcf, 'tag', 'au_userdefinedcritfunction');
            critfile = get(aucrth, 'userdata');
            if get(gcbo, 'value'),
                set(aucrth, 'enable', 'on', 'string', 'Press to select function');
                if ~isempty(critfile),
                    [pname fname] = fileparts(critfile);
                    set(aucrth, 'string', fname);
                end
            else
                set(aucrth, 'enable', 'off');
                if isempty(critfile),
                    set(aucrth, 'string', 'n/a');
                end
            end
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            
        case 'au_userdefinedcritfunction',
            
            mlmessage('This function should take TrialRecord as input and return an alert string, if any');
            [fname pname] = uigetfile([MLPrefs.Directories.ExperimentDirectory '*.m'], 'Choose Remote Alert Function');
            if fname(1) == 0,
                mlmessage('');
                return
            end
            [pname, fname, ext] = fileparts(fname); %eliminates '.m'
            set(gcbo, 'string', fname, 'userdata', [pname fname ext]);
            mlmessage('>>> User-defined alert criteria function set <<<');
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            
        case 'edittimingfile',
            
            val = get(findobj(gcf, 'tag', 'timingfiles'), 'value');
            tfile = get(findobj(gcf, 'tag', 'timingfiles'), 'string');
            tfile = deblank(tfile{val});
            f = find(tfile == filesep, 1);
            if isempty(f),
                tfile = [MLPrefs.Directories.ExperimentDirectory tfile];
                if ~exist(tfile, 'file'),
                    fid = fopen(tfile, 'w');
                    fprintf(fid, '%% %s', tfile);
                    fclose(fid);
                end
            end
            edit(tfile);
            mlmessage('>>> Opened timing file in MATLAB editor <<<')
            
        case 'iti',
            
            val = str2double(get(gcbo, 'string'));
            if isempty(val) || isnan(val),
                set(gcbo, 'string', num2str(get(gcbo, 'userdata')));
                return
            end
            set(gcbo, 'userdata', val);
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
                        
        case 'mltimetest',
                        
            nullstr = get(findobj(gcf, 'tag', 'totalconds'), 'string');
            if ~strcmp(nullstr, '--'),
                mlmessage('Testing MonkeyLogic latencies...');
                savecfg;
                prt = get(findobj(gcf, 'tag', 'priority'), 'value');
                set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'off');
                datafile = [MLPrefs.Directories.BaseDirectory 'timetest.bhv'];
                condfile = get(findobj(gcf, 'tag', 'condfileselect'), 'userdata');
                testflag = 1;
                Result = monkeylogic(condfile, datafile, testflag);
                Result = Result.ReactionTime; %contains the benchmarking data
                delete(datafile);
                close(findobj('tag', 'mlmonitor'));
                maxtime = 500;
                testmovie = Result{1};
                testpic = Result{2};
                mtarray = testmovie{1};
                mfarray = testmovie{2};
                ptarray = testpic{1};

                figure;
                if prt == 1,
                    prtstr = 'Normal';
                elseif prt == 2,
                    prtstr = 'High';
                elseif prt == 3,
                    prtstr = 'Highest';
                end
                str = sprintf('MonkeyLogic Latency Test (Run-Time Priority: %s)', prtstr);
                set(gcf, 'position', [100 150 900 700], 'color', [0 0 0], 'numbertitle', 'off', 'name', str, 'menubar', 'none');
                subplot(2, 1, 2);
                x = mtarray(2:end);
                xmin = min(x);
                x = x - xmin;
                y = diff(mtarray);
                h1 = plot(x, y);
                mmax = ceil(max(y));
                x = mfarray - xmin;
                y = 2*mmax*ones(size(mfarray));
                hold on
                h2 = stem(x, y);
                set(h1, 'linewidth', 1, 'color', [.8 .8 0]);
                set(h2, 'linewidth', 1, 'color', [1 0 0]);
                set(gca, 'color', [0 0 0], 'xlim', [-10 maxtime], 'ylim', [-0.1 mmax], 'xcolor', [1 1 1], 'ycolor', [1 1 1], 'yscale', 'linear');
                xlabel('Cycle Number');
                ylabel('Cycle Latency (milliseconds)');
                htxt = title('Movie Display Results');
                set(htxt, 'color', [1 1 1]);

                subplot(2, 1, 1);
                x = ptarray(2:end);
                x = x - min(x);
                y = diff(ptarray);
                pmax = ceil(max(y));
                h3 = plot(x, y);
                set(h3, 'linewidth', 1, 'color', [.8 .8 0]);
                set(gca, 'color', [0 0 0], 'xlim', [-10 maxtime], 'ylim', [-0.1 pmax] ,'xcolor', [1 1 1], 'ycolor', [1 1 1], 'yscale', 'linear');
                xlabel('Cycle Number');
                ylabel('Cycle Latency (milliseconds)');
                htxt = title('Static Picture Display Results');
                set(htxt, 'color', [1 1 1]);
                mlmessage('Done.');
                mlmessage('');
            end
            
        case 'speedtest',
            
            mlmessage('Testing MATLAB baseline latencies...')
            set(gcf, 'pointer', 'watch');
            
            numloops = 1000000;
            k = 1000;
            t = zeros(numloops, 1);
            prtnormal;
            mlmessage('Testing Normal Priority...');
            pause(0.1);
            tic;
            for i = 1:numloops+1,
                t(i) = k*toc;
            end
            prtnormal;
            Traw{1} = t;
            T{1} = diff(t);
            
            t = zeros(numloops, 1);
            prthigh;
            mlmessage('Testing High Priority...');
            pause(0.1);
            tic;
            for i = 1:numloops+1,
                t(i) = k*toc;
            end
            prtnormal;
            Traw{2} = t;
            T{2} = diff(t);
            
            t = zeros(numloops, 1);
            prtrealtime;
            mlmessage('Testing Highest Priority...');
            pause(0.1);
            tic;
            for i = 1:numloops+1,
                t(i) = k*toc;
            end
            prtnormal;
            Traw{3} = t;
            T{3} = diff(t);
            
            set(gcf, 'pointer', 'arrow');
            t_thresh = 0.01;

            mlmessage('Done.');
            mlmessage('');
            figure
            set(gcf, 'position', [300 100 600 800], 'color', [0 0 0], 'numbertitle', 'off', 'name', 'MATLAB Latency Test Results', 'menubar', 'none');
            xstep = 0.02;
            xmax = 1;
            xt = xstep:xstep:xmax;
            lhtext = 0.8*mean(xt);
            figlabels = {'Normal Process Priority' 'High Process Priority' 'Highest Process Priority'};
            for i = 1:3,
                subplot(3, 1, i);
                n1 = hist(T{i}, xt);
                h = bar(xt, n1);
                set(h, 'facecolor', [1 1 .5], 'edgecolor', [1 1 1], 'barwidth', 1);
                h = title(figlabels{i});
                set(h, 'fontsize', 14, 'color', [1 1 1]);
                ymax = max(get(gca, 'ylim'));
                h(1) = text(lhtext, 0.1*ymax, sprintf('Completed %i cycles in %2.3f seconds', numloops, 0.001*(Traw{i}(numloops)-Traw{i}(1))));
                h(2) = text(lhtext, 0.02*ymax, sprintf('Mean Latency = %1.4f ms', mean(T{i})));
                h(3) = text(lhtext, 0.004*ymax, sprintf('Max Latency = %1.3f ms', max(T{i})));
                h(4) = text(lhtext, 0.0008*ymax, sprintf('Fraction > %1.3f ms = %0.4f', t_thresh, sum(T{i} > t_thresh)/numloops));
                set(h, 'color', [1 1 1]);
                set(gca, 'box', 'on', 'color', [.2 .2 .2], 'xcolor', [1 1 1], 'ycolor', [1 1 1], 'xlim', [0 xmax], 'yscale', 'log');
            end
            h = xlabel('milliseconds');
            set(h, 'fontsize', 10, 'color', [1 1 1]);
            mlmessage('Done.');
            mlmessage('');

        case 'screenres',
            
            validres = get(gcbo, 'userdata');
            reschoice = get(gcbo, 'value');
            xsize = validres(reschoice, 1);
            ysize = validres(reschoice, 2);
            viewdist = str2double(get(findobj(gcf, 'tag', 'viewdist'), 'string'));
            diagsize = str2double(get(findobj(gcf, 'tag', 'diagsize'), 'string'));
            diagpix = sqrt((xsize^2) + (ysize^2));
            viewrad = 2*atan2(diagsize/2, viewdist);
            viewdeg = viewrad*180/pi;
            ppd = diagpix/viewdeg;
            set(findobj(gcf, 'tag', 'ppd'), 'string', sprintf('%2.2f', ppd));
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
                        
        case 'priority',
            
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            
        case 'viewdist',

            validres = get(findobj(gcf, 'tag', 'screenres'), 'userdata');
            reschoice = get(findobj(gcf, 'tag', 'screenres'), 'value');
            diagsize = get(findobj(gcf, 'tag', 'diagsize'), 'userdata');
            xsize = validres(reschoice, 1);
            ysize = validres(reschoice, 2);
            viewdist = str2double(get(gcbo, 'string'));
            if isempty(viewdist) || isnan(viewdist),
                set(gcbo, 'string', num2str(get(gcbo, 'userdata')));
                return
            else
                set(gcbo, 'userdata', diagsize);
            end
            diagsize = str2double(get(findobj(gcf, 'tag', 'diagsize'), 'string'));
            diagpix = sqrt((xsize^2) + (ysize^2));
            viewrad = 2*atan2(diagsize/2, viewdist);
            viewdeg = viewrad*180/pi;
            ppd = diagpix/viewdeg;
            set(findobj(gcf, 'tag', 'ppd'), 'string', sprintf('%2.2f', ppd));
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            
        case 'diagsize',

            validres = get(findobj(gcf, 'tag', 'screenres'), 'userdata');
            reschoice = get(findobj(gcf, 'tag', 'screenres'), 'value');
            xsize = validres(reschoice, 1);
            ysize = validres(reschoice, 2);
            viewdist = str2double(get(findobj(gcf, 'tag', 'viewdist'), 'string'));
            diagsize = str2double(get(findobj(gcf, 'tag', 'diagsize'), 'string'));
            if isempty(diagsize) || isnan(diagsize),
                set(gcbo, 'string', num2str(get(gcbo, 'userdata')));
                return
            else
                set(gcbo, 'userdata', diagsize);
            end
            diagpix = sqrt((xsize^2) + (ysize^2));
            viewrad = 2*atan2(diagsize/2, viewdist);
            viewdeg = viewrad*180/pi;
            ppd = diagpix/viewdeg;
            set(findobj(gcf, 'tag', 'ppd'), 'string', sprintf('%2.2f', ppd));
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
  
        case 'fixationfilename',

            mlmessage('Select the image file containing the new fixation point image');
            [cursorfile cursorpath] = uigetfile([MLPrefs.Directories.ExperimentDirectory '*.jpg; *.bmp; *.gif'], 'Choose fixation point image file');
            mlmessage('');
            if cursorfile == 0,
                if ~strcmpi(get(gcbo, 'userdata'), 'default'),
                    a = questdlg('Use default image for fixation spot?', 'Fixation spot');
                    if strcmpi(a, 'Yes'),
                        set(gcbo, 'string', '- Default - ', 'userdata', 'DEFAULT');
                    else
                        return
                    end
                else
                    return
                end
            else
                set(gcbo, 'string', cursorfile, 'userdata', [cursorpath cursorfile]);
            end
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            update_stimwindow;

        case 'cursorfilename',

            mlmessage('Choose image file for subject''s joystick cursor');
            [cursorfile cursorpath] = uigetfile([MLPrefs.Directories.ExperimentDirectory '*.jpg; *.bmp; *.gif'], 'Choose cursor image file');
            mlmessage('');
            if cursorfile == 0,
                if ~strcmpi(get(gcbo, 'userdata'), 'default'),
                    a = questdlg('Use default image for subject cursor?', 'Subject Cursor');
                    if strcmpi(a, 'Yes'),
                        set(gcbo, 'string', '- Default - ', 'userdata', 'DEFAULT');
                        set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
                        set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
                    end
                end
                return
            end
            set(gcbo, 'string', cursorfile, 'userdata', [cursorpath cursorfile]);
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            
        case 'userplotfunction',
            
            mlmessage('Choose m-file function to create a graph, replacing the RT histograms');
            [mfile mpath] = uigetfile([MLPrefs.Directories.ExperimentDirectory '*.m'], 'Choose user plot function');
            mlmessage('');
            if mfile == 0,
                if ~isempty(get(gcbo, 'userdata')),
                    a = questdlg('Use default RT graphs?', 'User Plot');
                    if strcmpi(a, 'Yes'),
                        set(gcbo, 'userdata', '', 'string', 'User Plot Function');
                        set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
                        set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
                    end
                end
                return
            end
            set(gcbo, 'string', ['Plot Function: ' mfile], 'userdata', [mpath mfile]);
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            
        case 'bgred',
            
            val = str2double(get(gcbo, 'string'));
            if isnan(val) || val < 0 || val > 1,
                val = get(gcbo, 'userdata');
                set(gcbo, 'string', num2str(val));
                return
            end            
            set(gcbo, 'userdata', val);
            update_stimwindow;
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            
        case 'bggreen',

            val = str2double(get(gcbo, 'string'));
            if isnan(val) || val < 0 || val > 1,
                val = get(gcbo, 'userdata');
                set(gcbo, 'string', num2str(val));
                return
            end            
            set(gcbo, 'userdata', val);
            update_stimwindow;
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
        
        case 'bgblue',
            
            val = str2double(get(gcbo, 'string'));
            if isnan(val) || val < 0 || val > 1,
                val = get(gcbo, 'userdata');
                set(gcbo, 'string', num2str(val));
                return
            end            
            set(gcbo, 'userdata', val);
            update_stimwindow;
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            
        case 'photodiode',
            
            pdh = findobj(gcf, 'tag', 'photodiodesize');
            if get(gcbo, 'value') > 1,
                pdsize = str2double(get(pdh, 'string'));
                if isnan(pdsize) || pdsize == 0,
                    set(pdh, 'string', '16');
                end
                set(pdh, 'enable', 'on');
            else
                set(pdh, 'string', '0');
                set(pdh, 'enable', 'off');
            end
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            
        case 'photodiodesize',
            
            str = get(gcbo, 'string');
            pdsize = str2double(str);
            if isnan(pdsize) || numel(pdsize) > 1,
                pdsize = 16;
            end
            pdsize = pdsize - mod(pdsize, 4);
            if pdsize == 0,
                pdsize = 4;
            end
            set(gcbo, 'string', num2str(pdsize));
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
                        
        case 'videodevice',
            
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            
        case 'refreshrate',
            
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            
        case 'bufferpages',
            
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            
        case 'videotest',

            logger.logMessage('<<< MonkeyLogic >>> Starting video test');
            mlmessage('Initializing video...');
            drawnow;
            
            
            bytesperpixel = 4;
            videodevice = get(findobj(gcf, 'tag', 'videodevice'), 'value');
            resval = get(findobj(gcf, 'tag', 'screenres'), 'value');
            validsizes = get(findobj(gcf, 'tag', 'screenres'), 'userdata');
            bufferpages = get(findobj(gcf, 'tag', 'bufferpages'), 'value');
            validrefresh = get(findobj(gcf, 'tag', 'refreshrate'), 'userdata');
            refreshrate = validrefresh(get(findobj(gcf, 'tag', 'refreshrate'), 'value'));
            validxsize = validsizes(:, 1);
            validysize = validsizes(:, 2);
            ScreenX = validxsize(resval);
            ScreenY = validysize(resval);
            numcycles = 10;
            halfx = ScreenX/2;
            halfy = ScreenY/2;
            [x y] = meshgrid(-halfx:halfx-1, -halfy:halfy-1);
            dist = sqrt((x.^2) + (y.^2));
            
            try
                mlvideo('init');
                mlvideo('initdevice', videodevice);
                mlvideo('setmode', videodevice, ScreenX, ScreenY, bytesperpixel, refreshrate, bufferpages);
                buffer = zeros(numcycles, 1);
                mlmessage('Generating video frame data...');
                for i = 1:numcycles,
                    buffer(i) = mlvideo('createbuffer', videodevice, ScreenX, ScreenY, bytesperpixel);
                    rpat = cos(dist./i+2);
                    gpat = cos(dist./(i+5));
                    bpat = cos(dist./(i+8));
                    testpattern = cat(3, rpat, gpat, bpat);
                    testpattern = (testpattern + 1)/2;
                    testpattern = round(255*testpattern);
                    testpattern = cat(3, testpattern, ones(ScreenY, ScreenX));
                    mlvideo('copybuffer', videodevice, buffer(i), testpattern);
                end
                mlmessage('Displaying test pattern...');
                t1 = tic;
                for j = 1:numcycles,
                    for i = 1:numcycles,
                        mlvideo('blit', videodevice, buffer(i));
                        mlvideo('flip', videodevice);
                    end
                    for i = numcycles:-1:1,
                        mlvideo('blit', videodevice, buffer(i));
                        mlvideo('flip', videodevice);
                    end
                end
                t2 = toc(t1);
                for i = 1:numcycles,
                    mlvideo('releasebuffer', videodevice, buffer(i));
                end
                mlvideo('showcursor', videodevice, 1);
                mlvideo('restoremode', videodevice);
                mlvideo('releasedevice', videodevice);
                mlvideo('release');
                totalframes = 2*(numcycles^2);
                framerate = 1/(t2/totalframes);
                mlmessage(sprintf('Approximate video refresh rate = %3.2f Hz', framerate));
            catch
                mlvideo('showcursor', videodevice, 1);
                mlvideo('restoremode', videodevice);
                mlvideo('releasedevice', videodevice);
                mlvideo('release');
                lasterr
                mlmessage('*** Error encountered during application of selected video settings ***');
            end           
            
        case 'updateinterval',
            
            val = str2double(get(gcbo, 'string'));
            if isnan(val) || val < 1,
                val = get(gcbo, 'userdata');
                set(gcbo, 'string', num2str(val));
                return
            end
            set(gcbo, 'userdata', val);
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            
        case 'eyered',
            
            val = str2double(get(gcbo, 'string'));
            if isnan(val) || val < 0 || val > 1,
                val = get(gcbo, 'userdata');
                set(gcbo, 'string', num2str(val));
                return
            end
            
            set(gcbo, 'userdata', val);
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            update_minicontrolscreen;
            
        case 'eyegreen',
            
            val = str2double(get(gcbo, 'string'));
            if isnan(val) || val < 0 || val > 1,
                val = get(gcbo, 'userdata');
                set(gcbo, 'string', num2str(val));
                return
            end
            
            set(gcbo, 'userdata', val);
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            update_minicontrolscreen;

        case 'eyeblue',

            val = str2double(get(gcbo, 'string'));
            if isnan(val) || val < 0 || val > 1,
                val = get(gcbo, 'userdata');
                set(gcbo, 'string', num2str(val));
                return
            end
            
            set(gcbo, 'userdata', val);
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            update_minicontrolscreen;
            
        case 'eyesize',
           
            val = str2double(get(gcbo, 'string'));
            if isnan(val) || val < 1,
                val = get(gcbo, 'userdata');
                set(gcbo, 'string', num2str(val));
                return
            end
            
            set(gcbo, 'userdata', val);
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            update_minicontrolscreen;

        case 'joyred',
            
            val = str2double(get(gcbo, 'string'));
            if isnan(val) || val < 0 || val > 1,
                val = get(gcbo, 'userdata');
                set(gcbo, 'string', num2str(val));
                return
            end
            
            set(gcbo, 'userdata', val);
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            update_minicontrolscreen;
            
        case 'joygreen',
            
            val = str2double(get(gcbo, 'string'));
            if isnan(val) || val < 0 || val > 1,
                val = get(gcbo, 'userdata');
                set(gcbo, 'string', num2str(val));
                return
            end
            
            set(gcbo, 'userdata', val);
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            update_minicontrolscreen;
            
        case 'joyblue',
            
            val = str2double(get(gcbo, 'string'));
            if isnan(val) || val < 0 || val > 1,
                val = get(gcbo, 'userdata');
                set(gcbo, 'string', num2str(val));
                return
            end

            set(gcbo, 'userdata', val);
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            update_minicontrolscreen;
            
        case 'joysize',
            
            val = str2double(get(gcbo, 'string'));
            if isnan(val) || val < 1,
                val = get(gcbo, 'userdata');
                set(gcbo, 'string', num2str(val));
                return
            end
            
            set(gcbo, 'userdata', val);
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            update_minicontrolscreen;
            
        case 'csgrid_cartesian',
            
            val = get(gcbo, 'value');
            if val,
                set(gcbo, 'string', 'Cartesian Grid ON', 'backgroundcolor', [.7 .8 .7]);
                set(findobj(gcf, 'tag', 'cartesianbrightness'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'cartesianbrightnessvalue'), 'string', sprintf('%1.2f', get(findobj(gcf, 'tag', 'cartesianbrightness'), 'value')));
            else
                set(gcbo, 'string', 'Cartesian Grid OFF', 'backgroundcolor', [.8 .7 .7]);
                set(findobj(gcf, 'tag', 'cartesianbrightness'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'cartesianbrightnessvalue'), 'string', 'n/a');
            end
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            update_minicontrolscreen;
           
        case 'csgrid_polar',
            
            val = get(gcbo, 'value');
            if val,
                set(gcbo, 'string', 'Polar Grid ON', 'backgroundcolor', [.7 .8 .7]);
                set(findobj(gcf, 'tag', 'polarbrightness'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'polarbrightnessvalue'), 'string', sprintf('%1.2f', get(findobj(gcf, 'tag', 'polarbrightness'), 'value')));
            else
                set(gcbo, 'string', 'Polar Grid OFF', 'backgroundcolor', [.8 .7 .7]);
                set(findobj(gcf, 'tag', 'polarbrightness'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'polarbrightnessvalue'), 'string', 'n/a');
            end
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            update_minicontrolscreen;
            
        case 'cartesianbrightness',
            
            set(findobj(gcf, 'tag', 'cartesianbrightnessvalue'), 'string', sprintf('%1.2f', get(gcbo, 'value')));
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            update_minicontrolscreen;
            
        case 'polarbrightness',
            
            set(findobj(gcf, 'tag', 'polarbrightnessvalue'), 'string', sprintf('%1.2f', get(gcbo, 'value')));
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            update_minicontrolscreen;

        case 'codesfile',
            
            [codesfile codespath] = uigetfile([MLPrefs.Directories.ExperimentDirectory '*.txt'], 'Choose codes text file');
            if codesfile == 0,
                return
            end
            set(gcbo, 'string', codesfile, 'userdata', [codespath codesfile]);
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            
        case 'editcodesfile',
            
            codesfile = get(findobj(gcf, 'tag', 'codesfile'), 'userdata');
            mlmessage('Waiting for NotePad to finish...');
            eval(['!%SystemRoot%\system32\notepad.exe ', codesfile]);
            mlmessage('');
            
        case 'experimentname',
            
            snameobject = findobj(gcf, 'tag', 'subjectname');
            subject = get(snameobject, 'string');
            if isempty(subject),
                subject = 'subject';
                set(snameobject, 'string', subject);
            end
            autodatafile = strcmpi(get(snameobject, 'userdata'), 'autodatafile = yes');
            dfileobject = findobj(gcf, 'tag', 'datafile');
            datafile = get(dfileobject, 'userdata');
            if isempty(datafile) || autodatafile,
                today = strrep(datestr(now, 2), '/', '-');
                today = [today(1:6) '20' today(7:8)];
                experimentname = get(gcbo, 'string');
                if isempty(experimentname),
                    experimentname = 'Experiment';
                    set(gcbo, 'string', experimentname);
                end
                datafilename = [experimentname '-' subject '-' today];
                datafile = [MLPrefs.Directories.ExperimentDirectory datafilename '.bhv'];
                if exist(datafile, 'file'),
                    dcount = 0;
                    while exist(datafile, 'file'),
                        dcount = dcount + 1;
                        dfilenum = sprintf('(%2.0f)', dcount);
                        dfilenum = strrep(dfilenum, ' ', '0');
                        datafile = [MLPrefs.Directories.ExperimentDirectory datafilename dfilenum '.bhv'];
                    end
                    datafilename = [datafilename dfilenum];
                end
                set(dfileobject, 'string', datafilename, 'userdata', datafile);
                set(findobj(gcf, 'tag', 'runbutton'), 'enable', 'on', 'cdata', imread('runbutton.jpg'));
                set(snameobject, 'userdata', 'autodatafile = yes');
            end
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            
        case 'subjectname',
            
            subject = get(gcbo, 'string');
            autodatafile = strcmpi(get(gcbo, 'userdata'), 'autodatafile = yes');
            subject(subject == ' ') = '_';
            if isempty(subject) || ~isvarname(subject),
                subject = 'subject';
            end
            set(gcbo, 'string', subject);
            dfileobject = findobj(gcf, 'tag', 'datafile');
            datafile = get(dfileobject, 'userdata');
            if isempty(datafile) || autodatafile,
                today = strrep(datestr(now, 2), '/', '-');
                today = [today(1:6) '20' today(7:8)];
                experimentname = get(findobj(gcf, 'tag', 'experimentname'), 'string');
                datafilename = [experimentname '-' subject '-' today];
                datafile = [MLPrefs.Directories.ExperimentDirectory datafilename '.bhv'];
                if exist(datafile, 'file'),
                    dcount = 0;
                    while exist(datafile, 'file'),
                        dcount = dcount + 1;
                        dfilenum = sprintf('(%2.0f)', dcount);
                        dfilenum = strrep(dfilenum, ' ', '0');
                        datafile = [MLPrefs.Directories.ExperimentDirectory datafilename dfilenum '.bhv'];
                    end
                    datafilename = [datafilename dfilenum];
                    mlmessage(sprintf('Appending a numerical suffix (%i) to create a unique data file name', dcount));
                end
                set(dfileobject, 'string', datafilename, 'userdata', datafile);
                set(findobj(gcf, 'tag', 'runbutton'), 'enable', 'on', 'cdata', imread('runbutton.jpg'));
                set(gcbo, 'userdata', 'autodatafile = yes');
            end
            
        case 'datafile',
            
            datafile = get(findobj(gcf, 'tag', 'datafile'), 'string');
            if isempty(datafile),
                set(findobj(gcf, 'tag', 'runbutton'), 'enable', 'inactive', 'cdata', imread('runbuttondim.jpg'));
                set(findobj(gcf, 'tag', 'subjectname'), 'userdata', 'autodatafile = yes');
                return
            end
                       
            [pname fname ext] = fileparts(datafile);
            if isempty(pname),
                datafile = [MLPrefs.Directories.ExperimentDirectory datafile];
            end
            if isempty(ext),
                datafile = [datafile '.bhv'];
            end

            set(gcbo, 'userdata', datafile);
            
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            if ~isempty(get(findobj(gcf, 'tag', 'condfileselect'), 'userdata')),
                set(findobj(gcf, 'tag', 'runbutton'), 'enable', 'on', 'cdata', imread('runbutton.jpg'));
            end
            set(findobj(gcf, 'tag', 'subjectname'), 'userdata', 'autodatafile = no');
                        
        case 'runbutton',
            
			if get(findobj(gcf, 'tag', 'blocklogic'), 'value') == 5 && isempty(get(findobj(gcf, 'tag', 'blockselectfun'), 'userdata')),
               mlmessage('Must specify a block-selection function for user-controlled block transitions');
               return
			end
			if get(findobj(gcf, 'tag', 'condlogic'), 'value') == 5 && isempty(get(findobj(gcf, 'tag', 'condselectfun'), 'userdata')),
                mlmessage('Must specify a condition-selection function for user-controlled conditions');
                return
			end
            
			set(findobj(gcf, 'tag', 'runbutton'), 'enable', 'off');			%this is a fail-safe in the case that a user hits the run button twice
            set(gcbo, 'hittest', 'off');
            nullstr = get(findobj(gcf, 'tag', 'totalconds'), 'string');
			if ~strcmp(nullstr, '--'),
                savecfg;
                set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'off');
                datafile = get(findobj(gcf, 'tag', 'datafile'), 'userdata');
                if exist(datafile, 'file'),
                    a = questdlg('Overwrite existing data file?', 'Data file already exists');
                    if strcmpi(a, 'No'),
                        mlmessage('Enter a new data file name to run the task');
						set(findobj(gcf, 'tag', 'runbutton'), 'enable', 'on');			%this is a fail-safe in the case that a user hits the run button twice
                        return
                    elseif strcmpi(a, 'Cancel'),
                        mlmessage('');
						set(findobj(gcf, 'tag', 'runbutton'), 'enable', 'on');			%this is a fail-safe in the case that a user hits the run button twice
                        return
                    end
                end
                condfile = get(findobj(gcf, 'tag', 'condfileselect'), 'userdata');
                testflag = 0;
                mlmessage('Running task...');
                set(findobj(gcf, 'tag', 'loadbutton'), 'userdata', struct);
                monkeylogic(condfile, datafile, testflag);
			end
            set(gcbo, 'hittest', 'on');
            mlmessage('Done.');

        case 'stimnames',
            
            update_stimwindow;
                        
        case 'savefullmovies',
            
            if get(gcbo, 'value'),
                mlmessage('Will save full Movie stimuli to the data file.');
            else
                mlmessage('Will save only the first frame of each Movie to the data file.');
            end
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            
        case 'countonlycorrect',
            
            if get(gcbo, 'value'),
                mlmessage('Will count only correct trials toward completing blocks.');
            else
                mlmessage('Will count all trials toward completing blocks.');
            end
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            
        case 'zoomslider',
            
            zpos = get(gcbo, 'value');
            stimax = findobj(gcf, 'tag', 'stimax');
            stimlist = findobj(gcf, 'tag', 'stimnames');
            val = get(stimlist, 'value');
            TaskObject = get(stimlist, 'userdata');
            TOB = TaskObject(val);
            minslider = get(gcbo, 'min');
            %maxslider = get(gcbo, 'max');
            if strcmpi(TOB.Type, 'fix') || strcmpi(TOB.Type, 'pic') || strcmpi(TOB.Type, 'crc') || strcmpi(TOB.Type, 'sqr') || strcmpi(TOB.Type, 'mov') || strcmpi(TOB.Type, 'gen'),
                zpos = zpos - minslider;
                minax = 0.5 - (0.5*zpos);
                maxax = minslider + (0.5*zpos);
                set(stimax, 'xlim', [minax maxax], 'ylim', [minax maxax]);
            elseif strcmpi(TOB.Type, 'snd') || strcmpi(TOB.Type, 'stm'),
                xlim = get(stimax, 'xlim');
                set(stimax, 'xlim', [xlim(1) xlim(1)+zpos]);
            end
            
        case 'positionslider',
            
            zpos = get(gcbo, 'value');
            stimax = findobj(gcf, 'tag', 'stimax');
            stimlist = findobj(gcf, 'tag', 'stimnames');
            val = get(stimlist, 'value');
            TaskObject = get(stimlist, 'userdata');
            TOB = TaskObject(val);
            if strcmpi(TOB.Type, 'mov'),
                c = get(stimax, 'children');
                M = get(stimax, 'userdata');
                imdata = M(:,:,:,round(zpos));
                set(c, 'cdata', imdata);
            elseif strcmpi(TOB.Type, 'snd') || strcmpi(TOB.Type, 'stm'),
                xlim = get(stimax, 'xlim');
                set(stimax, 'xlim', [zpos zpos+diff(xlim)]);
            end

        case 'viewplay',
            
            val = get(findobj(gcf, 'tag', 'stimnames'), 'value');
            TaskObject = get(findobj(gcf, 'tag', 'stimnames'), 'userdata');
            
            vdev = get(findobj(gcf, 'tag', 'videodevice'), 'value');
            resval = get(findobj(gcf, 'tag', 'screenres'), 'value');
            validsizes = get(findobj(gcf, 'tag', 'screenres'), 'userdata');
            bufferpages = get(findobj(gcf, 'tag', 'bufferpages'), 'value');
            validrefresh = get(findobj(gcf, 'tag', 'refreshrate'), 'userdata');
            refreshrate = validrefresh(get(findobj(gcf, 'tag', 'refreshrate'), 'value'));
            validxsize = validsizes(:, 1);
            validysize = validsizes(:, 2);
            xs = validxsize(resval);
            ys = validysize(resval);
            hxs = round(xs/2);
            hys = round(ys/2);
            ppd = str2double(get(findobj(gcf, 'tag', 'ppd'), 'string'));
            bgcolor = [get(findobj(gcf, 'tag', 'bgred'), 'userdata') get(findobj(gcf, 'tag', 'bggreen'), 'userdata') get(findobj(gcf, 'tag', 'bgblue'), 'userdata')];
            bytesperpixel = 4;
            modval = 64;
            
            ob = TaskObject(val);
            t = ob.Type;
            vbufnum = 0;
            if strcmpi(t, 'fix') || strcmpi(t, 'pic') || strcmpi(t, 'dot') || strcmpi(t, 'crc') || strcmpi(t, 'sqr') || strcmpi(t, 'gen'),

                if strcmp(t, 'fix') || strcmp(t, 'dot'),
                    imdata = get_fixspot(bgcolor);
                elseif strcmp(t, 'pic'),
                    imdata = double(imread(ob.Name));
                    imdata = double(imdata)/255;
                elseif strcmp(t, 'crc'),
                    crcrad = ob.Radius * ppd;
                    imdata = makecircle(crcrad, ob.Color, ob.FillFlag, bgcolor);
                elseif strcmp(t, 'sqr'),
                    sqrx = ob.Xsize * ppd;
                    sqry = ob.Ysize * ppd;
                    imdata = makesquare([sqrx sqry], ob.Color, ob.FillFlag, bgcolor);
                elseif strcmp(t, 'gen'), %user-generated from m-file
                    TrialRecord.CurrentTrialNumber = 1;
                    TrialRecord.CurrentTrialWithinBlock = 1;
                    TrialRecord.CurrentCondition = 1;
                    TrialRecord.CurrentBlock = 1;
                    TrialRecord.CurrentBlockCount = 1;
                    TrialRecord.ConditionsPlayed = [];
                    TrialRecord.ConditionsThisBlock = 1;
                    TrialRecord.BlocksPlayed = [];
                    TrialRecord.BlockCount = [];
                    TrialRecord.BlockOrder = [];
                    TrialRecord.BlocksSelected = 1;
                    TrialRecord.TrialErrors = [];
                    TrialRecord.ReactionTimes = [];
                    imdata = feval(ob.FunctionName, TrialRecord);
					if ischar(imdata)
						imdata = imread(imdata);
					end
                    if (max(max(max(imdata)))) > 1,
                      imdata = imdata/255;
                    end
                end

                [imdata xis yis xisbuf yisbuf] = pad_image(imdata, modval, bgcolor);
                xoffset = round(xis/2);
                yoffset = round(yis/2);
                xpos = 0; %all images display in the center of the screen
                ypos = 0;
                xscreenpos = hxs + round(ppd * xpos) - xoffset;
                yscreenpos = hys - round(ppd * ypos) - yoffset; %invert so that positive y is above the horizon

                mlmessage('Initializing video...');
                try
                    mlvideo('init');
                    mlvideo('initdevice', vdev);
                    mlvideo('setmode', vdev, xs, ys, bytesperpixel, refreshrate, bufferpages);
                    mlvideo('clear', vdev, bgcolor);
                    mlvideo('flip', vdev);
                    mlvideo('showcursor', vdev, 0);
                    vbuf = mlvideo('createbuffer', vdev, xisbuf, yisbuf, bytesperpixel);
                    mlvideo('copybuffer', vdev, vbuf, imdata);
                    mlvideo('blit', vdev, vbuf, xscreenpos, yscreenpos, xis, yis);
                    mlvideo('flip', vdev);
                    mlmessage('>>> Displaying picture <<<');
                    mlkbd('init');
                catch
                    mlkbd('release');
                    try
                    mlvideo('showcursor', vdev, 1);
                    mlvideo('restoremode', vdev);
                    mlvideo('releasedevice', vdev);
                    mlvideo('release');
                    catch
                    end
                    
                    mlmessage('*** Unable to initialize video ***');
                    lasterror
                    return
                end
                keypress = [];
                mlmessage('Press any key to continue...');
                while isempty(keypress),
                    keypress = mlkbd('getkey');
                end
                
                mlkbd('release');
                mlvideo('showcursor', vdev, 1);
                mlvideo('restoremode', vdev);
                mlvideo('releasedevice', vdev);
                mlvideo('release');
                set(findobj('tag', 'viewplay'), 'value', 0);
                mlmessage('');
                figure(findobj('tag', 'monkeylogicmainmenu'));

            elseif strcmpi(t, 'mov'), %movie
                
                if verLessThan('matlab', '8')
                    reader = mmreader(ob.Name); %#ok<DMMR>
                else
                    reader = VideoReader(ob.Name); 
                end
                numframes = get(reader, 'numberOfFrames');
                
                imdata = squeeze(read(reader, 1));
                if size(imdata, 3) > 1,
                    mlmessage('*** Warning: AVI files are assumed to contain TrueColor images ***');
                end
                                
                try
                    mlvideo('init');
                    mlvideo('initdevice', vdev);
                    mlvideo('setmode', vdev, xs, ys, bytesperpixel, refreshrate, bufferpages);
                    mlvideo('clear', vdev, bgcolor);
                    mlvideo('flip', vdev);
                    mlvideo('showcursor', vdev, 0);

                    mlmessage('Copying movie frames to video buffers...');
                    M = cell(numframes, 1);
                    mov = read(reader);
                    for fnum = 1:numframes,
                        [imdata xis yis xisbuf yisbuf] = pad_image(mov(:,:,:,fnum), modval, bgcolor);   %#ok<NASGU,NASGU>
                        imdata = double(imdata);
                        if ~any(imdata(:) > 1),
                            imdata = ceil(255*imdata);
                        end
                        M{fnum} = uint32(xglrgb8(imdata(:, :, 1)', imdata(:, :, 2)', imdata(:, :, 3)'));
                        vbuf = mlvideo('createbuffer', vdev, xisbuf, yisbuf, bytesperpixel);
                        mlvideo('copybuffer', vdev, vbuf, imdata);
                        vbufnum = vbufnum + 1;
                        vbuffer(vbufnum) = vbuf; %#ok<AGROW>
                    end
                    lastbuffer = vbufnum;
                    
                    xpos = 0;
                    ypos = 0;
                    xoffset = round(xis/2);
                    yoffset = round(yis/2);
                    xscreenpos = hxs + round(ppd * xpos) - xoffset;
                    yscreenpos = hys - round(ppd * ypos) - yoffset; %invert so that positive y is above the horizon

                    mlmessage('Initializing video...');
                    mlmessage('>>> Playing movie <<<');
                    mlkbd('init');
                    keypress = 0;
                    while ~keypress,
                        if ~keypress,
                            for vbufnum = 1:lastbuffer,
                                mlvideo('blit', vdev, vbuffer(vbufnum), xscreenpos, yscreenpos, xis, yis);
                                mlvideo('flip', vdev);
                                kb = mlkbd('getkey');
                                if ~isempty(kb),
                                    keypress = 1;
                                    break
                                end
                            end
                        end
                        if ~keypress,
                            for vbufnum = lastbuffer:-1:1,
                                mlvideo('blit', vdev, vbuffer(vbufnum), xscreenpos, yscreenpos, xis, yis);
                                mlvideo('flip', vdev);
                                kb = mlkbd('getkey');
                                if ~isempty(kb),
                                    keypress = 1;
                                    break
                                end
                            end
                        end
                    end
                catch ME
                    fprintf('Video playback error:\n%s\n',getReport(ME));
                    mlvideo('showcursor', vdev, 1);
                    mlvideo('restoremode', vdev);
                    mlvideo('releasedevice', vdev);
                    mlvideo('release');
                    mlkbd('release');
                    mlmessage('*** Unable to initialize video ***');
                    return
                end
                mlvideo('showcursor', vdev, 1);
                mlvideo('restoremode', vdev);
                mlvideo('releasedevice', vdev);
                mlvideo('release');
                mlkbd('release');
                mlmessage('Done.');
                mlmessage('');

            elseif strcmpi(t, 'snd'), %sound

                mlmessage('>>> Playing sound <<<');
                drawnow;
                io_audio = audioplayer(ob.WaveForm, ob.Freq, ob.NBits);
                play(io_audio);
                while isplaying(io_audio), end
                mlmessage('Done.');
                mlmessage('');

            elseif strcmpi(t, 'stm'), %stimulation waveform

                mlmessage('Initializing DAQ analog output...');
                io = get(findobj(gcf, 'tag', 'ioframe'), 'userdata');
                DAQ = initio(io); %#ok<NASGU>
                eval(sprintf('StimAO = DAQ.Stim%i;', ob.OutputPort));
                actual_rate = setverify(StimAO, 'SampleRate', ob.Freq);
                if actual_rate ~= ob.Freq,
                    daqreset;
                    mlmessage(sprintf('*** Unable to set analog output frequency to desired value of %iHz ***', ob.Freq));
                end
                [rows cols] = size(ob.WaveForm);
                if min([rows cols]) > 1,
                    mlmessage('*** Stimulus waveform must be a one-dimensional vector ***');
                end
                if cols > rows,
                    stimdata = ob.WaveForm';
                else
                    stimdata = ob.WaveForm;
                end
                stop(StimAO); %in case was still running from a previous trial
                putdata(StimAO, stimdata);
                start(StimAO);
                mlmessage(sprintf('>>> Analog output in progress on Stim%i <<<', ob.OutputPort)); 
                drawnow;
                trigger(StimAO);
                daqreset;
                clear StimAO
                mlmessage('Done.');
                mlmessage('');

            elseif strcmpi(t, 'ttl'), %TTL pulse

                mlmessage('Initializing DAQ digital output...');
                io = get(findobj(gcf, 'tag', 'ioframe'), 'userdata');
                [DAQ DAQerror] = initio(io);
                if ~isempty(DAQerror),
                    mlmessage(DAQerror{1});
                    return
                end
                eval(sprintf('TTLdio = DAQ.TTL%i;', ob.OutputPort));
                if isempty(TTLdio),
                    mlmessage(sprintf('*** No output port assigned for TTL%i ***', ob.OutputPort));
                    return
                end
                for i = 1:5,
                    putvalue(TTLdio, 1);
                    mlmessage(sprintf('>>> TTL%i: HIGH <<<', ob.OutputPort));
                    drawnow;
                    pause(1);
                    putvalue(TTLdio, 0);
                    mlmessage(sprintf('>>> TTL%i: LOW <<<', ob.OutputPort));
                    drawnow;
                    if i < 5,
                        pause(0.5);
                    end
                end
                daqreset;
                clear TTLdio
                mlmessage('Done.');
                mlmessage('');

            end

        case 'preprocessimages',
            
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            if ~get(gco, 'value'),
                set(gco, 'backgroundcolor', [0.9255 0.9137 0.8471]);
                return
            end
            T = get(findobj(gcf, 'tag', 'stimnames'), 'userdata');
            bgred = get(findobj('tag', 'bgred'), 'userdata');
            bggreen = get(findobj('tag', 'bggreen'), 'userdata');
            bgblue = get(findobj('tag', 'bgblue'), 'userdata');
            backgroundcolor = [bgred bggreen bgblue];
            modval = 64;
            count = 0;
            warning('off','all');
            for i = 1:length(T),
                typ = T(i).Type;
                if strcmpi(typ, 'mov') || strcmpi(typ, 'pic'),
                    sourcefile = T(i).Name;
                    [pname fname ext] = fileparts(sourcefile);
                    mlmessage(sprintf('Processing %s...', [fname ext]));
                    processedfile = [pname filesep fname '_preprocessed.mat'];
                    if exist(processedfile, 'file'),
                        delete(processedfile);
                    end
                    if strcmpi(typ, 'mov'),
                        
                        j=1;
                        processedfile = [pname filesep fname sprintf('_preprocessed%i.mat',j)];
                        while exist(processedfile, 'file'),
                            delete(processedfile);
                            j = j + 1;
                            processedfile = [pname filesep fname sprintf('_preprocessed%i.mat',j)];
                        end
                        
                        if verLessThan('matlab', '8')
                            reader = mmreader(sourcefile); %#ok<DMMR>
                        else
                            reader = VideoReader(sourcefile);  %#ok<TNMLP>
                        end
                        numframes = get(reader, 'numberOfFrames');
                        bpp       = get(reader, 'bitsPerPixel');
                        height    = get(reader, 'height');
                        width     = get(reader, 'width');
                        bpf       = height * width * bpp;
                        MAX_BITS_PER_FILE = 40 *1000*1000;
                        maxframes = floor(MAX_BITS_PER_FILE / bpf);
                                                
                        if maxframes >= numframes,
                            
                            processedfile = [pname filesep fname '_preprocessed.mat'];
                        
                            mov = read(reader);
                            [pimdata xis yis xisbuf yisbuf] = pad_image(mov(:,:,:,1), modval, backgroundcolor);
                            M = zeros([xisbuf*yisbuf numframes],'uint32');
                            for framenumber = 1:numframes,
                                imdata = pad_image(mov(:,:,:,framenumber), modval, backgroundcolor);
                                M(:,framenumber) = rgbval(imdata(:, :, 1)', imdata(:, :, 2)', imdata(:, :, 3)');
                            end
                            bgc = rgbval(uint8(255*backgroundcolor(1)),uint8(255*backgroundcolor(2)),uint8(255*backgroundcolor(3)));
                            M(M==0) = bgc; %#ok<NASGU>

                            save(processedfile, 'M', 'xis', 'yis', 'xisbuf', 'yisbuf');
                            
                        else
                            
                            partition = [1:maxframes:numframes numframes+1];
                            for j = 1:(length(partition)-1),
                                processedfile = [pname filesep fname sprintf('_preprocessed%i.mat',j)];
                                
                                part = [partition(j) partition(j+1)-1];
                                thisnumframes = part(2)-part(1)+1;
                                
                                mov = read(reader,part);
                                [pimdata xis yis xisbuf yisbuf] = pad_image(mov(:,:,:,1), modval, backgroundcolor);
                                M = zeros([xisbuf*yisbuf thisnumframes],'uint32');
                                for framenumber = 1:thisnumframes,
                                    imdata = pad_image(mov(:,:,:,framenumber), modval, backgroundcolor);
                                    M(:,framenumber) = rgbval(imdata(:, :, 1)', imdata(:, :, 2)', imdata(:, :, 3)');
                                end
                                bgc = rgbval(uint8(255*backgroundcolor(1)),uint8(255*backgroundcolor(2)),uint8(255*backgroundcolor(3)));
                                M(M==0) = bgc; %#ok<NASGU>

                                save(processedfile, 'M', 'xis', 'yis', 'xisbuf', 'yisbuf');
                                
                            end
                            
                        end
                        
                        count = count + 1;
                    end
                end
            end
            warning('on','all');
            set(gco, 'backgroundcolor', [.6 .8 .6]);
            clear M imdata pimdata
            mlmessage(sprintf('Preprocessed %i files in %2.1f seconds', count, toc));
            
        case 'daq',
            
            AdaptorInfo = get(gcbo, 'userdata');
            boardnum = get(gcbo, 'value');
            set(findobj(gcf, 'tag', 'subsystems'), 'string', AdaptorInfo(boardnum).SubSystemsNames, 'value', 1);
            chanports = AdaptorInfo(boardnum).AvailableChannels{1};
            if isempty(chanports),
                chanports = AdaptorInfo(boardnum).AvailablePorts{1};
            end
            set(findobj(gcf, 'tag', 'availablechannels'), 'string', chanports, 'value', 1, 'Min', 1, 'Max', length(chanports));
            
        case 'subsystems',
            
            AdaptorInfo = get(findobj(gcf, 'tag', 'daq'), 'userdata');
            boardnum = get(findobj(gcf, 'tag', 'daq'), 'value');
            subsysnum = get(gcbo, 'value');
            chanports = AdaptorInfo(boardnum).AvailableChannels{subsysnum};
            if isempty(chanports),
                chanports = AdaptorInfo(boardnum).AvailablePorts{subsysnum};
            end
            set(findobj(gcf, 'tag', 'availablechannels'), 'string', chanports, 'value', 1);
            
        case 'infodaq',
            
            AdaptorInfo = get(findobj(gcf, 'tag', 'daq'), 'userdata');
            boardnum = get(findobj(gcf, 'tag', 'daq'), 'value');
            %subsysnum = get(findobj(gcf, 'tag', 'subsystems'), 'value');
            
            try
                fullname = AdaptorInfo(boardnum).Name;
                f = find(fullname == ':');
                aname = fullname(1:f-1);
                daqhwinfo(aname);
            catch
                mlmessage('*** Unable to obtain info on selected board ***');
                return
            end
            
            bname = fullname(f+2:length(fullname));
            subsysnames = AdaptorInfo(boardnum).SubSystemsNames;
            numsubsystems = length(subsysnames);
            
            xwinsize = 500;
            ystep = 25;
            ywinsize = (2*ystep*numsubsystems) + ystep + 10;
            ypos = ywinsize - 30;
            xpos = 5;
            xw = xwinsize - (2*xpos);
            
            figure;
            set(gcf, 'numbertitle', 'off', 'menubar', 'none', 'name', 'DAQ Info', 'position', [500 500 xwinsize ywinsize], 'color', [1 1 1]);
            h = uicontrol('style', 'text', 'position', [xpos ypos xw ystep], 'string', bname, 'backgroundcolor', [0.3 0.3 0.5], 'foregroundcolor', [1 1 1], 'fontsize', 14);
            hcount = 0;
            for snum = 1:numsubsystems,
                hcount = hcount + 1;
                ypos = ypos - ystep;
                h(hcount) = uicontrol('style', 'text', 'position', [xpos ypos xw ystep], 'string', subsysnames{snum}, 'backgroundcolor', [.6 .6 .8]);
                hcount = hcount + 1;
                ypos = ypos - ystep;
                minsrate = AdaptorInfo(boardnum).MinSampleRate(snum);
                maxsrate = AdaptorInfo(boardnum).MaxSampleRate(snum);
                if isnan(minsrate),
                    minsrate = 'N/A';
                else
                    minsrate = [num2str(minsrate) 'Hz'];
                end
                if isnan(maxsrate),
                    maxsrate = 'N/A';
                else
                    maxsrate = [num2str(maxsrate) 'Hz'];
                end
                h(hcount) = uicontrol('style', 'text', 'position', [xpos ypos xw ystep], 'string', sprintf('Min Sample Rate: %s    Max Sample Rate: %s', minsrate, maxsrate), 'backgroundcolor', [.8 .8 1]);
            end
            set(h, 'fontsize', 12, 'horizontalalignment', 'center');
            
        case 'setio',
            
            hioselect = findobj(gcf, 'tag', 'ioselect');
            ionum = get(hioselect, 'value');
            if ionum > (get(hioselect, 'listboxtop') + 9),
                set(hioselect, 'listboxtop', ionum);
            end
            iolist = get(hioselect, 'userdata');
            iovar = iolist{ionum};

            InputOutput = get(findobj(gcf, 'tag', 'ioframe'), 'userdata');
            AdaptorInfo = get(findobj(gcf, 'tag', 'daq'), 'userdata');
            boardnum = get(findobj(gcf, 'tag', 'daq'), 'value');
            subsysnum = get(findobj(gcf, 'tag', 'subsystems'), 'value');
            channelindx = get(findobj(gcf, 'tag', 'availablechannels'), 'value');
            InputOutput.(iovar).Adaptor = AdaptorInfo(boardnum).Name;
            InputOutput.(iovar).Subsystem = AdaptorInfo(boardnum).SubSystemsNames{subsysnum};
            chanports = AdaptorInfo(boardnum).AvailableChannels{subsysnum};
            if isempty(chanports),
                chanports = AdaptorInfo(boardnum).AvailablePorts{subsysnum};
                if isempty(chanports),
                    mlmessage('*** No channels or ports selected ***');
                    return
                end
            end
            InputOutput.(iovar).Channel = chanports(channelindx);
            InputOutput.(iovar).Constructor = AdaptorInfo(boardnum).SubSystemsConstructors{subsysnum};
            
            if ~isempty(strfind(InputOutput.(iovar).Constructor, 'analoginput')),
                ai = eval(InputOutput.(iovar).Constructor);
                itype = set(ai, 'InputType');
                delete(ai);
                
                val = 1;
                for i = 1:length(itype),
                    if strcmpi(itype{i}, 'differential'),
                        val = i;
                        break
                    end
                end
                str = itype{val};
                InputOutput.Configuration.AnalogInputType = str;
                set(findobj(gcf, 'tag', 'ioframe'), 'userdata', InputOutput);
                
                set(findobj(gcf, 'tag', 'inputtype'), 'string', itype, 'enable', 'on', 'value', val);
                set(findobj(gcf, 'tag', 'aitest'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'menubar_aitest'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'analoginputfrequency'), 'enable', 'on');
            end
               
            if (strcmp(iovar, 'DigCodesStrobeBit') && ~strcmp(InputOutput.CodesDigOut.Description, 'Not Assigned')) || (strcmp(iovar, 'CodesDigOut') && ~strcmp(InputOutput.DigCodesStrobeBit.Description, 'Not Assigned')),
                set(findobj(gcf, 'tag', 'strobebitedge'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'digcodestest'), 'enable', 'on');
                set(findobj(gcf, 'tag', 'menubar_digcodestest'), 'enable', 'on');
            end
            
            if strcmp(iovar, 'Reward'),
                set(findobj(gcf, 'tag', 'menubar_rewardpolarity'), 'enable', 'on');
            end
            
            % See if need to select lines as well as ports:
            if (strncmpi('Button', iovar, 6) && strcmpi(AdaptorInfo(boardnum).SubSystemsNames(subsysnum), 'digitalio')) || ~isempty(strmatch('TTL', iovar)) || strcmp('DigCodesStrobeBit', iovar)  || strcmp('CodesDigOut', iovar),
                if ~strcmpi(AdaptorInfo(boardnum).SubSystemsNames(subsysnum), 'digitalio'),
                    mlmessage('*** TTLs and Digital Codes must be assigned to a digital output ***');
                    return
                end
                
                avports = AdatorInfo(boardnum).AvailablePorts{subsysnum};
                avlines = AdaptorInfo(boardnum).AvailableLines{subsysnum}{channelindx};
                
                nlines = length(avlines);
                if strcmp('CodesDigOut', iovar),
                    % first select ports (allows user to select multiple
                    % ports)
                    choose_dio_port(avports, 1);
                    portindx = get(findobj('tag', 'availablechannels'), 'userdata');
                    if isempty(portindx)
                        return
                    end
                    InputOutput.(iovar).Channel = avports(portindx);
                    linestoadd = [];
                    for portindx = portindx(1) : portindx(end)
                        thisport = avports(portindx);
                        indx = get(findobj('tag', 'availablechannels'), 'userdata');
                        if isempty(indx)
                            return
                        end
                        % e.g. nports = 3, nlines = 8: Port0->Lines 0-7,
                        % Port1->Lines 8-15, Port2->Lines 16-23
                        linestoadd = [linestoadd avlines(indx) + nlines * thisport]; %#ok<AGROW>
                    end
                    InputOutput.(iovar).Line = linestoadd;
                else
                    choose_dio_line(avlines);
                indx = get(findobj('tag', 'availablechannels'), 'userdata');
                if isempty(indx),
                    return
                end
                InputOutput.(iovar).Line = avlines(indx);
                end
                
            elseif strcmp('Reward', iovar) && strcmpi(AdaptorInfo(boardnum).SubSystemsNames(subsysnum), 'digitalio'),
                avlines = AdaptorInfo(boardnum).AvailableLines{subsysnum}{channelindx};
                choose_dio_line(avlines);
                indx = get(findobj('tag', 'availablechannels'), 'userdata');
                if isempty(indx), 
                    return
                end
                InputOutput.(iovar).Line = avlines(indx);
            end

            InputOutput = update_iostruct(InputOutput);
            set(findobj(gcf, 'tag', 'ioframe'), 'userdata', InputOutput);
            
            set(findobj(gcf, 'tag', 'checkio'), 'backgroundcolor', [0.9255 0.9137 0.8471], 'string', 'Check');
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            mlmessage('I/O assigned.  Press "Check" to test validity...');
            
        case 'ioclear',
            
            InputOutput = get(findobj(gcf, 'tag', 'ioframe'), 'userdata');
            ionum = get(findobj(gcf, 'tag', 'ioselect'), 'value');
            iolist = get(findobj(gcf, 'tag', 'ioselect'), 'userdata');
            iovar = iolist{ionum};
            if strcmp(iovar, 'DigCodesStrobeBit') || strcmp(iovar, 'CodesDigOut'),
                set(findobj(gcf, 'tag', 'strobebitedge'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'digcodestest'), 'enable', 'off');
                set(findobj(gcf, 'tag', 'menubar_digcodestest'), 'enable', 'off');
            end
            if strcmp(iovar, 'Reward'),
                set(findobj(gcf, 'tag', 'menubar_rewardpolarity'), 'enable', 'off');
            end
            
            InputOutput.(iovar) = struct;
            InputOutput = update_iostruct(InputOutput);
            set(findobj(gcf, 'tag', 'ioframe'), 'userdata', InputOutput);
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'checkio'), 'backgroundcolor', [0.9255 0.9137 0.8471], 'string', 'Check');
            mlmessage('Cleared selected I/O assignment.')
            
            foundai = 0;
            fn = fieldnames(InputOutput);
            for i = 1:length(fn),
                if isfield(InputOutput.(fn{i}), 'Constructor') && ~isempty(strfind(InputOutput.(fn{i}).Constructor, 'analoginput')),
                    foundai = 1;
                    break
                end
            end
            if foundai,
                str = 'on';
            else
                str = 'off';
            end
            set(findobj(gcf, 'tag', 'inputtype'), 'enable', str);
            set(findobj(gcf, 'tag', 'aitest'), 'enable', str);
            set(findobj(gcf, 'tag', 'menubar_aitest'), 'enable', str);
            set(findobj(gcf, 'tag', 'analoginputfrequency'), 'enable', str);
            
        case 'ioselect',
            
            ionum = get(findobj(gcf, 'tag', 'ioselect'), 'value');
            iolist = get(findobj(gcf, 'tag', 'ioselect'), 'userdata');
            iovar = iolist{ionum};
            InputOutput = get(findobj(gcf, 'tag', 'ioframe'), 'userdata');
            set(findobj(gcf, 'tag', 'iolabel'), 'string', InputOutput.(iovar).Label);
            set(findobj(gcf, 'tag', 'iotext'), 'string', InputOutput.(iovar).Description);
            
        case 'aiduplication',
            
            if get(gcbo, 'value'),
                dup = 1;
                set(gcbo, 'backgroundcolor', [.7 .8 .7], 'string', 'A-I Duplication ON');
                mlmessage('Will distribute analog input functions across duplicate boards for faster sampling');
            else
                dup = 0;
                set(gcbo, 'backgroundcolor', [.8 .7 .7], 'string', 'A-I Duplication OFF');
            end
            InputOutput = get(findobj(gcf, 'tag', 'ioframe'), 'userdata');
            InputOutput.Configuration.AnalogInputDuplication = dup;
            set(findobj(gcf, 'tag', 'ioframe'), 'userdata', InputOutput);
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            
        case 'inputtype', 
            
            str = get(gcbo, 'string');
            val = get(gcbo, 'value');
            itype = str{val};
            InputOutput = get(findobj(gcf, 'tag', 'ioframe'), 'userdata');
            InputOutput.Configuration.AnalogInputType = itype;
            set(findobj(gcf, 'tag', 'ioframe'), 'userdata', InputOutput);
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            
        case 'analoginputfrequency',
            
            val = str2double(get(gcbo, 'string'));
            if isnan(val) || val < 1,
                val = get(gcbo, 'userdata');
                set(gcbo, 'string', num2str(val));
                return
            end
            set(gcbo, 'userdata', val);
            InputOutput = get(findobj(gcf, 'tag', 'ioframe'), 'userdata');
            InputOutput.Configuration.AnalogInputFrequency = val;
            set(findobj(gcf, 'tag', 'ioframe'), 'userdata', InputOutput);
            set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'on');
            set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'on');
            
        case 'aitest',
            
            set(gcbo, 'string', 'Initializing...');
            drawnow;
            InputOutput = get(findobj(gcf, 'tag', 'ioframe'), 'userdata');
            [DAQ DAQerror] = initio(InputOutput);
            if ~isempty(DAQerror),
                mlmessage(DAQerror);
                set(gcbo, 'string', 'Test Analog Inputs');
                return
            end
            if isempty(DAQ.AnalogInput),
                mlmessage('No Analog Inputs Assigned')
                set(gcbo, 'string', 'Test Analog Inputs');
                return
            end
            if isempty(DAQ.AnalogInput2),
                DAQ.AI = DAQ.AnalogInput;
            else
                DAQ.AI = DAQ.AnalogInput2;
            end
            
            set(DAQ.AI,'BufferingConfig', [1 2]);
            set(DAQ.AI,'samplespertrigger', 2);
            
            start(DAQ.AnalogInput);
            while ~DAQ.AnalogInput.SamplesAvailable, end
            data = getsample(DAQ.AI);
            data = zeros(round(DAQ.AnalogInput.SampleRate*10), length(data));
            set(gcbo, 'string', 'Sampling...');
            drawnow;
            count = 0;
            tic
            while toc < 1,
                count = count + 1;
                data(count, :) = getsample(DAQ.AI);
            end
            data = data(1:count, :);
            stop(DAQ.AnalogInput);
            daqreset;
            effectivesamples = length(find(diff(data(:, 1))));
            mlmessage(sprintf('Average effective sampling rate: %i Hz   Maximum possible sampling rate: %i Hz', effectivesamples, count));
            set(gcbo, 'string', 'Test Analog Inputs');
            
        case 'digcodestest',
            
            h = findobj(gcf, 'tag', 'digcodestest'); %this function might also have been called by menubar_digcodestest, so can't use gcbo
            InputOutput = get(findobj(gcf, 'tag', 'ioframe'), 'userdata');
            bcol = get(h, 'backgroundcolor');
            bstr = get(h, 'string');
            [DAQ DAQerror] = initio(InputOutput);
            if isempty(DAQerror),
                sbval = get(findobj(gcf, 'tag', 'strobebitedge'), 'value') - 1;
                DaqDIO = DAQ.BehavioralCodes.DIO;
                databits = DAQ.BehavioralCodes.DataBits.Index;
                databits = cat(2, databits{:});
                numlines = length(databits);
                strobebit = DAQ.BehavioralCodes.StrobeBit.Index;
                z = zeros(1, numlines+1);
                putvalue(DaqDIO, z);

                set(h, 'string', 'Sending codes...', 'backgroundcolor', [.5 .7 .5]);
                mlmessage(sprintf('>>> Sending 10 cycles of 2.^(0:%i) <<<', numlines-1));
                drawnow;
                for i = 1:10,
                    for k = 0:numlines-1,
                        % Output codenumber on digital port (assume 8-bit)
                        codenumber = 2^k;
                        bvec([databits strobebit]) = [dec2binvec(codenumber, numlines) ~sbval];
                        putvalue(DaqDIO, bvec);
                        bvec(strobebit) = sbval; %#ok<AGROW>
                        putvalue(DaqDIO, bvec);
                        pause(0.01);
                    end
                    pause(0.1);
                end
                set(h, 'string', bstr, 'backgroundcolor', bcol);
                mlmessage('Done.');
                mlmessage('');
            else
                set(h, 'string', 'Failed', 'backgroundcolor', [.7 .5 .5]);
                pause(1);
                set(h, 'string', bstr, 'backgroundcolor', bcol);
                mlmessage(DAQerror);
            end
            daqreset;
            
        case 'testdaq',
            
            AdaptorInfo = get(findobj(gcf, 'tag', 'daq'), 'userdata');
            boardnum = get(findobj(gcf, 'tag', 'daq'), 'value');
            subsysnum = get(findobj(gcf, 'tag', 'subsystems'), 'value');
            chanindx = get(findobj(gcf, 'tag', 'availablechannels'), 'value');
            daqdata = get(findobj(gcf, 'tag', 'daq'), 'userdata');
            daqdata = daqdata(boardnum);
            DaqData.BoardName = daqdata.Name;
            DaqData.Constructor = daqdata.SubSystemsConstructors{subsysnum};
            DaqData.SubSystemName = daqdata.SubSystemsNames{subsysnum};
            channels = daqdata.AvailableChannels{subsysnum};
            ports = daqdata.AvailablePorts{subsysnum};
            if isempty(channels) && isempty(ports),
                mlmessage('*** No channels selected ***');
                return
            elseif ~isempty(channels),
                DaqData.Channel = channels(chanindx);
            else
                DaqData.Port = ports(chanindx);
                DaqData.Line = AdaptorInfo(boardnum).AvailableLines{subsysnum}{chanindx};
            end
            DaqData.SampleRate = daqdata.SampleRate(subsysnum);
            types = get(findobj(gcf, 'tag', 'inputtype'), 'string');
            typenum = get(findobj(gcf, 'tag', 'inputtype'), 'value');
            type = types{typenum};
            DaqData.InputType = type;
            mlmessage('Opening I/O test window...');
            mlmessage('');
            iotest(DaqData);
            
        case 'checkio',
            
            mlmessage('Testing I/O Configuration...');
            InputOutput = get(findobj(gcf, 'tag', 'ioframe'), 'userdata');
            fn = fieldnames(InputOutput);
            ioset = zeros(length(fn), 1);
            for i = 1:length(fn),
                if ~strcmp(fn{i}, 'Configuration') %&& ~strcmp(fn{i}, 'AnalogInputDuplication'),
                    ioset(i) = ~isempty(fieldnames(InputOutput.(fn{i})));
                else
                    ioset(i) = 0;
                end
            end
            if ~any(ioset),
                mlmessage('*** No I/O assignements selected ***')
                return
            end
            [DaqInfo DaqError] = initio(InputOutput);
            daqreset;
            if ~isempty(DaqError),
                set(findobj(gcf, 'tag', 'checkio'), 'foregroundcolor', [0 0 0], 'backgroundcolor', [.8 .6 .6], 'string', 'Failed');
                for i = 1:length(DaqError),
                    mlmessage(DaqError{i});
                    pause(1);
                end
            else
                set(findobj(gcf, 'tag', 'checkio'), 'foregroundcolor', [0 0 0], 'backgroundcolor', [.6 .8 .6], 'string', 'Passed');
                mlmessage('No errors encountered during I/O initialization.')
            end
            
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function imdata = get_fixspot(bgcolor)

fixspot = get(findobj(gcf, 'tag', 'fixationfilename'), 'userdata');
if ~strcmpi(fixspot, 'DEFAULT') && ~exist(fixspot, 'file'),
    mlmessage('WARNING: *** Unable to find selected fixation spot image file - will use default ***');
    fixspot = 'DEFAULT';
end
if strcmpi(fixspot, 'DEFAULT'),
    imdata = makecircle(4.5, [1 1 1], 1, bgcolor);
else
    imdata = imread(fixspot);
    imdata(:, :, 1) = imdata(:, :, 1)*(1-bgcolor(1)) + bgcolor(1);
    imdata(:, :, 2) = imdata(:, :, 2)*(1-bgcolor(2)) + bgcolor(2);
    imdata(:, :, 3) = imdata(:, :, 3)*(1-bgcolor(3)) + bgcolor(3);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function choose_dio_line(avlines, varargin)

xymouse = get(0, 'PointerLocation');
xpos = xymouse(1) - 230;
ypos = xymouse(2) - 100;
f = figure;
set(f, 'position', [xpos ypos 175 150], 'menubar', 'none', 'numbertitle', 'off', 'name', 'Select Line', 'color', [.76 .76 .8], 'tag', 'lineselectfig');
uicontrol('style', 'frame', 'position', [5 5 165 140]);
h = uicontrol('style', 'listbox', 'position', [15 15 70 120], 'string', avlines, 'userdata', avlines, 'tag', 'avlines', 'backgroundcolor', [1 1 1]);
uicontrol('style', 'pushbutton', 'position', [92 80 70 30], 'string', 'Ok', 'callback', 'set(findobj(''tag'', ''availablechannels''), ''userdata'', get(findobj(''tag'', ''avlines''), ''value'')); delete(gcf)');
uicontrol('style', 'pushbutton', 'position', [92 35 70 30], 'string', 'Cancel', 'callback', 'set(findobj(''tag'', ''availablechannels''), ''userdata'', []); delete(gcf)');
set(gcf, 'closerequestfcn', 'set(findobj(''tag'', ''availablechannels''), ''userdata'', []); delete(gcf)');
if ~isempty(varargin) && varargin{1},
    set(h, 'max', 2); %enable multi-select
    if varargin{2}
        portnum = varargin{2};
        set(f, 'name', ['Select Lines for Port ', num2str(portnum)]);
    else
    set(f, 'name', 'Select Lines');
end
end
waitfor(gcf);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function choose_dio_port(avports, varargin)

xymouse = get(0, 'PointerLocation');
xpos = xymouse(1) - 230;
ypos = xymouse(2) - 100;
f = figure;

set(f, 'position', [xpos ypos 175 150], 'menubar', 'none', 'numbertitle', 'off', 'name', 'Select Ports', 'color', [.76 .76 .8], 'tag', 'portselectfig');
uicontrol('style', 'frame', 'position', [5 5 165 140]);
h = uicontrol('style', 'listbox', 'position', [15 15 70 120], 'string', avports, 'userdata', avports, 'tag', 'avports', 'backgroundcolor', [1 1 1]);
uicontrol('style', 'pushbutton', 'position', [92 80 70 30], 'string', 'Ok', 'callback', 'set(findobj(''tag'', ''availablechannels''), ''userdata'', get(findobj(''tag'', ''avports''), ''value'')); delete(gcf)');
uicontrol('style', 'pushbutton', 'position', [92 35 70 30], 'string', 'Cancel', 'callback', 'set(findobj(''tag'', ''availablechannels''), ''userdata'', []); delete(gcf)');
set(gcf, 'closerequestfcn', 'set(findobj(''tag'', ''availablechannels''), ''userdata'', []); delete(gcf)');
if ~isempty(varargin) && varargin{1}
    set(h, 'max', 2);   % enable multi-select
    set(f, 'name', 'Select Ports');
end
waitfor(gcf);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function update_alertmenu

aufunh = findobj(gcf, 'tag', 'au_function');
audefh = findobj(gcf, 'tag', 'au_userdefinedcheck');
aucrth = findobj(gcf, 'tag', 'au_userdefinedcritfunction');
if get(findobj(gcf, 'tag', 'alertsandupdates'), 'value'),
    set(findobj(gcf, 'tag', 'alertsandupdates'), 'string', 'Remote Alerts ON', 'backgroundcolor', [.7 .8 .7]);
    set(findobj(gcf, 'tag', 'menubar_alertstest'), 'enable', 'on');
    set(findobj(gcf, 'tag', 'au_errorcheck'), 'enable', 'on');
    set(findobj(gcf, 'tag', 'au_blockcheck'), 'enable', 'on');
    set(audefh, 'enable', 'on');
    set(aufunh, 'enable', 'on', 'string', 'Press to select alert function');
    aufunction = get(aufunh, 'userdata');
    if ~isempty(aufunction),
        [pname fname] = fileparts(get(aufunh, 'userdata'));
        set(aufunh, 'string', ['Alert Function: ' fname]);
    end
    if get(audefh, 'value'),
        set(aucrth, 'enable', 'on');
        if isempty(get(aucrth, 'userdata')),
            set(aucrth, 'string', 'Press to select function');
        end
    end
else
    set(findobj(gcf, 'tag', 'alertsandupdates'), 'string', 'Remote Alerts OFF', 'backgroundcolor', [.8 .7 .7]);
    set(findobj(gcf, 'tag', 'menubar_alertstest'), 'enable', 'off');
    set(findobj(gcf, 'tag', 'au_errorcheck'), 'enable', 'off');
    set(findobj(gcf, 'tag', 'au_blockcheck'), 'enable', 'off');
    set(aucrth, 'enable', 'off');
    if isempty(get(aucrth, 'userdata')),
        set(aucrth, 'string', 'n/a');
    end
    set(audefh, 'enable', 'off');
    set(aufunh, 'enable', 'off', 'string', 'n/a');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function update_stimwindow

bgcolor = [get(findobj(gcf, 'tag', 'bgred'), 'userdata') get(findobj(gcf, 'tag', 'bggreen'), 'userdata') get(findobj(gcf, 'tag', 'bgblue'), 'userdata')];
set(findobj(gcf, 'tag', 'minicontrolscreen'), 'color', bgcolor);

stimH = findobj(gcf, 'tag', 'stimnames');
val = get(stimH, 'value');
TaskObject = get(stimH, 'userdata');
if isempty(TaskObject),
    return
end
firstrow = get(stimH, 'listboxtop');
TOB = TaskObject(val);
ppd = eval(get(findobj(gcf, 'tag', 'ppd'), 'string'));
stimax = findobj(gcf, 'tag', 'stimax');
if isempty(stimax), %sometimes doesn't seem to find the stim axis if user clicks through too quickly...
    pause(0.3);
    stimax = findobj(gcf, 'tag', 'stimax');
    if isempty(stimax),
        return
    end
end
set(gcf, 'CurrentAxes', stimax);
if strcmpi(TOB.Type, 'fix') || strcmpi(TOB.Type, 'pic') || strcmpi(TOB.Type, 'crc') || strcmpi(TOB.Type, 'sqr') || strcmpi(TOB.Type, 'mov') || strcmpi(TOB.Type, 'gen'),
    if strcmpi(TOB.Type, 'fix') || strcmpi(TOB.Type, 'dot'),
        fixspot = get(findobj(gcf, 'tag', 'fixationfilename'), 'userdata');
        if ~strcmpi(fixspot, 'DEFAULT') && ~exist(fixspot, 'file'),
            mlmessage('WARNING: *** Unable to find selected fixation spot image file - will use default ***');
            fixspot = 'DEFAULT';
        end
        if strcmpi(fixspot, 'DEFAULT'),
            imdata = makecircle(4.5, [1 1 1], 1, bgcolor);
            fixdescription = 'Fix: Default';
        else
            imdata = imread(fixspot);
            imdata(:, :, 1) = imdata(:, :, 1)*(1-bgcolor(1)) + bgcolor(1);
            imdata(:, :, 2) = imdata(:, :, 2)*(1-bgcolor(2)) + bgcolor(2);
            imdata(:, :, 3) = imdata(:, :, 3)*(1-bgcolor(3)) + bgcolor(3);
            dot = find(fixspot == '.');
            if ~isempty(dot),
                cursorfilename = fixspot(1:dot-1);
            else
                cursorfilename = fixspot;
            end
            fs = find(cursorfilename == filesep);
            if ~isempty(fs),
                cursorfilename = cursorfilename(max(fs)+1:length(cursorfilename));
            end
            fixdescription = sprintf('Fix: %s  [%i x %i]', cursorfilename, size(imdata, 2), size(imdata, 1));
        end
        stimwindow = findobj(gcf, 'tag', 'stimnames');
        UTaskObject = get(stimwindow, 'userdata');
        for i = 1:length(UTaskObject),
            if strcmp(UTaskObject(i).Type, 'fix'),
                UTaskObject(i).Description = fixdescription;
            end
        end
        set(stimwindow, 'string', {UTaskObject.Description});
    elseif strcmpi(TOB.Type, 'pic'),
        imdata = imread(TOB.Name);
        imdata = double(imdata)/255;
    elseif strcmpi(TOB.Type, 'gen'),
        imdata = imread('genimgsample.jpg');
        imdata = double(imdata)/255;
    elseif strcmpi(TOB.Type, 'mov'),
        if verLessThan('matlab', '8')
            reader = mmreader(TOB.Name); %#ok<DMMR>
        else
            reader = VideoReader(TOB.Name); 
        end
        numframes = get(reader, 'numberOfFrames');
        imdata = squeeze(read(reader, 1));
    elseif strcmpi(TOB.Type, 'crc'),
        crcrad = TOB.Radius * ppd;
        imdata = makecircle(crcrad, TOB.Color, TOB.FillFlag, bgcolor);
    elseif strcmpi(TOB.Type, 'sqr'),
        sqrx = TOB.Xsize * ppd;
        sqry = TOB.Ysize * ppd;
        imdata = makesquare([sqrx sqry], TOB.Color, TOB.FillFlag, bgcolor);
    end
    image(imdata, 'parent', stimax);
    axis square;
    xrange = diff(get(gca, 'xlim'));
    yrange = diff(get(gca, 'ylim'));
    fullrange = max([xrange yrange]);
    minzoom = fullrange;
    maxzoom = 10*fullrange;
    zoomstartval = fullrange;
    if strcmpi(TOB.Type, 'mov'),
        minpos = 1;
        maxpos = numframes;
        M = read(reader);
        set(stimax, 'userdata', M);
    else
        maxpos = 0.51;
        minpos = 0.49;
    end
    screenresvals = get(findobj(gcf, 'tag', 'screenres'), 'userdata');
    screenres = screenresvals(get(findobj(gcf, 'tag', 'screenres'), 'value'), :);
    if xrange > screenres(1) || yrange > screenres(2),
        mlmessage('*** Warning: This visual stimulus is too large to be displayed at the currently selected screen resolution ***');
    else
        num_objects_in_group = length(TOB.Xpos);
        for i = 1:num_objects_in_group,
            ppd = str2double(get(findobj(gcf, 'tag', 'ppd'), 'string'));
            centerx = 0.5*screenres(1);
            centery = 0.5*screenres(2);
            picxmax = centerx + (TOB.Xpos(i)*ppd) + (0.5*xrange);
            picxmin = centerx + (TOB.Xpos(i)*ppd) - (0.5*xrange);
            picymax = centery + (TOB.Ypos(i)*ppd) + (0.5*yrange);
            picymin = centery + (TOB.Ypos(i)*ppd) - (0.5*yrange);
            if picxmax > screenres(1) || picxmin < 0 || picymax > screenres(2) || picymin < 0,
                if num_objects_in_group == 1,
                    mlmessage('*** Warning: This object is not positioned wholly within allowed screen boundaries at the currently selected screen resolution ***');
                else
                    mlmessage('*** Warning: One of these objects is not positioned wholly within allowed screen boundaries at the current screen resolution ***');
                end
            end
        end
    end
elseif strcmpi(TOB.Type, 'snd') || strcmpi(TOB.Type, 'stm'),
    bgcolor = [0 0 0];
    wf = TOB.WaveForm;
    lwf = length(wf);
    zoomstartval = round(lwf/10);
    if lwf > zoomstartval,
        lwf = zoomstartval;
    end
    h = plot(wf);
    set(h, 'color', [1 1 1]);
    set(gca, 'xlim', [0 lwf], 'ylim', [min(wf)-(0.07*range(wf)) max(wf)+(0.07*range(wf))]);
    minzoom = 100;
    lwf2 = length(wf);
    if lwf2 < 100,
        lwf2 = lwf + 1;
    end
    maxzoom = lwf2;
    minpos = 0;
    maxpos = length(wf)-minzoom;
elseif strcmpi(TOB.Type, 'ttl'),
    minzoom = 0;
    maxzoom = 1;
    zoomstartval = 0;
    minpos = 0;
    maxpos = 1;
    bgcolor = [0 0 0];
    set(gcf, 'CurrentAxes', findobj(gcf, 'tag', 'stimax'));
    cla;
    set(gca, 'xlim', [0 1], 'ylim', [0 1], 'ydir', 'normal');
    h = line([0 .25 .25 .75 .75 1], [.2 .2 .8 .8 .2 .2]);
    set(h, 'color', [1 1 1], 'linewidth', 2);
elseif strcmpi(TOB.Type, 'gen'),
%     minzoom = 0; %temp
%     maxzoom = 1; %temp
%     minpos = 0; %temp
%     maxpos = 1; %temp
%     zoomstartval = 0; %temp
%     bgcolor = [0 0 0]; %temp
end

set(findobj(gcf, 'tag', 'zoomslider'), 'min', minzoom, 'max', maxzoom, 'value', zoomstartval);
set(findobj(gcf, 'tag', 'positionslider'), 'min', minpos, 'max', maxpos, 'value', minpos);

set(gca, 'tag', 'stimax', 'color', bgcolor, 'xtick', [], 'ytick', []); %this needs to be reset for next time
if val - firstrow >= 7,
    set(gcbo, 'listboxtop', val - 6);
elseif val == firstrow && val > 1,
    set(gcbo, 'listboxtop', firstrow - 1);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mlmessage(str)

h1 = findobj(gcf, 'tag', 'mlmessagebox');
if isempty(str),
    set(h1, 'string', '');
    return
end
h2 = findobj(gcf, 'tag', 'mlmessageframe');
if ~iscell(str),
    str = {str};
end
for i = 1:length(str),
    set(h1, 'string', str(i));
    set([h1 h2], 'backgroundcolor', [1 1 0.5]);
    pause(0.05);
    set([h1 h2], 'backgroundcolor', [1 1 1]);
    drawnow;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function str = blockmessage

val = get(findobj(gcf, 'tag', 'blocklogic'), 'value');
str = {'to be selected randomly' 'to be selected randomly' 'will be the lowest included  block' 'will be the highest included block' 'will be selected by a user-defined function'};
str = sprintf('First block %s', str{val});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ScreenInfo = gather_screen_params

ScreenInfo.PixelsPerDegree = str2double(get(findobj(gcf, 'tag', 'ppd'), 'string'));
resval = get(findobj(gcf, 'tag', 'screenres'), 'value');
validsizes = get(findobj(gcf, 'tag', 'screenres'), 'userdata');
validxsize = validsizes(:, 1);
validysize = validsizes(:, 2);
ScreenInfo.Xsize = validxsize(resval);
ScreenInfo.Ysize = validysize(resval);
ScreenInfo.BufferPages = get(findobj(gcf, 'tag', 'bufferpages'), 'value');
sbgcol(1) = get(findobj(gcf, 'tag', 'bgred'), 'userdata');
sbgcol(2) = get(findobj(gcf, 'tag', 'bggreen'), 'userdata');
sbgcol(3) = get(findobj(gcf, 'tag', 'bgblue'), 'userdata');
ScreenInfo.BackgroundColor = sbgcol;
ScreenInfo.Device = get(findobj(gcf, 'tag', 'videodevice'), 'value');
validrefresh = get(findobj(gcf, 'tag', 'refreshrate'), 'userdata');
ScreenInfo.RefreshRate = validrefresh(get(findobj(gcf, 'tag', 'refreshrate'), 'value'));
ScreenInfo.BytesPerPixel = 4;
ScreenInfo.OutOfBounds = 2*max([ScreenInfo.Xsize ScreenInfo.Ysize]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function clean_borders(fx, fy, fw, fh, fbg)

bw = 2;
uicontrol('style', 'frame', 'position', [fx fy fw bw], 'backgroundcolor', fbg, 'foregroundcolor', fbg);
uicontrol('style', 'frame', 'position', [fx fy bw fh], 'backgroundcolor', fbg, 'foregroundcolor', fbg);
uicontrol('style', 'frame', 'position', [fx fy+fh-1 fw bw], 'backgroundcolor', fbg, 'foregroundcolor', fbg);
uicontrol('style', 'frame', 'position', [fx+fw-2 fy bw fh], 'backgroundcolor', fbg, 'foregroundcolor', fbg);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function update_minicontrolscreen

% Eye Trace & Target
r = get(findobj(gcf, 'tag', 'eyered'), 'userdata');
g = get(findobj(gcf, 'tag', 'eyegreen'), 'userdata');
b = get(findobj(gcf, 'tag', 'eyeblue'), 'userdata');
set(findobj(gcf, 'tag', 'sample_eye_trace'), 'color', [r g b]);
set(findobj(gcf, 'tag', 'sample_eye_target'), 'color', 0.5*[r g b]);

% Eye Size
val = get(findobj(gcf, 'tag', 'eyesize'), 'userdata');
set(findobj(gcf, 'tag', 'sample_eye_trace'), 'markersize', val);

% Joy Trace & Target
r = get(findobj(gcf, 'tag', 'joyred'), 'userdata');
g = get(findobj(gcf, 'tag', 'joygreen'), 'userdata');
b = get(findobj(gcf, 'tag', 'joyblue'), 'userdata');
set(findobj(gcf, 'tag', 'sample_joy_trace'), 'color', [r g b]);
set(findobj(gcf, 'tag', 'sample_joy_target'), 'color', 0.5*[r g b]);

% Joystick Size
val = get(findobj(gcf, 'tag', 'joysize'), 'userdata');
set(findobj(gcf, 'tag', 'sample_joy_trace'), 'markersize', val);

% Cartesian & Polar Grids
val = get(findobj(gcf, 'tag', 'csgrid_cartesian'), 'value');
if val,
    bval = get(findobj(gcf, 'tag', 'cartesianbrightness'), 'value');
    set(findobj(gcf, 'tag', 'cartesiangrid'), 'color', [bval bval bval], 'linestyle', '-');
else
    set(findobj(gcf, 'tag', 'cartesiangrid'), 'color', [0 0 0], 'linestyle', 'none');
end

val = get(findobj(gcf, 'tag', 'csgrid_polar'), 'value');
if val,
    bval = get(findobj(gcf, 'tag', 'polarbrightness'), 'value');
    set(findobj(gcf, 'tag', 'polargrid'), 'color', [bval bval bval], 'linestyle', '-');
else
    set(findobj(gcf, 'tag', 'polargrid'), 'color', [0 0 0], 'linestyle', 'none');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function InputOutput = update_iostruct(InputOutput)

hioselect = findobj(gcf, 'tag', 'ioselect');
hval = get(hioselect, 'value');
iolabels = get(hioselect, 'string');
iovarnames = get(hioselect, 'userdata');

iostr = cell(length(iovarnames), 1);
for i = 1:length(iovarnames),
    if ~isfield(InputOutput, iovarnames{i}),
        InputOutput.(iovarnames{i}) = struct;
    end
    iolabel = iolabels{i};
    if isfield(InputOutput.(iovarnames{i}), 'Adaptor') && ~strcmp(iolabel(1), '{'),
        iolabel = ['{ ' iolabel ' }']; %#ok<AGROW>
    elseif ~isfield(InputOutput.(iovarnames{i}), 'Adaptor') && strcmp(iolabel(1), '{'),
        iolabel = iolabel(3:length(iolabel)-2);
    end

    InputOutput.(iovarnames{i}).Label = iolabel;
    iostr{i} = iolabel;
    if isfield(InputOutput.(iovarnames{i}), 'Adaptor'),
        InputOutput.(iovarnames{i}).Description = create_io_description(InputOutput.(iovarnames{i}), iovarnames{i});
    else
        InputOutput.(iovarnames{i}).Description = 'Not Assigned';
    end
    if i == hval,
        set(findobj(gcf, 'tag', 'iolabel'), 'string', iolabel);
        set(findobj(gcf, 'tag', 'iotext'), 'string', InputOutput.(iovarnames{i}).Description);
    end
end
set(hioselect, 'string', iostr);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function iotxt = create_io_description(io, iovar)

if strcmpi(io.Subsystem, 'DigitalIO') && ~isempty(strmatch('TTL', iovar)),
    iotxt = sprintf('%s %s Port %i Line %i', io.Adaptor, io.Subsystem, io.Channel, io.Line);
elseif strcmpi(io.Subsystem, 'DigitalIO'),
    if length(io.Channel) == 1
    iotxt = sprintf('%s %s Port %i', io.Adaptor, io.Subsystem, io.Channel);
    elseif length(io.Channel) > 1    % added by Panos Sapountzis
        iotxt = sprintf('%s %s Ports %i-%i', io.Adaptor, io.Subsystem, io.Channel(1), io.Channel(end));
    end
else
    iotxt = sprintf('%s  %s  Channel %i', io.Adaptor, io.Subsystem, io.Channel);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function loadcfg(cfgfile, logger)

load(cfgfile);

validscreensizes = get(findobj(gcf, 'tag' ,'screenres'), 'userdata');
validxsize = validscreensizes(:, 1);
validysize = validscreensizes(:, 2);
validrefresh = get(findobj(gcf, 'tag', 'refreshrate'), 'userdata');

set(findobj(gcf, 'tag', 'experimentname'), 'string', MLConfig.ExperimentName);
set(findobj(gcf, 'tag', 'errorlogic'), 'value', MLConfig.ErrorLogic);
set(findobj(gcf, 'tag', 'maxblocks'), 'string', num2str(MLConfig.MaxBlocks));
set(findobj(gcf, 'tag', 'maxtrials'), 'string', num2str(MLConfig.MaxTrials));
set(findobj(gcf, 'tag', 'blocklogic'), 'value', MLConfig.BlockLogic);
set(findobj(gcf, 'tag', 'condlogic'), 'value', MLConfig.CondLogic);
if MLConfig.BlockLogic == 5 && ~isempty(MLConfig.BlockSelectFunction),
    [pname fname] = fileparts(MLConfig.BlockSelectFunction);
    set(findobj(gcf, 'tag', 'blockselectfun'), 'string', ['Block Selection: ' fname], 'userdata', MLConfig.BlockSelectFunction, 'enable', 'on');
else
    %MLConfig.BlockLogic = 1;
    set(findobj(gcf, 'tag', 'blocklogic'), 'value', MLConfig.BlockLogic);
    set(findobj(gcf, 'tag', 'blockselectfun'), 'enable', 'off', 'string', 'n/a');
end
if MLConfig.CondLogic == 5 && ~isempty(MLConfig.CondSelectFunction),
    [pname fname] = fileparts(MLConfig.CondSelectFunction);
    set(findobj(gcf, 'tag', 'condselectfun'), 'string', ['Condition Selection: ' fname], 'userdata', MLConfig.CondSelectFunction, 'enable', 'on');
else
    %MLConfig.CondLogic = 1;
    set(findobj(gcf, 'tag', 'condlogic'), 'value', MLConfig.CondLogic);
    set(findobj(gcf, 'tag', 'condselectfun'), 'enable', 'off', 'string', 'n/a');
end

if isfield(MLConfig, 'CountOnlyCorrect'),
    set(findobj(gcf, 'tag', 'countonlycorrect'), 'value', MLConfig.CountOnlyCorrect);
end

hbfxn1 = findobj(gcf, 'tag', 'blockchangefun');
hbfxn2 = findobj(gcf, 'tag', 'blockselectfun');
set([hbfxn1 hbfxn2], 'backgroundcolor', [1 1 1]);
if isfield(MLConfig, 'BlockChangeFunction'),
    if isempty(MLConfig.BlockChangeFunction),
        set(findobj(gcf, 'tag', 'blockchangefunction'), 'string', 'Block Change Function', 'userdata', '');
        set(findobj(gcf, 'tag', 'trialsperblock'), 'enable', 'on');
        set(findobj(gcf, 'tag', 'applyblocknumstoall'), 'enable', 'on');
    else
        [pname fname] = fileparts(MLConfig.BlockChangeFunction);
        set(findobj(gcf, 'tag', 'blockchangefun'), 'string', ['Block Change: ' fname], 'userdata', MLConfig.BlockChangeFunction);
        set(findobj(gcf, 'tag', 'trialsperblock'), 'enable', 'off');
        set(findobj(gcf, 'tag', 'applyblocknumstoall'), 'enable', 'off');
        if get(findobj(gcf, 'tag', 'blocklogic'), 'value') == 5 && strcmpi(get(hbfxn1, 'userdata'), get(hbfxn2, 'userdata')),
            set([hbfxn1 hbfxn2], 'backgroundcolor', [.7 .8 .7]); %to indicate a match, so block-change fxn also selects actual block #, not just switch flag
        end
    end
else
    set(findobj(gcf, 'tag', 'blockchangefunction'), 'string', 'Block Change Function', 'userdata', '');
    set(findobj(gcf, 'tag', 'trialsperblock'), 'enable', 'on');
    set(findobj(gcf, 'tag', 'applyblocknumstoall'), 'enable', 'on');
end
if isfield(MLConfig, 'InterTrialInterval'),
    set(findobj(gcf, 'tag', 'iti'), 'string', num2str(MLConfig.InterTrialInterval), 'userdata', MLConfig.InterTrialInterval);
end
set(findobj(gcf, 'tag', 'calbutton'), 'userdata', MLConfig.EyeTransform);
set(findobj(gcf, 'tag', 'joycalbutton'), 'userdata', MLConfig.JoyTransform);
set(findobj(gcf, 'tag', 'ppd'), 'string', MLConfig.PixelsPerDegree);
set(findobj(gcf, 'tag', 'screenres'), 'value', find(validxsize == MLConfig.ScreenX & validysize == MLConfig.ScreenY));
set(findobj(gcf, 'tag', 'viewdist'), 'string', num2str(MLConfig.ViewingDistance));
set(findobj(gcf, 'tag', 'diagsize'), 'string', num2str(MLConfig.DiagonalScreenSize));
set(findobj(gcf, 'tag', 'photodiode'), 'value', MLConfig.PhotoDiode);
if MLConfig.PhotoDiode > 1,
    set(findobj(gcf, 'tag', 'photodiodesize'), 'enable', 'on');
end
set(findobj(gcf, 'tag', 'photodiodesize'), 'string', num2str(MLConfig.PhotoDiodeSize));
set(findobj(gcf, 'tag', 'useraw'), 'value', MLConfig.UseRawEyeSignal);
if MLConfig.UseRawEyeSignal,
    set(findobj(gcf, 'tag', 'eyeadjust'), 'enable', 'off');
else
    set(findobj(gcf, 'tag', 'eyeadjust'), 'enable', 'on');
end
set(findobj(gcf, 'tag', 'userawjoy'), 'value', MLConfig.UseRawJoySignal);
if isfield(MLConfig, 'EyeCalibrationTargets') && ~isempty(MLConfig.EyeCalibrationTargets),
   set(findobj(gcf, 'tag', 'eyecaltext'), 'userdata', MLConfig.EyeCalibrationTargets);
   set(findobj(gcf, 'tag', 'joycaltext'), 'userdata', MLConfig.JoystickCalibrationTargets);
end
if isfield(MLConfig, 'RewardCalibrationSettings') && ~isempty(MLConfig.RewardCalibrationSettings),
    set(findobj(gcf, 'tag', 'useraw'), 'userdata', MLConfig.RewardCalibrationSettings.EyeSignal);
    set(findobj(gcf, 'tag', 'userawjoy'), 'userdata', MLConfig.RewardCalibrationSettings.Joystick);
end
if isfield(MLConfig, 'OnlineEyeAdjustment') && ~isempty(MLConfig.OnlineEyeAdjustment),
    set(findobj(gcf, 'tag', 'eyeadjust'), 'value', MLConfig.OnlineEyeAdjustment);
    if isfield(MLConfig, 'UseFirstTargetOnly') && ~isempty(MLConfig.UseFirstTargetOnly),
        set(findobj(gcf, 'tag', 'firsttargetonly'), 'value', MLConfig.UseFirstTargetOnly);
    end
    if MLConfig.OnlineEyeAdjustment,
        set(findobj(gcf, 'tag', 'eyeadjust'), 'string', 'Eye Drift Correction ON', 'backgroundcolor', [.7 .8 .7]);
    else
        set(findobj(gcf, 'tag', 'eyeadjust'), 'string', 'Eye Drift Correction OFF', 'backgroundcolor', [.8 .7 .7]);
    end
    set(findobj(gcf, 'tag', 'fixdegrees'), 'string', num2str(MLConfig.FixDegrees), 'userdata', MLConfig.FixDegrees);
    set(findobj(gcf, 'tag', 'fixtime'), 'string', num2str(MLConfig.FixTime), 'userdata', MLConfig.FixTime);
    if isfield(MLConfig, 'EyeAdjustFraction'),
        set(findobj(gcf, 'tag', 'adjustfraction'), 'string', num2str(MLConfig.EyeAdjustFraction), 'userdata', MLConfig.EyeAdjustFraction);
        set(findobj(gcf, 'tag', 'smoothsigma'), 'string', num2str(MLConfig.EyeSmoothingSigma), 'userdata', MLConfig.EyeSmoothingSigma);
    end
    if MLConfig.OnlineEyeAdjustment && ~MLConfig.UseRawEyeSignal,
        set(findobj(gcf, 'tag', 'fixdegrees'), 'enable', 'on');
        set(findobj(gcf, 'tag', 'fixtime'), 'enable', 'on');
        set(findobj(gcf, 'tag', 'smoothsigma'), 'enable', 'on');
        set(findobj(gcf, 'tag', 'adjustfraction'), 'enable', 'on');
        set(findobj(gcf, 'tag', 'eyeadjusttest'), 'enable', 'on');
        set(findobj(gcf, 'tag', 'menubar_eyeadjusttest'), 'enable', 'on');
    else
        set(findobj(gcf, 'tag', 'fixdegrees'), 'enable', 'off');
        set(findobj(gcf, 'tag', 'fixtime'), 'enable', 'off');
        set(findobj(gcf, 'tag', 'smoothsigma'), 'enable', 'off');
        set(findobj(gcf, 'tag', 'adjustfraction'), 'enable', 'off');
        set(findobj(gcf, 'tag', 'eyeadjusttest'), 'enable', 'off');
        set(findobj(gcf, 'tag', 'menubar_eyeadjusttest'), 'enable', 'off');
    end
end
set(findobj(gcf, 'tag', 'appendflag'), 'value', 0, 'enable', 'off');
set(findobj(gcf, 'tag', 'priority'), 'value', MLConfig.Priority);

if isfield(MLConfig, 'Investigator'),
    set(findobj(gcf, 'tag', 'investigator'), 'string', MLConfig.Investigator);
end
if isfield(MLConfig, 'SubjectName'),
    set(findobj(gcf, 'tag', 'subjectname'), 'string', MLConfig.SubjectName);
end
if isfield(MLConfig, 'SaveFullMovies'),
    set(findobj(gcf, 'tag', 'savefullmovies'), 'value', MLConfig.SaveFullMovies);
else
    set(findobj(gcf, 'tag', 'savefullmovies'), 'value', 1);
end
if isfield(MLConfig, 'UserPlotFunction'),
    if isempty(MLConfig.UserPlotFunction),
        set(findobj(gcf, 'tag', 'userplotfunction'), 'userdata', '', 'string', 'User Plot Function');
    else
        [pname fname] = fileparts(MLConfig.UserPlotFunction);
        set(findobj(gcf, 'tag', 'userplotfunction'), 'userdata', MLConfig.UserPlotFunction, 'string', ['Plot Function: ' fname]);
    end
else
    set(findobj(gcf, 'tag', 'userplotfunction'), 'userdata', '', 'string', 'User Plot Function');
end
if isfield(MLConfig, 'UpdateInterval'),
    set(findobj(gcf, 'tag', 'updateinterval'), 'string', num2str(MLConfig.UpdateInterval), 'userdata', MLConfig.UpdateInterval);
    set(findobj(gcf, 'tag', 'eyered'), 'string', num2str(MLConfig.EyeTraceColor(1)), 'userdata', MLConfig.EyeTraceColor(1));
    set(findobj(gcf, 'tag', 'eyegreen'), 'string', num2str(MLConfig.EyeTraceColor(2)), 'userdata', MLConfig.EyeTraceColor(2));
    set(findobj(gcf, 'tag', 'eyeblue'), 'string', num2str(MLConfig.EyeTraceColor(3)), 'userdata', MLConfig.EyeTraceColor(3));
    set(findobj(gcf, 'tag', 'eyesize'), 'string', num2str(MLConfig.EyeTraceSize), 'userdata', MLConfig.EyeTraceSize);
    set(findobj(gcf, 'tag', 'joyred'), 'string', num2str(MLConfig.JoyTraceColor(1)), 'userdata', MLConfig.JoyTraceColor(1));
    set(findobj(gcf, 'tag', 'joygreen'), 'string', num2str(MLConfig.JoyTraceColor(2)), 'userdata', MLConfig.JoyTraceColor(2));
    set(findobj(gcf, 'tag', 'joyblue'), 'string', num2str(MLConfig.JoyTraceColor(3)), 'userdata', MLConfig.JoyTraceColor(3));
    set(findobj(gcf, 'tag', 'joysize'), 'string', num2str(MLConfig.JoyTraceSize), 'userdata', MLConfig.JoyTraceSize);
    
    set(findobj(gcf, 'tag', 'sample_eye_trace'), 'color', MLConfig.EyeTraceColor, 'markersize', MLConfig.EyeTraceSize);
    set(findobj(gcf, 'tag', 'sample_eye_target'), 'color', 0.5*MLConfig.EyeTraceColor);
    set(findobj(gcf, 'tag', 'sample_joy_trace'), 'color', MLConfig.JoyTraceColor, 'markersize', MLConfig.JoyTraceSize);
    set(findobj(gcf, 'tag', 'sample_joy_target'), 'color', 0.5*MLConfig.JoyTraceColor);
end
if isfield(MLConfig, 'ControlScreenGridCartesian'),
    val = MLConfig.ControlScreenGridCartesian;
    set(findobj(gcf, 'tag', 'csgrid_cartesian'), 'value', val);
    if val,
        set(findobj(gcf, 'tag', 'csgrid_cartesian'), 'string', 'Cartesian Grid ON', 'backgroundcolor', [.7 .8 .7]);
    else
        set(findobj(gcf, 'tag', 'csgrid_cartesian'), 'string', 'Cartesian Grid OFF', 'backgroundcolor', [.8 .7 .7]);
    end
end
if isfield(MLConfig, 'ControlScreenGridCartesianBrightness'),
    set(findobj(gcf, 'tag', 'cartesianbrightness'), 'value', MLConfig.ControlScreenGridCartesianBrightness);
    if MLConfig.ControlScreenGridCartesian,
        set(findobj(gcf, 'tag', 'cartesianbrightness'), 'enable', 'on');
        set(findobj(gcf, 'tag', 'cartesianbrightnessvalue'), 'string', sprintf('%1.2f', MLConfig.ControlScreenGridCartesianBrightness));
    else
        set(findobj(gcf, 'tag', 'cartesianbrightness'), 'enable', 'off');
        set(findobj(gcf, 'tag', 'cartesianbrightnessvalue'), 'string', 'n/a');
    end
end
if isfield(MLConfig, 'ControlScreenGridPolar'),
    val = MLConfig.ControlScreenGridPolar;
    set(findobj(gcf, 'tag', 'csgrid_polar'), 'value', val);
    if val,
        set(findobj(gcf, 'tag', 'csgrid_polar'), 'string', 'Polar Grid ON', 'backgroundcolor', [.7 .8 .7]);
    else
        set(findobj(gcf, 'tag', 'csgrid_polar'), 'string', 'Polar Grid OFF', 'backgroundcolor', [.8 .7 .7]);
    end
end
if isfield(MLConfig, 'ControlScreenGridPolarBrightness'),
    set(findobj(gcf, 'tag', 'polarbrightness'), 'value', MLConfig.ControlScreenGridPolarBrightness);
    if MLConfig.ControlScreenGridPolar,
        set(findobj(gcf, 'tag', 'polarbrightness'), 'enable', 'on');
        set(findobj(gcf, 'tag', 'polarbrightnessvalue'), 'string', sprintf('%1.2f', MLConfig.ControlScreenGridPolarBrightness));
    else
        set(findobj(gcf, 'tag', 'polarbrightness'), 'enable', 'off');
        set(findobj(gcf, 'tag', 'polarbrightnessvalue'), 'string', 'n/a');
    end
end

if isfield(MLConfig, 'StrobeBitEdge') && ~isempty(MLConfig.StrobeBitEdge),
    set(findobj(gcf, 'tag', 'strobebitedge'), 'value', MLConfig.StrobeBitEdge);
end
if isfield(MLConfig, 'BehavioralCodesTextFile'),
    codesfile = MLConfig.BehavioralCodesTextFile;
    if exist(codesfile, 'file'),
        [pathname codestr ext] = fileparts(codesfile);
        codestr = [codestr ext];
        set(findobj(gcf, 'tag', 'codesfile'), 'string', codestr, 'userdata', codesfile);
        set(findobj(gcf, 'tag', 'editcodesfile'), 'enable', 'on');
    end
end
if isfield(MLConfig, 'BufferPages'),
    set(findobj(gcf, 'tag', 'bufferpages'), 'value', MLConfig.BufferPages);
end
if isfield(MLConfig, 'FixationSpotImageFile'),
    fixspotfile = MLConfig.FixationSpotImageFile;
    if ~strcmpi(fixspotfile, 'default') && exist(fixspotfile, 'file'),
        [pathname fixstr ext] = fileparts(fixspotfile);
        fixstr = [fixstr ext];
        set(findobj(gcf, 'tag', 'fixationfilename'), 'string', fixstr, 'userdata', fixspotfile);
    else
        set(findobj(gcf, 'tag', 'fixationfilename'), 'string', '- Default -', 'userdata', 'DEFAULT');
    end
else
    set(findobj(gcf, 'tag', 'fixationfilename'), 'string', '- Default -', 'userdata', 'DEFAULT');
end
if isfield(MLConfig, 'CursorImageFile'),
    cursorfile = MLConfig.CursorImageFile;
    if exist(cursorfile, 'file'),
        [pathname cursorstr ext] = fileparts(cursorfile);
        cursorstr = [cursorstr ext];
        set(findobj(gcf, 'tag', 'cursorfilename'), 'string', cursorstr, 'userdata', cursorfile);
    end
else
    set(findobj(gcf, 'tag', 'cursorfilename'), 'string', '- Default -', 'userdata', 'DEFAULT');
end
if isfield(MLConfig, 'ScreenBackgroundColor'),
    sbgcol = MLConfig.ScreenBackgroundColor;
else
    sbgcol = [0 0 0];
end
set(findobj(gcf, 'tag', 'bgred'), 'string', num2str(sbgcol(1)), 'userdata', sbgcol(1));
set(findobj(gcf, 'tag', 'bggreen'), 'string', num2str(sbgcol(2)), 'userdata', sbgcol(2));
set(findobj(gcf, 'tag', 'bgblue'), 'string', num2str(sbgcol(3)), 'userdata', sbgcol(3));
set(findobj(gcf, 'tag', 'minicontrolscreen'), 'color', sbgcol);

numdevices = length(get(findobj(gcf, 'tag', 'videodevice'), 'string'));
if MLConfig.VideoDevice > numdevices,
    logger.logMessage(sprintf('*** WARNING: Assigned video device (#%i) not available ***', MLConfig.VideoDevice))
    MLConfig.VideoDevice = numdevices;
end
set(findobj(gcf, 'tag', 'videodevice'), 'value', MLConfig.VideoDevice);
f = find(validrefresh == MLConfig.RefreshRate);
if isempty(f),
    f = 1;
end
set(findobj(gcf, 'tag', 'refreshrate'), 'value', f);

if isfield(MLConfig, 'UsePreProcessedImages'),
    val = MLConfig.UsePreProcessedImages;
    set(findobj(gcf, 'tag', 'preprocessimages'), 'value', val);
    if val,
        set(findobj(gcf, 'tag', 'preprocessimages'), 'backgroundcolor', [.8 .6 .6]);
    else
        set(findobj(gcf, 'tag', 'preprocessimages'), 'backgroundcolor', [0.9255 0.9137 0.8471]);
    end
else
    set(findobj(gcf, 'tag', 'preprocessimages'), 'value', 0, 'backgroundcolor', [0.9255 0.9137 0.8471]);
end

if ~isempty(MLConfig.EyeTransform),
    set(findobj(gcf, 'tag', 'calbutton'), 'foregroundcolor', [0 .4 0], 'string', 'Re-calibrate Eye');
else
    set(findobj(gcf, 'tag', 'calbutton'), 'foregroundcolor', [0 0 0], 'string', 'Calibrate Eye-Position');
end

if MLConfig.UseRawEyeSignal == 1,
    set(findobj(gcf, 'tag', 'useraw'), 'value', 1);
    set(findobj(gcf, 'tag', 'calbutton'), 'enable', 'off');
    if ~isempty(MLConfig.EyeTransform),
        set(findobj(gcf, 'tag', 'calbutton'), 'foregroundcolor', [0.4 0 0], 'string', 'Calibration Not Used');
    end
else
    set(findobj(gcf, 'tag', 'useraw'), 'value', 0);
    set(findobj(gcf, 'tag', 'calbutton'), 'enable', 'on');
end

if ~isempty(MLConfig.JoyTransform),
    set(findobj(gcf, 'tag', 'joycalbutton'), 'foregroundcolor', [0 .4 0], 'string', 'Re-calibrate Joystick');
else
    set(findobj(gcf, 'tag', 'joycalbutton'), 'foregroundcolor', [0 0 0], 'string', 'Calibrate Joystick');
end

if MLConfig.UseRawJoySignal == 1,
    set(findobj(gcf, 'tag', 'userawjoy'), 'value', 1);
    set(findobj(gcf, 'tag', 'joycalbutton'), 'enable', 'off');
    if ~isempty(MLConfig.JoyTransform),
        set(findobj(gcf, 'tag', 'joycalbutton'), 'foregroundcolor', [0.4 0 0], 'string', 'Joystick Calibration Not Used');
    end
else
    set(findobj(gcf, 'tag', 'userawjoy'), 'value', 0);
    set(findobj(gcf, 'tag', 'joycalbutton'), 'enable', 'on');
end

tpb = MLConfig.BlockLength;
currentblocks = get(findobj(gcf, 'tag', 'blocklist'), 'string');
numblocks = length(currentblocks);
if ~strcmp(currentblocks(1, :), '--'),
    currentblocks = str2num(currentblocks); %#ok<ST2NM>
    if length(tpb) > numblocks;
        mlmessage(sprintf('WARNING: *** Configuration file contains more blocks than current file. Truncating. ***'))
        tpb = tpb(1:numblocks);
    elseif length(tpb) < length(currentblocks),
        mlmessage(sprintf('WARNING: *** Configuration file contains fewer blocks than current file. Replicating last value. ***'))
        tpb(length(tpb)+1:numblocks) = tpb(length(tpb));
    end
end
set(findobj(gcf, 'tag', 'trialsperblock'), 'userdata', tpb, 'string', tpb(1));
runblocks = MLConfig.RunBlocks';
blocklist = get(findobj(gcf, 'tag', 'runblocks'), 'userdata');

if isempty(runblocks) || max(runblocks) > max(blocklist),
    set(findobj(gcf, 'tag', 'runblocks'), 'value', 1);
else
    set(findobj(gcf, 'tag', 'runblocks'), 'value', find(ismember(blocklist, runblocks)));
end
set(findobj(gcf, 'tag', 'firstblock'), 'string', cat(1, {'Default'}, num2cell(runblocks)), 'userdata', runblocks);
if isfield(MLConfig, 'FirstBlock'),
    if MLConfig.FirstBlock == 0,
        f = 1;
    else
        f = find(runblocks == MLConfig.FirstBlock);
        if isempty(f),
            f = 1;
        else
            f = f + 1;
        end
    end
    set(findobj(gcf, 'tag', 'firstblock'), 'value', f);
else
    set(findobj(gcf, 'tag', 'firstblock'), 'value', 1);
end

if isfield(MLConfig.InputOutput, 'AnalogInputDuplication'), %obsolete organization
    MLConfig.InputOutput = rmfield(MLConfig.InputOutput, 'AnalogInputDuplication');
end
MLConfig.InputOutput = update_iostruct(MLConfig.InputOutput);
set(findobj(gcf, 'tag', 'ioselect'), 'value', 1);
iovar = get(findobj(gcf, 'tag', 'ioselect'), 'userdata');
set(findobj(gcf, 'tag', 'iolabel'), 'string', MLConfig.InputOutput.(iovar{1}).Label);
set(findobj(gcf, 'tag', 'iotext'), 'string', MLConfig.InputOutput.(iovar{1}).Description);

fn = fieldnames(MLConfig.InputOutput);
itypes = {'Differential'};
foundai = 0;
for i = 1:length(fn),
    if isfield(MLConfig.InputOutput.(fn{i}), 'Constructor') && ~isempty(strfind(MLConfig.InputOutput.(fn{i}).Constructor, 'analoginput')),
        try
            ai = eval(MLConfig.InputOutput.(fn{i}).Constructor);
            itypes = set(ai, 'InputType');
            foundai = 1;
            break
        catch
            str = sprintf('*** WARNING: Assigned adaptor for %s not currently available ***', fn{i});
            mlmessage(str);
            logger.logMessage(str)
        end
    end
end
if foundai,
    str = 'on';
else
    str = 'off';
end
if isfield(MLConfig.InputOutput.Reward, 'Constructor'),
    set(findobj(gcf, 'tag', 'menubar_rewardpolarity'), 'enable', 'on');
else
    set(findobj(gcf, 'tag', 'menubar_rewardpolarity'), 'enable', 'off');
end
set(findobj(gcf, 'tag', 'inputtype'), 'string', itypes, 'enable', str, 'value', 1);
set(findobj(gcf, 'tag', 'aitest'), 'enable', str);
set(findobj(gcf, 'tag', 'menubar_aitest'), 'enable', str);
set(findobj(gcf, 'tag', 'analoginputfrequency'), 'enable', str);

if isfield(MLConfig.InputOutput, 'Configuration'),
    set(findobj(gcf, 'tag', 'aiduplication'), 'value', MLConfig.InputOutput.Configuration.AnalogInputDuplication);
    if MLConfig.InputOutput.Configuration.AnalogInputDuplication,
        set(findobj(gcf, 'tag', 'aiduplication'), 'backgroundcolor', [.7 .8 .7], 'string', 'A-I Duplication ON');
    else
        set(findobj(gcf, 'tag', 'aiduplication'), 'backgroundcolor', [.8 .7 .7], 'string', 'A-I Duplication OFF');
    end
    if isfield(MLConfig.InputOutput.Configuration, 'AnalogInputType'),
        val = find(strcmpi(itypes, MLConfig.InputOutput.Configuration.AnalogInputType));
        if ~isempty(val),
            set(findobj(gcf, 'tag', 'inputtype'), 'value', val);
        end
    else
        MLConfig.InputOutput.Configuration.AnalogInputType = 'Differential';
        MLConfig.InputOutput.Configuration.AnalogInputFrequency = 1000;
    end
    if isfield(MLConfig.InputOutput.Configuration, 'RewardPolarity'),
        if MLConfig.InputOutput.Configuration.RewardPolarity == -1,
            set(findobj(gcf ,'tag', 'menubar_rewardpolarity'), 'checked', 'on');
        else
            set(findobj(gcf, 'tag', 'menubar_rewardpolarity'), 'checked', 'off');
        end
    else
        MLConfig.InputOutput.Configuration.RewardPolarity = 1;
        set(findobj(gcf, 'tag', 'menubar_rewardpolarity'), 'checked', 'off');
    end
else
    MLConfig.InputOutput.Configuration.AnalogInputDuplication = 0;
    set(findobj(gcf, 'tag', 'aiduplication'), 'value', 0, 'backgroundcolor', [.8 .7 .7], 'string', 'A-I Duplication OFF');
    MLConfig.InputOutput.Configuration.AnalogInputType = 'Differential';
    MLConfig.InputOutput.Configuration.AnalogInputFrequency = 1000;
    MLConfig.InputOutput.Configuration.RewardPolarity = 1;
    set(findobj(gcf, 'tag', 'menubar_rewardpolarity'), 'checked', 'off');
end
set(findobj(gcf, 'tag', 'analoginputfrequency'), 'string', MLConfig.InputOutput.Configuration.AnalogInputFrequency, 'userdata', MLConfig.InputOutput.Configuration.AnalogInputFrequency);
set(findobj(gcf, 'tag', 'ioframe'), 'userdata', MLConfig.InputOutput);

set(findobj(gcf, 'tag', 'checkio'), 'backgroundcolor', [0.9255 0.9137 0.8471], 'string', 'Check');
if ~isempty(fieldnames(MLConfig.InputOutput.DigCodesStrobeBit)) && ~strcmp(MLConfig.InputOutput.DigCodesStrobeBit.Description, 'Not Assigned'),
    set(findobj(gcf, 'tag', 'strobebitedge'), 'enable', 'on');
    set(findobj(gcf, 'tag', 'digcodestest'), 'enable', 'on');
    set(findobj(gcf, 'tag', 'menubar_digcodestest'), 'enable', 'on');
else
    set(findobj(gcf, 'tag', 'strobebitedge'), 'enable', 'off');
    set(findobj(gcf, 'tag', 'digcodestest'), 'enable', 'off');
    set(findobj(gcf, 'tag', 'menubar_digcodestest'), 'enable', 'off');
end

if isfield(MLConfig, 'Alerts') && ~isempty(MLConfig.Alerts.Enable),
    set(findobj(gcf, 'tag', 'alertsandupdates'), 'value', MLConfig.Alerts.Enable);
    if ~isempty(MLConfig.Alerts.AlertFunction),
        [pname fname ext] = fileparts(MLConfig.Alerts.AlertFunction);
        if strcmpi(ext, '.html') || strcmpi(ext, '.htm'),
            set(findobj(gcf, 'tag', 'au_function'), 'string', ['Web Template: ' fname], 'userdata', MLConfig.Alerts.AlertFunction);
        else
            set(findobj(gcf, 'tag', 'au_function'), 'string', ['Alert Function: ' fname], 'userdata', MLConfig.Alerts.AlertFunction);
        end
    else
        set(findobj(gcf, 'tag', 'au_function'), 'string', 'n/a', 'userdata', '');
    end
    set(findobj(gcf, 'tag', 'au_errorcheck'), 'value', MLConfig.Alerts.ErrorAlerts);
    set(findobj(gcf, 'tag', 'au_blockcheck'), 'value', MLConfig.Alerts.BlockUpdates);
    set(findobj(gcf, 'tag', 'au_userdefinedcheck'), 'value', MLConfig.Alerts.UserCriteria);
    if ~isempty(MLConfig.Alerts.UserCriteriaFunction),
        [pname fname] = fileparts(MLConfig.Alerts.UserCriteriaFunction);
        set(findobj(gcf, 'tag', 'au_userdefinedcritfunction'), 'string', fname, 'userdata', MLConfig.Alerts.UserCriteriaFunction);
    else
        set(findobj(gcf, 'tag', 'au_userdefinedcritfunction'), 'string', 'n/a', 'userdata', '');
    end
    update_alertmenu;
end

if isfield(MLConfig, 'MLHelperOff') && MLConfig.MLHelperOff,
    set(findobj(gcf, 'tag', 'menubar_mlhelper'), 'Checked', 'on');
else
    set(findobj(gcf, 'tag', 'menubar_mlhelper'), 'Checked', 'off');
end

if isfield(MLConfig, 'PreloadVideo') && MLConfig.PreloadVideo,
    set(findobj(gcf, 'tag', 'menubar_preload'), 'Checked', 'on');
else
    set(findobj(gcf, 'tag', 'menubar_preload'), 'Checked', 'off');
end

mlmessage(sprintf('Loaded configuration file %s.', cfgfile))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function savecfg(varargin)

if ~isempty(varargin),
    hardware_flag = varargin{1};
else
    hardware_flag = -1;
end

MLPrefs.Directories = getpref('MonkeyLogic', 'Directories');

MLConfig.ExperimentName = get(findobj(gcf, 'tag', 'experimentname'), 'string');
MLConfig.Investigator = get(findobj(gcf, 'tag', 'investigator'), 'string');
MLConfig.SubjectName = get(findobj(gcf, 'tag', 'subjectname'), 'string');
MLConfig.ErrorLogic = get(findobj(gcf, 'tag', 'errorlogic'), 'value');
MLConfig.MaxBlocks = str2double(get(findobj(gcf, 'tag', 'maxblocks'), 'string'));
MLConfig.BlockLength = get(findobj(gcf, 'tag', 'trialsperblock'), 'userdata');
MLConfig.MaxTrials = str2double(get(findobj(gcf, 'tag', 'maxtrials'), 'string'));
MLConfig.BlockLogic = get(findobj(gcf, 'tag', 'blocklogic'), 'value');
MLConfig.CondLogic = get(findobj(gcf, 'tag', 'condlogic'), 'value');
MLConfig.BlockSelectFunction = get(findobj(gcf, 'tag', 'blockselectfun'), 'userdata');
MLConfig.CondSelectFunction = get(findobj(gcf, 'tag', 'condselectfun'), 'userdata');
MLConfig.BlockChangeFunction = get(findobj(gcf, 'tag', 'blockchangefun'), 'userdata');
blocklist = get(findobj(gcf, 'tag', 'runblocks'), 'userdata');
MLConfig.RunBlocks = blocklist(get(findobj(gcf, 'tag', 'runblocks'), 'value'));
runblocks = get(findobj(gcf, 'tag', 'firstblock'), 'userdata');
fbval = get(findobj(gcf, 'tag', 'firstblock'), 'value');
if fbval > 1,
    MLConfig.FirstBlock = runblocks(fbval-1);
else
    MLConfig.FirstBlock = 0;
end
%%%%%
MLConfig.CountOnlyCorrect = get(findobj(gcf, 'tag', 'countonlycorrect'), 'value');
%%%%%
MLConfig.SaveFullMovies = get(findobj(gcf, 'tag', 'savefullmovies'), 'value');
MLConfig.InterTrialInterval = get(findobj(gcf, 'tag', 'iti'), 'userdata');
MLConfig.StrobeBitEdge = get(findobj(gcf, 'tag', 'strobebitedge'), 'value');
MLConfig.EyeTransform = get(findobj(gcf, 'tag', 'calbutton'), 'userdata');
MLConfig.JoyTransform = get(findobj(gcf, 'tag', 'joycalbutton'), 'userdata');
MLConfig.EyeCalibrationTargets = get(findobj(gcf, 'tag', 'eyecaltext'), 'userdata');
MLConfig.JoystickCalibrationTargets = get(findobj(gcf, 'tag', 'joycaltext'), 'userdata');
MLConfig.RewardCalibrationSettings.EyeSignal = get(findobj(gcf, 'tag', 'useraw'), 'userdata');
MLConfig.RewardCalibrationSettings.Joystick = get(findobj(gcf, 'tag', 'userawjoy'), 'userdata');
MLConfig.UseFirstTargetOnly = get(findobj(gcf, 'tag', 'firsttargetonly'), 'value');
MLConfig.OnlineEyeAdjustment = get(findobj(gcf, 'tag', 'eyeadjust'), 'value');
MLConfig.FixDegrees = get(findobj(gcf, 'tag', 'fixdegrees'), 'userdata');
MLConfig.FixTime = get(findobj(gcf, 'tag', 'fixtime'), 'userdata');
MLConfig.EyeAdjustFraction = get(findobj(gcf, 'tag', 'adjustfraction'), 'userdata');
MLConfig.EyeSmoothingSigma = get(findobj(gcf, 'tag', 'smoothsigma'), 'userdata');
MLConfig.PixelsPerDegree = str2double(get(findobj(gcf, 'tag', 'ppd'), 'string'));
resval = get(findobj(gcf, 'tag', 'screenres'), 'value');
validsizes = get(findobj(gcf, 'tag', 'screenres'), 'userdata');
validxsize = validsizes(:, 1);
validysize = validsizes(:, 2);
MLConfig.ScreenX = validxsize(resval);
MLConfig.ScreenY = validysize(resval);
MLConfig.BufferPages = get(findobj(gcf, 'tag', 'bufferpages'), 'value');
MLConfig.DiagonalScreenSize = str2double(get(findobj(gcf, 'tag', 'diagsize'), 'string'));
MLConfig.ViewingDistance = str2double(get(findobj(gcf, 'tag', 'viewdist'), 'string'));
MLConfig.FixationSpotImageFile = get(findobj(gcf, 'tag', 'fixationfilename'), 'userdata');
MLConfig.ShowCursor = 0;
MLConfig.CursorImageFile = get(findobj(gcf, 'tag', 'cursorfilename'), 'userdata');
MLConfig.UserPlotFunction = get(findobj(gcf, 'tag', 'userplotfunction'), 'userdata');
sbgcol(1) = get(findobj(gcf, 'tag', 'bgred'), 'userdata');
sbgcol(2) = get(findobj(gcf, 'tag', 'bggreen'), 'userdata');
sbgcol(3) = get(findobj(gcf, 'tag', 'bgblue'), 'userdata');
MLConfig.ScreenBackgroundColor = sbgcol;
MLConfig.PhotoDiode = get(findobj(gcf, 'tag', 'photodiode'), 'value');
MLConfig.PhotoDiodeSize = str2double(get(findobj(gcf, 'tag', 'photodiodesize'), 'string'));
MLConfig.UsePreProcessedImages = get(findobj(gcf, 'tag', 'preprocessimages'), 'value');

MLConfig.UpdateInterval = get(findobj(gcf, 'tag', 'updateinterval'), 'userdata');
r = get(findobj(gcf, 'tag', 'eyered'), 'userdata');
g = get(findobj(gcf, 'tag', 'eyegreen'), 'userdata');
b = get(findobj(gcf, 'tag', 'eyeblue'), 'userdata');
MLConfig.EyeTraceColor = [r g b];
MLConfig.EyeTraceSize = get(findobj(gcf, 'tag', 'eyesize'), 'userdata');
r = get(findobj(gcf, 'tag', 'joyred'), 'userdata');
g = get(findobj(gcf, 'tag', 'joygreen'), 'userdata');
b = get(findobj(gcf, 'tag', 'joyblue'), 'userdata');
MLConfig.JoyTraceColor = [r g b];
MLConfig.JoyTraceSize = get(findobj(gcf, 'tag', 'joysize'), 'userdata');
MLConfig.ControlScreenGridCartesian = get(findobj(gcf, 'tag', 'csgrid_cartesian'), 'value');
MLConfig.ControlScreenGridCartesianBrightness = get(findobj(gcf, 'tag', 'cartesianbrightness'), 'value');
MLConfig.ControlScreenGridPolar = get(findobj(gcf, 'tag', 'csgrid_polar'), 'value');
MLConfig.ControlScreenGridPolarBrightness = get(findobj(gcf, 'tag', 'polarbrightness'), 'value');
MLConfig.BehavioralCodesTextFile = get(findobj(gcf, 'tag', 'codesfile'), 'userdata');

raweye = get(findobj(gcf, 'tag', 'useraw'), 'value');
rawjoy = get(findobj(gcf, 'tag', 'userawjoy'), 'value');
if isempty(MLConfig.EyeTransform),
    raweye = 1;
    set(findobj(gcf, 'tag', 'useraw'), 'value', 1);
end
if isempty(MLConfig.JoyTransform),
    rawjoy = 1;
    set(findobj(gcf, 'tag', 'userawjoy'), 'value', 1);
end
MLConfig.UseRawEyeSignal = raweye;
MLConfig.UseRawJoySignal = rawjoy;
MLConfig.Priority = get(findobj(gcf, 'tag', 'priority'), 'value');
MLConfig.VideoDevice = get(findobj(gcf, 'tag', 'videodevice'), 'value');
validrefresh = get(findobj(gcf, 'tag', 'refreshrate'), 'userdata');
MLConfig.RefreshRate = validrefresh(get(findobj(gcf, 'tag', 'refreshrate'), 'value'));
MLConfig.InputOutput = get(findobj(gcf, 'tag', 'ioframe'), 'userdata');

MLConfig.Alerts.Enable = get(findobj(gcf, 'tag', 'alertsandupdates'), 'value');
MLConfig.Alerts.AlertFunction = get(findobj(gcf, 'tag', 'au_function'), 'userdata');
MLConfig.Alerts.ErrorAlerts = get(findobj(gcf, 'tag', 'au_errorcheck'), 'value');
MLConfig.Alerts.BlockUpdates = get(findobj(gcf, 'tag', 'au_blockcheck'), 'value');
MLConfig.Alerts.UserCriteria = get(findobj(gcf, 'tag', 'au_userdefinedcheck'), 'value');
MLConfig.Alerts.UserCriteriaFunction = get(findobj(gcf, 'tag', 'au_userdefinedcritfunction'), 'userdata');

MLConfig.MLHelperOff              = strcmp(get(findobj(gcf, 'tag', 'menubar_mlhelper'), 'Checked'),'on');
MLConfig.PreloadVideo             = strcmp(get(findobj(gcf, 'tag', 'menubar_preoload'), 'Checked'),'on');
MLConfig.PersonalHardwareSettings = strcmp(get(findobj(gcf, 'tag', 'menubar_personalhardware'), 'Checked'),'on');

cfgfile = get(findobj(gcf, 'tag', 'configfilename'), 'string');
cfgfile = [MLPrefs.Directories.ExperimentDirectory cfgfile];

try
    save(cfgfile, 'MLConfig');
catch
    if isdir(MLPrefs.Directories.ExperimentDirectory),
        cfgfile = [MLPrefs.Directories.ExperimentDirectory 'default_cfg.mat'];
    else
        cfgfile = [MLPrefs.Directories.BaseDirectory 'default_cfg.mat'];
    end
    logger.logMessage('... Saving new default configuration file ...')
    save(cfgfile, 'MLConfig');
end
setpref('MonkeyLogic', 'Directories', MLPrefs.Directories);

mlmessage(sprintf('Wrote configuration file %s', cfgfile))            
set(findobj(gcf, 'tag', 'savebutton'), 'enable', 'off');
set(findobj(gcf, 'tag', 'menubar_savebutton'), 'enable', 'off');

function rgb = rgbval(r,g,b)
r=uint32(r);
g=uint32(g);
b=uint32(b);
z = 65536*r+256*g+b;
rgb = z(:)';

function chknewupdates(lastupdate)

checkinterval = 30; %in days
if ~ispref('MonkeyLogic', 'LastUpdateCheck'),
    lastchecknum = floor(now)-checkinterval-1;
    setpref('MonkeyLogic', 'LastUpdateCheck', lastchecknum);
end
lastchecknum = getpref('MonkeyLogic', 'LastUpdateCheck');
todaynum = floor(now);

try
    if todaynum > lastchecknum + checkinterval,
        mmm = lastupdate(1:3);
        yyyy = lastupdate(end-3:end);
        currentversion = datenum([mmm yyyy], 'mmmyyyy');
        str = urlread('http://www.monkeylogic.org/revisiondate.txt');
        mmm = str(1:3);
        yyyy = str(end-3:end);
        latestversion = datenum([mmm yyyy], 'mmmyyyy');
        if latestversion > currentversion,
            msgbox(sprintf('New MonkeyLogic update available (%s) at www.monkeylogic.org', str));
        end
        setpref('MonkeyLogic', 'LastUpdateCheck', todaynum);
    end
catch ME %likely no network...
    logger.logMessage(sprintf('>>> Unable to check for MonkeyLogic updates (%s) <<<', ME.identifier))
end


