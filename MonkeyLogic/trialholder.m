function TrialData = trialholder(TaskObject, ScreenInfo, DaqInfo, EyeTransform, JoyTransform, BehavioralCodes, TrialRecord, trialtype)
global SIMULATION_MODE

% This is the code into which a timing script is embedded (by
% "embedtimingfile") to create the run-time trial function.  
% 
% See www.monkeylogic.org for more information.
%
% Created by WA 6/15/06
% modified 12/20/06 -WA (new DAQ structure incorporated)
% modified 1/19/08 -WA (new video routines to check vertical blank status) 
% modified 4/03/08 -WA (fixed bug re: sending multiple codes to 'eventmarker')
% modified 7/23/08 -WA (getkeypress now properly restores run-time priority)
% modified 7/25/08 -WA (now saves absolute trial start time)
% modified 8/10/08 -WA (joystick cursor now properly centered)
% modified 8/24/08 -MS & WA (movie presentation & translation added)
% - several undocumented modifications during this stretch of time -
% modified 5/01/12 -WA (to fix bugs visualizing joystick cursor)
% modified 5/07/12 -WA (to allow use of multiple "tic" commands, using ticID syntax)
% modified 10/2/12 -DF (to fix bug that caused first movie frame to be
% displayed twice)
% modified 3/18/13 -DF (set_object_path bug fix)
% modified 3/28/13 -DF (ttl bug fix/ modify/improve toggleobject)

Codes = []; %#ok<NASGU>
rt = NaN; %#ok<NASGU>
AIdata = []; %#ok<NASGU>

%flush keyboard buffer
mlkbd('flush');

%start DAQ objects for Eye & Joystick
if ~isempty(DaqInfo.AnalogInput),
    %set(DaqInfo.AnalogInput,'DataMissedFcn',@data_missed);
    start(DaqInfo.AnalogInput);
    while ~isrunning(DaqInfo.AnalogInput), end
    trialtime(-1, ScreenInfo); %initialize trial timer
    set(gcf, 'CurrentAxes', findobj(ScreenInfo.ControlScreenHandle, 'tag', 'replica'));
    drawnow; %flush all pending graphics
    while ~DaqInfo.AnalogInput.SamplesAvailable, end
else
    trialtime(-1, ScreenInfo); %initialize trial timer
end
%%% initialize video subroutines:
toggleobject(-1, TaskObject, ScreenInfo, DaqInfo);
set_frame_order(-1, TaskObject);
reposition_object(-1, TaskObject, ScreenInfo);
set_object_path(-1, TaskObject, ScreenInfo);
set_iti(-1);
showcursor(-1, ScreenInfo);
%%% initialize i/o subroutines:
eyejoytrack(-1, TaskObject, DaqInfo, ScreenInfo, EyeTransform, JoyTransform);
idle(-1, ScreenInfo);
joystick_position(-1, DaqInfo, ScreenInfo, JoyTransform);
eye_position(-1, DaqInfo, ScreenInfo, EyeTransform);
simulation_positions(-1);
get_analog_data(-1, DaqInfo, EyeTransform, JoyTransform);
getkeypress(-1, ScreenInfo);
hotkey(-1);
goodmonkey(-1, DaqInfo);
user_text(-1, ScreenInfo);
user_warning(-1, ScreenInfo);
bhv_variable(-1);
%%% initialize end-trial subroutine;
end_trial(-1, DaqInfo, ScreenInfo, EyeTransform, JoyTransform, trialtype);
%%% initialize eventmarker subroutine
eventmarker(-1, DaqInfo, BehavioralCodes);

if trialtype == 0, %a regular task trial
    eventmarker(9);
    eventmarker(9);
    eventmarker(9);
elseif trialtype == 1, %initialization trial
    user_warning('off');
    mov = 1;
    t = (1000*TaskObject(mov).NumFrames/ScreenInfo.RefreshRate) - 50;
    toggleobject(mov);
    goodmonkey(-2); %will test output only if reward line exists
    idle(t);
    toggleobject(mov);
    end_trial;
    return
elseif trialtype == 2, %benchmark trial
    user_warning('off');
    disp('<<< MonkeyLogic >>> Entering benchmark mode...'); %mltimetest.m takes over from here
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% EASY ESCAPE
hotkey('esc', 'escape_screen;');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% EYE OFFSET
hotkey('c', 'eye_position(-2);');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% REWARD
hotkey('r', 'goodmonkey(100);');
hotkey('-', 'goodmonkey(-4,-10);');
hotkey('=', 'goodmonkey(-4,10);');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% WARNINGS
hotkey('w', 'user_warning(-2);');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SIMULATION MODE
SIMULATION_MODE = TrialRecord.SimulationMode;

hotkey('numrarr', 'simulation_positions(1,1,1);');
hotkey('numlarr', 'simulation_positions(1,1,-1);');
hotkey('numuarr', 'simulation_positions(1,2,1);');
hotkey('numdarr', 'simulation_positions(1,2,-1);');

hotkey('rarr', 'simulation_positions(1,3,1);');
hotkey('larr', 'simulation_positions(1,3,-1);');
hotkey('uarr', 'simulation_positions(1,4,1);');
hotkey('darr', 'simulation_positions(1,4,-1);');

hotkey('space', 'simulation_positions(2,5,-Inf);');
hotkey('bksp', 'simulation_positions(2,5,Inf);');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isfield(TrialRecord, 'CurrentConditionInfo')
	Info = TrialRecord.CurrentConditionInfo;       %#ok<NASGU>
else
	Info = []; %#ok<NASGU>
end
if isfield(TrialRecord, 'CurrentConditionStimulusInfo')
	StimulusInfo = TrialRecord.CurrentConditionStimulusInfo; %#ok<NASGU>
else
	StimulusInfo = []; %#ok<NASGU>
end
user_text('');
try
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%INSERT TRIAL POINT********************************************************
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%end_trial subroutine called by run-time script (necessary code inserted by
%embedtimingfile.m at this point and at any "return" statement)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
catch ME
    if strcmp(ME.identifier,'ML:TrialAborted'),
        toggleobject(-5);
        end_trial(-2,9);
        TrialData = end_trial;
        TrialData.ReactionTime = NaN;
        TrialData.TrialRecord = TrialRecord;
        return;
    else
        rethrow(ME);
    end
end

return

%%
function [tflip, framenumber] = toggleobject(stimuli, varargin)
persistent TrialObject ScreenData DAQ togglecount ObjectStatusRecord yrasterthresh ltb lastframe activemovies % %taken from TaskObject & ScreenInfo

tflip = [];
framenumber = [];
movie_advance_only = 0;
update_cursor = 0;
if stimuli == -1, %initialize
    TrialObject = varargin{1};
    ScreenData = varargin{2};
    DAQ = varargin{3};
    mlvideo('clear', ScreenData.Device, ScreenData.BackgroundColor);
    mlvideo('flip', ScreenData.Device);
    if ScreenData.PhotoDiode > 1,
        ScreenData.PdStatus = 0;
    end
    ltb = length(TrialObject);
    togglecount = 0;
    ObjectStatusRecord = [];
    yrasterthresh = floor(0.9*ScreenData.Ysize);
    lastframe = 0;
    activemovies = false(ltb, 1);
    return
elseif stimuli == -2, %trial exit data
    tflip = ObjectStatusRecord;
    return
elseif stimuli == -3, %call from reposition_object or set_object_path
    stimnum = varargin{1};
	status = TrialObject(stimnum).Status;
	TrialObject(stimnum) = varargin{2};
	TrialObject(stimnum).Status = status;
    statrec = double(cat(1, TrialObject.Status));
    if varargin{3}, %called from reposition_object, not set_object_path
        togglecount = togglecount + 1;
        statrec(stimnum) = 2;
        ObjectStatusRecord(togglecount).Time = round(trialtime);
        ObjectStatusRecord(togglecount).Status = statrec;
        ObjectStatusRecord(togglecount).Data{1} = [TrialObject(stimnum).XPos TrialObject(stimnum).YPos];
        if TrialObject(stimnum).Status
            toggleobject(stimnum, 'Status', 'On', 'drawmode', 'fast');
        end
    end
    return
elseif stimuli == -4, %update movies and/or subject's cursor only
    movie_advance_only = 1;
	if ~isempty(varargin),
        cursorpos = varargin{1};
        update_cursor = 1;
	end
elseif stimuli == -5, %turn off all TrialObjects with status.  Called when trial is aborted.
    ob = TrialObject(1:ltb);
    ob = [ob.Status];
    f = find(ob);
    if ~isempty(f),
        toggleobject(f);
    end
    return;
end

fastdraw = 0; %will draw to subject screen but not control screen if == 1
behavioralcode = [];
statselect = 0;
setstartframe = 0;
setstartposition = 0;

if ~isempty(varargin) && ~movie_advance_only,
    numargs = length(varargin);
    if mod(numargs, 2),
        error('ToggleObject requires all arguments beyond the first to come in parameter/value pairs');
    end
    for k = 1:2:numargs,
        v = varargin{k};
        a = varargin{k+1};
        if ~ischar(v),
            error('ToggleObject requires all arguments beyond the first to come in parameter/value pairs');
        end
        if strcmpi(v, 'status'),
            statselect = 1;
            statval = 0;
            if ischar(a),
                if strcmpi(a, 'on'),
                    statval = 1;
                elseif ~strcmpi(a, 'off'),
                    error('Unrecognized value %s for Toggleobject parameter "status"', a);
                end
            elseif a,
                statval = 1;
            end
            for i = 1:length(stimuli),
                TrialObject(stimuli(i)).Status = statval;
            end
        elseif strcmpi(v, 'drawmode'),
            if (ischar(a) && strcmpi(a, 'fast')) || (~ischar(a) && a),
                fastdraw = 1;
            end
        elseif strcmpi(v, 'eventmarker'),
            if ischar(a),
                error('Value for <Toggleobject: EventMarker> must be numeric');
            end
            behavioralcode = a;
        elseif strcmpi(v, 'moviestartframe'),
            if ischar(a) || iscell(a),
                error('Value for <Toggleobject: MovieStartFrame> must be numeric');
            end
            if length(a) == 1
				for i = stimuli
					TrialObject(i).StartFrame = a;
				end
			elseif length(a) == length(stimuli)
				for i = length(stimuli)
					TrialObject(stimuli(i)).StartFrame = a(i);
				end
            else
                error('Number of values for <ToggleObject: MovieStartFrame> must be equal to the number of specified stimuli, or scalar');
            end
            setstartframe = 1;
        elseif strcmpi(v, 'moviestep'),
			if ischar(a) || iscell(a),
                error('Value for <Toggleobject: MovieStep> must be numeric');
			end
			if length(a) == 1
				for i = stimuli
					TrialObject(i).FrameStep = a;
				end
			elseif length(a) == length(stimuli)
				for i = length(stimuli)
					TrialObject(stimuli(i)).FrameStep = a(i);
				end
            else
                error('Number of values for <ToggleObject: MovieStep> must be equal to the number of specified stimuli, or scalar');
			end
			if ~setstartframe && any(a < 0),
				stimsubset = stimuli(a < 0);
				for i = 1:length(stimsubset),
					TrialObject(stimsubset(i)).StartFrame = TrialObject(stimsubset(i)).NumFrames; %start playing backwards from last frame
				end
			end
        elseif strcmpi(v, 'startposition'),
            if ischar(a) || iscell(a),
                error('Value for <Toggleobject: StartPosition> must be numeric');
            end
            if length(a) == 1
				for i = stimuli
					TrialObject(i).StartPosition = a;
				end
			elseif length(a) == length(stimuli)
				for i = length(stimuli)
					TrialObject(stimuli(i)).StartPosition = a(i);
				end
            else
                error('Number of values for <ToggleObject: StartPosition> must be equal to the number of specified stimuli, or scalar');
            end
            setstartposition = 1;
        elseif strcmpi(v, 'positionstep'),
			if ischar(a) || iscell(a),
                error('Value for <Toggleobject: PositionStep> must be numeric');
			end
			if length(a) == 1
				for i = 1 : stimuli
					TrialObject(i).PositionStep = a;
				end
			elseif length(a) == length(stimuli)
				for i = length(stimuli)
					TrialObject(stimuli(i)).PositionStep = a(i);
				end
            else
                error('Number of values for <ToggleObject: PositionStep> must be equal to the number of specified stimuli, or scalar');
			end
			if ~setstartposition && any(a < 0),
				stimsubset = stimuli(a < 0);
				for i = 1:length(stimsubset),
					TrialObject(stimsubset(i)).StartPosition = TrialObject(stimsubset(i)).NumPositions; %start translating backwards from last position
				end
			end
        else
            error('Unrecognized option "%s" calling ToggleObject', v);
        end
    end
end

if ~statselect && stimuli(1) && ~movie_advance_only, %(i.e., if ~stimuli(1) redraw only, without toggling)
    for i = 1:length(stimuli),
        stimnum = stimuli(i);
        TrialObject(stimnum).Status = ~TrialObject(stimnum).Status;
    end
end

if stimuli(1) || movie_advance_only,
    togglecount = togglecount + 1;
end

initmovies = false(ltb, 1);
posarray = zeros(ltb, 2);

mlvideo('clear', ScreenData.Device, ScreenData.BackgroundColor);
[t currentframe] = trialtime;
while currentframe == lastframe, %to avoid queueing flips in the same frame
    [t currentframe] = trialtime;
end

videochange = 0;

if any(stimuli == -4 | stimuli == 0)										%the bitwise or takes care of cases where stimuli is a vector
	stimuli_fortoggle = find([TrialObject.Status] ~= 0);
	stimuli_fortoggle = fliplr(stimuli_fortoggle);
else
	temp = find([TrialObject.Status] ~= 0);									%all objects with non-zero status
	temp = setdiff(temp, stimuli);											%all objects with non-zero status excluding stimuli objects
																			%this is in case the same stimulus is called multiple times
	stimuli_fortoggle = sort([stimuli temp], 2, 'descend');
end

for i = stimuli_fortoggle,
	ob = TrialObject(i);
    if ob.Status,
        if ob.Modality == 1, %static video object
            mlvideo('blit', ScreenData.Device, ob.Buffer, ob.XsPos, ob.YsPos, ob.Xsize, ob.Ysize);
            videochange = 1;
        elseif ob.Modality == 2, %movie
            if ~movie_advance_only && ~activemovies(i) && ~ob.Used, % initialize movie
                ob.Status = ob.StartFrame;
                ob.CurrentPosition = ob.StartPosition;
                initmovies(i) = 1;
				ob.Used = 1;
				ob.CurrFrame = ob.InitFrame;
            else %advance frame(s) and / or position(s)
				if currentframe - lastframe > 1,
                    eventmarker(13);
                    fprintf('Warning: skipped %i frame(s) of %s at %3.1f ms\n', (currentframe - lastframe - 1), ob.Name, trialtime);
                    user_warning('Skipped %i frame(s) of %s at %3.1f ms', (currentframe - lastframe - 1), ob.Name, trialtime);
				end
				
				if ~activemovies(i)			%this is for when an object is toggled back on after being toggled off in one trial
					activemovies(i) = 1;
				end
				
                indx = round(ob.FrameStep*(currentframe - ob.InitFrame)) + ob.StartFrame;
                modulus = max(length(ob.FrameOrder),ob.NumFrames);
                indx = mod(indx, modulus);
				if indx == 0
					indx = modulus;			%don't want the last frame to be skipped
				end
                
				if ~isempty(ob.FrameEvents),
                    f_list = ob.FrameEvents(1,:);
                    e_list = ob.FrameEvents(2,:);
                    f = find(f_list == indx);
                    if ~isempty(f),
                        behavioralcode = e_list(f(1));
                    end
				end
                
				if indx > length(ob.FrameOrder),
                    ob.Status = indx - 1;									%the -1 negates the +1 that comes a few lines later
																			%that +1 is required to take care of set_object_path
                else
                    ob.Status = ob.FrameOrder(indx);
				end
				
				ob.Status = mod(ob.Status, ob.NumFrames) + 1;
				ob.CurrFrame = ob.CurrFrame + (currentframe - lastframe) * ob.PositionStep;
				indx = round(ob.CurrFrame - ob.InitFrame) + ob.StartPosition;
				ob.CurrentPosition = mod(indx, ob.NumPositions) + 1;
            end
            mlvideo('blit', ScreenData.Device, ob.Buffer(ob.Status), ob.XsPos(ob.CurrentPosition), ob.YsPos(ob.CurrentPosition), ob.Xsize, ob.Ysize);
            TrialObject(i) = ob; %update persistent TrialObject array
            %Save for ObjectStatusRecord:
            xpos = ob.XPos(ob.CurrentPosition);
            ypos = ob.YPos(ob.CurrentPosition);
            posarray(i, 1:2) = [xpos ypos];
            videochange = 1;
        elseif ob.Modality == 3 && ~movie_advance_only, % sound
            play(ob.PlayerObject);
            TrialObject(i).Status = 0;
        elseif ob.Modality == 4 && ~movie_advance_only, % analog stimulation
            trigger(DAQ.AnalogOutput);
            TrialObject(i).Status = 0;
        elseif ob.Modality == 5 && ~movie_advance_only, % TTL (digital) output
            putvalue(DAQ.(ob.Class), 1);
        end
    elseif ~ob.Status && ~movie_advance_only,
        if ob.Modality == 2, % reset activemovies flag for that movie
            activemovies(i) = 0;
        elseif ob.Modality == 3, % can abort sound manually
            stop(ob.PlayerObject);
        elseif ob.Modality == 5, % TTL must be turned off manually
            putvalue(DAQ.(ob.Class), 0);
        end
    end
end

%PhotoDiode
if ScreenData.PhotoDiode > 1 && videochange && ~update_cursor,
    if ~ScreenData.PdStatus,
        mlvideo('blit', ScreenData.Device, ScreenData.PdBuffer, ScreenData.PdX, ScreenData.PdY, ScreenData.PdXsize, ScreenData.PdYsize);
        ScreenData.PdStatus = 1;
    else
        mlvideo('blit', ScreenData.Device, ScreenData.PdBufferBlack, ScreenData.PdX, ScreenData.PdY, ScreenData.PdXsize, ScreenData.PdYsize);
        ScreenData.PdStatus = 0;
    end
end

%Subject's Joystick Cursor
if update_cursor,
    mlvideo('blit', ScreenData.Device, ScreenData.CursorBuffer, cursorpos(1), cursorpos(2), ScreenData.CursorXsize, ScreenData.CursorYsize);
    if ScreenData.PhotoDiode > 1, %keep current photodiode trigger on-screen (so doesn't flash with cursor)
        if ~ScreenData.PdStatus,
            mlvideo('blit', ScreenData.Device, ScreenData.PdBufferBlack, ScreenData.PdX, ScreenData.PdY, ScreenData.PdXsize, ScreenData.PdYsize);
        else
            mlvideo('blit', ScreenData.Device, ScreenData.PdBuffer, ScreenData.PdX, ScreenData.PdY, ScreenData.PdXsize, ScreenData.PdYsize);
        end
    end
end

% FLIP SCREEN
if ~isempty(behavioralcode), %syncs the code with the screen flip
    mlvideo('waitflip', ScreenData.Device, yrasterthresh);
    [tflip framenumber] = trialtime;
    while ~mlvideo('verticalblank', ScreenData.Device), end
    eventmarker(behavioralcode);
else %either movie update, cursor re-position, or no behavioral code
    mlvideo('flip', ScreenData.Device);
    [tflip framenumber] = trialtime;
end
lastframe = framenumber;
%disp(sprintf('T = %i ms;   Frame = %i', round(tflip), framenumber))

%send update to eyejoytrack so it knows about the user's call to toggleobject
if ~movie_advance_only,
    eyejoytrack(-5, TrialObject, framenumber);
end

%movie record-keeping
if any(initmovies),
	for i = (find(initmovies))'
		TrialObject(i).InitFrame = framenumber;
	end
    activemovies = activemovies | initmovies;
end

%update ObjectStatusRecord (used to play-back trials from BHV file)
if stimuli(1) && togglecount > 0,
    ObjectStatusRecord(togglecount).Time = round(trialtime);
    statrec = cat(1, TrialObject.Status);
    if any(activemovies),
        framearray = zeros(ltb, 1);
        fnum = statrec(activemovies);
        statrec(activemovies) = 3;
        framearray(activemovies) = fnum;
        ObjectStatusRecord(togglecount).Status = statrec;
        ObjectStatusRecord(togglecount).Data{1} = framearray;
        ObjectStatusRecord(togglecount).Data{2} = reshape(posarray, numel(posarray), 1);
        if movie_advance_only,
            return
        end
    else
        ObjectStatusRecord(togglecount).Status = statrec;
        ObjectStatusRecord(togglecount).Data{1} = [];
    end
end

%Update control-screen objects
if ~fastdraw,
    for i = 1:ltb,
        ob = TrialObject(i);
        if ob.Modality == 1 || ob.Modality == 2, %visual object or movie
            if ob.Status >= 1,
                set(ob.ControlObjectHandle, 'xdata', ob.XPos, 'ydata', ob.YPos);
            else
                set(ob.ControlObjectHandle, 'xdata', ScreenData.OutOfBounds, 'ydata', ScreenData.OutOfBounds);
            end
        elseif ob.Modality == 4 || ob.Modality == 5, %analog stimulation or TTL
            if ob.Status >= 1,
                set(ob.ControlObjectHandle, 'position', [ob.XPos ob.YPos 0]);
            else
                set(ob.ControlObjectHandle, 'position', [ScreenData.OutOfBounds ScreenData.OutOfBounds 0]);
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function eventmarker_long(codenumber, varargin)
persistent bitspercode

if codenumber == -1,
    bitspercode = varargin{1};
    return
elseif any(codenumber ~= floor(codenumber)) || any(codenumber <= 0),
    error('Eventmarker value must be a positive integer');
end

vec = dec2binvec(codenumber);
num = ceil(length(vec)/bitspercode);
codelist = zeros(1,num+2);
codelist(1)   = 254;
codelist(end) = 255;
for i = 1:num,
    a = (i-1)*bitspercode + 1;
    b = i*bitspercode;
    if b > length(vec),
        b = length(vec);
    end
    thiscode = false(1,bitspercode);
    thiscode(1:(b-a+1)) = vec(a:b);
    codelist(i+1) = binvec2dec(thiscode);
end
for i = 1:length(codelist),
    eventmarker(codelist(i));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Codes = eventmarker(codenumber, varargin)
persistent numcodes CodeNumbers CodeTimes DaqDIO digoutflag z databits strobebit sbval numdatabits

tstamp = round(trialtime);

if codenumber == -1, %set trial-start time
    numcodes = 0;
    maxcodes = 4096;
    CodeNumbers = zeros(maxcodes, 1);
    CodeTimes = CodeNumbers;
    DAQ = varargin{1};
    digoutflag = 0;
    if isfield(DAQ.BehavioralCodes, 'DIO'),
        digoutflag = 1;
        DaqDIO = DAQ.BehavioralCodes.DIO;
        databits = DAQ.BehavioralCodes.DataBits.Index;
        databits = cat(2, databits{:});
        numdatabits = length(databits);
        eventmarker_long(-1,numdatabits);
        strobebit = DAQ.BehavioralCodes.StrobeBit.Index;
        z = zeros(1, numdatabits+1);
        putvalue(DaqDIO, z);
    end
    sbval = DAQ.StrobeBitEdge - 1; %falling edge -> 0 or rising edge -> 1
    return
elseif codenumber == -2, %return codes at end of trial
    Codes.CodeTimes = CodeTimes(1:numcodes);
    Codes.CodeNumbers = CodeNumbers(1:numcodes);
    return
elseif any(codenumber ~= floor(codenumber)),
    error('Eventmarker value must be a positive integer');
end

for i = 1:length(codenumber),
    % Output codenumber on digital port
    if digoutflag,
        bvec = dec2binvec(codenumber(i), numdatabits);
        if length(bvec) > numdatabits,
            error('Too few digital lines (%i) allocated for event marker value %i', numdatabits, codenumber);
        end
        bvec([databits strobebit]) = [bvec ~sbval];
        putvalue(DaqDIO, bvec);
        bvec(strobebit) = sbval;
        putvalue(DaqDIO, bvec);
    end

    % store codes in array to be saved to disk on local machine
    numcodes = numcodes + 1;
    CodeNumbers(numcodes) = codenumber(i);
    CodeTimes(numcodes) = tstamp;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ontarget, rt] = eyejoytrack(fxn1, varargin)
global SIMULATION_MODE
global RFM_TASK
persistent TrialObject DAQ AI ScreenData eTform jTform ControlObject totalsamples ejt_totaltime min_cyclerate...
    joyx joyy eyex eyey joypresent eyepresent eyetarget_index eyetarget_record ...
    buttonspresent analogbuttons buttonnumber buttonx buttonsdio ...
    lastframe benchmark benchdata benchcount benchdata2 benchcount2 benchmax ...
	rfmkeyflag rfmobpos rfmmov numframespermov rfmkeys

t1 = trialtime;
ontarget = 0;
rt = NaN;

if fxn1 == -1,
    ejt_totaltime = 0;
    min_cyclerate = Inf;
    totalsamples = 0;
    lastframe = 0;
    benchmark = 0;
    benchdata = [];
    benchcount = 0;
    benchdata2 = benchdata;
    benchcount2 = benchcount;
    benchmax = 30000;
    TrialObject = varargin{1};
    DAQ = varargin{2};
    AI = [];
    if isempty(DAQ.AnalogInput2),
        if ~isempty(DAQ.AnalogInput),
            AI = DAQ.AnalogInput;
        end
    else
        AI = DAQ.AnalogInput2; %use a second board for on-line sampling (much faster sample updates)
    end
    ScreenData = varargin{3};
    eTform = varargin{4};
    jTform = varargin{5};
	ControlObject.EyeTargetHandle = findobj('tag', 'fixcircle');
	ControlObject.EyeTraceHandle = findobj('tag', 'eyetrace');
    ControlObject.JoyTargetHandle = findobj('tag', 'target');
    ControlObject.JoyTraceHandle = findobj('tag', 'trace');
    ControlObject.ButtonLines = findobj('tag', 'ButtonLine');
    ControlObject.ButtonCircles = findobj('tag', 'ButtonCircle');
    ControlObject.ButtonThresh = findobj('tag', 'ButtonThresh');
    if isempty(DAQ.EyeSignal),
        eyex = [];
        eyey = [];
        eyepresent = 0;
    else
        eyex = DAQ.AnalogInput.EyeX.Index;
        eyey = DAQ.AnalogInput.EyeY.Index;
        eyepresent = 1;
    end
    if isempty(DAQ.Joystick),
        joyx = [];
        joyy = [];
        joypresent = 0;
    else
        joyx = DAQ.AnalogInput.JoyX.Index;
        joyy = DAQ.AnalogInput.JoyY.Index;
        joypresent = 1;
    end
    if isempty(DAQ.Buttons),
        buttonx = [];
        buttonspresent = 0;
    else
        buttonspresent = DAQ.Buttons.ButtonsPresent;
        analogbuttons = strcmpi(DAQ.Buttons.Subsystem, 'analog');
        if analogbuttons,
            for i = 1:length(buttonspresent),
                buttonnumber = buttonspresent(i);
                bname = sprintf('Button%i', buttonnumber);
                buttonx(buttonnumber) = DAQ.AnalogInput.(bname).Index;
            end
        else
            buttonsdio = DAQ.Buttons.DIO;
            for i = 1:length(buttonspresent),
                buttonnumber = buttonspresent(i);
                bname = sprintf('Button%i', buttonnumber);
                buttonx(buttonnumber) = buttonsdio.(bname).Index;
            end
        end
    end
    data = [];
    count = 0;
    if joypresent || eyepresent,
        while isempty(data) && count < 1000,
            data = getsample(DAQ.AnalogInput);
            count = count + 1;
        end
        if isempty(data),
            error('*** Unable to acquire data from analog input object ***')
        end
    end
    eyetarget_index = 0;
    eyetarget_record = cell(100, 1);
    return
elseif fxn1 == -2, %call from showcursor
    ScreenData.ShowCursor = varargin{1};
    return
elseif fxn1 == -3, %update from reposition_object or set_object_path
    stimnum = varargin{1};
	status = TrialObject(stimnum).Status;
    TrialObject(stimnum) = varargin{2};
	TrialObject(stimnum).Status = status;
    return
elseif fxn1 == -4, %call from end_trial
    if eyetarget_index,
        ontarget = cat(1, eyetarget_record{:});
    else
        ontarget = [];
    end
    if ejt_totaltime,
        rt = [min_cyclerate round(1000*totalsamples/ejt_totaltime)]; %returns the cycle-rate
    else
        rt = 0;
    end
    return
elseif fxn1 == -5, %update from ToggleObject
    TrialObject = varargin{1};
    lastframe = varargin{2};
    return
elseif fxn1 == -6, %benchmarking
    b = varargin{1};
    if b, %turn ON benchmarking & initialize bench arrays
        benchmark = 1;
        benchdata = zeros(benchmax, 1);
        benchcount = 0;
        benchdata2 = benchdata;
        benchcount2 = benchcount;
    else %turn OFF benchmarking
        benchmark = 0;
    end
    ontarget = cell(2, 1); %needed to convert from numeric to cell
    ontarget{1} = benchdata(1:benchcount); %retrieve current benchmark data
    ontarget{2} = benchdata2(1:benchcount2);
    return
elseif fxn1 == -7, %RFM
    fxn1 = 'holdfix';
    if isempty(rfmmov)
        rfmmov = varargin{1};
    end
    movs = 2 : 6;                   % taskobject indices for the rfm movies
    for i = movs
        TrialObject(i).FrameStep = 0;
    end
	reposition_object(-1, TrialObject, ScreenData); % update reposition_object's copy of TrialObject
	toggleobject(-1, TrialObject, ScreenData, DAQ); % update toggleobject's copy of TrialObject
	
    rfmkeyflag = 0;					% initialize
    rfmobpos_conds = [1 5 8 3 3];	% number of shapes, sizes, rotations, size ratios, colors in rfm object. TODO make soft-coded
    numframespermov = prod(rfmobpos_conds) / rfmobpos_conds(2);   % number of frames per movie
	Xnew = 0;
	Ynew = 0;						% variables to store mouse position
    
    rfmkeys = 20 : 24;              % key codes for keys used for changing stimuli
	
    rfmscreeninfo = get(0, 'MonitorPosition');
    xoffset = rfmscreeninfo(2, 1);
    yoffset = rfmscreeninfo(2, 2);
    l = xoffset;
    t = yoffset;
    r = rfmscreeninfo(2, 3);
    b = rfmscreeninfo(2, 4);
% 	edge = 300;
% 	clipl = l + edge;
% 	clipr = r - edge;
% 	clipt = t + edge;
% 	clipb = b - edge;
    dirs = getpref('MonkeyLogic', 'Directories');
    system(sprintf('%smlhelper --cursor-enable', dirs.BaseDirectory));
%     system(sprintf('%smlhelper --cursor-clip %i %i %i %i', dirs.BaseDirectory, clipl, clipt, clipr, clipb));
	system(sprintf('%smlhelper --clicks-disable', dirs.BaseDirectory));
	
	if ~isempty(RFM_TASK) && RFM_TASK == 2								%return from escape screen
		mlvideo('setmouse', [(l + r)/2 (t + b)/2]);						%set the mouse to the center of the screen on returning from escape screen
	end
	RFM_TASK = 1;					%required for check_keyboard
	FIRST_FRAME = 1;
end

eyetrack = 0;
joytrack = 0;
buttontrack = 0;
eyestatus = 0;
joystatus = 0;
bstatus = 0;
eyefirst = 0;
joyfirst = 0;

idle = 0;
if strcmp(fxn1, 'idle'),
    idle = 1;
    if ~isempty(eyex),
        eyetrack = 1;
    end
    if ~isempty(joyx),
        joytrack = 1;
    end
    maxtime = varargin{1};
else
    tob1 = varargin{1};
    trad1 = varargin{2};
	if length(trad1) < length(tob1),
        trad1 = trad1 * ones(size(tob1));
	end
	if exist('Xnew', 'var')     % Hardcode fixation point as object # 1 in timing file 
        tob1 = 1;
	end
    maxtime = varargin{3};
    if strcmpi(fxn1, 'acquirefix'),
        eyetrack = 1;
        eyeop = 0; %less than
        eyeobject = TrialObject(tob1);
        eyerad = trad1';
        eyefirst = 1;
        eyeobindex = tob1;
    elseif strcmpi(fxn1, 'holdfix'),
        if length(tob1) > 1,
            error('*** Must specify exactly one object on which to hold fixation ***');
        end
        eyetrack = 1;
        eyeop = 1; %greater than
        eyeobject = TrialObject(tob1);
        eyerad = trad1';
        eyefirst = 1;
        eyeobindex = tob1;
    elseif strcmpi(fxn1, 'acquiretarget'),
        joytrack = 1;
        joyop = 0; %less than
        joyobject = TrialObject(tob1);
        joyrad = trad1';
        joyfirst = 1;
        joyobindex = tob1;
    elseif strcmpi(fxn1, 'holdtarget'),
        if length(tob1) > 1,
            error('*** Must specify exactly one object on which to hold target ***');
        end
        joytrack = 1;
        joyop = 1; %greater than
        joyobject = TrialObject(tob1);
        joyrad = trad1';
        joyfirst = 1;
        joyobindex = tob1;
    elseif strcmpi(fxn1, 'acquiretouch'),
        buttontrack = 1;
        buttonop = 0;
        bthresh = trad1;
        buttonindex = tob1;
    elseif strcmpi(fxn1, 'holdtouch'),
        buttontrack = 1;
        buttonop = 1;
        bthresh = trad1;
        buttonindex = tob1;
    else
        error('Undefined eyejoytrack function "%s".',fxn1);
    end
end

numsigs = 1;
if length(varargin) > 3,
    numsigs = 2;
    fxn2 = maxtime;
    tob2 = varargin{4};
    trad2 = varargin{5};
    if length(trad2) < length(tob2),
        trad2 = trad2 * ones(size(tob2));
    end
    maxtime = varargin{6};
    if strcmpi(fxn2, 'acquirefix'),
        if eyetrack,
            error('*** Eye tracking criteria double-set in one "eyejoytrack" command ***');
        end
        eyetrack = 1;
        eyeop = 0; %less than
        eyeobject = TrialObject(tob2);
        eyerad = trad2';
        eyeobindex = tob2;
    elseif strcmpi(fxn2, 'holdfix'),
        if eyetrack,
            error('*** Eye tracking criteria double-set in one "eyejoytrack" command ***');
        end
        if length(tob2) > 1,
            error('*** Must specify exactly one object on which to hold fixation ***');
        end
        eyetrack = 1;
        eyeop = 1; %greater than
        eyeobject = TrialObject(tob2);
        eyerad = trad2';
        eyeobindex = tob2;
    elseif strcmpi(fxn2, 'acquiretarget'),
        if joytrack,
            error('*** Joystick tracking criteria double-set in one "eyejoytrack" command ***');
        end
        joytrack = 1;
        joyop = 0; %less than
        joyobject = TrialObject(tob2);
        joyrad = trad2';
        joyobindex = tob2;
    elseif strcmpi(fxn2, 'holdtarget'),
        if joytrack,
            error('*** Joystick tracking criteria double-set in one "eyejoytrack" command ***');
        end
        if length(tob2) > 1,
            error('*** Must specify exactly one object on which to hold target ***');
        end
        joytrack = 1;
        joyop = 1; %greater than
        joyobject = TrialObject(tob2);
        joyrad = trad2';
        joyobindex = tob2;
    elseif strcmpi(fxn2, 'acquiretouch'),
        if buttontrack,
            error('*** Button tracking criteria double-set in one "eyejoytrack" command ***');
        end
        buttontrack = 1;
        buttonop = 0;
        bthresh = trad2;
        buttonindex = tob2;
    elseif strcmpi(fxn2, 'holdtouch'),
        if buttontrack,
            error('*** Button tracking criteria double-set in one "eyejoytrack" command ***');
        end
        buttontrack = 1;
        buttonop = 1;
        bthresh = trad2;
        buttonindex = tob2;
    else
        error('Undefined eyejoytrack function "%s".',fxn2);
    end
end

% make certain requested inputs are present
if eyetrack && ~eyepresent,
    error('*** No eye-signal inputs defined in I/O menu ***');
end
if joytrack && ~joypresent,
    error('*** No joystick inputs defined in I/O menu ***');
end
if buttontrack,
    if ~any(buttonspresent),
        error('*** No buttons defined in I/O menu ***');
    end
    if min(buttonindex) < 1 || any(floor(buttonindex) ~= buttonindex),
        error('*** Buttons must be referenced by positive integers ***');
    end
    if max(buttonindex) > length(buttonx) || any(buttonx(buttonindex) == 0),
        error('*** At least one requested Button has not been assigned to a DAQ object ***');
    end
end

%Check to see if intermittent video updates are required...
moviesplaying = any(cat(1, TrialObject.Status) & cat(1, TrialObject.Modality) == 2);
yesshowcursor = ScreenData.ShowCursor;
if moviesplaying || yesshowcursor,
	videoupdates = 1;
	drawnowok = 0;
else
	videoupdates = 0;
	drawnowok = 1;
end

%create button indicators
if any(buttonspresent),
    numbuttons = length(buttonspresent);
    degsep = 2;
    bindx = (2:degsep:degsep*numbuttons) - numbuttons - 1;
    bscreenlims = get(ControlObject.ButtonLines(1), 'ydata');
    bscreenmin = min(bscreenlims);
    bscreenmax = max(bscreenlims);
    bscreenrange = bscreenmax - bscreenmin;
    if analogbuttons,
        bvalscale = AI.Channel.InputRange(1);
    else
        bvalscale = [0 1];
    end
    bvalmin = min(bvalscale);
    bvalrange = max(bvalscale) - bvalmin;
    buttonhandle = zeros(max(buttonspresent), 1);
    for i = 1:numbuttons,
        buttonnumber = buttonspresent(i);
        set(ControlObject.ButtonLines(i), 'xdata', [bindx(i) bindx(i)]);
        buttonhandle(buttonnumber) = ControlObject.ButtonCircles(i);
        set(buttonhandle(buttonnumber), 'xdata', bindx(i), 'ydata', bscreenmin+mean(bscreenrange));
    end
end

%set targets
eye_position(-4,NaN,NaN);
if ~idle,
    if eyetrack,
        numeyeobjects = length(eyeobject);
        eyestatus = 0;
        ex = {eyeobject.XPos}';
        ey = {eyeobject.YPos}';
        eyetarget_index = eyetarget_index + 1;
        eyetarget_record{eyetarget_index} = [ex ey];
        esize = num2cell(2*eyerad*ScreenData.PixelsPerDegree*ScreenData.ControlScreenRatio(1)/ScreenData.PixelsPerPoint);
        if ~moviesplaying,
            set(ControlObject.EyeTargetHandle(eyeobindex)', {'xdata'}, ex, {'ydata'}, ey, {'markersize'}, esize);
        end
        ex = cat(1, ex{:});
        ey = cat(1, ey{:});
        if numeyeobjects > 1 && ~moviesplaying,
            set(ControlObject.EyeTargetHandle(eyeobindex(2:numeyeobjects))', 'markeredgecolor', (ScreenData.EyeTargetColor/2));
        end
        eye_position(-4,ex,ey);
    end
    if joytrack,
        numjoyobjects = length(joyobject);
        joystatus = 0;
        jx = {joyobject.XPos}';
        jy = {joyobject.YPos}';
        jsize = num2cell(2*joyrad*ScreenData.PixelsPerDegree*ScreenData.ControlScreenRatio(1)/ScreenData.PixelsPerPoint);
        if ~moviesplaying,
            set(ControlObject.JoyTargetHandle(joyobindex)', {'xdata'}, jx, {'ydata'}, jy, {'markersize'}, jsize);
        end
        jx = cat(1, jx{:});
        jy = cat(1, jy{:});
        if numjoyobjects > 1 && ~moviesplaying,
            set(ControlObject.JoyTargetHandle(joyobindex(2:numjoyobjects))', 'markeredgecolor', (ScreenData.JoyTargetColor/2));
        end
    end
    if buttontrack,
        if isempty(bthresh),
            if analogbuttons,
                bthresh = 3;
            else
                bthresh = 0.5;
            end
        end
        if length(bthresh) == 1,
            bthresh = ones(numbuttons, 1)*bthresh;
        elseif length(bthresh) > numbuttons,
            error('*** More threshold values supplied than there are buttons available ***')
        end
        if ~moviesplaying,
            for i = 1:numbuttons,
                xpos = bindx(i);
                ypos = (bthresh(i) - bvalmin)/bvalrange;
                ypos = bscreenmin + (ypos*bscreenrange);
                set(ControlObject.ButtonThresh(i), 'xdata', xpos, 'ydata', ypos);
            end
        end
    end
end

tupdate = 0;
userawjoy = ScreenData.UseRawJoySignal;
useraweye = ScreenData.UseRawEyeSignal;

earlybreak = 0;
t2 = trialtime - t1;

while t2 < maxtime,
    totalsamples = totalsamples + 1;
	if ~isempty(AI),
        data = getsample(AI);
	end
	if eyepresent,
        if SIMULATION_MODE,
            sim_vals = simulation_positions(0);
            xp_eye = sim_vals(3);
            yp_eye = sim_vals(4);
        else
            xp_eye = data(eyex);
            yp_eye = data(eyey);
            if ~useraweye,
                [xp_eye yp_eye] = tformfwd(eTform, xp_eye, yp_eye);
                [exOff eyOff] = eye_position(-3);
                xp_eye = xp_eye + exOff;
                yp_eye = yp_eye + eyOff;
            end 
        end

        if ~idle && eyetrack,
            eye_dist = realsqrt((xp_eye - ex).^2 + (yp_eye - ey).^2);
            if eyeop, %holdfix
                eyestatus = eye_dist > eyerad;
            else %acquirefix
                eyestatus = eye_dist <= eyerad;
            end
        end
	end
    
	if joypresent,
        if SIMULATION_MODE,
            sim_vals = simulation_positions(0);
            xp_joy = sim_vals(1);
            yp_joy = sim_vals(2);
        else
            xp_joy = data(joyx);
            yp_joy = data(joyy);
        end

        if ~userawjoy,
            [xp_joy yp_joy] = tformfwd(jTform, xp_joy, yp_joy);
        end
        if ~idle && joytrack,
            joy_dist = realsqrt((xp_joy - jx).^2 + (yp_joy - jy).^2);
            if joyop, %holdtarget
                joystatus = joy_dist > joyrad;
            else %acquiretarget
                joystatus = joy_dist <= joyrad;
            end
        end
	end
    
	if any(buttonspresent),
        if analogbuttons,
            allbvals = data(buttonx);
        else
            allbvals = getvalue(buttonsdio);
        end
        if ~idle && buttontrack,
            if SIMULATION_MODE,
                sim_vals = simulation_positions(0);
                bval = sim_vals(5);
            else
                if analogbuttons,
                    bval = allbvals(buttonindex);
                else
                    bval = allbvals(buttonx(buttonindex));
                end
            end
            if buttonop, %holdtouch
                bstatus = bval < bthresh;
            else %acquiretouch
                bstatus = bval > bthresh;
            end
        end
	end
	
	if exist('Xnew', 'var')
        rfmtarget = mlvideo('getmouse');
		Xold = Xnew;
		Yold = Ynew;
        Xnew = (rfmtarget(1) - xoffset - ScreenData.Half_xs)/ScreenData.PixelsPerDegree;
        Ynew = -(rfmtarget(2) - yoffset - ScreenData.Half_ys)/ScreenData.PixelsPerDegree;
		changepos = Xold ~= Xnew || Yold ~= Ynew;
		
		if isempty(rfmobpos)                                                % which it is for the first trial
			rfmobpos = zeros(1,length(rfmobpos_conds));						% current shape, rotation, size ratio, size, color of rfm object
			mlvideo('setmouse', [(l + r)/2 (t + b)/2]);						% set the mouse to the center of the screen on the first trial
		end
		
        rfmkeyflag = mlkbd('getkey');
		if isempty(rfmkeyflag)
			rfmkeyflag = 0;
		end
		if any(rfmkeyflag == rfmkeys)                                       %change shape, rotation, size ratio, size, color
			changestim = 1;
            rfmkeyflag = rfmkeyflag - 19;									% subtract 19 to index by desired object trait
            if rfmkeyflag == 1
				rfmobpos(3) = rfmobpos(3) - 1;                              % counter-clockwise rotation
                if rfmobpos(3) < 0
					rfmobpos(3) = rfmobpos_conds(3) - 1;                    % if not rotated, then rfmobpos(2) = 0
                end
            else
                rfmobpos(rfmkeyflag) = rfmobpos(rfmkeyflag) + 1;                % advance desired property
                if rfmobpos(rfmkeyflag) == rfmobpos_conds(rfmkeyflag)
                rfmobpos(rfmkeyflag) = 0;
                end
            end
		else
			changestim = 0;
		end
		rfmframe = rfmobpos(1)*prod(rfmobpos_conds(2:5)) + rfmobpos(2)*prod(rfmobpos_conds(3:5)) + rfmobpos(3)*prod(rfmobpos_conds(4:5)) + rfmobpos(4)*rfmobpos_conds(5) + rfmobpos(5) + 1; %index to desired frame
		
		if FIRST_FRAME
			reposition_object(rfmmov, Xnew, Ynew);
            rfmframe = mod(rfmframe, numframespermov);
			toggleobject(rfmmov, 'MovieStartFrame', rfmframe);				%frame ended on in previous trial/first frame for first trial
			reposition_object(-1, TrialObject, ScreenData);					%convey start frame and position to reposition_object
			videoupdates = 1;
			FIRST_FRAME = 0;
		end

		if changepos
			reposition_object(rfmmov, Xnew, Ynew);
		end
		
		if changestim
            mov = ceil(rfmframe / numframespermov) + 1;                     % +1 because fixation point is 1. Movies start at 2 in TrialObject structure.
            rfmframe = mod(rfmframe, numframespermov);
            if rfmmov == mov                                                % movie need not be changed
                toggleobject(rfmmov, 'MovieStartFrame', rfmframe, 'Status', 'On');
                reposition_object(-1, TrialObject, ScreenData);				% convey start frame to reposition_object
            else                                                            % movie needs to be changed
                reposition_object(rfmmov, Xnew, Ynew);                      % even thought it will be turned off, its position still needs to be updated.
                toggleobject(rfmmov, 'Status', 'Off');                      % turn off old movie
                rfmmov = mov;
                reposition_object(rfmmov, Xnew, Ynew);                      % reposition new movie and turn it on
                toggleobject(rfmmov, 'MovieStartFrame', rfmframe, 'Status', 'On');
                reposition_object(-1, TrialObject, ScreenData);
            end
		end
	end
	
    if any(eyestatus) || any(joystatus) || any(bstatus),
        t = trialtime - t1;
        rt = round(t);
        t2 = maxtime;
        earlybreak = 1;
        if eyetrack,
            etargetnumber = find(eyestatus);
            eyestatus = any(eyestatus);
        end
        if joytrack,
            jtargetnumber = find(joystatus);
            joystatus = any(joystatus);
        end
        if buttontrack,
            btargetnumber = find(bstatus);
            bstatus = any(bstatus);
        end
        if numsigs == 1 && eyetrack,
            ontarget = ~eyeop*etargetnumber;
        elseif numsigs == 1 && joytrack,
            ontarget = ~joyop*jtargetnumber;
        elseif numsigs == 1 && buttontrack,
            ontarget = ~buttonop*btargetnumber;
        elseif numsigs == 2,
            if eyetrack && joytrack,
                if eyestatus && ~joystatus,
                    ontarget = [~eyeop*etargetnumber joyop];
                elseif ~eyestatus && joystatus,
                    ontarget = [eyeop ~joyop*jtargetnumber];
                else %both 
                    ontarget = [~eyeop*etargetnumber ~joyop*jtargetnumber];
                end
                if ~eyefirst,
                    ontarget = [ontarget(2) ontarget(1)];
                end
            elseif eyetrack && buttontrack,
                if eyestatus && ~bstatus,
                    ontarget = [~eyeop*etargetnumber buttonop];
                elseif ~eyestatus && bstatus,
                    ontarget = [eyeop ~buttonop*btargetnumber];
                else %both
                    ontarget = [~eyeop*etargetnumber ~buttonop*btargetnumber];
                end
                if ~eyefirst,
                    ontarget = [ontarget(2) ontarget(1)];
                end
            elseif joytrack && buttontrack, %seems strange a task would need this, but you never know...
                if joystatus && ~bstatus,
                    ontarget = [~joyop*etargetnumber buttonop];
                elseif ~joystatus && bstatus,
                    ontarget = [joyop ~buttonop*btargetnumber];
                else %both
                    ontarget = [~joyop*etargetnumber ~buttonop*btargetnumber];
                end
                if ~joyfirst,
                    ontarget = [ontarget(2) ontarget(1)];
                end
            end
        end
    else
        [t currentframe] = trialtime;
        if benchmark,
            benchcount = benchcount + 1;
            benchdata(benchcount) = t;
            if videoupdates && currentframe > lastframe,
                benchcount2 = benchcount2 + 1;
                benchdata2(benchcount2) = t;
            end
        end
        if videoupdates && currentframe > lastframe,
            if yesshowcursor,
                cxpos = floor(ScreenData.Half_xs + (ScreenData.PixelsPerDegree*xp_joy) - (ScreenData.CursorXsize/2));
                cypos = floor(ScreenData.Half_ys - (ScreenData.PixelsPerDegree*yp_joy) - (ScreenData.CursorYsize/2));
                [tflip lastframe] = toggleobject(-4, [cxpos cypos]);
            else
                [tflip lastframe] = toggleobject(-4);
            end
            drawnowok = 1; %can only update the control screen if just completed a video update (should still have enough time before the next flip)
        end
        dt = (t - t1) - t2;
        this_cyclerate = round(1000/dt);
        min_cyclerate = min(min_cyclerate,this_cyclerate);
        t2 = t - t1;
        if t2 > tupdate && drawnowok, %control screen updates are always required, but need not occur every frame
            if eyepresent,
                set(ControlObject.EyeTraceHandle, 'xdata', xp_eye, 'ydata', yp_eye);
            end
            if joypresent,
                set(ControlObject.JoyTraceHandle, 'xdata', xp_joy, 'ydata', yp_joy);
            end
            if any(buttonspresent),
                for i = 1:numbuttons,
                    buttonnumber = buttonspresent(i);
                    if SIMULATION_MODE,
                        sim_vals = simulation_positions(0);
                        bval = sim_vals(5);
                        if bval >= 0,
                            by = 1;
                        else
                            by = 0;
                        end
                    else
                        by = (allbvals(i) - bvalmin)/bvalrange;
                    end
                    by = bscreenmin + (by*bscreenrange);
                    set(ControlObject.ButtonCircles(buttonnumber), 'ydata', by);
                end
            end
            tupdate = t2+ScreenData.UpdateInterval;
            drawnow;
            if videoupdates,
                drawnowok = 0;
            end
            kb = mlkbd('getkey');
            if ~isempty(kb),
                hotkey(kb);
            end
        end
    end
end

if ~earlybreak && ~idle,
    if numsigs == 1,
        if eyetrack,
            ontarget = eyeop*find(~eyestatus);
        elseif joytrack,
            ontarget = joyop*find(~joystatus);
        elseif buttontrack,
            ontarget = buttonop*find(~bstatus);
        end
    else %numsigs == 2
        if eyetrack && joytrack,
            if eyefirst,
                ontarget = [eyeop*(find(~eyestatus))' joyop*(find(~joystatus))'];
            else
                ontarget = [joyop*(find(~joystatus))' eyeop*(find(~eyestatus))'];
            end
        elseif eyetrack && buttontrack,
            if eyefirst,
                ontarget = [eyeop*(find(~eyestatus))' buttonop*(find(~bstatus))'];
            else
                ontarget = [buttonop*(find(~bstatus))' eyeop*(find(~eyestatus))'];
            end
        elseif joytrack && buttontrack,
            if joyfirst,
                ontarget = [joyop*(find(~joystatus))' buttonop*(find(~bstatus))'];
            else
                ontarget = [buttonop*(find(~bstatus))' joyop*(find(~joystatus))'];
            end
        end
    end
end

set(ControlObject.EyeTargetHandle, 'xdata', ScreenData.OutOfBounds, 'ydata', ScreenData.OutOfBounds);
set(ControlObject.JoyTargetHandle, 'xdata', ScreenData.OutOfBounds, 'ydata', ScreenData.OutOfBounds);
if eyetrack && ~idle && numeyeobjects > 1,
    set(ControlObject.EyeTargetHandle(eyeobindex(2:numeyeobjects)), 'markeredgecolor', ScreenData.EyeTargetColor);
end
if joytrack && ~idle && numjoyobjects > 1,
    set(ControlObject.JoyTargetHandle(joyobindex(2:numjoyobjects)), 'markeredgecolor', ScreenData.JoyTargetColor);
end
if isnan(rt),
    ejt_totaltime = ejt_totaltime + maxtime;
else
    ejt_totaltime = ejt_totaltime + rt;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [jx, jy] = joystick_position(varargin)
persistent DAQ AI ScreenData joyx joyy jTform cxpos_last cypos_last last_jtrace_update ControlObject

t1 = trialtime;

if ~isempty(varargin) && varargin{1} == -1,
    DAQ = varargin{2};
    AI = [];
    if isempty(DAQ.AnalogInput),
        return
    end
    if isempty(DAQ.AnalogInput2),
        AI = DAQ.AnalogInput;
    else
        AI = DAQ.AnalogInput2; %use a second board for on-line sampling (much faster sample updates)
    end
    ScreenData = varargin{3};
    jTform = varargin{4};
    ControlObject.JoyTraceHandle = findobj('tag', 'trace');
    if isempty(DAQ.Joystick),
        joyx = [];
        joyy = [];
    else
        joyx = DAQ.Joystick.XChannelIndex;
        joyy = DAQ.Joystick.YChannelIndex;
    end
    cxpos_last = NaN;
    cypos_last = NaN;
    last_jtrace_update = t1;
    return
end

if isempty(AI),
    error('*** No analog inputs defined for joystick signal acquisition ***')
end

data = getsample(AI);
jx = data(joyx);
jy = data(joyy);
if ~ScreenData.UseRawJoySignal,
    [jx jy] = tformfwd(jTform, jx, jy);
end

if (t1 - last_jtrace_update) > ScreenData.UpdateInterval,
    set(ControlObject.JoyTraceHandle, 'xdata', jx, 'ydata', jy);
    if ScreenData.ShowCursor,
        if ~isnan(cxpos_last),
            mlvideo('blit', ScreenData.Device, ScreenData.CursorBlankBuffer, cxpos_last, cypos_last, ScreenData.CursorXsize, ScreenData.CursorYsize);
        end
        cxpos = floor((ScreenData.Xsize/2) + (ScreenData.PixelsPerDegree*xp));
        cypos = floor((ScreenData.Ysize/2) - (ScreenData.PixelsPerDegree*yp));
        mlvideo('blit', ScreenData.Device, ScreenData.CursorBuffer, cxpos, cypos, ScreenData.CursorXsize, ScreenData.CursorYsize);
        mlvideo('flip', ScreenData.Device);
        cxpos_last = cxpos;
        cypos_last = cypos;
    end
    drawnow;
    last_jtrace_update = trialtime;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ex, ey] = eye_position(varargin)
persistent DAQ AI ScreenData eyex eyey eTform exOff eyOff exTarget eyTarget last_etrace_update ControlObject

t1 = trialtime;

if ~isempty(varargin), 
    if varargin{1} == -1,
        DAQ = varargin{2};
        AI = [];
        if isempty(DAQ.AnalogInput),
            return
        end
        if isempty(DAQ.AnalogInput2),
            AI = DAQ.AnalogInput;
        else
            AI = DAQ.AnalogInput2;
        end
        ScreenData = varargin{3};
        eTform = varargin{4};
        exOff = 0;
        eyOff = 0;
        exTarget = 0;
        eyTarget = 0;
        ControlObject.EyeTraceHandle = findobj('tag', 'eyetrace');
        if isempty(DAQ.EyeSignal),
            eyex = [];
            eyey = [];
        else
            eyex = DAQ.EyeSignal.XChannelIndex;
            eyey = DAQ.EyeSignal.YChannelIndex;
        end
        last_etrace_update = t1;
        return
    elseif varargin{1} == -2,
        if isnan(exTarget) || isnan(eyTarget),
            return
        end
        [ex ey] = eye_position;
        exOff = exOff - ex + exTarget;
        eyOff = eyOff - ey + eyTarget;
        return
    elseif varargin{1} == -3,
        ex = exOff;
        ey = eyOff;
        return
    elseif varargin{1} == -4,
        exTarget = varargin{2};
        eyTarget = varargin{3};
        return
    end
end

if isempty(AI),
    error('*** No analog inputs defined for eye-signal acquisition ***')
end

data = getsample(AI);
ex = data(eyex);
ey = data(eyey);
if ~ScreenData.UseRawEyeSignal,
    [ex ey] = tformfwd(eTform, ex, ey);
    ex = ex + exOff;
    ey = ey + eyOff;
end

if (t1 - last_etrace_update) > ScreenData.UpdateInterval,
    set(ControlObject.EyeTraceHandle, 'xdata', ex, 'ydata', ey);
    drawnow;
    last_etrace_update = trialtime;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [adata, frq] = get_analog_data(sig, varargin)
persistent DAQ eTform jTform aipresent

if sig == -1,
    DAQ = varargin{1};
    if isempty(DAQ.AnalogInput),
        aipresent = 0;
    else
        aipresent = 1;
    end
    eTform = varargin{2};
    jTform = varargin{3};
    adata = [];
    frq = [];
    return
end

if ~aipresent,
    adata = [];
    frq = 0;
    disp('Warning: No analog inputs present for call to "get_analog_data"');
    return
end

try
    isch = ischannel(DAQ.AnalogInput.(sig));
catch ME
    isch = 0;
end
if ~isch,
    fprintf(getReport(ME));
    error('Signal "%s" not found during call to "get_analog_data"', sig);
end

if isempty(varargin),
    numsamples = 1;
else
    numsamples = varargin{1};
end
aisample = peekdata(DAQ.AnalogInput, numsamples);

if strcmpi(sig(1:3), 'eye'),
    x = aisample(:, DAQ.EyeSignal.XChannelIndex);
    y = aisample(:, DAQ.EyeSignal.YChannelIndex);
    [x y] = tformfwd(eTform, x, y);
    adata = [x y];
elseif strcmpi(sig(1:3), 'joy'),
    x = aisample(:, DAQ.Joystick.XChannelIndex);
    y = aisample(:, DAQ.Joystick.YChannelIndex);
    [x y] = tformfwd(jTform, x, y);
    adata = [x y];
else
    chindex = DAQ.AnalogInput.(sig).Index;
    adata = aisample(:, chindex);
end
frq = DAQ.AnalogInput.SampleRate;

function val = simulation_positions(action, varargin)
persistent sim_vals %joyx joyy eyex eyey bval

if action == -1,
    sim_vals = zeros(1,5);
    sim_vals(5) = -Inf;
    val = 1;
    return
end

if action == 0,
    val = sim_vals;
    return
end

if action == 1,
    which_val = varargin{1};
    delta_val = varargin{2};
    sim_vals(which_val) = sim_vals(which_val) + delta_val;
    val = sim_vals;
    return
end

if action == 2,
    which_val = varargin{1};
    setto_val = varargin{2};
    sim_vals(which_val) = setto_val;
    val = sim_vals;
    return
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function idle(duration, varargin)
persistent ScreenData

if duration == -1,
    ScreenData = varargin{1};
    return
end

colorflag = 0;
if ~isempty(varargin),
    colorflag = 1;
    color = varargin{1};
    if length(color) ~= 3,
        error('*** Unable to parse passed color values in trial subfunction: "idle" ***')
    end
    if max(color) > 1,
        color = color / max(color);
    end
    mlvideo('clear', ScreenData.Device, color);
    mlvideo('flip', ScreenData.Device);
end

eyejoytrack('idle', duration);

if colorflag == 1,
    mlvideo('clear', ScreenData.Device, ScreenData.BackgroundColor);
    mlvideo('flip', ScreenData.Device);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [scancode, rt] = getkeypress(maxtime, varargin)
persistent ScreenData

if maxtime == -1,
    ScreenData = varargin{1};
    return
end

t1 = trialtime;
t2 = 0;

rt = NaN;
scancode = [];

if ScreenData.Priority > 1,
    prtnormal;
end
while t2 < maxtime,
    scancode = mlkbd('getkey');
    t2 = trialtime - t1;
    if ~isempty(scancode),
        rt = t2;
        t2 = maxtime;
    end
end
if ScreenData.Priority == 2,
    prthigh;
elseif ScreenData.Priority == 3,
    prtrealtime;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = goodmonkey(duration, varargin)
persistent DAQ rewardtype reward_on reward_off noreward rewardsgiven rewardstart rewardend reward_dur rewardpolarity rewardindex pausetime triggerval

if duration == -1,
    DAQ = varargin{1};
    noreward = 0;
    pausetime = 40;
    triggerval = 5;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% REWARD
    loadbutton = findobj('tag', 'loadbutton');
    VV = get(loadbutton, 'userdata');
    reward_dur = VV.reward_dur;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
    rewardsgiven = 0;
    rewardstart = [];
    rewardend = [];
    return
elseif duration == -2, %init
    if noreward,
        return %this way no warning message given
    end
    duration = 1;
elseif duration == -3, %retrieve data at end-of-trial
    if ~rewardsgiven,
        RewardRecord = [];
    else
        RewardRecord.StartTimes = round(rewardstart);
        RewardRecord.EndTimes = round(rewardend);
    end
    varargout = {RewardRecord};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% REWARD
    loadbutton = findobj('tag', 'loadbutton');
    VV = get(loadbutton, 'userdata');
    VV.reward_dur = reward_dur;
    set(findobj('tag', 'loadbutton'), 'userdata', VV);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    return
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% REWARD
elseif duration == -4,
    diff = varargin{1};
    reward_dur = reward_dur + diff;
    return
elseif ischar(duration),
    if strcmpi(duration,'user'),
        duration = reward_dur;
    else
        dnum = str2double(duration);
        if isempty(dnum),
            error('Unable to parse string "%s" as argument to goodmonkey.  Acceptable values are positive numbers or "user".',duration);
        else
            duration = dnum;
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

if noreward,
    disp('WARNING: *** No reward output defined ***')
    return
end

if isempty(varargin),
    numreward = 1;
    pausetime = 0;
else
    numreward = 1;
    pausetime = 0;
    for i = 1:2:length(varargin),
        prm = varargin{i};
        val = varargin{i+1};
        if strcmpi(prm, 'NumReward'),
            numreward = val;
        elseif strcmpi(prm, 'PauseTime'),
            pausetime = val;
        elseif strcmpi(prm, 'TriggerVal'),
            triggerval = val;
        else
            error('Unrecognized parameter passed to goodmonkey: valid parameters are ''NumReward'', ''PauseTime'' and ''TriggerVal''');
        end
    end
    reward_on(rewardindex) = triggerval*rewardpolarity;
    reward_off(rewardindex) = triggerval*~rewardpolarity;
end

for i = 1:numreward,
    rewardsgiven = rewardsgiven + 1;
    t1 = trialtime;
    t2 = 0;
    if rewardtype == 1,
        putsample(DAQ.AnalogOutput, reward_on);
    else
        putvalue(DAQ.Reward.DIO, reward_on);
    end
    while t2 < duration,
        t2 = trialtime - t1;
    end
    if rewardtype == 1,
        putsample(DAQ.AnalogOutput, reward_off); 
    else
        putvalue(DAQ.Reward.DIO, reward_off); 
    end
    rewardend(rewardsgiven) = trialtime;
    rewardstart(rewardsgiven) = t1;
    if i < numreward, %add gaps only between rewards
        t1 = trialtime;
        t2 = 0;
        while t2 < pausetime
            t2 = trialtime - t1;
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function success = set_frame_order(stimnum, frameorder, varargin)
persistent TrialObject

if stimnum == -1,
    TrialObject = frameorder;
    success = [];
    return
end

if TrialObject(stimnum).Modality ~= 2,
    error('set_frame_order can only be used with ''Movie'' objects');
elseif ~isnumeric(frameorder),
    error('Frame order arguments to set_frame_order must be numeric');
elseif min(size(frameorder)) > 1 || ndims(frameorder) > 2,
    error('Frame order arguments for set_frame_order must be vectors');
end

TO = TrialObject(stimnum);

if ~isempty(varargin),
    if length(varargin) ~= 2,
        error('set_frame_order accepts only 2 or 4 arguments');
    end
    frame_list = varargin{1};
    em_list = varargin{2};
    if length(frame_list) ~= length(em_list),
        error('Frame-triggered event marker arguments must be of equal length');
    elseif ~isnumeric(frame_list) || ~isnumeric(em_list),
        error('Frame-triggered event marker arguments must be numeric');
    elseif min(size(frame_list)) > 1 || ndims(frame_list) > 2 || min(size(em_list)) > 1 || ndims(em_list) > 2,
        error('Frame-triggered event marker arguments must be vectors');
    end
    TO.FrameEvents = cat(1,frame_list,em_list);
end

TO.FrameOrder = frameorder;

toggleobject(-3, stimnum, TO, 0);
eyejoytrack(-3, stimnum, TO);
TrialObject(stimnum) = TO;
success = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function translate_success = set_object_path(stimnum, xpath, ypath)
persistent ScreenData TrialObject

if stimnum == -1,
    TrialObject = xpath;
    ScreenData = ypath;
    translate_success = [];
    return
end

if ~isnumeric(xpath) || ~isnumeric(ypath),
    error('path arguments to set_object_path must be numeric vectors');
elseif min(size(xpath)) > 1 || ndims(ypath) > 2,
    error('x- and y- path arguments for set_object_path must be vectors');
elseif length(xpath) ~= length(ypath),
    error('x- and y- path vectors for set_object_path must be equal in size');
elseif isempty(TrialObject(stimnum).XPos),
    user_warning('Cannot set_object_path for object #%i.', stimnum)
    translate_success = 0;
    return
end

TO = TrialObject(stimnum);

xpos_bak = TO.XPos;
ypos_bak = TO.YPos;
xspos_bak = TO.XsPos;
yspos_bak = TO.YsPos;

TO.XPos = xpath;
TO.YPos = ypath;
hxs = round(ScreenData.Xsize/2);
hys = round(ScreenData.Ysize/2);
xoffset = round(TO.Xsize)/2;
yoffset = round(TO.Ysize)/2;
TO.XsPos = hxs + round(ScreenData.PixelsPerDegree * xpath) - xoffset;
TO.YsPos = hys - round(ScreenData.PixelsPerDegree * ypath) - yoffset; %invert so that positive y is above the horizon

if any(TO.XsPos + TO.Xsize > ScreenData.Xsize | TO.YsPos + TO.Ysize > ScreenData.Ysize | TO.XsPos < 1 | TO.YsPos < 1),
    TO.XPos = xpos_bak;
    TO.YPos = ypos_bak;
    TO.XsPos = xspos_bak;
    TO.YsPos = yspos_bak;
    translate_success = 0;
    user_warning('Attempt set path for object #%i failed. Target outside screen boundary.', stimnum);
else
    TO.StartPosition = 1;
	TO.CurrFrame = 0;
    TO.NumPositions = length(xpath);
    if TO.Modality == 1,
        TO.Class = 'Movie';
        TO.Modality = 2; % set to "movie"
        TO.StartFrame = 1;
        TO.NumFrames = 1;
    end
    toggleobject(-3, stimnum, TO, 0);
    eyejoytrack(-3, stimnum, TO);
    TrialObject(stimnum) = TO;
    translate_success = 1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function repos_success = reposition_object(stimnum, xnew, ynew)
persistent ScreenData TrialObject

if stimnum == -1,
    TrialObject = xnew;
    ScreenData = ynew;
    repos_success = [];
    return
end

if length(stimnum) > 1,
    error('The function "reposition_object" is not vectorized (accepts only scalar inputs)');
end

TO = TrialObject(stimnum);
if ~isempty(TrialObject(stimnum).XPos),
    
    xpos_bak = TO.XPos;
    ypos_bak = TO.YPos;
    xspos_bak = TO.XsPos;
    yspos_bak = TO.YsPos;
    
    TO.XPos = xnew;
    TO.YPos = ynew;
    hxs = round(ScreenData.Xsize/2);
    hys = round(ScreenData.Ysize/2);
    xoffset = round(TO.Xsize)/2;
    yoffset = round(TO.Ysize)/2;
    TO.XsPos = hxs + round(ScreenData.PixelsPerDegree * xnew) - xoffset;
    TO.YsPos = hys - round(ScreenData.PixelsPerDegree * ynew) - yoffset; %invert so that positive y is above the horizon

    if TO.XsPos + TO.Xsize > ScreenData.Xsize || TO.YsPos + TO.Ysize > ScreenData.Ysize || TO.XsPos < 1 || TO.YsPos < 1,
        TO.XPos = xpos_bak;
        TO.YPos = ypos_bak;
        TO.XsPos = xspos_bak;
        TO.YsPos = yspos_bak;
        repos_success = 0;
        user_warning('Attempt reposition object #%i failed. Target outside screen boundary.', stimnum);
    else
        toggleobject(-3, stimnum, TO, 1);
        eyejoytrack(-3, stimnum, TO);
        TrialObject(stimnum) = TO;
        repos_success = 1;
    end

else
    user_warning('Cannot reposition object #%i.', stimnum);
    repos_success = 0;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [t, f] = trialtime(varargin)
persistent k abs_tstart frame_length frame_offset ticID

if ~isempty(varargin),
    var = varargin{1};
    if var == -1,
        ticID = tic;
        abs_tstart = clock; %absolute time of trial start for fMRI tasks
        k = 1000;
        ScreenData = varargin{2};
        while mlvideo('verticalblank', ScreenData.Device), end
        while ~mlvideo('verticalblank', ScreenData.Device), end
        frame_offset = k*toc(ticID); 
        %t = 0 should be nearly aligned with DAQ "isrunning" upon entry to this initialization
        %t = frame_offset should align with the start of the vertical blank
        frame_length = ScreenData.FrameLength;
        return
    elseif var == -2,
        t = abs_tstart;
        return
    end
end

t = k*toc(ticID);
f = floor((t-frame_offset)/frame_length);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function iti = set_iti(t)
persistent time

if t==-1,
    time = -1;
    iti = -1;
elseif t==-2,
    iti = time;
else
    time = t;
    iti = -1;
end
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function showcursor(cflag, varargin)
persistent ScreenData

if cflag == -1,
    ScreenData = varargin{1};
    return
end

if ischar(cflag),
    cflag = strcmpi(cflag, 'on');
else
    cflag = cflag > 0;
end

for i = 1:ScreenData.BufferPages-1,
    toggleobject(0, 'drawmode', 'fast'); %redraws existing stimuli to avoid re-activating extinguished ones
end
eyejoytrack(-2, cflag);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function hotkey(keyval, varargin)
persistent scanletters scancodes keynumbers keycallbacks

if isnumeric(keyval), %init or call from eyejoytrack
    if keyval == -1, %init
        scanletters = '`1234567890-=qwertyuiop[]\asdfghjkl;''zxcvbnm,./';
        scancodes = [41 2:13 16:27 43 30:40 44:53];
        keynumbers = [];
        keycallbacks = {};
        return
    else %call from eyejoytrack
        k = (keynumbers == keyval);
        if any(k),
            eval(keycallbacks{k});
        end
        return
    end
end

keynum = [];
if length(keyval) > 1,
    if strcmpi(keyval, 'esc'),
        keynum = 1;
    elseif strcmpi(keyval, 'rarr'),
        keynum = 205;
    elseif strcmpi(keyval, 'larr'),
        keynum = 203;
    elseif strcmpi(keyval, 'uarr'),
        keynum = 200;
    elseif strcmpi(keyval, 'darr'),
        keynum = 208;
    elseif strcmpi(keyval, 'numrarr'),
        keynum = 77;
    elseif strcmpi(keyval, 'numlarr'),
        keynum = 75;
    elseif strcmpi(keyval, 'numuarr'),
        keynum = 72;
    elseif strcmpi(keyval, 'numdarr'),
        keynum = 80;
    elseif strcmpi(keyval, 'space'),
        keynum = 57;
    elseif strcmpi(keyval, 'bksp'),
        keynum = 14;
    elseif strcmpi(keyval(1), 'f'),
        fval = str2double(keyval(2:end));
        if ~isnan(fval) && fval > 0 && fval < 11,
            keynum = 58 + fval;
        elseif fval == 11,
            keynum = 87;
        elseif fval == 12,
            keynum = 88;
        end
    end
    if isempty(keynum),
        error('Must specify only one letter, number, or symbol on each call to "hotkey" unless specifying a function key such as "F3"');
    end
else
    keynum = scancodes(scanletters == lower(keyval));
end
if isempty(varargin) || isempty(varargin{1}),
    disp('Warning: No function declared for HotKey "%s"', keyval);
    return
end
keyfxn = varargin{1};
n = length(keynumbers) + 1;
keynumbers(n) = keynum;
keycallbacks{n} = keyfxn;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function val = bhv_variable(varname, varargin)
persistent vars

if varname == -1,
    vars = struct;
    val = 0;
    return
end

if varname == -2,
    val = vars;
    return
end

if ~ischar(varname),
    error('Variable names for bhv_variable must be strings.');
end

if length(varname) > 32,
    error('Variable names must be 32 characters or fewer.');
end

if isempty(varargin),
    val = vars.(varname);
    return
end

varval = varargin{1};

if isempty(varval),
    vars.(varname) = [];
end

if ~isvector(varval),
    error('Variables must be vectors or scalars.');
end

if length(varval) > 128,
    error('Variables must be vectors of length 128 or less.');
end

if isnumeric(varval),
    vars.(varname) = double(varval);
elseif ischar(varval)
    vars.(varname) = char(varval);
else
    error('Variables must be either numeric or chars.');
end

val = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function trialerror(e) %#ok<DEFNU>

if ischar(e),
    str = {'correct' 'no response' 'late response' 'break fixation' 'no fixation' 'early response' 'incorrect' 'lever break', 'ignored'};
    f = strmatch(lower(e), str);
    if length(f) > 1,
        error('*** Ambiguous argument passed to TrialError ***');
    elseif isempty(f),
        error('*** Unrecognized string passed to TrialError ***');
    end
    e = f;
elseif isnumeric(e) && (e < 0 || e > 9),
    error('*** TrialErrors can range from 0 to 9 ***');
elseif ~isnumeric(e) && ~ischar(e),
    error('*** Unexpected argument type passed to TrialError (must be either numeric or string) ***');
end
end_trial(-2, e);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function user_text(text, varargin)
persistent ScreenInfo

if text == -1,
    ScreenInfo = varargin{1};
    return
end

if ~ischar(text),
    error('User text must be passed as a char array.');
end

text = sprintf(text,varargin{:});
initcontrolscreen(6, ScreenInfo, text);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function user_warning(text, varargin)
persistent ScreenInfo on

if text == -1,
    ScreenInfo = varargin{1};
    on = true;
    return
end

if text == -2,
    initcontrolscreen(7, ScreenInfo);
    return
end

if ~ischar(text),
    error('User warnings must be passed as a char array.');
end

if strcmpi(text,'off');
    on = false;
    return
end

if strcmpi(text,'on');
    on = true;
    return
end

if ~on,
    return
end

text = sprintf(text,varargin{:});
initcontrolscreen(7, ScreenInfo, text);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function abort_trial
error('ML:TrialAborted','Trial aborted.');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function escape_screen %#ok<DEFNU>
end_trial(-3);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data_missed(obj, event) %#ok<INUSD,DEFNU>
user_warning('Analog input data missed event!');
abort_trial;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function TrialData = end_trial(varargin)
global SIMULATION_MODE
persistent DAQ ScreenData eTform jTform trialtype trialerror escape

if ~isempty(varargin),
    v = varargin{1};
    if v == -1,
        DAQ = varargin{2};
        ScreenData = varargin{3};
        eTform = varargin{4};
        jTform = varargin{5};
        trialtype = varargin{6};
        trialerror = 9;
        escape = 0;
        return
    elseif v == -2,
        trialerror = varargin{2};
        return
    elseif v == -3
        escape = 1;
        return
    end
end

t1 = trialtime;
if trialtype > 0,
    if isfield(DAQ, 'AnalogInput'),
        if ~isempty(DAQ.AnalogInput),
            stop(DAQ.AnalogInput);
            getdata(DAQ.AnalogInput, DAQ.AnalogInput.SamplesAvailable); %remove & discard any AI samples
        end
    end
    TrialData.BehavioralCodes = [];
    TrialData.AnalogData = [];
    return
end

eventmarker(18);
eventmarker(18);
eventmarker(18);

% Get current trial time to calculate # of samples
MinSamplesExpected = (trialtime * DAQ.AnalogInput.SampleRate/1000) + 1; %changed by NS (03/28/2012)

[exOff eyOff] = eye_position(-3);
[eyetargets cyclerate] = eyejoytrack(-4);
if ~isempty(eyetargets),
    etX = cat(1, eyetargets{:, 1});
    etY = cat(1, eyetargets{:, 2});
    etXY = cat(2, etX, etY);
    [X, I] = unique(etXY, 'rows', 'first');
    AIdata.EyeTargetList = etXY(sort(I),:);
else
    AIdata.EyeTargetList = [];
end
AIdata.EyeSignal = [];
AIdata.Joystick = [];
AIdata.PhotoDiode = [];
for i = 1:9,
    gname = sprintf('Gen%i', i);
    AIdata.General.(gname) = [];
end
if ~isempty(DAQ.AnalogInput),
    while DAQ.AnalogInput.SamplesAvailable < MinSamplesExpected, end %changed by NS (03/28/2012)
    stop(DAQ.AnalogInput);
    data = getdata(DAQ.AnalogInput, DAQ.AnalogInput.SamplesAvailable);
    set(gcf, 'CurrentAxes', findobj('tag', 'replica'));
    if ~isempty(DAQ.Joystick) && ~SIMULATION_MODE,
        joyx = DAQ.Joystick.XChannelIndex;
        joyy = DAQ.Joystick.YChannelIndex;
        jx = data(:, joyx);
        jy = data(:, joyy);
        if ~ScreenData.UseRawJoySignal,
            [jx jy] = tformfwd(jTform, jx, jy);
        end
        h1 = plot(jx, jy);
        set(h1, 'color', ScreenData.JoyTraceColor/2);
        h2 = plot(jx, jy, '.');
        set(h2, 'markeredgecolor', ScreenData.JoyTraceColor, 'markersize', 3);
        AIdata.Joystick = [jx jy];
    end
    if ~isempty(DAQ.EyeSignal) && ~SIMULATION_MODE,
        eyex = DAQ.EyeSignal.XChannelIndex;
        eyey = DAQ.EyeSignal.YChannelIndex;
        ex = data(:, eyex);
        ey = data(:, eyey);
        if ~ScreenData.UseRawEyeSignal,
            [ex ey] = tformfwd(eTform, ex, ey);
            ex = ex + exOff;
            ey = ey + eyOff;
        end
        h1 = plot(ex, ey);
        set(h1, 'color', ScreenData.EyeTraceColor/2);
        h2 = plot(ex, ey, '.');
        set(h2, 'markeredgecolor', ScreenData.EyeTraceColor, 'markersize', 3);
        AIdata.EyeSignal = [ex ey];
    end
    if ~isempty(DAQ.General),
        generalpresent = DAQ.General.GeneralPresent;
        if generalpresent,
            for i = 1:length(generalpresent),
                generalnumber = generalpresent(i);
                gname = sprintf('Gen%i', generalnumber);
                chindex = DAQ.General.(gname).ChannelIndex;
                gendata = data(:, chindex);
                AIdata.General.(gname) = gendata;
            end
        end
    end
    if ~isempty(DAQ.PhotoDiode),
        pdindx = DAQ.PhotoDiode.ChannelIndex;
        pd = data(:, pdindx);
        AIdata.PhotoDiode = pd;
    end
end

newtform = [];
if ~isempty(eTform)
    tri = [0 0; 1 0; 0 1];
    trans = maketform('affine', tri, tri+repmat([exOff eyOff],3,1));
    comp = maketform('composite',trans,eTform);
    cpi = [0 0; 1 0; 0 1; 1 1];
    cpo = tformfwd(comp,cpi);
    newtform = cp2tform(cpi,cpo,'projective');
end

TrialData.UserVars = bhv_variable(-2);
TrialData.Escape = escape;
TrialData.NewTransform = newtform;
TrialData.NewITI = set_iti(-2);
TrialData.AnalogData = AIdata;
TrialData.AbsoluteTrialStartTime = trialtime(-2);
TrialData.BehavioralCodes = eventmarker(-2);
TrialData.ObjectStatusRecord = toggleobject(-2);
TrialData.RewardRecord = goodmonkey(-3);
TrialData.TrialError = trialerror;
TrialData.CycleRate = cyclerate;
TrialData.TrialExitTime = round(trialtime - t1);
