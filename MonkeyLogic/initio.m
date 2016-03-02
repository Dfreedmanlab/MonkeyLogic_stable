function [DAQ, DaqError] = initio(IO)
% Converts the structure of i/o assignments into actual DAQ objects
%
% Created by WA 8/28/06
% Revised 12/20/06 -WA (near complete re-write)
% Modified 2/19/08 -WA (incorporated DJF changes to analog channel input range parameters)
% Modified 2/21/08 -WA (incorporated code for "Buttons" & reward configuration settings)
% Last modified 8/11/08 -WA (to make certain analog-input objects use DMA)
% Last modified 11/17/15 -ER (Added DigitalInputStream for touchscreens and other future devices)

logger = log4m.getLogger('monkeylogic.log');
logger.setCommandWindowLevel(logger.ALL); 
logger.setLogLevel(logger.ALL);

logger.info('initio.m', '<<< MonkeyLogic >>> Initializing I/O');

%for manual editing:
configIO.AI.BufferingConfig =  [16 1024]; %[1 2000];
configIO.AI.InputRange = [-10 10];
configIO.Reward.TriggerValue = 5; %if analog, number of volts to trigger or hold at (will be "1" if digital).

%from menu:
if isfield(IO.Configuration, 'AnalogInputFrequency')
    configIO.AI.SampleRate = IO.Configuration.AnalogInputFrequency;
end
if isfield(IO.Configuration, 'AnalogInputType')
    configIO.AI.InputType = IO.Configuration.AnalogInputType;
end
if isfield(IO.Configuration, 'AnalogInputDuplication')
    configIO.AI.AnalogInputDuplication = IO.Configuration.AnalogInputDuplication;
end
if isfield(IO.Configuration, 'RewardPolarity')
    configIO.Reward.Polarity = IO.Configuration.RewardPolarity; %+1 for positive-edge reward trigger, -1 for negative edge
end

IO = rmfield(IO, 'Configuration');
daqreset;

fnames = fieldnames(IO);
numfields = length(fnames);
for i = 1:numfields,
    fn = fnames{i};
    DAQ.(fn) = [];
    fnfrag = fn(1:3);

    if strcmp(fnfrag, 'Eye') || strcmp(fnfrag, 'Joy') || strcmp(fnfrag, 'Gen'),
        REQSYS.(fn) = {'AnalogInput'};
    elseif strcmp(fnfrag, 'Tou') || strcmp(fnfrag, 'Mou'),
        REQSYS.(fn) = {'DigitalInputStream'};
    elseif strcmp(fnfrag, 'Rew'),
        REQSYS.(fn) = {'DigitalIO' 'AnalogOutput'};
    elseif strcmp(fnfrag, 'Cod') || strcmp(fnfrag, 'Dig'),
        REQSYS.(fn) = {'DigitalIO'};
    elseif strcmp(fnfrag, 'Vsy') || strcmp(fnfrag, 'Pho'),
        REQSYS.(fn) = {'AnalogInput'};
    elseif strcmp(fnfrag, 'But'),
        REQSYS.(fn) = {'DigitalIO' 'AnalogInput'};
    elseif strcmp(fnfrag, 'Sti'),
        REQSYS.(fn) = {'AnalogOutput'};
    elseif strcmp(fnfrag, 'TTL'),
        REQSYS.(fn) = {'DigitalIO'};
    else
        logger.info('initio.m', sprintf('Warning: Unable to test IO type %s for subsystem validity using "initio.m"', fn));
    end
end

DaqError = [];

%Check that basic assignments are permitted:
for i = 1:length(fnames),
    fn = fnames{i};
    io = IO.(fn);
    if isfield(io, 'Adaptor'),
        reqsys = REQSYS.(fn);
        if ~any(strcmpi(io.Subsystem, reqsys)),
            DaqError = cell(2, 1);
            DaqError{1} = '*** Error: Non-permitted I/O mapping ***';
            DaqError{2} = sprintf('Allowed Type for %s: %s %s ', fn, reqsys{:});
            logger.info('initio.m', sprintf('*** Error: Non-permitted I/O mapping for %s ***', fn));
            return
        end
    end
end

%Check that all analog inputs are on the same board:
count = 0;
aicstr = {};
for i = 1:length(fnames),
    fn = fnames{i};
    if isfield(IO.(fn), 'Adaptor') && strcmp(IO.(fn).Subsystem, 'AnalogInput'),
        count = count + 1;
        aicstr{count} = IO.(fn).Constructor; %#ok<AGROW>
    end
end
if length(unique(aicstr)) > 1,
    DaqError{1} = '*** Error: All analog inputs must be on the same board ***';
    logger.info('initio.m', DaqError{1});
    return
end

%Check that all buttons are either digital or analog inputs (not mixed)
count = 0;
butsys = {};
for i = 1:length(fnames),
    fn = fnames{i};
    if strfind(fn, 'Button'),
        if isfield(IO.(fn), 'Adaptor'),
            count = count + 1;
            butsys{count} = IO.(fn).Subsystem; %#ok<AGROW>
        end
    end
end
if count > 1 && length(unique(butsys)) > 1,
   DaqError{1} = '*** Error: Button inputs must be either all analog or all digital ***';
   logger.info('initio.m', DaqError{1});
end

DAQ.AnalogInput = [];
DAQ.AnalogInput2 = [];
DAQ.AnalogOutput = [];
DAQ.EyeSignal = [];
DAQ.Joystick = [];
DAQ.TouchSignal = [];
DAQ.MouseSignal = [];
DAQ.Buttons = [];
DAQ.General = [];
DAQ.BehavioralCodes = [];

EyeXpresent = isfield(IO.EyeX, 'Adaptor');
EyeYpresent = isfield(IO.EyeY, 'Adaptor');
if EyeXpresent || EyeYpresent,
    numfieldsEyeX = length(fieldnames(IO.EyeX));
    numfieldsEyeY = length(fieldnames(IO.EyeY));
end
if EyeXpresent || EyeYpresent,
    if numfieldsEyeX ~= numfieldsEyeY,
        DaqError{1} = 'I/O Error: Must define 0 or 2 eye signal inputs';
        logger.info('initio.m', '<<< MonkeyLogic >>> I/O Error: Must define 0 or 2 eye signal inputs');
        return 
    end
end

JoyXpresent = isfield(IO.JoyX, 'Adaptor');
JoyYpresent = isfield(IO.JoyY, 'Adaptor');
if JoyXpresent || JoyYpresent,
    numfieldsJoyX = length(fieldnames(IO.JoyX));
    numfieldsJoyY = length(fieldnames(IO.JoyY));
end
if JoyXpresent || JoyYpresent,
    if numfieldsJoyX ~= numfieldsJoyY,
        DaqError{1} = 'I/O Error: Must define 0 or 2 joystick inputs';
        logger.info('initio.m', '<<< MonkeyLogic >>> I/O Error: Must define 0 or 2 joystick inputs');
        return
    end
end

TouchXpresent = isfield(IO.TouchX, 'Adaptor');
TouchYpresent = isfield(IO.TouchY, 'Adaptor');
if TouchXpresent || TouchYpresent,
    numfieldsTouchX = length(fieldnames(IO.TouchX));
    numfieldsTouchY = length(fieldnames(IO.TouchY));
end
if TouchXpresent || TouchYpresent,
    if numfieldsTouchX ~= numfieldsTouchY,
        DaqError{1} = 'I/O Error: Must define 0 or 2 touchscreen inputs';
        logger.info('initio.m', '<<< MonkeyLogic >>> I/O Error: Must define 0 or 2 touchscreen inputs');
        return
    end
end

MouseXpresent = isfield(IO.MouseX, 'Adaptor');
MouseYpresent = isfield(IO.MouseY, 'Adaptor');
if MouseXpresent || MouseYpresent,
    numfieldsMouseX = length(fieldnames(IO.MouseX));
    numfieldsMouseY = length(fieldnames(IO.MouseY));
end
if MouseXpresent || MouseYpresent,
    if numfieldsMouseX ~= numfieldsMouseY,
        DaqError{1} = 'I/O Error: Must define 0 or 2 mouse inputs';
        logger.info('initio.m', '<<< MonkeyLogic >>> I/O Error: Must define 0 or 2 mouse inputs');
        return
    end
end

%Look for duplicate boards:
AdaptorInfo = ioscan();
adaptors = {AdaptorInfo(:).Name};

duplicateboard = zeros(length(adaptors), 1);
for i = 1:length(adaptors), %if 2 or more boards by the same name exist, then duplicate them
    matches = strcmp(adaptors(i), adaptors);
    if sum(matches) > 1,
        f = find(matches);
        duplicateboard(i) = f(f ~= i);
    end
end

%Create DAQ objects within DAQ structure
for i = 1:length(fnames),
    signame = fnames{i};
    sigpresent = isfield(IO.(signame), 'Adaptor');

    if sigpresent,
        if strcmpi(IO.(signame).Subsystem, 'AnalogInput'),

            %create ai objects
            if isempty(DAQ.AnalogInput),
                [DAQ.AnalogInput DaqError] = init_ai(IO.(signame).Constructor, configIO);
                if ~isempty(DaqError),
                    DaqError{1} = sprintf('%s: %s', signame, DaqError{1});
                    logger.info('initio.m', DaqError{1});
                    daqreset;
                    return
                end
            end
            ch = addchannel(DAQ.AnalogInput, IO.(signame).Channel, signame);
            
%             srange = get(ch, 'SensorRange');
%             if srange(1) > configIO.AI.InputRange(1),
%                 configIO.AI.InputRange(1) = srange(1);
%                 disp(sprintf('Warning: Voltage range minimum for analog acquisition is %2.1f V', srange(1)));
%             end
%             if srange(2) < configIO.AI.InputRange(2),
%                 configIO.AI.InputRange(2) = srange(2);
%                 disp(sprintf('Warning: Voltage range maximum for analog acquisition is %2.1f V', srange(2)));
%             end
            
            ch.InputRange = configIO.AI.InputRange;   % added by DJF 2/14/08
            ch.SensorRange = configIO.AI.InputRange;  %
            ch.UnitsRange = configIO.AI.InputRange;   %

            if strcmp(signame, 'EyeX'),
                DAQ.EyeSignal.XChannelIndex = ch.Index;
            elseif strcmp(signame, 'EyeY'),
                DAQ.EyeSignal.YChannelIndex = ch.Index;
            elseif strcmp(signame, 'JoyX'),
                DAQ.Joystick.XChannelIndex = ch.Index;
            elseif strcmp(signame, 'JoyY'),
                DAQ.Joystick.YChannelIndex = ch.Index;
            elseif ~isempty(strfind(signame, 'Button')),
                if ~isfield(DAQ.Buttons, 'ButtonsPresent'),
                    DAQ.Buttons.ButtonsPresent = [];
                end
                buttonnumber = str2double(signame(length(signame)));  %as is, will work for up to only 9 buttons
                DAQ.Buttons.ButtonsPresent = [DAQ.Buttons.ButtonsPresent buttonnumber];
                DAQ.Buttons.(signame).ChannelIndex = ch.Index;
                DAQ.Buttons.Subsystem = 'analog';
            elseif ~isempty(strfind(signame, 'Gen')),
                if ~isfield(DAQ.General, 'GeneralPresent'),
                    DAQ.General.GeneralPresent = [];
                end
                generalnumber = str2double(signame(length(signame)));  %as is, will work for up to only 9 general
                DAQ.General.GeneralPresent = [DAQ.General.GeneralPresent generalnumber];
                DAQ.General.(signame).ChannelIndex = ch.Index;
                DAQ.General.Subsystem = 'analog';
            else
                DAQ.(signame).ChannelIndex = ch.Index;
            end

            board2 = duplicateboard(strcmp(IO.(signame).Adaptor, adaptors));
            if any(board2) && configIO.AI.AnalogInputDuplication && isempty(DAQ.AnalogInput2),
                IO.(signame).Constructor2 = [];
                for k = 1:length(board2),
                    aisubsysnum = strcmpi(AdaptorInfo(board2(k)).SubSystemsNames, 'AnalogInput');
                    cstr = AdaptorInfo(board2(k)).SubSystemsConstructors{aisubsysnum};
                    if ~strcmp(cstr, IO.(signame).Constructor),
                        IO.(signame).Constructor2 = cstr;
                    end
                end
                if ~isempty(IO.(signame).Constructor2),
                    [DAQ.AnalogInput2 DaqError] = init_ai(IO.(signame).Constructor2, configIO);
                    if ~isempty(DaqError),
                        DaqError{1} = sprintf('%s: %s', signame, DaqError{1});
                        disp(DaqError{1})
                        daqreset;
                        return
                    end
                else
                    disp('Warning: Cannot distribute AI functions across existing devices');
                end
            elseif ~any(board2) && configIO.AI.AnalogInputDuplication,
                h = findobj('tag', 'monkeylogicmainmenu');
                if ~isempty(h) && strcmpi(get(findobj(h, 'tag', 'aiduplication'), 'enable'), 'on'),
                    logger.info('initio.m', sprintf('Warning: No duplicate boards found to assign %s...', signame));
                    logger.info('initio.m', '... must sample and store data from the same DAQ board (suboptimal performance will result)');
                end
            end
            
            if ~isempty(DAQ.AnalogInput2) && configIO.AI.AnalogInputDuplication,
            	ch = addchannel(DAQ.AnalogInput2, IO.(signame).Channel, signame);
                ch.InputRange=configIO.AI.InputRange;
                ch.SensorRange=configIO.AI.InputRange;
                ch.UnitsRange=configIO.AI.InputRange;
            else
                DAQ.AnalogInput.BufferingConfig = configIO.AI.BufferingConfig; %shrink buffers for more frequent data transfers
            end
             
        elseif strcmpi(IO.(signame).Subsystem, 'DigitalInputStream'),
            if strcmp(signame, 'TouchX'),
                DAQ.TouchSignal.XChannelIndex = IO.(signame).Channel;
            elseif strcmp(signame, 'TouchY'),
                DAQ.TouchSignal.YChannelIndex = IO.(signame).Channel;
            elseif strcmp(signame, 'MouseX'),
                DAQ.MouseSignal.XChannelIndex = IO.(signame).Channel;
            elseif strcmp(signame, 'MouseY'),
                DAQ.MouseSignal.YChannelIndex = IO.(signame).Channel;
            end
            
        elseif strcmp(signame, 'Reward'),

            if strcmpi(IO.Reward.Subsystem, 'AnalogOutput'),
                if isempty(DAQ.AnalogOutput),
                    DAQ.AnalogOutput = eval(IO.Reward.Constructor);
                end
                ch = addchannel(DAQ.AnalogOutput, IO.Reward.Channel, 'Reward');
                DAQ.Reward.Subsystem = 'analog';
                DAQ.Reward.ChannelIndex = ch.Index;
                DAQ.Reward.TriggerValue = configIO.Reward.TriggerValue;
            else
                DAQ.Reward.DIO = eval(IO.Reward.Constructor);
                portnumber = IO.Reward.Channel;
                if ~isfield(IO.Reward, 'Line'),
                    lineabsenterror;
                end
                hwline = IO.Reward.Line;
                addline(DAQ.Reward.DIO, hwline, portnumber, 'out', 'Reward');
                DAQ.Reward.Subsystem = 'digital';
                DAQ.Reward.TriggerValue = 1;
            end
            DAQ.Reward.Polarity = configIO.Reward.Polarity;

        elseif strcmp(signame, 'CodesDigOut') || strcmp(signame, 'DigCodesStrobeBit'),

            if ~isfield(IO.CodesDigOut, 'Constructor'),
               DaqError{1} = '*** No digital lines assigned for event marker output ***';
               logger.info('initio.m', DaqError{1});
               daqreset;
               return
            end
            if ~isfield(IO.DigCodesStrobeBit, 'Constructor'),
                DaqError{1} = '*** Must assign a strobe bit for behavioral code digital output ***';
                logger.info('initio.m', DaqError{1});
                daqreset;
                return
            end
            if ~strcmp(IO.DigCodesStrobeBit.Constructor, IO.CodesDigOut.Constructor),
                DaqError{1} = '*** Strobe bit line must be on the same board & subsystem as the behavioral code data lines ***';
                logger.info('initio.m', DaqError{1});
                daqreset;
                return
            end
            
            DAQ.BehavioralCodes.DIO = eval(IO.CodesDigOut.Constructor);
            portnumber = IO.CodesDigOut.Channel;
            if ~isfield(IO.CodesDigOut, 'Line'),
                lineabsenterror;
            end
            hwlines = IO.CodesDigOut.Line;
            try
                % no need to specify the port number. Lines are coded in
                % the following manner:
                % e.g. for 3 ports with 8 lines in each port:
                % Port0->Lines 0-7, Port1->Lines 8-15, Port2->Lines 16-23
                DAQ.BehavioralCodes.DataBits = addline(DAQ.BehavioralCodes.DIO, hwlines, 'out', 'BehaviorCodes');
            catch
                DaqError{1} = '*** Unable to assign output digital lines for Behavioral Codes ***';
                logger.info('initio.m', DaqError{1});
                rethrow(lasterror);
                daqreset;
                return
            end
                        
            portnumber = IO.DigCodesStrobeBit.Channel;
            hwline = IO.DigCodesStrobeBit.Line;
            try
                DAQ.BehavioralCodes.StrobeBit = addline(DAQ.BehavioralCodes.DIO, hwline, portnumber, 'out', 'StrobeBit');
            catch
                DaqError{1} = sprintf('*** Unable to assign line %i on port %i as a digital strobe output bit ***', hwline, portnumber);
                logger.info('initio.m', DaqError{1});
                daqreset;
                return
            end
            
        elseif strfind(signame, 'Stim'),
            
            if isempty(DAQ.AnalogOutput),
                DAQ.AnalogOutput = eval(IO.(signame).Constructor);
            end
            ch = addchannel(DAQ.AnalogOutput, IO.(signame).Channel, signame);
            DAQ.(signame).ChannelIndex = ch.Index;
            
        elseif strfind(signame, 'TTL'),

            if ~isfield(IO.(signame), 'Line'),
                lineabsenterror;
            end
            portnumber = IO.(signame).Channel;
            DAQ.(signame) = eval(IO.(signame).Constructor);
            addline(DAQ.(signame), IO.(signame).Line, portnumber, 'out', signame);
            
        elseif strfind(signame, 'Button'),
            
            %if analog input, DAQ object already created, above.
            if strcmpi(IO.(signame).Subsystem, 'DigitalIO'),
                if ~isfield(DAQ.Buttons, 'DIO'),
                    DAQ.Buttons.DIO = eval(IO.(signame).Constructor);
                    DAQ.Buttons.ButtonsPresent = [];
                end
                buttonnumber = str2double(signame(length(signame)));
                DAQ.Buttons.ButtonsPresent = [DAQ.Buttons.ButtonsPresent buttonnumber];
                portnumber = IO.(signame).Channel;
                if ~isfield(IO.(signame), 'Line'),
                    lineabsenterror;
                end
                hwline = IO.(signame).Line;
                addline(DAQ.Buttons.DIO, hwline, portnumber, 'in', signame);
                DAQ.Buttons.Subsystem = 'digital';
            end

        end
    end
end

if ~isempty(DAQ.AnalogOutput),
    set(DAQ.AnalogOutput, 'TriggerType', 'Manual');
end

rmf = {'EyeX' 'EyeY' 'JoyX' 'JoyY' 'TouchX' 'TouchY' 'MouseX' 'MouseY' 'CodesDigOut' 'DigCodesStrobeBit'};
for i = 1:length(rmf),
    if isfield(DAQ, rmf{i}),
        DAQ = rmfield(DAQ, rmf{i});
    end
end
fn = fieldnames(DAQ);
for i = 1:length(fn),
    fname = fn{i};
    if ~isempty(strfind(fname, 'Button')) && ~strcmp(fname, 'Buttons'),
        DAQ = rmfield(DAQ, fname);
    end
end
fn = fieldnames(DAQ);
for i = 1:length(fn),
    fname = fn{i};
    if ~isempty(strfind(fname, 'Gen')) && ~strcmp(fname, 'General'),
        DAQ = rmfield(DAQ, fname);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ai DaqError] = init_ai(constructor, configIO)
DaqError = [];
try
    ai = eval(constructor);
catch
    ai = [];
    DaqError{1} = 'Cannot create analog input object';
    return
end
transfertypes = get(ai, 'TransferMode');
tfound = strcmpi(transfertypes, 'DualDMA');
if any(tfound),
    set(ai, 'TransferMode', 'DualDMA');
else
    tfound = strcmpi(transfertypes, 'SingleDMA');
    if any(tfound),
        set(ai, 'TransferMode', 'SingleDMA');
    else
        disp('Warning: unable to set analog inputs to transfer over DMA');
    end
end
try
    actualrate = setverify(ai, 'SampleRate', configIO.AI.SampleRate);
catch
    actualrate = NaN;
end
if actualrate ~= configIO.AI.SampleRate,
    DaqError{1} = sprintf('Cannot set analog input sample rate to desired value of %i Hz', configIO.AI.SampleRate);
    return
end
ai.SamplesPerTrigger = Inf;
ai.InputType = configIO.AI.InputType;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function lineabsenterror
error('*** Newer versions of MonkeyLogic require selecting specific lines for Digital output.  Please re-set digital outputs in main menu. ***');
