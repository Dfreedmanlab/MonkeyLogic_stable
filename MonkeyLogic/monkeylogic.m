function varargout = monkeylogic(varargin)
global MLHELPER_OFF
% See http:\\www.monkeylogic.net for information
%
% Created by WA 6/15/06
% Modified 3/15/08 by WA to include keyboard-checking function modified by
% CPS
% Modified 3/25/08 -WA (UserLoop function based on suggestions by CPS)
% Modified 4/14/08 -WA (timing script can now modify and output TrialRecord)
% Modified 4/17/08 -TB & VY (fixed bug in pause-task menu)
% Modified 7/20/08 -WA (ftp/web updates added)
% Modified 7/25/08 -WA (now stores absolute trial start time for each trial)
% Modified 8/07/08 -WA (remote commands added)
% Modified 2/04/13 -DF (editable variables bug fix)
% Modified 10/7/13 -DF (actual refresh rate measurement loop added)

% Syntax:
%        monkeylogic(ConditionsFile, DataFile, TestFlag)
%       
% This function will pick blocks and conditions as configured in the menu
% (mlmenu), and will perform behavioral error handling (e.g., repeat errors
% vs ignore), will initialize video, and will call the timing file
% specified in each condition of the Conditions file.  Behavioral data will
% be written to a ".bhv" file, which can be read using the "bhv_read" 
% function.
%

% ToDo:
% Add user-defined variables to the BHV file from the timing script (e.g., "bhvaddvariable")
% Make alpha values active for stimuli (transparency)
global errorfile					%global because other functions also use it (like create_taskobjects)
errorfile = 'ml_error_workspace.mat';
if isempty(varargin),
    f = findobj('tag', 'monkeylogicmainmenu');
    if isempty(f),
        mlflush;
        mlmenu;
    else
        set(0, 'CurrentFigure', f);
    end
    return
end
logger = log4m.getLogger('log.txt');
logger.setCommandWindowLevel(logger.ALL); 
logger.setLogLevel(logger.ALL);

logger.info('monkeylogic.m', sprintf('\r\r\r'));

if length(varargin) > 2,
    thisisonlyatest = varargin{3};
end

MLPrefs.Directories = getpref('MonkeyLogic', 'Directories');
path(MLPrefs.Directories.RunTimeDirectory, path); %move run-time directory to head of list

%%% Initialize task
clear Conditions BlockSpec BlockTypes
trial = 0;
trialsthisblock = 0;
lasterror = 0;
lastblock = [];
lastcond = [];
%%% initialize the random number generator
if verLessThan('matlab', '8')
    RandStream.setDefaultStream(RandStream('mt19937ar', 'seed', sum(100*clock))); %#ok<SETRS>
else
    RandStream.setGlobalStream(RandStream('mt19937ar', 'seed', sum(100*clock)));
end
condfile = varargin{1};

% Load configuration info:
[pname fname] = fileparts(condfile);
cfgfile = [MLPrefs.Directories.ExperimentDirectory fname '_cfg.mat'];
localcfgfile = [MLPrefs.Directories.ExperimentDirectory 'LOCAL_cfg.mat'];
if exist(cfgfile, 'file'),
    load(cfgfile);
    if isfield(MLConfig, 'UseLocal') && MLConfig.UseLocal, %#ok<NODEF>
        if exist(localcfgfile, 'file'),
            load([MLPrefs.Directories.ExperimentDirectory 'LOCAL_cfg.mat']);
            MLConfig.StrobeBitEdge      = MLConfigLoc.StrobeBitEdge;
            MLConfig.ScreenX            = MLConfigLoc.ScreenX;
            MLConfig.ScreenY            = MLConfigLoc.ScreenY;
            MLConfig.BufferPages        = MLConfigLoc.BufferPages;
            MLConfig.DiagonalScreenSize = MLConfigLoc.DiagonalScreenSize;
            MLConfig.ViewingDistance    = MLConfigLoc.ViewingDistance;
            MLConfig.VideoDevice        = MLConfigLoc.VideoDevice;
            MLConfig.RefreshRate        = MLConfigLoc.RefreshRate;
            MLConfig.InputOutput        = MLConfigLoc.InputOutput;
        else
            error('ML:NoLocalCFG','No local configuration file found.');
        end
    end
   
    fprintf('<<< MonkeyLogic >>> Using configuration file: %s\n', cfgfile);
    xs = MLConfig.ScreenX;
    ys = MLConfig.ScreenY;
else
    error('ML:NoCFG','Unable to find configuration file %s', cfgfile);
end
%Apparently, the actual refresh rate is sometimes different from
%MLConfig.RefreshRate. Introducing a video test (same as the one in mlmenu)
%to measure the actual refresh rate and store it in a field called
%ActualRefreshRate.
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

try
	mlvideo('init', MLConfig.PixelsPerDegree);
	mlvideo('initdevice', videodevice);
	mlvideo('setmode', videodevice, ScreenX, ScreenY, bytesperpixel, refreshrate, bufferpages);
	mlvideo('showcursor', videodevice, 0);
	mlvideo('clear', videodevice, [0 0 0]);
	frames = 0;
	t2 = 0;
	
	mlmessage('Now measuring actual screen refresh rate...');
	while ~mlvideo('verticalblank', videodevice)
	end
	t1 = tic;
	mlvideo('flip', videodevice);
	
	while t2 < 1
		mlvideo('clear', videodevice, [0 0 0]);
		while ~mlvideo('verticalblank', videodevice)
		end
		mlvideo('flip', videodevice);
		frames = frames + 1;
		t2 = toc(t1);
	end
	
	mlvideo('showcursor', videodevice, 1);
	mlvideo('restoremode', videodevice);
	mlvideo('releasedevice', videodevice);
	mlvideo('release');
	framerate = frames/t2;
	mlmessage(sprintf('Approximate video refresh rate = %3.2f Hz', framerate));
catch
	mlvideo('showcursor', videodevice, 1);
	mlvideo('restoremode', videodevice);
	mlvideo('releasedevice', videodevice);
	mlvideo('release');
	lasterr
	mlmessage('*** Error encountered during application of selected video settings ***');
end
MLConfig.ActualRefreshRate  = framerate;

MLConfig.ComputerName = lower(getenv('COMPUTERNAME'));
MLHELPER_OFF = MLConfig.MLHelperOff;
%logger.info('monkeylogic.m', sprintf('Setting MLHELPER_OFF to %i', MLHELPER_OFF));

% Read conditions file
Conditions_temp = load_conditions(condfile);
if iscell(Conditions_temp), %user-defined task-loop
    numconds = 1;
    MLConfig.CondSelectFunctionName = '';
    MLConfig.BlockSelectFunctionName = '';
    MLConfig.BlockChangeFunctionName = '';
    userloopfunction = Conditions_temp{1};
    [pname userloopfunction] = fileparts(userloopfunction);
    appendflag = 0;
    if length(varargin) > 1,
        datafile = varargin{2};
    end
    RunTimeFiles = {'blank'};
    Conditions = [];
    userdefinedtaskloop = 1;
else %standard task-loop (using a conditions text file and timing files, etc)
    userdefinedtaskloop = 0;
    condcount = 1;
    for i = 1:length(Conditions_temp), %expand conditions to explicitly represent frequency
        numreps = Conditions_temp(i).RelativeFrequency;
        Conditions_temp(i).RelativeFrequency = 1;
        Conditions_temp(i).OriginalConditionNumber = i;
        Conditions(condcount:condcount + numreps - 1) = Conditions_temp(i);
        originalcond(condcount:condcount + numreps - 1) = i;
        condcount = condcount + numreps;
    end
    BlockSpec = cell(1, length(Conditions));
    TFiles = cell(1, length(Conditions));
    for i = 1:length(Conditions),
        BlockSpec{i} = Conditions(i).CondInBlock;
        TFiles{i} = Conditions(i).TimingFile;
    end
    if length(varargin) > 1,
        datafile = varargin{2};
        if length(varargin) > 2,
            appendflag = varargin{3};
        else
            appendflag = 0; %overwrite any existing file.
        end
    end
    numconds = length(Conditions);
    Txy = [];
    for cnum = 1:numconds,
        tobject = Conditions(cnum).TaskObject;
        tx = cat(1, tobject.Xpos);
        ty = cat(1, tobject.Ypos);
        Txy = cat(1, Txy, [tx ty]);
    end
    Txy = unique(Txy, 'rows');
    logger.info('monkeylogic.m', sprintf('<<< MonkeyLogic >>> Loaded & parsed conditions file: %s', condfile))
    drawnow;
    
    %Make certain all timing files are on the path:
    tfarray = unique(TFiles);
    numtfiles = length(tfarray);
    RunTimeFiles = cell(numtfiles, 1);
    for i = 1:numtfiles,
        try
            tfile = [MLPrefs.Directories.ExperimentDirectory tfarray{i}];
            [pname fname] = fileparts(tfarray{i});
            clear(fname); %force reload
            logger.info('monkeylogic.m', sprintf('<<< MonkeyLogic >>> Embedding %s...', tfile));
            RunTimeFiles{i} = embedtimingfile(tfile, 'trialholder.m');
        catch
            save(errorfile);
            error('*** Unable to embed timing script(s) ***');
        end
    end
    if numtfiles == 1,
        logger.info('monkeylogic.m', '<<< MonkeyLogic >>> Successfully created the run-time function from the timing script');
    else
        logger.info('monkeylogic.m', sprintf('<<< MonkeyLogic >>> Successfully created %i run-time functions from %i timing scripts...\n', numtfiles, numtfiles));
    end
    drawnow;

    % BlockTypes will list the conditions available from within any one block.
    BlockTypes = sortblocks(BlockSpec);

    if MLConfig.CondLogic == 5, %user-defined m-file
        MLConfig.CondSelectFunctionName = prep_m_file(MLConfig.CondSelectFunction, MLPrefs.Directories);
        if isempty(MLConfig.CondSelectFunctionName),
            save(errorfile);
            error('*** Condition-selection function not found or is not an m-file ***');
        end
    else
        MLConfig.CondSelectFunctionName = '';
    end

    if MLConfig.BlockLogic == 5, %user-defined m-file
        MLConfig.BlockSelectFunctionName = prep_m_file(MLConfig.BlockSelectFunction, MLPrefs.Directories);
        if isempty(MLConfig.BlockSelectFunctionName),
            save(errorfile);
            error('*** Block-selection function not found or is not an m-file ***');
        end
    else
        MLConfig.BlockSelectFunctionName = '';
    end

    if ~isempty(MLConfig.BlockChangeFunction),
        MLConfig.BlockChangeFunctionName = prep_m_file(MLConfig.BlockChangeFunction, MLPrefs.Directories);
        if isempty(MLConfig.BlockChangeFunctionName),
            save(errorfile);
            error('*** Block Change function not found or is not an m-file ***');
        end
    else
        MLConfig.BlockChangeFunctionName = '';
    end
end

if ~isempty(MLConfig.UserPlotFunction),
    MLConfig.UserPlotFunctionName = prep_m_file(MLConfig.UserPlotFunction, MLPrefs.Directories);
    if isempty(MLConfig.UserPlotFunctionName),
        save(errorfile);
        error('*** User-Plot function not found or is not an m-file ***');
    end
else
    MLConfig.UserPlotFunctionName = '';
end

ResponseError = cell(numconds, 1); %to be list of response errors sorted by condition
OverAll = NaN*zeros(1, MLConfig.MaxTrials); %over-all performance regardless of condition
BlocksPlayed = zeros(1, MLConfig.MaxTrials); %to be list of selected blocks
ConditionsPlayed = zeros(1, MLConfig.MaxTrials); %to be list of selected conditions
ReactionTime = cell(numconds, 1);
RTall = NaN*zeros(1, MLConfig.MaxTrials);

%set up alerts and move relevant files to the run-time directory
MLConfig.Alerts.FunctionName = '';
MLConfig.Alerts.UserCriteriaFunctionName = '';
MLConfig.Alerts.WebPage.Enable = 0;
Instruction.Message = '';
Instruction.Command = ' ';
Instruction.Value = [];
if MLConfig.Alerts.Enable,
    if isempty(MLConfig.Alerts.AlertFunction),
        MLConfig.Alerts.Enable = 0;
        logger.info('monkeylogic.m', 'Warning: No alert function selected');
    else
        [pname fname ext] = fileparts(MLConfig.Alerts.AlertFunction);
        if strcmpi(ext, '.html') || strcmpi(ext, '.htm'),
            if exist('ftpinfo.txt', 'file'),
                fftp = fopen('ftpinfo.txt', 'r');
                try
                    MLConfig.Alerts.WebPage.Server = fgetl(fftp);
                    MLConfig.Alerts.WebPage.User = fgetl(fftp);
                    MLConfig.Alerts.WebPage.Pwd = fgetl(fftp);
                    MLConfig.Alerts.WebPage.PassCode = fgetl(fftp);
                    MLConfig.Alerts.WebPage.FTPdir = fgetl(fftp);
                    MLConfig.Alerts.WebPage.Enable = 1;
                catch
                    logger.info('monkeylogic.m', 'Warning: Unable to gather required ftp info from "ftpinfo.txt"');
                end
                fclose(fftp);
                if MLConfig.Alerts.WebPage.Enable,
                    mlwebsummary(1, MLConfig, [fname '.html']);
                end
            else
                logger.info('monkeylogic.m', 'Warning: No "ftpinfo.txt" file found for web updates...')
            end
            MLConfig.Alerts.Enable = 0; %so only perform web page updates.
        else
            MLConfig.Alerts.FunctionName = prep_m_file(MLConfig.Alerts.AlertFunction, MLPrefs.Directories);
            if isempty(MLConfig.Alerts.FunctionName),
                save(errorfile)
                error('*** Alert function not found or is not an m-file ***');
            end
            if MLConfig.Alerts.UserCriteria,
                if isempty(MLConfig.Alerts.UserCriteriaFunction),
                    MLConfig.Alerts.UserCriteria = 0;
                    logger.info('monkeylogic.m', 'Warning: No function selected for user-defined alerts');
                else
                    MLConfig.Alerts.UserCriteriaFunctionName = prep_m_file(MLConfig.Alerts.UserCriteriaFunction, MLPrefs.Directories);
                    if isempty(MLConfig.Alerts.UserCriteriaFunctionName),
                        save(errorfile)
                        error('*** User-defined alert function not found or is not an m-file ***');
                    end
                end
            end
        end
    end
end

logger.info('monkeylogic.m', '<<< MonkeyLogic >>> Initialized task parameters...')
drawnow;

% Get list of behavioral codes
codesfile = MLConfig.BehavioralCodesTextFile;
if exist(codesfile, 'file'),
    fidcodes = fopen(codesfile, 'r');
    if fidcodes < 0,
        save(errorfile);
        error('Error opening %s file', codesfile)
        BehavioralCodes = [];
    else
        logger.info('monkeylogic.m', sprintf('<<< MonkeyLogic >>> Reading behavioral codes file: %s...', codesfile))
        fgetl(fidcodes); %get & discard header
        count = 0;
        while ~feof(fidcodes),
            textline = fgetl(fidcodes);
            if length(textline) > 1;
                count = count + 1;
                textline = parse(textline);
                BehavioralCodes.CodeNumbers(count, 1) = str2double(textline(1, :));
                BehavioralCodes.CodeNames{count} = deblank(textline(2, :));
            end
        end
        fclose(fidcodes);
    end
	clear count codesfile header textline fidcodes;
else
	logger.info('monkeylogic.m', 'Warning: Behavioral codes text file not found...')
	BehavioralCodes = [];
end

% Open data file ("BHV" format)
logger.info('monkeylogic.m', sprintf('<<< MonkeyLogic >>> Opening %s...', datafile));
WriteData = struct([]);
if appendflag == 0,
    fidbhv = fopen(datafile, 'w');
else
    fidbhv = fopen(datafile, 'a');
end
if fidbhv == -1,
    save(errorfile);
    error('*** Unable to open data file: %s ***', datafile);
end
bhv_write(1, fidbhv, MLConfig, condfile, RunTimeFiles, Conditions, MLConfig.EyeTransform, MLConfig.JoyTransform);
logger.info('monkeylogic.m', sprintf('<<< MonkeyLogic >>> Initialized data file %s...', datafile));
MLConfig.DataFile = datafile;

% Set up subject screen parameters
ScreenInfo.Device = MLConfig.VideoDevice;
ScreenInfo.RefreshRate = MLConfig.RefreshRate;
ScreenInfo.Xsize = xs;
ScreenInfo.Ysize = ys;
ScreenInfo.ModVal = 64;
ScreenInfo.BufferPages = MLConfig.BufferPages;
ScreenInfo.PixelsPerDegree = MLConfig.PixelsPerDegree;
ScreenInfo.Xdegrees = ScreenInfo.Xsize / ScreenInfo.PixelsPerDegree;
ScreenInfo.Ydegrees = ScreenInfo.Ysize / ScreenInfo.PixelsPerDegree;
ScreenInfo.PixelsPerPoint = get(0, 'ScreenPixelsPerInch')/72; %1 point = 1/72 inch
ScreenInfo.PhotoDiode = MLConfig.PhotoDiode;
ScreenInfo.PhotoDiodeSize = MLConfig.PhotoDiodeSize;
ScreenInfo.UseRawEyeSignal = MLConfig.UseRawEyeSignal; %use raw input signal (i.e., pre-calibrated eyetrace or joystick)
if isempty(MLConfig.EyeTransform),
    ScreenInfo.UseRawEyeSignal = 1;
end
ScreenInfo.UseRawJoySignal = MLConfig.UseRawJoySignal; %use raw input signal (i.e., pre-calibrated eyetrace or joystick)
if isempty(MLConfig.JoyTransform),
    ScreenInfo.UseRawJoySignal = 1;
end
ScreenInfo.UseRawTouchSignal = 0; %use raw input signal (i.e., pre-calibrated touchscreen)
ScreenInfo.UseRawMouseSignal = 0; %use raw input signal (i.e., pre-calibrated mouse)
ScreenInfo.UpdateInterval = MLConfig.UpdateInterval;
%%
ScreenInfo.EyeTraceColor = MLConfig.EyeTraceColor;
ScreenInfo.EyeTraceSize = MLConfig.EyeTraceSize;
ScreenInfo.EyeTargetColor = 0.5*MLConfig.EyeTraceColor;
ScreenInfo.EyeTargetLinewidth = 2;
%%
ScreenInfo.JoyTraceColor = MLConfig.JoyTraceColor;
ScreenInfo.JoyTraceSize = MLConfig.JoyTraceSize;
ScreenInfo.JoyTargetColor = 0.5*MLConfig.JoyTraceColor;
ScreenInfo.JoyTargetLinewidth = 3;
%%
ScreenInfo.TouchTraceColor = MLConfig.JoyTraceColor;        % use Joystick setting
ScreenInfo.TouchTraceSize = MLConfig.JoyTraceSize;          % use Joystick setting
ScreenInfo.TouchTargetColor = 0.5*MLConfig.JoyTraceColor;   % use Joystick setting
ScreenInfo.TouchTargetLinewidth = 3;                        % use Joystick setting
%%
ScreenInfo.MouseTraceColor = MLConfig.JoyTraceColor;        % use Joystick setting
ScreenInfo.MouseTraceSize = MLConfig.JoyTraceSize;          % use Joystick setting
ScreenInfo.MouseTargetColor = 0.5*MLConfig.JoyTraceColor;   % use Joystick setting
ScreenInfo.MouseTargetLinewidth = 3;                        % use Joystick setting

ScreenInfo.OutOfBounds = 2*max([ScreenInfo.Xsize ScreenInfo.Ysize])/ScreenInfo.PixelsPerDegree;
ScreenInfo.FixationSpotImageFile = MLConfig.FixationSpotImageFile;
ScreenInfo.ShowCursor = 0;
ScreenInfo.CursorImageFile = MLConfig.CursorImageFile;
ScreenInfo.BackgroundColor = MLConfig.ScreenBackgroundColor;
ScreenInfo.UsePreProcessedImages = 1; %for initialization - will assign real value after that.
ScreenInfo.IsActive = 0;

% load FixationPoint image data (in variable "imdata")
if strcmpi(ScreenInfo.FixationSpotImageFile, 'DEFAULT') || ~exist(ScreenInfo.FixationSpotImageFile, 'file'),
    imdata = makecircle(4.5, [1 1 1], 1, ScreenInfo.BackgroundColor);
else
    imdata = imread(ScreenInfo.FixationSpotImageFile);
    imdata(:, :, 1) = imdata(:, :, 1)*(1-ScreenInfo.BackgroundColor(1)) + ScreenInfo.BackgroundColor(1);
    imdata(:, :, 2) = imdata(:, :, 2)*(1-ScreenInfo.BackgroundColor(2)) + ScreenInfo.BackgroundColor(2);
    imdata(:, :, 3) = imdata(:, :, 3)*(1-ScreenInfo.BackgroundColor(3)) + ScreenInfo.BackgroundColor(3);
end
ScreenInfo.FixationPoint = imdata;

% Initialize Control Screen:
ScreenInfo.ControlScreenHandle = initcontrolscreen(1, ScreenInfo, MLConfig);
ScreenInfo.ControlScreenRatio = get(gcf, 'userdata');
blankstring = get(findobj(ScreenInfo.ControlScreenHandle, 'tag', 'conderrors'), 'userdata');
blankstring = cellstr(repmat(blankstring, numconds, 1));
set(findobj(ScreenInfo.ControlScreenHandle, 'tag', 'conderrors'), 'userdata', blankstring);
drawnow;

% Initialize I/O
[DaqInfo DaqError] = initio(MLConfig.InputOutput);
if ~isempty(DaqError),
    daqreset;
    clear DaqInfo
    for i = 1:length(DaqError),
        logger.info('monkeylogic.m', DaqError{i});
        save(errorfile);
        error('*** DAQ initialization error ***');
    end
    return
end
DaqInfo.StrobeBitEdge = MLConfig.StrobeBitEdge;
EyeSignalInUse = ~ScreenInfo.UseRawEyeSignal && ~isempty(DaqInfo.EyeSignal);
JoystickInUse = ~ScreenInfo.UseRawJoySignal && ~isempty(DaqInfo.Joystick);
TouchscreenInUse = ~ScreenInfo.UseRawTouchSignal && ~isempty(DaqInfo.TouchSignal);
MouseInUse = ~ScreenInfo.UseRawMouseSignal && ~isempty(DaqInfo.MouseSignal);
logger.info('monkeylogic.m', '<<< MonkeyLogic >>> Successfully completed initializing I/O.');
drawnow;

% Initialize reward
goodmonkey(-1,DaqInfo);

% Initialize keyboard
mlkbd('init');

% Initialize Video
ScreenInfo.BytesPerPixel = 4;
ScreenInfo.Half_xs = round(xs/2);
ScreenInfo.Half_ys = round(ys/2);

logger.info('monkeylogic.m', '<<< MonkeyLogic >>> Video graphics initialization started...');

ScreenInfo = init_video(ScreenInfo);
if ~ScreenInfo.IsActive,
    error_escape(ScreenInfo, DaqInfo, fidbhv);
    clear DaqInfo
    save(errorfile);
    error('*** Video Initialization Error ***')
end
logger.info('monkeylogic.m', '<<< MonkeyLogic >>> Video graphics initialization completed successfully.')

% per MS: calculate video frame length for use with movies...
logger.info('monkeylogic.m', '<<< MonkeyLogic >>> Calculating video frame length...')
numframes = 10;
flength = zeros(numframes, 2);
k = 1000;
while mlvideo('verticalblank', ScreenInfo.Device), end
tic;
for i = 1:numframes,
    while ~mlvideo('verticalblank', ScreenInfo.Device), end
    flength(i, 1) = k*toc;
    while mlvideo('verticalblank', ScreenInfo.Device), end
    flength(i, 2) = k*toc;
end
ScreenInfo.FrameLength = mean(mean(diff(flength(2:numframes, :))));
logger.info('monkeylogic.m', sprintf('...Average video frame length = %2.3f ms', ScreenInfo.FrameLength));
drawnow;

available_blocks = MLConfig.RunBlocks;

TrialRecord.CurrentTrialNumber = 0;
TrialRecord.CurrentTrialWithinBlock = 0;
TrialRecord.CurrentCondition = [];
TrialRecord.CurrentBlock = [];
TrialRecord.CurrentBlockCount = [];
TrialRecord.ConditionsPlayed = [];
TrialRecord.ConditionsThisBlock = [];
TrialRecord.BlocksPlayed = [];
TrialRecord.BlockCount = [];
TrialRecord.BlocksSelected = available_blocks;
TrialRecord.TrialErrors = [];
TrialRecord.ReactionTimes = [];
TrialRecord.LastTrialAnalogData.EyeSignal = [];
TrialRecord.LastTrialAnalogData.Joystick = [];
TrialRecord.LastTrialAnalogData.TouchSignal = [];
TrialRecord.LastTrialAnalogData.MouseSignal = [];
TrialRecord.LastTrialCodes.CodeNumbers = [];
TrialRecord.LastTrialCodes.CodeTimes = [];
TrialRecord.DataFile = datafile;
TrialRecord.SimulationMode = 0;

AllCodes.CodeNumbers = [];

% Initialize Timing Files
if strcmpi(RunTimeFiles{1}, 'blank'),   %CPS
    [C timingfile TrialRecord varargout] = feval(userloopfunction, ScreenInfo, DaqInfo, TrialRecord);
    RunTimeFiles{1} = embedtimingfile(timingfile, 'trialholder.m');
end
C = initstim('initializing.avi', ScreenInfo);
[TaskObject ScreenInfo.ActiveVideoBuffers] = create_taskobjects(C, ScreenInfo, DaqInfo, TrialRecord, MLPrefs.Directories, fidbhv);
TaskObject = initcontrolscreen(2, ScreenInfo, TaskObject);
for i = 1:length(TaskObject),
    set(TaskObject(i).ControlObjectHandle, 'markeredgecolor', [0 0 0]);
end
TempScreenInfo = ScreenInfo;
%TempScreenInfo.BackgroundColor = [0 0 0];
trialtype = 1;

logger.info('monkeylogic.m', '<<< MonkeyLogic >>> Initialization trial starting...');

disable_cursor;
disable_syskeys;
try
    for i = 1:length(RunTimeFiles),
        [pname timingfile] = fileparts(RunTimeFiles{i});
        feval(timingfile, TaskObject, TempScreenInfo, DaqInfo, MLConfig.EyeTransform, MLConfig.JoyTransform, BehavioralCodes, TrialRecord, trialtype);
    end
catch ME
    fprintf('<<<*** MonkeyLogic ***>>> Initialization Error\n%s\n',getReport(ME));
    cd(MLPrefs.Directories.BaseDirectory);
    enable_cursor;
    enable_syskeys;
    error_escape(ScreenInfo, DaqInfo, fidbhv);
    clear DaqInfo
    save(errorfile);
    return
end
enable_cursor;
enable_syskeys;
clear TempScreenInfo C ssfile
close_video(ScreenInfo, 'BuffersOnly');
logger.info('monkeylogic.m', sprintf('<<< MonkeyLogic >>> Successfully initialized Timing Files.'))

if MLConfig.PreloadVideo,
    [preloaded ScreenInfo.PreloadedVideoBuffers] = preload_videos(Conditions,ScreenInfo);
    fprintf('<<< MonkeyLogic >>> Successfully preloaded video files.\n');
else
    preloaded = [];
end

% Check to see if this run is simply a time-test...
if thisisonlyatest, 
    logger.info('monkeylogic.m', '<<< MonkeyLogic >>> Initializing Latency Test...')
    C(1) = initstim('benchmarkpic.jpg', ScreenInfo);
    C(2) = initstim('initializing.avi', ScreenInfo);
    [TaskObject ScreenInfo.ActiveVideoBuffers] = create_taskobjects(C, ScreenInfo, DaqInfo, TrialRecord, MLPrefs.Directories, fidbhv);
    TaskObject = initcontrolscreen(2, ScreenInfo, TaskObject);
    tfile = [MLPrefs.Directories.BaseDirectory 'mltimetest.m'];
    timingfile = embedtimingfile(tfile, 'trialholder.m');
    [pname timingfile] = fileparts(timingfile);
    TempScreenInfo = ScreenInfo;
    TempScreenInfo.BackgroundColor = [0 0 0];
    trialtype = 2;
    try
        TrialData = feval(timingfile, TaskObject, TempScreenInfo, DaqInfo, MLConfig.EyeTransform, MLConfig.JoyTransform, BehavioralCodes, TrialRecord, trialtype);
        varargout{1} = TrialData;
    catch
        error_escape(ScreenInfo, DaqInfo, fidbhv);
        clear DaqInfo
        save(errorfile);
        logger.info('monkeylogic.m', '<<<*** MonkeyLogic ***>>> Error running latency test')
        varargout{1} = [];
        return
    end
    mlkbd('release');
    close_video(ScreenInfo);
    close_daq(DaqInfo);
    fclose(fidbhv);
    rmpath(MLPrefs.Directories.RunTimeDirectory);
    logger.info('monkeylogic.m', '<<< MonkeyLogic >>>  Done.')
    return
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% TASKLOOP %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
trialtype = 0;
ScreenInfo.UsePreProcessedImages = MLConfig.UsePreProcessedImages;
logger.info('monkeylogic.m', sprintf('<<< MonkeyLogic >>> BHV File: %s. Started running trials at %s...', datafile, datestr(rem(now, 1))));
[pname fname] = fileparts(datafile);
set(findobj('tag', 'mlmonitor'), 'name', sprintf('MonkeyLogic: %s Started running trials at %s  %s', fname, datestr(rem(now, 1)), datestr(date)));
drawnow;
if MLConfig.Alerts.Enable,
    success = monkeylogic_alert(2, sprintf('Started running trials at %s %s', datestr(rem(now, 1)), datestr(date)), MLConfig.Alerts);
    if ~success,
        logger.info('monkeylogic.m', 'Warning: Unable to send alerts...')
    end
end

pausechangeblock = 0;
blockcounter = 0;
TrialRecord.RecentReset = 1;
TrialRecord.CurrentTrialNumber = 0;

disable_cursor;
disable_syskeys;
try
%%%%% Start Monkeylogic in escape menu
maxtrialsholder = -1;
[ScreenInfo, MLConfig, UserChanges] = check_keyboard(MLConfig, EyeSignalInUse, JoystickInUse, ScreenInfo, DaqInfo, TrialRecord, Instruction);
if UserChanges.NewBlock,
    block = UserChanges.NewBlock;
    pausechangeblock = 1;
end
if UserChanges.ErrorHandler,
    MLConfig.ErrorLogic = UserChanges.ErrorHandler;
end
if UserChanges.ITI,
    MLConfig.InterTrialInterval = UserChanges.ITI;
end
if UserChanges.MaxBlocks,
    MLConfig.MaxBlocks = UserChanges.MaxBlocks;
end
if UserChanges.MaxTrials,
    MLConfig.MaxTrials = UserChanges.MaxTrials;
end
if UserChanges.QuitFlag,
    maxtrialsholder = MLConfig.MaxTrials;
	MLConfig.MaxTrials = 0;
end
if UserChanges.SimulationMode == 0,
    TrialRecord.SimulationMode = 0;
end
if UserChanges.SimulationMode == 1,
    TrialRecord.SimulationMode = 1;
end
%%%%%

for trial = 1:MLConfig.MaxTrials,
	
	TrialRecord.CurrentTrialNumber = trial;
	
    if ~userdefinedtaskloop,
        %% Select Block
        if trial == 1,
            trialsperblock = 0;
            trialsthisblock = 0;
            lastcond = 0;
            lasterror = 0;
            block = MLConfig.FirstBlock;
            TrialData = struct;
        end

        selectednexttrial = 0;
        while selectednexttrial == 0,
            bswitchflag = 0;
            if pausechangeblock,
                userblockalreadychosen = 1;
                trialsthisblock = 0;
            else
                userblockalreadychosen = 0;
            end
            repeatflag = 0;
            if lasterror && ~pausechangeblock,
                switch MLConfig.ErrorLogic
                    case 1 % ignore
                        %do nothing
                    case 2 % repeat immediately
                        cond = lastcond;
                        block = lastblock;
                        repeatflag = 1;
                        trialsperblock = trialsperblock + 1;
                    case 3 % repeat delayed
                        possconds(length(possconds) + 1) = lastcond;
                        if ~MLConfig.CountOnlyCorrect,
                            trialsperblock = trialsperblock + 1;
                        end
                end
			end

            if ~isempty(MLConfig.BlockChangeFunctionName) && trial > 1 && ~pausechangeblock,
                try
                    bswitchflag = feval(MLConfig.BlockChangeFunctionName, TrialRecord);
                    if isempty(bswitchflag),
                        bswitchflag = 0;
                    end
                catch
                    if trial > 1,
                        bhv_write(3, fidbhv, AllCodes, BehavioralCodes, trial-1);
                    end
                    cd(MLPrefs.Directories.BaseDirectory);
                    enable_cursor;
                    enable_syskeys;
                    mlhelper_stop;
                    monkeylogic_alert(4, 'Error in user-defined Block-Change function', MLConfig.Alerts);
                    logger.info('monkeylogic.m', '<<<*** MonkeyLogic ***>>> Error in user-defined Block-Change function')
                    error_escape(ScreenInfo, DaqInfo, fidbhv);
                    clear DaqInfo
                    save(errorfile);
                    return
                end
                if bswitchflag,
                    trialsperblock = trialsthisblock;
                    if strcmpi(MLConfig.BlockSelectFunctionName, MLConfig.BlockChangeFunctionName),
                        block = bswitchflag;
                        possconds = BlockTypes{block};
                        userblockalreadychosen = 1;
                    end
                else
                    trialsperblock = Inf;
                end
            end
            
            %%%%%
            if MLConfig.CountOnlyCorrect,
                trialcount = sum(OverAll(trial-trialsthisblock:trial-1) == 0);
            else
                trialcount = trialsthisblock;
            end
            %%%%%
			if ((~repeatflag && trialcount == trialsperblock && ~userblockalreadychosen) || trial == 1) || bswitchflag %if block > 0, FirstBlock was set, so use that...
                switch MLConfig.BlockLogic,
                    case 1 % Random with replacement
                        if trial > 1 || (trial == 1 && block == 0),
                            block = MLConfig.RunBlocks(ceil(rand(1) * length(MLConfig.RunBlocks)));
                        end
                    case 2 % Random without replacement
                        numblocks_remaining = length(available_blocks);
                        if numblocks_remaining == 1,
                            if trial > 1 || (trial == 1 && block == 0),
                                block = available_blocks(1);
                            end
                            available_blocks = MLConfig.RunBlocks; %replenish
                        else
                            if trial > 1 || (trial == 1 && block == 0),
                                indx = ceil(rand(1) * numblocks_remaining);
                                block = available_blocks(indx);
                                %this makes certain 1st block of new set is not equal to last block of last set:
                                if ~isempty(lastblock) && length(MLConfig.RunBlocks) > 1 && numblocks_remaining == length(MLConfig.RunBlocks),
                                    while block == lastblock,
                                        indx = ceil(rand(1) * numblocks_remaining);
                                        block = available_blocks(indx);
                                    end
                                end
                            else
                                indx = find(available_blocks == block);
                            end
                            available_blocks = available_blocks(available_blocks ~= available_blocks(indx));
                        end
                    case 3 % Increasing block order
                        if trial > 1 || (trial == 1 && block == 0),
                            indx = find(MLConfig.RunBlocks == block);
                            if isempty(indx) || indx == length(MLConfig.RunBlocks),
                                indx = 0;
                            end
                            indx = indx + 1;
                            block = MLConfig.RunBlocks(indx);
                        end
                    case 4 % Decreasing block order
                        if trial > 1 || (trial == 1 && block == 0),
                            indx = find(MLConfig.RunBlocks == block);
                            if isempty(indx) || indx == 1,
                                indx = length(MLConfig.RunBlocks) + 1;
                            end
                            indx = indx - 1;
                            block = MLConfig.RunBlocks(indx);
                        end
                    case 5 % User-defined m-file
                        if trial > 1 || (trial == 1 && block == 0),
                            try
                                block = feval(MLConfig.BlockSelectFunctionName, TrialRecord);
                            catch
                                if trial > 1,
                                    bhv_write(3, fidbhv, AllCodes, BehavioralCodes, trial-1);
                                end
                                save(errorfile);
                                cd(MLPrefs.Directories.BaseDirectory);
                                enable_cursor;
                                enable_syskeys;
                                monkeylogic_alert(4, 'Block selection error in user-defined function', MLConfig.Alerts);
                                logger.info('monkeylogic.m', '<<<*** MonkeyLogic ***>>> Block selection error in user-defined function')
                                error_escape(ScreenInfo, DaqInfo, fidbhv);
                                clear DaqInfo
                                save(errorfile);
                                return
                            end
                            if block > length(MLConfig.BlockLength),
                                if trial > 1,
                                    bhv_write(3, fidbhv, AllCodes, BehavioralCodes, trial-1);
                                end
                                save(errorfile);
                                enable_cursor;
                                enable_syskeys;
                                monkeylogic_alert(4, 'Error: selected block does not exist', MLConfig.Alerts);
                                logger.info('monkeylogic.m', '<<<*** MonkeyLogic ***>>> Error: selected block does not exist')
                                error_escape(ScreenInfo, DaqInfo, fidbhv);
                                clear DaqInfo
                                save(errorfile);
                                return
                            end
                        end
                end
                if block == 0, %re-select last block
                    if trial == 1,
                        block = MLConfig.RunBlocks(1);
                    else
                        block = TrialRecord.BlocksPlayed(trial-1);
                    end
                elseif block == -1, %end task
                    blockcounter = MLConfig.MaxBlocks + 1;
                end

                blockcounter = blockcounter + 1;
                if blockcounter > MLConfig.MaxBlocks,
                    break
                end
                
                BlockPerformance = NaN*zeros(MLConfig.MaxTrials, 1);
                trialsperblock = MLConfig.BlockLength(block);
                trialsthisblock = 0;
                possconds = BlockTypes{block};

                if blockcounter > 1,
                    monkeylogic_alert(1, TrialRecord, MLConfig.Alerts);
                end

			end
            
			if pausechangeblock,
                BlockPerformance = NaN*zeros(MLConfig.MaxTrials, 1);
                trialsperblock = MLConfig.BlockLength(block);
                possconds = BlockTypes{block};
			end

            TrialRecord.CurrentBlock = block;
            TrialRecord.CurrentTrialWithinBlock = trialsthisblock + 1;
            TrialRecord.CurrentBlockCount = blockcounter;
            TrialRecord.ConditionsThisBlock = possconds;

            if ~repeatflag,
                switch MLConfig.CondLogic,
                    case 1 % Random with replacement
                        cond = possconds(ceil(rand(1) * length(possconds)));
                    case 2 % Random without replacement
                        if length(possconds) == 1,
                            cond = possconds(1);
                            possconds = BlockTypes{block}; %replenish
                        else
                            indx = ceil(rand(1) * length(possconds));
                            cond = possconds(indx);
                            f = find(possconds == cond, 1); %find first instance of match, so as to only delete one element
                            possconds = possconds(1:length(possconds) ~= f);
                        end
                    case 3 % Increasing cond order
                        if block == lastblock,
                            cond = lastcond + 1;
                            if cond > max(possconds),
                                cond = min(possconds);
                            end
                        else
                            cond = min(possconds);
                        end
                    case 4 % Decreasing cond order
                        if block == lastblock,
                            cond = lastcond - 1;
                            if cond < min(possconds),
                                cond = max(possconds);
                            end
                        else
                            cond = max(possconds);
                        end
                    case 5 % User-defined m-file
                        try
                            chosencond = feval(MLConfig.CondSelectFunctionName, TrialRecord);
                        catch ME
                            if trial > 1,
                                bhv_write(3, fidbhv, AllCodes, BehavioralCodes, trial-1);
                            end
                            cd(MLPrefs.Directories.BaseDirectory);
                            enable_cursor;
                            enable_syskeys;
                            mlhelper_stop;
                            fprintf('<<<*** MonkeyLogic ***>>> Condition selection error in user-defined function\n%s\n',getReport(ME));
                            monkeylogic_alert(4, 'Condition selection error in user-defined function', MLConfig.Alerts);
                            error_escape(ScreenInfo, DaqInfo, fidbhv);
                            clear DaqInfo
                            save(errorfile);
                            return
                        end
                        cond = find(originalcond == chosencond);
                        if isempty(cond),
                            error_escape(ScreenInfo, DaqInfo, fidbhv);
                            clear DaqInfo
                            save(errorfile);
                            error('*** User-selected condition #%i not found ***', chosencond);
                        end
                        cond = cond(1);
                end
                f = findobj(ScreenInfo.ControlScreenHandle, 'tag', 'conderrors');
                errorlist = get(f, 'userdata');
                errorlist = errorlist{originalcond(cond)};
                set(f, 'string', errorlist);
            end
            if block == -1, %such as could have been set by user-defined block-select function (instructs: end task)
                break
            elseif cond == -1, %such as could have been set by user-defined cond-select function (instructs: advance to next block)
                trialsperblock = trialsthisblock;
            else
                selectednexttrial = 1;
            end
        end

        TrialRecord.CurrentCondition = originalcond(cond);

        timingfile = TFiles{cond};
        timingfile = [timingfile(1:length(timingfile)-2) '_runtime']; %remove the ".m", add "_runtime"
        C = Conditions(cond).TaskObject;
    else %userloop, as per CPS, incorporated by WA
        cond = 1;
        originalcond = 1;
        block = 1;
        TrialRecord.CurrentBlock = block;
        TrialRecord.CurrentTrialWithinBlock = trial;
        TrialRecord.CurrentBlockCount = 1;
        TrialRecord.ConditionsThisBlock = cond;
        BlockPerformance = NaN*zeros(MLConfig.MaxTrials, 1);
        
        try
            [C timingfile TrialRecord varargout] = feval(userloopfunction, ScreenInfo, DaqInfo, TrialRecord); 
        catch ME
            if trial > 1,
                bhv_write(3, fidbhv, AllCodes, BehavioralCodes, trial-1);
            end
            cd(MLPrefs.Directories.BaseDirectory);
            enable_cursor;
            enable_syskeys;
            mlhelper_stop;
            fprintf('<<<*** MonkeyLogic ***>>> User-Loop Error\n%s\n',getReport(ME));
            monkeylogic_alert(4, 'User-Loop Error: Task Halted', MLConfig.Alerts);
            error_escape(ScreenInfo, DaqInfo, fidbhv);
            clear DaqInfo
            save(errorfile);
            return
        end
        if ~isempty(varargout), %third output is a custom version of "trialholder.m"
            tholder = [MLPrefs.Directories.ExperimentDirectory varargout{1} '.m'];
        else
            tholder = 'trialholder.m';
        end
        try
            tfile = [MLPrefs.Directories.ExperimentDirectory timingfile];
            tfile = embedtimingfile(tfile, tholder);
        catch ME
            if trial > 1,
                bhv_write(3, fidbhv, AllCodes, BehavioralCodes, trial-1);
            end
            cd(MLPrefs.Directories.BaseDirectory);
            enable_cursor;
            enable_syskeys;
            mlhelper_stop;
            fprintf('<<<*** MonkeyLogic ***>>> User-Loop Error\n%s\n',getReport(ME));
            monkeylogic_alert(4, 'Unable to embed user-specified timing script', MLConfig.Alerts);
            error_escape(ScreenInfo, DaqInfo, fidbhv);
            clear DaqInfo
            save(errorfile);
            return
        end
        [pname timingfile] = fileparts(tfile);
    end    
    
    %update monitor stats
    set(findobj(ScreenInfo.ControlScreenHandle, 'tag', 'blockno'), 'string', num2str(block));
    set(findobj(ScreenInfo.ControlScreenHandle, 'tag', 'condno'), 'string', num2str(originalcond(cond)));
    set(findobj(ScreenInfo.ControlScreenHandle, 'tag', 'trialno'), 'string', num2str(trial));
    set(findobj(ScreenInfo.ControlScreenHandle, 'tag', 'trialsthisblock'), 'string', num2str(trialsthisblock));
    set(findobj(ScreenInfo.ControlScreenHandle, 'tag', 'numblocksplayed'), 'string', num2str(blockcounter-1));
    set(findobj(ScreenInfo.ControlScreenHandle, 'tag', 'numcorrect'), 'string', num2str(sum(OverAll(1:trial) == 0)));
    set(findobj(ScreenInfo.ControlScreenHandle, 'tag', 'tfile'), 'string', timingfile);
	set(findobj(ScreenInfo.ControlScreenHandle, 'tag', 'eventlist'), 'string', '');
    
    trialsthisblock = trialsthisblock + 1;
    
    if trial > 1,
        denom = trial-1;
        overall_perfarray = zeros(12,1);
        for p = 0:11,
            overall_perfarray(p+1,1) = sum(OverAll(1:trial) == p)/denom;
        end
        set(findobj(gcf, 'tag', 'overallcorrect'), 'string', sprintf('%i%% correct', round(100*(sum(OverAll(1:trial) == 0)/denom))));
    else
        overall_perfarray = nan(12,1);
        set(findobj(gcf, 'tag', 'overallcorrect'), 'string', '% correct');
    end
    if trial > TrialRecord.RecentReset,
        denom = trial-TrialRecord.RecentReset;
        recent_perfarray = zeros(12,1);
        for p = 0:11,
            recent_perfarray(p+1,1) = sum(OverAll(TrialRecord.RecentReset:trial) == p)/denom;
        end
        set(findobj(gcf, 'tag', 'recentcorrect'), 'string', sprintf('%i%% correct', round(100*(sum(OverAll(TrialRecord.RecentReset:trial) == 0)/denom))));
    else
        recent_perfarray = nan(12,1);
        set(findobj(gcf, 'tag', 'recentcorrect'), 'string', '% correct');
    end
    if ~any(~isnan(BlockPerformance)),
        block_perfarray = nan(12,1);
        set(findobj(gcf, 'tag', 'blockcorrect'), 'string', '% correct');
    else
        denom = sum(~isnan(BlockPerformance));
        block_perfarray = zeros(12,1);
        for p = 0:11,
            block_perfarray(p+1,1) = sum(BlockPerformance(1:trialsthisblock) == p)/denom;
        end
        set(findobj(gcf, 'tag', 'blockcorrect'), 'string', sprintf('%i%% correct', round(100*(sum(BlockPerformance(1:trialsthisblock) == 0)/denom)))); 
    end
    trialsthiscond = length(ResponseError{originalcond(cond)});
    if trialsthiscond > 1,
        condperf = ResponseError{originalcond(cond)};
        denom = length(condperf);
        cond_perfarray = zeros(12,1);
        for p = 0:11,
            cond_perfarray(p+1,1) = sum(condperf == p)/denom;
        end
        set(findobj(gcf, 'tag', 'condcorrect'), 'string', sprintf('%i%% correct', round(100*(sum(condperf == 0)/denom))));
    else
        cond_perfarray = nan(12,1);
        set(findobj(gcf, 'tag', 'condcorrect'), 'string', '% correct');
    end
    initcontrolscreen(3, [overall_perfarray block_perfarray cond_perfarray recent_perfarray]);
    if isempty(MLConfig.UserPlotFunctionName),
        initcontrolscreen(5, RTall(1:trial), ReactionTime{originalcond(cond)});
    else
        initcontrolscreen(5, MLConfig.UserPlotFunctionName, TrialRecord);
    end
    TrialRecord.CurrentConditionInfo = Conditions(cond).Info;
    
    if MLConfig.PreloadVideo,
        pl = preloaded(cond,:);
    else
        pl = [];
    end
    
    % Generate / Load stimuli for this trial
    [TaskObject ScreenInfo.ActiveVideoBuffers StimulusInfo] = create_taskobjects(C, ScreenInfo, DaqInfo, TrialRecord, MLPrefs.Directories, fidbhv, pl);
    TrialRecord.CurrentConditionStimulusInfo = StimulusInfo;
    
    %prepare control window objects
    TaskObject = initcontrolscreen(2, ScreenInfo, TaskObject);
    
    %**********************************************************************
    %%%%%%%%%%%%%%%%%%%%%%%%%%%% Run trial %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %**********************************************************************
          
    if trial == 1,
        tic;
        TrialData.TrialExitTime = 0;
    end

    % Set process priority
    switch MLConfig.Priority,
        case 1,
            prtnormal;
        case 2,
            prthigh;
        case 3,
            prtrealtime;
    end
    ScreenInfo.Priority = MLConfig.Priority; %to pass to trial subfunctions
    
    iti_time = MLConfig.InterTrialInterval;
    if isfield(TrialData,'NewITI') && TrialData.NewITI >= 0,
        iti_time = TrialData.NewITI;
    end
    
    if toc*1000 > iti_time,
        iti_t = round(toc*1000);
        fprintf('*** Warning: Desired ITI exceeded (ITI ~= %i ms) ***\n', iti_t);
        initcontrolscreen(7, ScreenInfo, sprintf('Desired ITI exceeded (ITI ~= %i ms)', iti_t));
    else
        while toc*1000 < iti_time-TrialData.TrialExitTime, end %use up remaining ITI
    end
    set(findobj(ScreenInfo.ControlScreenHandle, 'tag', 'deadtimemarker'), 'backgroundcolor', [0 1 0]);
    
    try
        % Call trial, passing condition-specific info (stimuli, timing, etc).
        TrialData = feval(timingfile, TaskObject, ScreenInfo, DaqInfo, MLConfig.EyeTransform, MLConfig.JoyTransform, BehavioralCodes, TrialRecord, trialtype);
    catch ME
        if trial > 1,
            bhv_write(3, fidbhv, AllCodes, BehavioralCodes, trial-1);
        end
        cd(MLPrefs.Directories.BaseDirectory);
        enable_cursor;
        enable_syskeys;
        mlhelper_stop;
        fprintf('<<<*** MonkeyLogic ***>>> Timing File Execution Error\n%s\n',getReport(ME));
        monkeylogic_alert(4, 'Trial Execution Error: Task Halted', MLConfig.Alerts);
        error_escape(ScreenInfo, DaqInfo, fidbhv);
        clear DaqInfo
        save(errorfile);
        if MLConfig.Alerts.WebPage.Enable,
            mlwebsummary(2, TrialRecord, '*** Error ***');
            mlwebsummary(4);
        end
        
        return
    end
    tic; %start ITI counter
    
    % Restore default run-time priority
    prtnormal;
    
    MLConfig.EyeTransform = TrialData.NewTransform;
    TrialRecord = TrialData.TrialRecord;
    trialerror = TrialData.TrialError;
    Codes = TrialData.BehavioralCodes;
    reactiontime = TrialData.ReactionTime;
    %TrialData also includes ObjectStatusRecord
        
    if trial == 1,
        trackvarchanges(trial);
    end
    
    set(findobj(ScreenInfo.ControlScreenHandle, 'tag', 'deadtimemarker'), 'backgroundcolor', [1 0 0]);
    drawnow;
    
    % Release video buffers
    ScreenInfo = close_video(ScreenInfo, 'BuffersOnly');
    
    AllCodes.CodeNumbers = cat(1, AllCodes.CodeNumbers, Codes.CodeNumbers);
    AllCodes.CodeNumbers = unique(AllCodes.CodeNumbers);
    
    %Write Trial data
    WriteData(trial).AbsoluteTrialStartTime = TrialData.AbsoluteTrialStartTime;
    WriteData(trial).TrialNumber = trial;
    WriteData(trial).BlockNumber = block;
    WriteData(trial).CondNumber = originalcond(cond);
    WriteData(trial).TrialError = trialerror;
    WriteData(trial).NumCodes = length(Codes.CodeNumbers);
    WriteData(trial).CodeNumbers = {Codes.CodeNumbers};
    WriteData(trial).CodeTimes = {Codes.CodeTimes};
    WriteData(trial).EyeSignal = TrialData.AnalogData.EyeSignal;
    WriteData(trial).Joystick = TrialData.AnalogData.Joystick;
    WriteData(trial).TouchSignal = TrialData.AnalogData.TouchSignal;
    WriteData(trial).MouseSignal = TrialData.AnalogData.MouseSignal;
    WriteData(trial).PhotoDiode = TrialData.AnalogData.PhotoDiode;
    WriteData(trial).GeneralAnalog = TrialData.AnalogData.General;
    WriteData(trial).ReactionTime = reactiontime;
    WriteData(trial).ObjectStatusRecord = TrialData.ObjectStatusRecord;
    WriteData(trial).RewardRecord = TrialData.RewardRecord;
    WriteData(trial).CycleRate = TrialData.CycleRate;
    WriteData(trial).UserVars = TrialData.UserVars;
    
    bhv_write(2, fidbhv, WriteData(trial));
    
    lastcond = cond;
    lastblock = block;
    lasterror = trialerror;
    
    %Update "cycle rate" and "latency" indicators...
    set(findobj('tag', 'cyclerate'), 'string', sprintf('%i Hz', TrialData.CycleRate(2)));
    if TrialData.CycleRate(2) < 1000,
        set(findobj(gcf, 'tag', 'cyclerate'), 'backgroundcolor', [1 0 0]);
        set(findobj(gcf, 'tag', 'cyclerateframe'), 'backgroundcolor', [1 0 0]);
    else
        set(findobj(gcf, 'tag', 'cyclerate'), 'backgroundcolor', [.3 .3 .3]);
        set(findobj(gcf, 'tag', 'cyclerateframe'), 'backgroundcolor', [.3 .3 .3]);
    end
    
    set(findobj('tag', 'mincyclerate'), 'string', sprintf('%2.1f ms', 1000/TrialData.CycleRate(1)));
    if TrialData.CycleRate(1) < 500,
        set(findobj(gcf, 'tag', 'mincyclerate'), 'backgroundcolor', [1 0 0]);
        set(findobj(gcf, 'tag', 'mincyclerateframe'), 'backgroundcolor', [1 0 0]);
    else
        set(findobj(gcf, 'tag', 'mincyclerate'), 'backgroundcolor', [.3 .3 .3]);
        set(findobj(gcf, 'tag', 'mincyclerateframe'), 'backgroundcolor', [.3 .3 .3]);
    end
    
    %These arrays are used for displaying cond/block-specific performance and RTs
    ResponseError{originalcond(cond)} = [ResponseError{originalcond(cond)} trialerror];
    OverAll(trial) = trialerror;
    BlockPerformance(trialsthisblock) = trialerror;
    ConditionsPlayed(trial) = originalcond(cond);
    BlocksPlayed(trial) = block;
    ReactionTime{originalcond(cond)} = [ReactionTime{originalcond(cond)} reactiontime];
    RTall(trial) = reactiontime;
    
    %These arrays are passed to user functions (e.g., cond/block selection, stimulus-generation, timing file)
    TrialRecord.ConditionsPlayed = ConditionsPlayed(1:trial);
    TrialRecord.BlocksPlayed = BlocksPlayed(1:trial);
    TrialRecord.BlockCount = [TrialRecord.BlockCount blockcounter];
    TrialRecord.TrialErrors = [TrialRecord.TrialErrors trialerror];
    TrialRecord.ReactionTimes = RTall(1:trial);
    TrialRecord.LastTrialCodes.CodeNumbers = Codes.CodeNumbers;
    TrialRecord.LastTrialCodes.CodeTimes = Codes.CodeTimes;
    TrialRecord.LastTrialAnalogData = TrialData.AnalogData;
    bo = cat(2, 0, TrialRecord.BlocksPlayed);
    TrialRecord.BlockOrder = bo(find(diff(bo))+1);
    
    %update control screen error lists & time-line:
    update_error_lists(trialerror, originalcond, cond, ScreenInfo);
    initcontrolscreen(4, [Codes.CodeNumbers Codes.CodeTimes], BehavioralCodes, [trial originalcond(cond)]);
    
    %On-Line Eye Adjustments...
    if MLConfig.OnlineEyeAdjustment && ~trialerror && ~ScreenInfo.UseRawEyeSignal,
        if ~isempty(TrialData.AnalogData.EyeTargetList),
            fixtargets = TrialData.AnalogData.EyeTargetList;
        else
            fixtargets = Txy;
        end
        if MLConfig.UseFirstTargetOnly,
            config_fixtargets = fixtargets(1,:);
        else
            config_fixtargets = fixtargets;
        end
        newTform = adjust_eye_calibration(TrialData.AnalogData.EyeSignal, config_fixtargets, DaqInfo, MLConfig.EyeTransform, MLConfig.EyeAdjustFraction, MLConfig.FixDegrees, MLConfig.FixTime, MLConfig.EyeSmoothingSigma, MLConfig.EyeCalibrationTargets);
        if ~isempty(newTform),
            MLConfig.EyeTransform = newTform;
        end
    end

    %User-defined alerts...
    if MLConfig.Alerts.Enable && MLConfig.Alerts.UserCriteria,
        success = monkeylogic_alert(3, TrialRecord, MLConfig.Alerts);
        if ~success,
            logger.info('monkeylogic.m', sprintf('Warning: Unable to send user-defined alert...'))
        end
    end
        
    set(findobj(ScreenInfo.ControlScreenHandle, 'tag', 'deadtimemarker'), 'backgroundcolor', [1 1 0]);
    drawnow;
    UserChanges.QuitFlag = 0;
    pausechangeblock = 0;
    %%%%%%%%%% Easy-Escape
    TrialRecord.EscapeQueued = 0;
    if isfield(TrialData,'Escape') && TrialData.Escape,
        TrialRecord.EscapeQueued = 1;
    end
    %%%%%%%%%%
    while toc < 0.5 && ~UserChanges.QuitFlag, %will recognize keypresses within the first 500ms of the ITI
        [ScreenInfo, MLConfig, UserChanges] = check_keyboard(MLConfig, EyeSignalInUse, JoystickInUse, ScreenInfo, DaqInfo, TrialRecord, Instruction);
        TrialRecord.EscapeQueued = 0;
        if UserChanges.NewBlock,
            block = UserChanges.NewBlock;
            pausechangeblock = 1;
        end
        if UserChanges.ErrorHandler,
            MLConfig.ErrorLogic = UserChanges.ErrorHandler;
        end
        if UserChanges.ITI,
            MLConfig.InterTrialInterval = UserChanges.ITI;
        end
        if UserChanges.MaxBlocks,
            MLConfig.MaxBlocks = UserChanges.MaxBlocks;
        end
        if UserChanges.MaxTrials,
            MLConfig.MaxTrials = UserChanges.MaxTrials;
        end
        if UserChanges.RecentReset,
            TrialRecord.RecentReset = trial+1;
        end
        if UserChanges.SimulationMode == 0,
            TrialRecord.SimulationMode = 0;
        end
        if UserChanges.SimulationMode == 1,
            TrialRecord.SimulationMode = 1;
        end 
    end
    set(findobj(ScreenInfo.ControlScreenHandle, 'tag', 'deadtimemarker'), 'backgroundcolor', [1 0 0]);
    drawnow;
    if UserChanges.QuitFlag,
        break
    end
    
    %Web Page update via ftp
    if MLConfig.Alerts.WebPage.Enable,
        mlwebsummary(2, TrialRecord, 'Running...', Instruction.Message);
        if ~mod(trial, 10) || trial == 1,
            mlwebsummary(3, TrialRecord);
            mlwebsummary(4, 'UpdateFigure');
            if ~mod(trial, 100), 
                clc; %to clean up ftp output
            end
        else
            mlwebsummary(4);
        end
        
        commfile = [MLConfig.ComputerName 'command.txt'];
        RemoteCommand = [];
        if exist(commfile,'file'),
            fid2 = fopen(commfile, 'r+');
            if ~feof(fid2),
                RemoteCommand = fgetl(fid2);
            end
            fclose(fid2);
        end
        
        last_message = Instruction.Message;
        Instruction = parse_remote_command(RemoteCommand, MLConfig.Alerts.WebPage.PassCode, logger);
        if isempty(Instruction.Message),
            Instruction.Message = last_message;
        end
        [ScreenInfo, MLConfig, UserChanges] = check_keyboard(MLConfig, EyeSignalInUse, JoystickInUse, ScreenInfo, DaqInfo, TrialRecord, Instruction);
        if UserChanges.NewBlock,
            block = UserChanges.NewBlock;
            pausechangeblock = 1;
        end
        if UserChanges.ErrorHandler,
            MLConfig.ErrorLogic = UserChanges.ErrorHandler;
        end
        if UserChanges.ITI,
            MLConfig.InterTrialInterval = UserChanges.ITI;
        end
        if UserChanges.MaxBlocks,
            MLConfig.MaxBlocks = UserChanges.MaxBlocks;
        end
        if UserChanges.MaxTrials,
            MLConfig.MaxTrials = UserChanges.MaxTrials;
        end
    end
    Instruction.Command = ' ';
    Instruction.Value = [];
    if UserChanges.QuitFlag,
        break
    end
end

%%%%%%%%%%%%%%%%%% END TASKLOOP %%%%%%%%%%%%%%%%%%%%%
catch ME
    logger.info('monkeylogic.m', sprintf('<<<*** MonkeyLogic ***>>> Task Loop Execution Error\n%s',getReport(ME)));
    cd(MLPrefs.Directories.BaseDirectory);
    unclip_cursor;
    enable_cursor;
    enable_syskeys;
    mlhelper_stop;
    return
end
enable_cursor;
enable_syskeys;
mlhelper_stop;

if isempty(trial),
    trial = 0;
    if maxtrialsholder ~= -1,
        MLConfig.MaxTrials = maxtrialsholder;
    end
end

if trial == MLConfig.MaxTrials || blockcounter > MLConfig.MaxBlocks,
    cla;
    texth = text(0, 0, '- Done -');
    set(texth, 'color', [1 1 1], 'fontsize', 24, 'horizontalalignment', 'center');
    monkeylogic_alert(2, '<<< MonkeyLogic >>> Task Complete.', MLConfig.Alerts);
end

if MLConfig.Alerts.WebPage.Enable,
    mlwebsummary(2, TrialRecord, 'Done.');
    mlwebsummary(4, 'UpdateFigure');
end


% Close keyboard
mlkbd('release');

% Close Video
for i = 1:ScreenInfo.BufferPages,
    mlvideo('clear', ScreenInfo.Device, [0 0 0]);
    mlvideo('flip', ScreenInfo.Device);
end
close_video(ScreenInfo);

% Close DAQ
close_daq(DaqInfo);

% Close data file, clear record of variable changes, & remove runtime directory from path
bhv_write(3, fidbhv, AllCodes, BehavioralCodes, trial);
fclose(fidbhv);
trackvarchanges(-2);
rmpath(MLPrefs.Directories.RunTimeDirectory);

% Save MLConfig (signal transforms may have been altered during task)
save(cfgfile, 'MLConfig');

if trial ~= 0 && ~thisisonlyatest,
    RESULT.FinishTime = datestr(rem(now, 1));
    RESULT.CorrectTrials = sum(OverAll(1:trial) == 0);
    RESULT.TotalTrials = trial;
    figtitle = get(gcf, 'name');
    set(gcf, 'name', [figtitle '   Finished at ' RESULT.FinishTime]);
    logger.info('monkeylogic.m', sprintf('<<< MonkeyLogic >>> Finished running trials at %s.', RESULT.FinishTime))
    logger.info('monkeylogic.m', sprintf('<<< MonkeyLogic >>> Completed %i correct trials over %i total trials.', RESULT.CorrectTrials, RESULT.TotalTrials))
    set(findobj('tag', 'mlmessagebox'), 'string', sprintf('Completed %i correct trials over %i total trials.', RESULT.CorrectTrials, RESULT.TotalTrials));
    behaviorsummary('CurrentFile');
else
    RESULT = struct;
    set(findobj('tag', 'mlmessagebox'), 'string', 'Done.');
end

set(findobj('tag', 'runbutton'), 'enable', 'on');		%Enable the run button in the monkeylogic's main menu
varargout = {RESULT};



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [firstbuffer, lastbuffer, vbuffer, vbufnum, xis, yis, xscreenpos, yscreenpos, numframes] = buf_mov(name, xpos, ypos, vbuffer, vbufnum, ScreenInfo, pre, gen)

M = 0;
xis = 0;
yis = 0;
xisbuf = 0;
yisbuf = 0;
numframes = 0;

preprocessed = 0;

if gen                          % what to do in case the movie to be buffered is a matrix, not a file
    [~, xis, yis, xisbuf, yisbuf] = pad_image(name(:,:,:,1), ScreenInfo.ModVal, ScreenInfo.BackgroundColor);
    numframes = size(name, 4);
    M = uint32(zeros([xisbuf*yisbuf numframes]));

    firstbuffer = vbufnum + 1;
    for framenumber = 1:numframes,
        [imdata, xis, yis, xisbuf, yisbuf] = pad_image(name(:,:,:,framenumber), ScreenInfo.ModVal, ScreenInfo.BackgroundColor);   %#ok<NASGU,NASGU>
        imdata = double(imdata);
        if ~any(imdata(:) > 1),
            imdata = ceil(255*imdata);
        end
        imdata = uint32(xglrgb8(imdata(:, :, 1)', imdata(:, :, 2)', imdata(:, :, 3)'));
        vbuf = mlvideo('createbuffer', ScreenInfo.Device, xisbuf, yisbuf, ScreenInfo.BytesPerPixel);
        mlvideo('copybuffer', ScreenInfo.Device, vbuf, imdata, ScreenInfo.BackgroundColor);
        vbufnum = vbufnum + 1;
        vbuffer(vbufnum) = vbuf;
    end
    lastbuffer = vbufnum;
    
    xoffset = round(xis/2);
    yoffset = round(yis/2);
    xscreenpos = ScreenInfo.Half_xs + round(ScreenInfo.PixelsPerDegree * xpos) - xoffset;
    yscreenpos = ScreenInfo.Half_ys - round(ScreenInfo.PixelsPerDegree * ypos) - yoffset; %invert so that positive y is above the horizone

    if xscreenpos + xis > ScreenInfo.Xsize || yscreenpos + yis > ScreenInfo.Ysize || xscreenpos < 0 || yscreenpos < 0,
        error('*** MonkeyLogic Error: Movie "%s" is placed outside of screen pixel boundaries', name);
    end
end
     
if pre && ~gen,
    [pname fname] = fileparts(name);
    file = [pname filesep fname '_preprocessed.mat'];
    if exist(file, 'file'),
        MovFile = load(file);
        M = MovFile.M;
        xisbuf = MovFile.xisbuf;
        yisbuf = MovFile.yisbuf;
        xis = MovFile.xis;
        yis = MovFile.yis;
        numframes = size(M,2);
        preprocessed = 1;

        firstbuffer = vbufnum + 1;
        for fnum = 1:numframes,
            imdata = M(:,fnum);
            vbuf = mlvideo('createbuffer', ScreenInfo.Device, xisbuf, yisbuf, ScreenInfo.BytesPerPixel);
            mlvideo('copybuffer', ScreenInfo.Device, vbuf, imdata, ScreenInfo.BackgroundColor);
            vbufnum = vbufnum + 1;
            vbuffer(vbufnum) = vbuf;
        end
        lastbuffer = vbufnum;
        
        xoffset = round(xis/2);
        yoffset = round(yis/2);
        xscreenpos = ScreenInfo.Half_xs + round(ScreenInfo.PixelsPerDegree * xpos) - xoffset;
        yscreenpos = ScreenInfo.Half_ys - round(ScreenInfo.PixelsPerDegree * ypos) - yoffset; %invert so that positive y is above the horizone

        if xscreenpos + xis > ScreenInfo.Xsize || yscreenpos + yis > ScreenInfo.Ysize || xscreenpos < 0 || yscreenpos < 0,
            error('*** MonkeyLogic Error: Movie "%s" is placed outside of screen pixel boundaries', name);
        end
    else
        j=1;
        file = [pname filesep fname sprintf('_preprocessed%i.mat',j)];
        if exist(file, 'file'),
            numframes = 0;
            firstbuffer = vbufnum + 1;
            while exist(file, 'file');
            	load(file); %gets M, xis, yis, xisbuf, yisbuf
                thisnumframes = size(M,2);
                
                for fnum = 1:thisnumframes,
                    imdata = M(:,fnum);
                    vbuf = mlvideo('createbuffer', ScreenInfo.Device, xisbuf, yisbuf, ScreenInfo.BytesPerPixel);
                    mlvideo('copybuffer', ScreenInfo.Device, vbuf, imdata, ScreenInfo.BackgroundColor);
                    vbufnum = vbufnum + 1;
                    vbuffer(vbufnum) = vbuf;
                end
                
                numframes = numframes + thisnumframes;
                j = j + 1;
                file = [pname filesep fname sprintf('_preprocessed%i.mat',j)];
            end
            lastbuffer = vbufnum;
            preprocessed = 1;
            
            xoffset = round(xis/2);
            yoffset = round(yis/2);
            xscreenpos = ScreenInfo.Half_xs + round(ScreenInfo.PixelsPerDegree * xpos) - xoffset;
            yscreenpos = ScreenInfo.Half_ys - round(ScreenInfo.PixelsPerDegree * ypos) - yoffset; %invert so that positive y is above the horizone

            if xscreenpos + xis > ScreenInfo.Xsize || yscreenpos + yis > ScreenInfo.Ysize || xscreenpos < 0 || yscreenpos < 0,
                error('*** MonkeyLogic Error: Movie "%s" is placed outside of screen pixel boundaries', name);
            end
            
        else
            fprintf('Warning: unable to find preprocessed movie file %s\n', file);
        end
    end
end
if ~preprocessed && ~gen,
    file = name;
    if ischar(file), %file name
        if verLessThan('matlab', '8')
            reader = mmreader(file); %#ok<DMMR>
        else
            reader = VideoReader(file); 
        end
        numframes = get(reader, 'numberOfFrames');
        mov = read(reader);
    else %movie data already present, as if created using a "gen" function
        mov = file;
        numframes = size(mov, 4);
    end
    [pimdata xis yis xisbuf yisbuf] = pad_image(mov(:,:,:,1), ScreenInfo.ModVal, ScreenInfo.BackgroundColor); %#ok<ASGLU>
    
    M = zeros([xisbuf*yisbuf numframes],'uint32');
    for fnum = 1:numframes,
        imdata = pad_image(mov(:,:,:,fnum), ScreenInfo.ModVal, ScreenInfo.BackgroundColor);
        M(:,fnum) = rgbval(imdata(:, :, 1)', imdata(:, :, 2)', imdata(:, :, 3)');
    end
    bgc = rgbval(uint8(255*ScreenInfo.BackgroundColor(1)),uint8(255*ScreenInfo.BackgroundColor(2)),uint8(255*ScreenInfo.BackgroundColor(3)));
    M(M==0) = bgc;

    firstbuffer = vbufnum + 1;
    for fnum = 1:numframes,
        imdata = M(:,fnum);
        vbuf = mlvideo('createbuffer', ScreenInfo.Device, xisbuf, yisbuf, ScreenInfo.BytesPerPixel);
        mlvideo('copybuffer', ScreenInfo.Device, vbuf, imdata, ScreenInfo.BackgroundColor);
        vbufnum = vbufnum + 1;
        vbuffer(vbufnum) = vbuf;
    end
    lastbuffer = vbufnum;
    
    xoffset = round(xis/2);
    yoffset = round(yis/2);
    xscreenpos = ScreenInfo.Half_xs + round(ScreenInfo.PixelsPerDegree * xpos) - xoffset;
    yscreenpos = ScreenInfo.Half_ys - round(ScreenInfo.PixelsPerDegree * ypos) - yoffset; %invert so that positive y is above the horizone

    if xscreenpos + xis > ScreenInfo.Xsize || yscreenpos + yis > ScreenInfo.Ysize || xscreenpos < 0 || yscreenpos < 0,
        error('*** MonkeyLogic Error: Movie "%s" is placed outside of screen pixel boundaries', name);
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [preloaded, vbuffer] = preload_videos(Conditions, ScreenInfo)

preloaded_base = struct('Class', '', 'Type', '', 'Name', '', 'Modality', 0, 'XPos', [], 'YPos', [], 'Buffer', [], 'InitFrame', 0, 'NumFrames', 0, 'StartFrame', 1, 'FrameStep', 1, 'FrameOrder', [], 'FrameEvents', [], 'StartPosition', 1, 'PositionStep', 1, 'NumPositions', 1, 'CurrentPosition', 1, 'XsPos', [], 'YsPos', [], 'Xsize', [], 'Ysize', [], 'Status', 0, 'WaveForm', [], 'Freq', [], 'NBits', [], 'OutputPort', [], 'ControlObjectColor', [], 'CurrFrame', 0);
preloaded(1:length(Conditions),1) = preloaded_base;

vbuffer = zeros(10000, 1);
vbufnum = 0;
vbufrecord = {};

usepreprocessed = ScreenInfo.UsePreProcessedImages;

for cond = 1:length(Conditions)
    C = Conditions(cond).TaskObject;
    for obnum = 1:length(C),
        
        if strcmpi(C(obnum).Type, 'mov'),
            
            record = [];
            for i = 1:size(vbufrecord,1),
                if strcmpi(vbufrecord{i,1},C(obnum).Name),
                    record = vbufrecord{i,2};
                    numframes = vbufrecord{i,3};
                    xis = vbufrecord{i,4};
                    yis = vbufrecord{i,5};
                    break
                end
            end
            
            if isempty(record),

                xpos = C(obnum).Xpos;
                ypos = C(obnum).Ypos;

                [firstbuffer, lastbuffer, vbuffer, vbufnum, xis, yis, xscreenpos, yscreenpos, numframes] = buf_mov(C(obnum).Name, xpos, ypos, vbuffer, vbufnum, ScreenInfo, usepreprocessed, C(obnum).GenMov);
                
                rec = vbuffer(firstbuffer:lastbuffer);
                vbufrecord{end+1,1} = C(obnum).Name; %#ok<AGROW>
                vbufrecord{end,2} = rec;             %#ok<AGROW>
                vbufrecord{end,3} = numframes;       %#ok<AGROW>
                vbufrecord{end,4} = xis;             %#ok<AGROW>
                vbufrecord{end,5} = yis;             %#ok<AGROW>

                preloaded(cond,obnum).Class = 'Movie';
                preloaded(cond,obnum).Modality = 2; % movie
                preloaded(cond,obnum).InitFrame = 0; %the video frame, as numbered since the beginning of a trial, in which the stimulus was first displayed
                preloaded(cond,obnum).StartFrame = 1; %the frame number, in terms of movie frames in this movie stimulus, to start playback
                preloaded(cond,obnum).FrameStep = 1; %the number of steps to move forward or back (if negative) per video frame
                preloaded(cond,obnum).NumFrames = numframes; %the total number of movie frames
                preloaded(cond,obnum).StartPosition = 1; %for translation, the index of the (x,y) pair at which the stimulus is to start
                preloaded(cond,obnum).PositionStep = 1; %for translation, the number of (x,y) pairs in the path vectors to move, each video frame
                preloaded(cond,obnum).NumPositions = 1; %for translation, the total number of (x,y) pairs in the translation path
                preloaded(cond,obnum).CurrentPosition = 1; %for translation, the current index (x,y) pair for this stimulus
				preloaded(cond,obnum).CurrFrame = 0; %for translation, the current frame for this stimulus
                preloaded(cond,obnum).XPos = xpos; %the initial x position, in the absence of a translation path
                preloaded(cond,obnum).YPos = ypos; %the initial y position, in the absence of a translation path
                preloaded(cond,obnum).ControlObjectColor = [1 1 0.5]; %the color of the representative symbol to appear on the control screen
                preloaded(cond,obnum).Buffer = rec; %the addresses of the video buffers
                preloaded(cond,obnum).XsPos = xscreenpos; %the actual screen position in pixels (for XPos)
                preloaded(cond,obnum).YsPos = yscreenpos; %the actual screen position in pixels (for YPos)
                preloaded(cond,obnum).Xsize = xis; %the x-size of the image, in pixels
                preloaded(cond,obnum).Ysize = yis; %the y-size of the image, in pixels
                preloaded(cond,obnum).Status = 0; %the status of the movie (0 = off, any positive integer reflects the current frame number)
                preloaded(cond,obnum).Name = C(obnum).Name;
            else
                xpos = C(obnum).Xpos;
                ypos = C(obnum).Ypos;
                
                xoffset = round(xis/2);
                yoffset = round(yis/2);
                xscreenpos = ScreenInfo.Half_xs + round(ScreenInfo.PixelsPerDegree * xpos) - xoffset;
                yscreenpos = ScreenInfo.Half_ys - round(ScreenInfo.PixelsPerDegree * ypos) - yoffset; %invert so that positive y is above the horizone

                if xscreenpos + xis > ScreenInfo.Xsize || yscreenpos + yis > ScreenInfo.Ysize || xscreenpos < 0 || yscreenpos < 0,
                    error('*** MonkeyLogic Error: Movie "%s" is placed outside of screen pixel boundaries', C(obnum).Name);
                end
                
                preloaded(cond,obnum).Class = 'Movie';
                preloaded(cond,obnum).Modality = 2; % movie
                preloaded(cond,obnum).InitFrame = 0; %the video frame, as numbered since the beginning of a trial, in which the stimulus was first displayed
                preloaded(cond,obnum).StartFrame = 1; %the frame number, in terms of movie frames in this movie stimulus, to start playback
                preloaded(cond,obnum).FrameStep = 1; %the number of steps to move forward or back (if negative) per video frame
                preloaded(cond,obnum).NumFrames = numframes; %the total number of movie frames
                preloaded(cond,obnum).StartPosition = 1; %for translation, the index of the (x,y) pair at which the stimulus is to start
                preloaded(cond,obnum).PositionStep = 1; %for translation, the number of (x,y) pairs in the path vectors to move, each video frame
                preloaded(cond,obnum).NumPositions = 1; %for translation, the total number of (x,y) pairs in the translation path
                preloaded(cond,obnum).CurrentPosition = 1; %for translation, the current index (x,y) pair for this stimulus
				preloaded(cond,obnum).CurrFrame = 0; %for translation, the current frame for this stimulus
                preloaded(cond,obnum).XPos = xpos; %the initial x position, in the absence of a translation path
                preloaded(cond,obnum).YPos = ypos; %the initial y position, in the absence of a translation path
                preloaded(cond,obnum).ControlObjectColor = [1 1 0.5]; %the color of the representative symbol to appear on the control screen
                preloaded(cond,obnum).Buffer = record; %the addresses of the video buffers
                preloaded(cond,obnum).XsPos = xscreenpos; %the actual screen position in pixels (for XPos)
                preloaded(cond,obnum).YsPos = yscreenpos; %the actual screen position in pixels (for YPos)
                preloaded(cond,obnum).Xsize = xis; %the x-size of the image, in pixels
                preloaded(cond,obnum).Ysize = yis; %the y-size of the image, in pixels
                preloaded(cond,obnum).Status = 0; %the status of the movie (0 = off, any positive integer reflects the current frame number)
                preloaded(cond,obnum).Name = C(obnum).Name;
            end
        else
            preloaded(cond,obnum) = preloaded_base;
        end
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [TaskObject, vbuffer, StimulusInfo] = create_taskobjects(C, ScreenInfo, DaqInfo, TrialRecord, mldirectories, fidbhv, varargin)
global errorfile				%errorfile declared and initialized at the beginning of monkeylogic.m
preloaded = [];
if ~isempty(varargin),
    preloaded = varargin{1};
end

logger = log4m.getLogger('log.txt');
logger.setCommandWindowLevel(logger.ALL); 
logger.setLogLevel(logger.ALL);


vbuffer = zeros(10000, 1);
vbufnum = 0;

lc = length(C);
TaskObject(1:lc) = struct('Class', '', 'Type', '', 'Modality', 0, 'XPos', [], 'YPos', [], 'Buffer', [], 'FrameOrder', [], 'FrameEvents', [], 'XsPos', [], 'YsPos', [], 'Xsize', [], 'Ysize', [], 'Status', 0, 'WaveForm', [], 'Freq', [], 'NBits', [], 'OutputPort', [], 'ControlObjectColor', [], 'Used', 0, 'GenMov', 0);
StimulusInfo = cell(1,lc);

usepreprocessed = ScreenInfo.UsePreProcessedImages;

for obnum = 1:lc, %first check for user-generated images and movies
    imdata = [];
    MoreInfo = [];
    if strcmp(C(obnum).Type, 'gen')
        [pname, fname] = fileparts(C(obnum).FunctionName); %#ok<ASGLU>
        prep_m_file(C(obnum).FunctionName, mldirectories);
        
		try
            needxy = isnan(C(obnum).Xpos) || isnan(C(obnum).Ypos);
            nout = nargout(fname);
			if nout < 3 && needxy,
                error('*** "Gen" function %s should return two additional output arguments to specify X & Y position', fname);
			end
            
			if nout == 1,
                imdata = feval(fname, TrialRecord);
            elseif nout == 2,
                [imdata, MoreInfo] = feval(fname, TrialRecord);
            elseif nout == 3,
                [imdata, xpos, ypos] = feval(fname, TrialRecord);
            else
                [imdata, xpos, ypos, MoreInfo] = feval(fname, TrialRecord);
			end

            if needxy,
                if isstruct(xpos) || iscell(xpos) || isstruct(ypos) || iscell(ypos) || ischar(xpos) || ischar(ypos) || numel(xpos) > 1 || numel(ypos) > 1,
                    error('*** Xpos and Ypos values returned by "Gen" function %s should be simple scalar variables', fname);
                end
                C(obnum).Xpos = xpos;
                C(obnum).Ypos = ypos;
            end

        catch ME
            fclose(fidbhv); %need to add code to finalize bhv file...
            str = sprintf('*** Error executing "gen" function %s', fname);
            % monkeylogic_alert(4, str, MLConfig.Alerts);
            logger.info('monkeylogic.m', ['<<< MonkeyLogic >>> ' str]);
            logger.info('monkeylogic.m', getReport(ME));
            error_escape(ScreenInfo, DaqInfo, fidbhv);
            clear DaqInfo
            save(errorfile);
            return
		end
		
		movs = '.((avi)|(mpg))';
		pics = '.((bmp)|(jpg)|(jpeg)|(gif))';
		
		if ischar(imdata)							%file name generated by gen function. Could be either a movie or a pic.
			C(obnum).Name = imdata;
			if any(regexpi(imdata, pics, 'start'))
				imdata = imread(imdata);
			elseif ~any(regexpi(imdata, movs, 'start'))
					error('Unrecognized file type chosen by gen function.');
			end
		end
        
		if ndims(imdata) == 4 || ischar(imdata)	%movie
			C(obnum).Type = 'mov';
            if ndims(imdata) == 4               % generated movie
                TaskObject(obnum).GenMov = 1;
            end
		elseif ndims(imdata) == 3 %RGB image
            C(obnum).Type = 'pic';
		elseif ndims(imdata) == 2, %#ok<ISMAT>
            imdata = repmat(imdata, [1 1 3]); %grayscale image;
            C(obnum).Type = 'pic';
        else
            fprintf('*** WARNING *** image data for "gen" object created by %s contains an unexpected number of dimensions', fname);
            imdata = repmat(imdata(:, :, 1), [1 1 3]); % band-aid, to allow task execution to continue
            C(obnum).Type = 'pic';
		end
    end

    t = C(obnum).Type;
    TaskObject(obnum).Type = t;
    TaskObject(obnum).ControlObjectColor = [1 1 1];
    if strcmpi(t, 'fix') || strcmpi(t, 'pic') || strcmpi(t, 'dot') || strcmpi(t, 'crc') || strcmpi(t, 'sqr'), %static visual stimuli

		if strcmp(t, 'fix') || strcmp(t, 'dot'),
            imdata = ScreenInfo.FixationPoint;
            cocolor = [1 1 1];
            TaskObject(obnum).Class = 'FixationPoint';
        elseif strcmp(t, 'pic'),
            if isempty(imdata), %not user-generated, which would have been loaded above
                MoreInfo = imfinfo(C(obnum).Name);
                [imdata immap imalpha] = imread(C(obnum).Name); %need to incorporate transparency into visual stim presentation...            
                imdata = double(imdata);
            end
            
            if C(obnum).Xsize ~= -1 && C(obnum).Ysize ~= -1,
                imdata = imresize(imdata, [C(obnum).Ysize C(obnum).Xsize]);
                if any(any(any(imdata < 0))),
                    imdata(imdata < 0) = 0;
                end
                if any(any(any(imdata > 255))),
                    imdata(imdata > 255) = 255;
                end
            end
            
            %create control screen object using average non-background color
            cimdata1 = imdata(:, :, 1);
            cimdata2 = imdata(:, :, 2);
            cimdata3 = imdata(:, :, 3);
            cimdata1(cimdata1 == ScreenInfo.BackgroundColor(1)) = NaN;
            cimdata2(cimdata2 == ScreenInfo.BackgroundColor(2)) = NaN;
            cimdata3(cimdata3 == ScreenInfo.BackgroundColor(3)) = NaN;
            cocolor = ([nan_mean(nan_mean(cimdata1)) nan_mean(nan_mean(cimdata2)) nan_mean(nan_mean(cimdata3))]);
            cocolor(isnan(cocolor)) = 0;
            TaskObject(obnum).Class = 'StaticImage';
        elseif strcmp(t, 'crc'),
            crcrad = C(obnum).Radius * ScreenInfo.PixelsPerDegree;
            imdata = makecircle(crcrad, C(obnum).Color, C(obnum).FillFlag, ScreenInfo.BackgroundColor);
            cocolor = (C(obnum).Color);
            TaskObject(obnum).Class = 'Circle';
        elseif strcmp(t, 'sqr'),
            sqrx = C(obnum).Xsize * ScreenInfo.PixelsPerDegree;
            sqry = C(obnum).Ysize * ScreenInfo.PixelsPerDegree;
            imdata = makesquare([sqrx sqry], C(obnum).Color, C(obnum).FillFlag, ScreenInfo.BackgroundColor);
            cocolor = (C(obnum).Color);
            TaskObject(obnum).Class = 'Square';
		end

		if ~isnan(C(obnum).Xpos),
            xpos = C(obnum).Xpos; %these are in degrees of viewing angle
            ypos = C(obnum).Ypos;
		end

        [imdata xis yis xisbuf yisbuf] = pad_image(imdata, ScreenInfo.ModVal, ScreenInfo.BackgroundColor);

        xoffset = round(xis/2);
        yoffset = round(yis/2);
        xscreenpos = ScreenInfo.Half_xs + round(ScreenInfo.PixelsPerDegree * xpos) - xoffset;
        yscreenpos = ScreenInfo.Half_ys - round(ScreenInfo.PixelsPerDegree * ypos) - yoffset; %invert so that positive y is above the horizon
        
        if xscreenpos + xis > ScreenInfo.Xsize || yscreenpos + yis > ScreenInfo.Ysize || xscreenpos < 0 || yscreenpos < 0,
            fprintf('*** MonkeyLogic Error: Image "%s" is placed outside of screen pixel boundaries.\n', C(obnum).Name);
            error_escape(ScreenInfo, DaqInfo, fidbhv);
            clear DaqInfo
            save(['create_taskobjects_' errorfile]);
        end

        vbuf = mlvideo('createbuffer', ScreenInfo.Device, xisbuf, yisbuf, ScreenInfo.BytesPerPixel);
        mlvideo('copybuffer', ScreenInfo.Device, vbuf, imdata);
        vbufnum = vbufnum + 1;
        vbuffer(vbufnum) = vbuf;

        TaskObject(obnum).Modality = 1; %static visual: pic, gen, crc, sqr, or fix
        TaskObject(obnum).XPos = xpos; %the initial X-position, in degrees of visual angle
        TaskObject(obnum).YPos = ypos; %the initial Y-position, in degrees of visual angle
        TaskObject(obnum).InitFrame = 0; %the video frame, as numbered since the beginning of a trial, in which the stimulus was first displayed
        TaskObject(obnum).StartFrame = 1; %will remain "1" for static images (required for image translation)
        TaskObject(obnum).FrameStep = 1; %will remain "1" for static images (required for image translation)
        TaskObject(obnum).NumFrames = 1; %will remain "1" for static images (required for image translation)
        TaskObject(obnum).StartPosition = 1; %for translation, the index of the (x,y) pair in the path at which the image is to start
        TaskObject(obnum).PositionStep = 1; %for translation, the number of (x,y) pairs to step along the path each video frame
        TaskObject(obnum).NumPositions = 1; %for translation, the number of (x,y) pairs that make up the path
        TaskObject(obnum).CurrentPosition = 1; %for translation, the index for the current (x,y) pair
		TaskObject(obnum).CurrFrame = 0; %for translation, the current frame for this stimulus
        TaskObject(obnum).ControlObjectColor = cocolor; %the color of the symbol appearing on the control-screen
        TaskObject(obnum).Buffer = vbuf; %the address of the video buffer
        TaskObject(obnum).XsPos = xscreenpos; %the screen position in pixels (of XPos)
        TaskObject(obnum).YsPos = yscreenpos; %the screen position in pixels (of YPos)
        TaskObject(obnum).Xsize = xis; %the x-size of the image (in pixels)
        TaskObject(obnum).Ysize = yis; %the y-size of the image (in pixels)
        TaskObject(obnum).Status = 0; %tells 'toggleobject' if the image is currently displayed
        n = C(obnum).Name;
		if isempty(n),
            n = C(obnum).Type;
        else
            f = (n == filesep);
            if any(f),
                n = n(find(f, 1, 'last')+1:length(n));
            end
            dot = (n == '.');
            if any(dot),
                n = n(1:find(dot, 1, 'last')-1);
            end
		end
        TaskObject(obnum).Name = n; %for control display (not currently used)

    elseif strcmpi(t, 'mov'), %movie
        
        if isempty(preloaded)

            xpos = C(obnum).Xpos;
            ypos = C(obnum).Ypos;

            if ~isempty(imdata),
                mov = imdata;
            else
                mov = C(obnum).Name;
            end
            
            [firstbuffer, lastbuffer, vbuffer, vbufnum, xis, yis, xscreenpos, yscreenpos, numframes] = buf_mov(mov, xpos, ypos, vbuffer, vbufnum, ScreenInfo, usepreprocessed, TaskObject(obnum).GenMov);

            TaskObject(obnum).Class = 'Movie';
            TaskObject(obnum).Modality = 2; % movie
            TaskObject(obnum).InitFrame = 0; %the video frame, as numbered since the beginning of a trial, in which the stimulus was first displayed
            TaskObject(obnum).StartFrame = 1; %the frame number, in terms of movie frames in this movie stimulus, to start playback
            TaskObject(obnum).FrameStep = 1; %the number of steps to move forward or back (if negative) per video frame
            TaskObject(obnum).NumFrames = numframes; %the total number of movie frames
            TaskObject(obnum).StartPosition = 1; %for translation, the index of the (x,y) pair at which the stimulus is to start
            TaskObject(obnum).PositionStep = 1; %for translation, the number of (x,y) pairs in the path vectors to move, each video frame
            TaskObject(obnum).NumPositions = 1; %for translation, the total number of (x,y) pairs in the translation path
            TaskObject(obnum).CurrentPosition = 1; %for translation, the current index (x,y) pair for this stimulus
			TaskObject(obnum).CurrFrame = 0; %for translation, the current frame for this stimulus
            TaskObject(obnum).XPos = xpos; %the initial x position, in the absence of a translation path
            TaskObject(obnum).YPos = ypos; %the initial y position, in the absence of a translation path
            TaskObject(obnum).ControlObjectColor = [1 1 0.5]; %the color of the representative symbol to appear on the control screen
            TaskObject(obnum).Buffer = vbuffer(firstbuffer:lastbuffer); %the addresses of the video buffers
            TaskObject(obnum).XsPos = xscreenpos; %the actual screen position in pixels (for XPos)
            TaskObject(obnum).YsPos = yscreenpos; %the actual screen position in pixels (for YPos)
            TaskObject(obnum).Xsize = xis; %the x-size of the image, in pixels
            TaskObject(obnum).Ysize = yis; %the y-size of the image, in pixels
            TaskObject(obnum).Status = 0; %the status of the movie (0 = off, any positive integer reflects the current frame number)
            TaskObject(obnum).Name = C(obnum).Name;
			if isempty(TaskObject(obnum).Name)
				TaskObject(obnum).Name = 'mov';
			end
        else
            TaskObject(obnum) = preloaded(obnum);
%             TaskObject(obnum).Class = preloaded(obnum).Class;
%             TaskObject(obnum).Modality = preloaded(obnum).Modality; % movie
%             TaskObject(obnum).InitFrame = preloaded(obnum).InitFrame; %the video frame, as numbered since the beginning of a trial, in which the stimulus was first displayed
%             TaskObject(obnum).StartFrame = preloaded(obnum).StartFrame; %the frame number, in terms of movie frames in this movie stimulus, to start playback
%             TaskObject(obnum).FrameStep = preloaded(obnum).FrameStep; %the number of steps to move forward or back (if negative) per video frame
%             TaskObject(obnum).NumFrames = preloaded(obnum).NumFrames; %the total number of movie frames
%             TaskObject(obnum).StartPosition = preloaded(obnum).StartPosition; %for translation, the index of the (x,y) pair at which the stimulus is to start
%             TaskObject(obnum).PositionStep = preloaded(obnum).PositionStep; %for translation, the number of (x,y) pairs in the path vectors to move, each video frame
%             TaskObject(obnum).NumPositions = preloaded(obnum).NumPositions; %for translation, the total number of (x,y) pairs in the translation path
%             TaskObject(obnum).CurrentPosition = preloaded(obnum).CurrentPosition; %for translation, the current index (x,y) pair for this stimulus
%             TaskObject(obnum).XPos = preloaded(obnum).XPos; %the initial x position, in the absence of a translation path
%             TaskObject(obnum).YPos = preloaded(obnum).YPos; %the initial y position, in the absence of a translation path
%             TaskObject(obnum).ControlObjectColor = preloaded(obnum).ControlObjectColor; %the color of the representative symbol to appear on the control screen
%             TaskObject(obnum).Buffer = preloaded(obnum).Buffer; %the addresses of the video buffers
%             TaskObject(obnum).XsPos = preloaded(obnum).XsPos; %the actual screen position in pixels (for XPos)
%             TaskObject(obnum).YsPos = preloaded(obnum).YsPos; %the actual screen position in pixels (for YPos)
%             TaskObject(obnum).Xsize = preloaded(obnum).Xsize; %the x-size of the image, in pixels
%             TaskObject(obnum).Ysize = preloaded(obnum).Ysize; %the y-size of the image, in pixels
%             TaskObject(obnum).Status = preloaded(obnum).Status; %the status of the movie (0 = off, any positive integer reflects the current frame number)
%             TaskObject(obnum).Name = preloaded(obnum).Name;
        end

    elseif strcmpi(t, 'snd'), %sound

        TaskObject(obnum).Class = 'Sound';
        TaskObject(obnum).Modality = 3; %snd
        TaskObject(obnum).PlayerObject = audioplayer(C(obnum).WaveForm, C(obnum).Freq, C(obnum).NBits); %#ok<TNMLP>

    elseif strcmpi(t, 'stm'), %stimulation waveform

        TaskObject(obnum).Modality = 4; %analog
        TaskObject(obnum).WaveForm = C(obnum).WaveForm;
        TaskObject(obnum).Freq = C(obnum).Freq;
        TaskObject(obnum).NBits = C(obnum).NBits;
        TaskObject(obnum).OutputPort = C(obnum).OutputPort;
        TaskObject(obnum).Class = sprintf('Stim%i', C(obnum).OutputPort);
        TaskObject(obnum).Name = TaskObject(obnum).Class;

        %StimAO = eval(sprintf('StimAO = DaqInfo.Stim%i', TaskObject(obnum).OutputPort));
        if isempty(DaqInfo.AnalogOutput),
            daqreset;
            save(['create_taskobjects_' errorfile]);
            error('*** No analog output defined for STM (stimulation) object ***');
        end
        try
            actual_rate = setverify(DaqInfo.AnalogOutput, 'SampleRate', TaskObject(obnum).Freq);
        catch %#ok<CTCH>
            actual_rate = NaN;
        end
        if actual_rate ~= TaskObject(obnum).Freq,
            daqreset;
            save(['create_taskobjects_' errorfile]);
            error('*** Unable to set analog output frequency to desired value ***');
        end
        [rows cols] = size(TaskObject(obnum).WaveForm);
        if min([rows cols]) > 1,
            daqreset;
            save(['create_taskobjects_' errorfile]);
            error('*** Stimulus waveform must be a one-dimensional vector ***');
        end
        aochannels = cat(1, DaqInfo.AnalogOutput.Channel.Index);
        numaochannels = length(aochannels);
        stimchanindex = eval(sprintf('DaqInfo.Stim%i.ChannelIndex', TaskObject(obnum).OutputPort));
        stimdata = zeros(length(TaskObject(obnum).WaveForm), numaochannels); %for now, can only stim through one port
        if cols > rows,
            stimdata(:, stimchanindex) = TaskObject(obnum).WaveForm';
        else
            stimdata(:, stimchanindex) = TaskObject(obnum).WaveForm;
        end
        stop(DaqInfo.AnalogOutput); %in case was still running from a previous trial
        putdata(DaqInfo.AnalogOutput, stimdata);
        if ~isempty(DaqInfo.AnalogOutput),
            start(DaqInfo.AnalogOutput);
            %isrunning?
        end

    elseif strcmpi(t, 'ttl'), %TTL pulse

        TaskObject(obnum).Modality = 5; %digital
        TaskObject(obnum).OutputPort = C(obnum).OutputPort;
        TaskObject(obnum).Status = 0;
        TaskObject(obnum).Class = sprintf('TTL%i', C(obnum).OutputPort);
        TaskObject(obnum).Name = TaskObject(obnum).Class;

    end
    if ~isempty(MoreInfo),
        TaskObject(obnum).MoreInfo = MoreInfo;
    end
    StimulusInfo(obnum) = {TaskObject(obnum)};   
end
vbuffer = vbuffer(1:vbufnum);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Instruction = parse_remote_command(RemoteCommand, PassCode)
persistent lastcommandtime

logger = log4m.getLogger('log.txt');
logger.setCommandWindowLevel(logger.ALL); 
logger.setLogLevel(logger.ALL);


Instruction.Message = ' ';
Instruction.Command = ' ';
Instruction.Value = [];

if length(RemoteCommand) > 1,
    f1 = find(RemoteCommand == '*');
    f2 = find(RemoteCommand == '|');
    commandtime = str2double(RemoteCommand(f2+1:end));
    if isempty(lastcommandtime),
        lastcommandtime = commandtime;
        return
    elseif lastcommandtime == commandtime,
        return %[computername]command.txt file not updated, so don't re-issue old commands
    end
    lastcommandtime = commandtime;
    if f2 == f1 + 1,
        Instruction.Message = 'Must enter an authorization code';
        return
    end
    instruction = lower(RemoteCommand(1:f1-1));
    passcode = RemoteCommand(f1+1:f2-1);
    if strcmp(passcode, PassCode),
        logger.info('monkeylogic.m', '<<<>>> Remote Access Accepted <<<>>>')
        if ~isempty(strfind(instruction, 'pause')) || ~isempty(strfind(instruction, 'timeout')) || ~isempty(strfind(instruction, 'hold')) || ~isempty(strfind(instruction, 'wait')),
            Instruction.Command = 'p';
            Instruction.Message = 'Pause';
        elseif ~isempty(strfind(instruction, 'resume')) || ~isempty(strfind(instruction, 'continue')) || ~isempty(strfind(instruction, 'start')),
            Instruction.Command = 'r';
            Instruction.Message = 'Resume';
        elseif ~isempty(strfind(instruction, 'quit')) || ~isempty(strfind(instruction, 'stop')) || ~isempty(strfind(instruction, 'done')),
            Instruction.Command = 'q';
            Instruction.Message = 'Quit';
        elseif ~isempty(strfind(instruction, 'maxblocks')),
            f = find(ismember(instruction, '1234567890'));
            if isempty(f) || any(diff(f) > 1),
                Instruction.Message = 'Numeric value for MaxBlocks not understood';
            else
                Instruction.Value = str2double(instruction(f));
                if Instruction.Value < 1,
                    Instruction.Message = 'Value for MaxBlocks must be a positive integer';
                    return
                end
                Instruction.Command = 'm';
                Instruction.Message = sprintf('Maximum blocks to run now %i', Instruction.Value);
                set(findobj('tag', 'maxblocks'), 'string', num2str(Instruction.Value));
            end
        elseif ~isempty(strfind(instruction, 'maxtrials')),
            f = find(ismember(instruction, '1234567890'));
            if isempty(f) || any(diff(f) > 1),
                Instruction.Message = 'Numeric value for MaxTrials not understood';
            else
                Instruction.Value = str2double(instruction(f));
                if Instruction.Value < 1,
                    Instruction.Message = 'Value for MaxTrials must be a positive integer';
                    return
                end
                Instruction.Command = 't';
                Instruction.Message = sprintf('Maximum trials to run now %i', Instruction.Value);
                set(findobj('tag', 'maxtrials'), 'string', num2str(Instruction.Value));
            end
        elseif ~isempty(strfind(instruction, 'block')),
            f = find(ismember(instruction, '1234567890'));
            if isempty(f) || any(diff(f) > 1),
                Instruction.Message = 'Numeric value for block switch not understood.';
            else
                Instruction.Command = 'b';
                Instruction.Value = str2double(instruction(f));
                Instruction.Message = sprintf('Switched to block %i', Instruction.Value);
            end
        elseif ~isempty(strfind(instruction, 'iti ')),
            f = find(ismember(instruction, '1234567890'));
            if isempty(f) || any(diff(f) > 1),
                Instruction.Message = 'Numeric value for inter-trial-interval length not understood.';
            else
                Instruction.Value = str2double(instruction(f));
                if Instruction.Value < 0,
                    Instruction.Message = 'ITI length must be a positive integer';
                    return
                end
                Instruction.Command = 'i';
                Instruction.Message = sprintf('ITI now set to %i ms', Instruction.Value);
                set(findobj('tag', 'iti'), 'string', num2str(Instruction.Value));
            end
        elseif ~isempty(strfind(instruction, 'error')),
            if ~isempty(strfind(instruction, 'ignore')),
                Instruction.Command = 'x';
                Instruction.Value = 1;
                Instruction.Message = 'On error: ignore';
            elseif ~isempty(strfind(instruction, 'immediate')),
                Instruction.Command = 'x';
                Instruction.Value = 1;
                Instruction.Message = 'On error: repeat immediately';
            elseif ~isempty(strfind(instruction, 'delay')) || ~isempty(strfind(instruction, 'later')),
                Instruction.Command = 'x';
                Instruction.Value = 3;
                Instruction.Message = 'On error: repeat delayed';
            else
                Instruction.Message = 'Command to alter behavioral-error handling not understood';
                return
            end
            set(findobj('tag', 'errorlogic'), 'value', Instruction.Value);
        else
            Instruction.Message = 'Unknown remote command.';
        end
        logger.info('monkeylogic.m', sprintf('...Action: %s', Instruction.Message))
    else
        Instruction.Message = 'Access Denied.';
        logger.info('monkeylogic.m', '*** Unauthorized Access Attempted ***')
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function function_name = prep_m_file(file, mldirectories)

if ~exist(file, 'file'),
    function_name = '';
    return
end
[pname fname] = fileparts(file);
function_name = fname;
copyfile(file, mldirectories.RunTimeDirectory);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function error_escape(ScreenInfo, DaqInfo, fidbhv)

prtnormal;
mlkbd('release');
mlvideo('showcursor', ScreenInfo.Device, 1);
close_video(ScreenInfo);
close_daq(DaqInfo);
fclose(fidbhv);
trackvarchanges(-2);						%clears VarChanges, which is a record of changes to editable variables.
ax = findobj('tag', 'replica');
set(findobj('tag', 'runbutton'), 'enable', 'on');	%Enables the run button in the main menu
if ~isempty(ax),
    set(gcf, 'CurrentAxes', ax);
    cla;
    h = text(0,0, '* Error *');
    set(h, 'color', [1 0 0], 'fontsize', 18);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function update_error_lists(trialerror, originalcond, cond, ScreenInfo)

%update overall errorlist
herror = findobj(ScreenInfo.ControlScreenHandle', 'tag', 'errorlist');
errorstring = get(herror, 'string');
esl = length(errorstring);
errorstring(1:esl-1) = errorstring(2:esl);
errorstring(esl) = num2str(trialerror);
set(herror, 'string', errorstring);
%then update errors this condition:
herror = findobj(ScreenInfo.ControlScreenHandle', 'tag', 'conderrors');
conderrors = get(herror, 'userdata');
errorstring = conderrors{originalcond(cond)};
esl = length(errorstring);
errorstring(1:esl-1) = errorstring(2:esl);
errorstring(esl) = num2str(trialerror);
conderrors(originalcond(cond)) = {errorstring};
set(herror, 'string', errorstring, 'userdata', conderrors);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ScreenInfo = init_video(ScreenInfo)

ScreenInfo.IsActive = 0;
try
    mlvideo('init', ScreenInfo.PixelsPerDegree);
    mlvideo('initdevice', ScreenInfo.Device);
    mlvideo('setmode', ScreenInfo.Device, ScreenInfo.Xsize, ScreenInfo.Ysize, ScreenInfo.BytesPerPixel, ScreenInfo.RefreshRate, ScreenInfo.BufferPages);
    pause(1);
    mlvideo('clear', ScreenInfo.Device, ScreenInfo.BackgroundColor);
    mlvideo('flip', ScreenInfo.Device);
    mlvideo('showcursor', ScreenInfo.Device, 0);

catch ME
    fprintf('Video Initialization Error\n%s\n',getReport(ME));
    mlvideo('showcursor', ScreenInfo.Device, 1);
    mlvideo('restoremode', ScreenInfo.Device);
    mlvideo('releasedevice', ScreenInfo.Device);
    mlvideo('release');
    return
end
ScreenInfo.IsActive = 1;

% Initialize Photodiode trigger:
if ScreenInfo.PhotoDiode > 1,
    xis = ScreenInfo.PhotoDiodeSize; %must be multiple of 4
    yis = xis; %must be multiple of 4
    img = ones(xis, yis, 3);
    [img xis yis xisbuf yisbuf] = pad_image(img, ScreenInfo.ModVal);
    ScreenInfo.PdBuffer = mlvideo('createbuffer', ScreenInfo.Device, xisbuf, yisbuf, ScreenInfo.BytesPerPixel);
    mlvideo('copybuffer', ScreenInfo.Device, ScreenInfo.PdBuffer, img);
    img = zeros(xis, yis, 3);
    [img xis yis xisbuf yisbuf] = pad_image(img, ScreenInfo.ModVal);
    ScreenInfo.PdBufferBlack = mlvideo('createbuffer', ScreenInfo.Device, xisbuf, yisbuf, ScreenInfo.BytesPerPixel);
    mlvideo('copybuffer', ScreenInfo.Device, ScreenInfo.PdBufferBlack, img);
    switch ScreenInfo.PhotoDiode,
        case 2, %upper left
            ScreenInfo.PdX = 0;
            ScreenInfo.PdY = 0;
        case 3, %upper right
            ScreenInfo.PdX = ScreenInfo.Xsize - xis;
            ScreenInfo.PdY = 0;
        case 4, %lower right
            ScreenInfo.PdX = ScreenInfo.Xsize - xis;
            ScreenInfo.PdY = ScreenInfo.Ysize - yis;
        case 5, %lower left
            ScreenInfo.PdX = 0;
            ScreenInfo.PdY = ScreenInfo.Ysize - yis;
    end
    ScreenInfo.PdXsize = xis;
    ScreenInfo.PdYsize = yis;
end

% If subject sees his/her own joystick cursor, need to have image ready
if strcmpi(ScreenInfo.CursorImageFile, 'DEFAULT') || ~exist(ScreenInfo.CursorImageFile, 'file'),
    imdata = makecircle(round(ScreenInfo.PixelsPerDegree/4), [1 1 1], 1, ScreenInfo.BackgroundColor);
else
    imdata = imread(ScreenInfo.CursorImageFile);
end

[imdata xis yis xisbuf yisbuf] = pad_image(imdata, ScreenInfo.ModVal, ScreenInfo.BackgroundColor);
ScreenInfo.CursorBuffer = mlvideo('createbuffer', ScreenInfo.Device, xisbuf, yisbuf, ScreenInfo.BytesPerPixel);
mlvideo('copybuffer', ScreenInfo.Device, ScreenInfo.CursorBuffer, imdata);
ScreenInfo.CursorBlankBuffer = mlvideo('createbuffer', ScreenInfo.Device, xisbuf, yisbuf, ScreenInfo.BytesPerPixel);
blankbuffer = zeros(size(imdata));
blankbuffer(:, :, 1) = ScreenInfo.BackgroundColor(1);
blankbuffer(:, :, 2) = ScreenInfo.BackgroundColor(2);
blankbuffer(:, :, 3) = ScreenInfo.BackgroundColor(3);
mlvideo('copybuffer', ScreenInfo.Device, ScreenInfo.CursorBlankBuffer, blankbuffer);
ScreenInfo.CursorXsize = xis;
ScreenInfo.CursorYsize = yis;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ScreenInfo = close_video(ScreenInfo, varargin)

for i = 1:length(ScreenInfo.ActiveVideoBuffers),
    mlvideo('releasebuffer', ScreenInfo.Device, ScreenInfo.ActiveVideoBuffers(i));
    ScreenInfo.ActiveVideoBuffers(i) = 0;
end
ScreenInfo.ActiveVideoBuffers(~ScreenInfo.ActiveVideoBuffers) = [];
if any(ScreenInfo.ActiveVideoBuffers),
    logger.info('monkeylogic.m', 'WARNING: *** Unable to release all active video buffers ***')
end

if ~isempty(varargin) && strcmpi(varargin{1}, 'BuffersOnly'),
    return
end

if isfield(ScreenInfo,'PreloadedVideoBuffers'),
    for i = 1:length(ScreenInfo.PreloadedVideoBuffers),
        mlvideo('releasebuffer', ScreenInfo.Device, ScreenInfo.PreloadedVideoBuffers(i));
        ScreenInfo.PreloadedVideoBuffers(i) = 0;
    end
    ScreenInfo.PreloadedVideoBuffers(~ScreenInfo.PreloadedVideoBuffers) = [];
    if any(ScreenInfo.PreloadedVideoBuffers),
        logger.info('monkeylogic.m', 'WARNING: *** Unable to release all active video buffers ***')
    end
end

if ScreenInfo.PhotoDiode > 1,
    mlvideo('releasebuffer', ScreenInfo.Device, ScreenInfo.PdBuffer);
end
mlvideo('releasebuffer', ScreenInfo.Device, ScreenInfo.CursorBuffer);
mlvideo('releasebuffer', ScreenInfo.Device, ScreenInfo.CursorBlankBuffer);
mlvideo('showcursor', ScreenInfo.Device, 1);
mlvideo('restoremode', ScreenInfo.Device);
mlvideo('releasedevice', ScreenInfo.Device);
mlvideo('release');
ScreenInfo.IsActive = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function close_daq(DaqInfo)

if ~isempty(DaqInfo),
    if ~isempty(DaqInfo.AnalogInput)
        stop(DaqInfo.AnalogInput);
        delete(DaqInfo.AnalogInput);
    end
    if ~isempty(DaqInfo.AnalogOutput),
        stop(DaqInfo.AnalogOutput);
        delete(DaqInfo.AnalogOutput)
    end
    if ~isempty(DaqInfo.BehavioralCodes),
        delete(DaqInfo.BehavioralCodes.DIO);
    end
    if ~isempty(DaqInfo.TTL1);
        delete(DaqInfo.TTL1);
    end
    if ~isempty(DaqInfo.TTL2);
        delete(DaqInfo.TTL2);
    end
    if ~isempty(DaqInfo.TTL3);
        delete(DaqInfo.TTL3);
    end
    if ~isempty(DaqInfo.TTL4);
        delete(DaqInfo.TTL4);
    end
end
clear DaqInfo

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ScreenInfo, MLConfig, UserChanges] = check_keyboard(MLConfig, EyeSignalInUse, JoystickInUse, ScreenInfo, DaqInfo, TrialRecord, Instruction)
global MLHELPER_OFF
global RFM_TASK

logger = log4m.getLogger('log.txt');
logger.setCommandWindowLevel(logger.ALL); 
logger.setLogLevel(logger.ALL);

startmenu    = TrialRecord.CurrentTrialNumber == 0;
escapequeued = 0;
if isfield(TrialRecord,'EscapeQueued'),
    escapequeued = TrialRecord.EscapeQueued;
end

UserChanges.QuitFlag = 0;
UserChanges.NewBlock = 0;
UserChanges.ErrorHandler = 0;
UserChanges.RecentReset = 0;
UserChanges.ITI = 0;
UserChanges.MaxBlocks = 0;
UserChanges.MaxTrials = 0;
UserChanges.SimulationMode = TrialRecord.SimulationMode;

if Instruction.Command == 'b',
    UserChanges.NewBlock = Instruction.Value;
    return
elseif Instruction.Command == 'x',
    UserChanges.ErrorHandler = Instruction.Value;
    return
elseif Instruction.Command == 'i',
    UserChanges.ITI = Instruction.Value;
    return
elseif Instruction.Command == 'm',
    UserChanges.MaxBlocks = Instruction.Value;
    return
elseif Instruction.Command == 't',
    UserChanges.MaxTrials = Instruction.Value;
    return
end

VV = get(findobj('tag', 'loadbutton'), 'userdata');
if ~isempty(fieldnames(VV)),
    EditVarsInUse = 1;
else
    EditVarsInUse = 0;
end

kb = mlkbd('getkey');
remotecommand = any('pqr' == Instruction.Command);
if startmenu || escapequeued,
    kb = 25;
    remotecommand = 0;
end;
if ~isempty(kb) || remotecommand,
    if remotecommand,
        if Instruction.Command == 'p',
            kb = 1;
        elseif Instruction.Command == 'r',
            kb = 57;
        elseif Instruction.Command == 'q',
            kb = 16;
        end
    end
    if kb == 19, % "r" for reward
        goodmonkey(100);
    elseif kb == 25 || kb == 1 || remotecommand, % "p" or esc for pause
        
		if ~isempty(RFM_TASK)
			RFM_TASK = 2;
			unclip_cursor;
			enable_clicks;
			disable_cursor;
		end
		
        delete(get(gca, 'children'));
        texth = text(0, 0.22*max(get(gca, 'ylim')), '- Paused -');
        set(texth, 'color', [1 1 1], 'fontsize', 24, 'horizontalalignment', 'center');
        
        if startmenu,
            texth0 = text(0, 0.10*max(get(gca, 'ylim')), 'Press [space] to start or [Q] to quit');
            texth3 = [];
        else
            texth0 = text(0, 0.10*max(get(gca, 'ylim')), 'Press [space] to resume or [Q] to quit');
            texth3 = text(0, 0.25*min(get(gca, 'ylim')), 'Press [R] to reset the recent behavior counter');
        end
        texth1 = text(0, 0.05*min(get(gca, 'ylim')), 'Press [B] to select a new block');
        texth2 = text(0, 0.15*min(get(gca, 'ylim')), 'Press [X] to alter behavioral-error handling');
        dmenu = 0;
        if EyeSignalInUse && JoystickInUse,
            texth4 = text(0, (0.35-startmenu*0.1)*min(get(gca, 'ylim')), 'Press [E] or [J] to recalibrate Eye Signal or Joystick');
            dmenu = 2;
        elseif EyeSignalInUse,
            texth4 = text(0, (0.35-startmenu*0.1)*min(get(gca, 'ylim')), 'Press [E] to recalibrate Eye Signal');
            dmenu = 2;
        elseif JoystickInUse,
            texth4 = text(0, (0.35-startmenu*0.1)*min(get(gca, 'ylim')), 'Press [J] to recalibrate Joystick');
            dmenu = 1;
        else
            texth4 = [];
        end
        if EyeSignalInUse,
            if MLConfig.OnlineEyeAdjustment,
                texth5 = text(0, (0.45-startmenu*0.1)*min(get(gca, 'ylim')), 'Press [D] to turn OFF eye drift correction');
            else
                texth5 = text(0, (0.45-startmenu*0.1)*min(get(gca, 'ylim')), 'Press [D] to turn ON eye drift correction');
            end
        else
            texth5 = [];
        end
        if EditVarsInUse,
            texth6 = text(0, (0.35+dmenu*0.1-startmenu*0.1)*min(get(gca, 'ylim')), 'Press [V] to edit timing file variables');
            dmenu = dmenu + 1;
        else
            texth6 = [];
        end
        if UserChanges.SimulationMode,
            texth7 = text(0, (0.35+dmenu*0.1-startmenu*0.1)*min(get(gca, 'ylim')), 'Press [S] to turn off simulation mode');  % old position = 0.65*min(get(gca, 'ylim'))
        else
            texth7 = text(0, (0.35+dmenu*0.1-startmenu*0.1)*min(get(gca, 'ylim')), 'Press [S] to turn on simulation mode');
        end
        set(texth0, 'color', [.7 .7 .7], 'fontsize', 18, 'horizontalalignment', 'center');
        set([texth1 texth2 texth3 texth4 texth5 texth6 texth7], 'color', [.7 .7 .7], 'fontsize', 14, 'horizontalalignment', 'center');
        drawnow;
        if MLConfig.Alerts.WebPage.Enable,
            mlwebsummary(2, TrialRecord, '- Paused -', Instruction.Message);
            mlwebsummary(3, TrialRecord);
            mlwebsummary(4, 'UpdateFigure');
        end
        resumeflag = 0;
        t1 = toc;
        while resumeflag == 0,
            if isempty(kb) || (~(remotecommand && kb == 16) && ~(remotecommand && kb == 57)),
                kb = mlkbd('getkey');
            end
            if ~isempty(kb) && kb == 57,
                % spacebar to resume
                resumeflag = 1;
                delete([texth texth0 texth1 texth2 texth3 texth4 texth5 texth6 texth7]);
                drawnow;
            elseif ~isempty(kb) && kb == 18 && EyeSignalInUse,
                % "e" for eye calibration
                targetlist = MLConfig.EyeCalibrationTargets;
                ScreenInfo.EyeOrJoy = 1;
                ScreenInfo = close_video(ScreenInfo);
                xycalibrate(ScreenInfo, targetlist, DaqInfo, MLConfig.EyeTransform, MLHELPER_OFF);
                fig = findobj('tag', 'xycalibrate');
                enable_cursor;
                clip_cursor(get(fig,'position'));
                waitfor(fig);
                unclip_cursor;
                disable_cursor;
                ScreenInfo = init_video(ScreenInfo);
                MLConfig.EyeTransform = get(findobj('tag', 'calbutton'), 'userdata');
                MLConfig.EyeCalibrationTargets = get(findobj('tag', 'eyecaltext'), 'userdata');
            elseif ~isempty(kb) && kb == 36 && JoystickInUse,
                % "j" for joystick calibration
                targetlist = MLConfig.JoystickCalibrationTargets;
                ScreenInfo.EyeOrJoy = 2;
                ScreenInfo = close_video(ScreenInfo);
                xycalibrate(ScreenInfo, targetlist, DaqInfo, MLConfig.JoyTransform, MLHELPER_OFF);
                fig = findobj('tag', 'xycalibrate');
                enable_cursor;
                clip_cursor(get(fig,'position'));
                waitfor(fig);
                unclip_cursor;
                disable_cursor;
                ScreenInfo = init_video(ScreenInfo);
                MLConfig.JoyTransform = get(findobj('tag', 'joycalbutton'), 'userdata');
                MLConfig.JoystickCalibrationTargets = get(findobj('tag', 'joycaltext'), 'userdata');
            elseif ~isempty(kb) && kb == 31,
                % "s" for simulation mode
                if UserChanges.SimulationMode,
                    set(texth7, 'string', 'Press [S] to turn on simulation mode');
                else
                    set(texth7, 'string', 'Press [S] to turn off simulation mode');
                end
                UserChanges.SimulationMode = ~UserChanges.SimulationMode;
                drawnow;
            elseif ~isempty(kb) && kb == 32 && EyeSignalInUse,
                % "d" for eye Drift correction
                if MLConfig.OnlineEyeAdjustment,
                    MLConfig.OnlineEyeAdjustment = 0;
                    set(texth5, 'string', 'Press [D] to turn ON eye drift correction');
                    drawnow;
                else
                    MLConfig.OnlineEyeAdjustment = 1;
                    set(texth5, 'string', 'Press [D] to turn OFF eye drift correction');
                    drawnow;
                end
            elseif ~isempty(kb) && kb ==47,
                % "v" for variable editing
                mlkbd('release');
                ScreenInfo = close_video(ScreenInfo);
                enable_cursor;
                VV = get(findobj('tag', 'loadbutton'), 'userdata');
                changevars(VV);
                uiwait(findobj('tag', 'edittfvars'));
                disable_cursor;
                mlkbd('init');
                set(0, 'CurrentFigure', findobj('tag', 'mlmonitor'));
                ScreenInfo = init_video(ScreenInfo);
                trackvarchanges(TrialRecord.CurrentTrialNumber + 1);
            elseif ~isempty(kb) && kb == 48,
                % "b" for block change
                mlkbd('release');
                ScreenInfo = close_video(ScreenInfo);
                enable_cursor;
                chooseblock;
                uiwait(findobj('tag', 'chooseblock'));
                disable_cursor;
                b = get(findobj('tag', 'allblocks'), 'userdata');
                if ~isempty(b),
                    UserChanges.NewBlock = b;
                end
                mlkbd('init');
                set(0, 'CurrentFigure', findobj('tag', 'mlmonitor'));
                ScreenInfo = init_video(ScreenInfo);
             elseif ~isempty(kb) && kb == 19,
                % "r" for reset recent behavior
                if UserChanges.RecentReset,
                    UserChanges.RecentReset = 0;
                    set(texth3, 'string', 'Press [R] to reset the recent behavior counter');
                    drawnow;
                else
                    UserChanges.RecentReset = 1;
                    set(texth3, 'string', 'Press [R] to undo reseting the recent behavior counter');
                    drawnow;
                end
            elseif ~isempty(kb) && kb == 45,
                % "x" for error-handling
                mlkbd('release');
                ScreenInfo = close_video(ScreenInfo);
                enable_cursor;
                chooseerrorhandling;
                uiwait(findobj('tag', 'chooseerrorhandling'));
                disable_cursor;
                UserChanges.ErrorHandler = get(findobj('tag', 'errorlogic'), 'value');
                mlkbd('init');
                set(0, 'CurrentFigure', findobj('tag', 'mlmonitor'));
                ScreenInfo = init_video(ScreenInfo);
            elseif ~isempty(kb) && kb == 16,
                % "q" for quit
                UserChanges.QuitFlag = 1;
                set(texth, 'string', '- Stopped -', 'position', [0 0]);
                delete([texth0 texth1 texth2 texth3 texth4 texth5 texth6 texth7]);
                drawnow;
                return;
            end
            t2 = toc;
            if MLConfig.Alerts.WebPage.Enable && t2 - t1 > 1, %check every 1 second
                mlwebsummary(4, 'GetCommandOnly');
                commfile = [MLConfig.ComputerName 'command.txt'];
                RemoteCommand = [];
                if exist(commfile,'file'),
                    fid2 = fopen(commfile, 'r+');
                    if ~feof(fid2),
                        RemoteCommand = fgetl(fid2);
                    end
                    fclose(fid2);
                end
                Instruction = parse_remote_command(RemoteCommand, MLConfig.Alerts.WebPage.PassCode);
                remotecommand = any('qr' == Instruction.Command);
                if remotecommand,
                    if Instruction.Command == 'r',
                        kb = 57;
                    elseif Instruction.Command == 'q',
                        kb = 16;
                    end
                end
                t1 = toc;
            end
        end
    end
    tic; %restart ITI timer
end

%%
function goodmonkey(duration, varargin)
persistent DAQ rewardtype reward_on reward_off noreward

if duration == -1,
    DAQ = varargin{1};
    noreward = 0;
    if isempty(DAQ.Reward),
        noreward = 1;
    elseif strcmpi(DAQ.Reward.Subsystem, 'analog'),
        rewardtype = 1;
        ao_channels = DAQ.AnalogOutput.Channel.Index;
        reward_off = zeros(size(ao_channels))';
        rewardindex = DAQ.Reward.ChannelIndex;
        reward_on = reward_off;
        rewardpolarity = DAQ.Reward.Polarity > 0;
        reward_on(rewardindex) = DAQ.Reward.TriggerValue*rewardpolarity;
        reward_off(rewardindex) = DAQ.Reward.TriggerValue*(~rewardpolarity);
    else %digital
        rewardtype = 2;
        reward_on = DAQ.Reward.Polarity;
        reward_off = ~DAQ.Reward.Polarity;
    end
    return
end

if noreward,
    logger.info('monkeylogic.m', 'WARNING: *** No reward output defined ***')
    return
end

if isempty(varargin),
    numreward = 1;
    pausetime = 0;
else
    numreward = varargin{1};
    if length(varargin) > 1,
        pausetime = varargin{2};
    else
        pausetime = 40;
    end
end

for i = 1:numreward,
    t1 = toc;
    t2 = 0;
    if rewardtype == 1,
        putsample(DAQ.AnalogOutput, reward_on);
    else
        putvalue(DAQ.Reward.DIO, reward_on);
    end
    while t2*1000 < duration,
        t2 = toc - t1;
    end
    if rewardtype == 1,
        putsample(DAQ.AnalogOutput, reward_off); 
    else
        putvalue(DAQ.Reward.DIO, reward_off); 
    end
    if i < numreward, %add gaps only between rewards
        t1 = toc;
        t2 = 0;
        while t2*1000 < pausetime
            t2 = toc - t1;
        end
    end
end

%%
function m = nan_mean(x)
m = mean(x(~isnan(x)));

%%
function rgb = rgbval(r,g,b)
r=uint32(r);
g=uint32(g);
b=uint32(b);
z = 65536*r+256*g+b;
rgb = z(:)';

%%
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

%% mlhelper.exe wrapper functions
function disable_cursor
global MLHELPER_OFF
if MLHELPER_OFF,
    %logger.info('monkeylogic.m', 'disable_cursor MLHELPER_OFF');
    return
end
thisfig = get(0,'CurrentFigure');
if ~isempty(thisfig)
    set(thisfig,'PointerShapeCData',nan(16));
    set(thisfig,'Pointer','custom');
end
dirs = getpref('MonkeyLogic', 'Directories');
message = sprintf('%smlhelper --cursor-disable',dirs.BaseDirectory);
fprintf(message);
system(message);

%%
function enable_cursor
global MLHELPER_OFF
if MLHELPER_OFF,
    %logger.info('monkeylogic.m', 'enable_cursor MLHELPER_OFF');
    return
end
thisfig = get(0,'CurrentFigure');
if ~isempty(thisfig)
    set(thisfig,'Pointer','arrow');
end
dirs = getpref('MonkeyLogic', 'Directories');
message = sprintf('%smlhelper --cursor-enable',dirs.BaseDirectory);
fprintf(message);
system(message);

%%
function disable_clicks %#ok<DEFNU>
global MLHELPER_OFF
if MLHELPER_OFF,
    return
end
dirs = getpref('MonkeyLogic', 'Directories');
message = sprintf('%smlhelper --clicks-disable',dirs.BaseDirectory);
fprintf(message);
system(message);

%%
function enable_clicks
global MLHELPER_OFF
if MLHELPER_OFF,
    return
end
dirs = getpref('MonkeyLogic', 'Directories');
message = sprintf('%smlhelper --clicks-enable',dirs.BaseDirectory);
fprintf(message);
system(message);

%%
function disable_syskeys
global MLHELPER_OFF
if MLHELPER_OFF,
    return
end
dirs = getpref('MonkeyLogic', 'Directories');
system(sprintf('%smlhelper --syskeys-disable',dirs.BaseDirectory));

%%
function enable_syskeys
global MLHELPER_OFF
if MLHELPER_OFF,
    return
end
dirs = getpref('MonkeyLogic', 'Directories');
system(sprintf('%smlhelper --syskeys-enable',dirs.BaseDirectory));

%%
function clip_cursor(varargin)
global MLHELPER_OFF
if MLHELPER_OFF,
    return
end
if nargin == 1,
    rect = varargin{1};
elseif nargin == 4,
    rect = [varargin{1:4}];
else
    error('clip_cursor takes 1 1x4 array or 4 scalars.');
end
sheight = get(0,'ScreenSize');
sheight = sheight(4);
l = rect(1);
t = sheight-(rect(2)+rect(4));
r = rect(1)+rect(3);
b = sheight-rect(2);
dirs = getpref('MonkeyLogic', 'Directories');
system(sprintf('%smlhelper --cursor-clip %i %i %i %i',dirs.BaseDirectory,l,t,r,b));

%%
function unclip_cursor
global MLHELPER_OFF
if MLHELPER_OFF,
    return
end
dirs = getpref('MonkeyLogic', 'Directories');
system(sprintf('%smlhelper --cursor-unclip',dirs.BaseDirectory));

%%
function mlhelper_stop
global MLHELPER_OFF
if MLHELPER_OFF,
    return
end
dirs = getpref('MonkeyLogic', 'Directories');
system(sprintf('%smlhelper --stop',dirs.BaseDirectory));
