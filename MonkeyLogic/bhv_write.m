function status = bhv_write(mode, fidbhv, WriteData, varargin)
%SYNTAX:
%        status = bhvwrite(mode, fidbhv, Data)
%
% Mode: 1 = write header
%       2 = write trial info
%       3 = write footer
%
% Must provide an fid to the already-open data file.
% This function is called by MonkeyLogic, which takes care of opening and
% closing the datafile.
%
% See "bhvread" for information on file structure.
% BHV.NumTrials will be updated when the footer is written.
%
% Created by WA 7/06
% Modified 1/20/08 -WA
% Modified 8/13/08 -WA (added movie images to file; v2.5)
% Modified 8/31/08 -WA (handles option to NOT store PICs and MOVs to file)
% Modified 7/27/12 -WA (Increases possible trial duration to 2^32)
% Modified 7/16/13 -DF (New field: ActualVideoRefreshRate; v3.1)

persistent numtrialpointer

status = 0;
bhvfileversion = 3.3;

switch mode,
    case 1, %write header
        %should be called as: bhvwrite(1, bhvfid, MLConfig, condfile, RunTimeFiles);
        MLConfig = WriteData;
        condfile = varargin{1};
        RunTimeFiles = varargin{2};
        Conditions = varargin{3};
        EyeTransform = varargin{4};
        JoyTransform = varargin{5};

        BHV.MagicNumber = 2837160;
        BHV.FileHeader = 'MonkeyLogic BHV File';
        BHV.FileVersion = bhvfileversion;
        
        BHV.StartTime = datestr(now);
        BHV.ExperimentName = MLConfig.ExperimentName;
        BHV.Investigator = MLConfig.Investigator;
        BHV.SubjectName = MLConfig.SubjectName;
        BHV.ComputerName = MLConfig.ComputerName;
        BHV.ConditionsFile = condfile;
        BHV.NumTimingFiles = length(RunTimeFiles);
        BHV.TimingFiles = RunTimeFiles;
        
        switch MLConfig.ErrorLogic,
            case 1,
                str = 'On error: Ignore';
            case 2,
                str = 'On error: Repeat immediately';
            case 3,
                str = 'On error: Repeat delayed';
        end
        BHV.ErrorLogic = str;
        
        switch MLConfig.BlockLogic,
            case 1,
                str = 'Blocks: Random with replacement';
            case 2,
                str = 'Blocks: Random without replacement';
            case 3,
                str = 'Blocks: Increasing block order';
            case 4, 
                str = 'Blocks: Decreasing block order';
            case 5,
                str = 'Blocks: User-defined';
        end
        BHV.BlockLogic = str;
        
        switch MLConfig.CondLogic,
            case 1,
                str = 'Conditions: Random with replacement';
            case 2,
                str = 'Conditions: Random without replacement';
            case 3,
                str = 'Conditions: Increasing condition order';
            case 4,
                str = 'Conditions: Decreasing condition order';
            case 5,
                str = 'Conditions: User-defined';
        end
        BHV.CondLogic = str;
        
        BHV.BlockSelectFunction = MLConfig.BlockSelectFunction;
        BHV.CondSelectFunction = MLConfig.CondSelectFunction;
        BHV.VideoRefreshRate = MLConfig.RefreshRate;
		BHV.ActualVideoRefreshRate = MLConfig.ActualRefreshRate;
        BHV.VideoBufferPages = MLConfig.BufferPages;
        BHV.ScreenXresolution = MLConfig.ScreenX;
        BHV.ScreenYresolution = MLConfig.ScreenY;
        BHV.ViewingDistance = MLConfig.ViewingDistance;
        BHV.PixelsPerDegree = MLConfig.PixelsPerDegree;
        BHV.ScreenBackgroundColor = MLConfig.ScreenBackgroundColor;
        BHV.EyeTraceColor = MLConfig.EyeTraceColor;
        BHV.JoyTraceColor = MLConfig.JoyTraceColor;
        
        BHV.AnalogInputType = MLConfig.InputOutput.Configuration.AnalogInputType;
        BHV.AnalogInputFrequency = MLConfig.InputOutput.Configuration.AnalogInputFrequency;
        BHV.AnalogInputDuplication = MLConfig.InputOutput.Configuration.AnalogInputDuplication;
        
        if MLConfig.UseRawEyeSignal == 1,
            str = 'Raw signal (precalibrated)';
        else
            str = 'Online transformation matrix';
        end
        BHV.EyeSignalCalibrationMethod = str;
        BHV.EyeTransform = EyeTransform;
        
        if MLConfig.UseRawJoySignal == 1,
            str = 'Raw signal (precalibrated)';
        else
            str = 'Online transformation matrix';
        end
        BHV.JoystickCalibrationMethod = str;
        BHV.JoyTransform = JoyTransform;
         
        switch MLConfig.PhotoDiode,
            case 1,
                str = 'None';
            case 2,
                str = 'Upper left';
            case 3,
                str = 'Upper right';
            case 4,
                str = 'Lower right';
            case 5,
                str = 'Lower left';
        end
        BHV.PhotoDiode = str;
        BHV.Padding = zeros(1024, 1);
        BHV.NumTrials = 0;
        
        %find unique images used in conditions file:
        [picnames picsizes pics movnames movsizes movs] = getcondpics(Conditions);
       
        psizearray = [];
        picdata = [];
        if isempty(picnames),
            numpics = 0;
        else
            numpics = length(picnames);
            for i = 1:numpics,
                psize = picsizes{i}';
                psizearray = cat(1, psizearray, psize);
                picdata = cat(1, picdata, reshape(pics{i}, prod(psize), 1));
            end
        end
        Stimuli.PIC.NumStim = numpics;
        Stimuli.PIC.Name = picnames;
        Stimuli.PIC.Size = psizearray;
        Stimuli.PIC.Data = picdata;
 
        msizearray = [];
        if isempty(movnames),
            nummovs = 0;
            MM = {};
        else
            nummovs = length(movnames);
            MM = cell(nummovs, 1);
            for i = 1:nummovs,
                msize = movsizes{i}';
%                if ~MLConfig.SaveFullMovies,
                    msize(4) = 1; %crucial line: saves only 1 frame per movie
%                end
                msizearray = cat(1, msizearray, msize);
                M = movs{i};
%                numframes = msize(4);
%                 movdata = [];
%                 for fnum = 1:numframes,
%                     movdata = cat(1, movdata, reshape(M{fnum}, prod(msize(1:3)), 1));
%                 end
                MM{i} = reshape(M, prod(msize(1:3)), 1);
            end
        end
        Stimuli.MOV.NumStim = nummovs;
        Stimuli.MOV.Name = movnames;
        Stimuli.MOV.Size = msizearray;
        Stimuli.MOV.Data = MM;
    
        [RawTaskObject, TimingFile, CondInBlock, Info] = parsecondfile(BHV.ConditionsFile);
        BHV.RawTaskObject = RawTaskObject;
        BHV.TimingFile_cond = TimingFile;
        %%%%% Version 2.71
        BHV.Block_cond = CondInBlock;
        %%%%%
        BHV.Info_cond = Info;
        BHV.NumConds = size(BHV.RawTaskObject, 1);
        BHV.ObjectsPerCond = size(BHV.RawTaskObject, 2);
        BHV.RawTaskObject = reshape(BHV.RawTaskObject, BHV.NumConds * BHV.ObjectsPerCond, 1);
        
        fwrite(fidbhv, BHV.MagicNumber, 'uint32');
        fwritetext(fidbhv, BHV.FileHeader, 64);
        fwrite(fidbhv, BHV.FileVersion, 'double');
        fwritetext(fidbhv, BHV.StartTime, 32);
        fwritetext(fidbhv, BHV.ExperimentName, 128);
        fwritetext(fidbhv, BHV.Investigator, 128);
        fwritetext(fidbhv, BHV.SubjectName, 128);
        fwritetext(fidbhv, BHV.ComputerName, 128);
        fwritetext(fidbhv, BHV.ConditionsFile, 128);
        fwrite(fidbhv, BHV.NumConds, 'uint16');
        fwrite(fidbhv, BHV.ObjectsPerCond, 'uint16');
        fwritetext(fidbhv, BHV.RawTaskObject, 64);
        %%%%% Version 2.65
        fwritetext(fidbhv, BHV.TimingFile_cond, 128);
        %%%%% Version 2.71
        bc = [];
        for i = 1:BHV.NumConds,
            bci = BHV.Block_cond{i};
            for j = 1:length(bci),
                bc(i,j) = bci(j);
            end
        end
        fwrite(fidbhv, size(bc,2), 'uint8');
        fwrite(fidbhv, bc, 'uint8');
        %%%%%
        fwritetext(fidbhv, BHV.Info_cond, 128);
        %%%%%
        fwrite(fidbhv, BHV.NumTimingFiles, 'uint8');
        fwritetext(fidbhv, BHV.TimingFiles, 128);
        fwritetext(fidbhv, BHV.ErrorLogic, 64);
        fwritetext(fidbhv, BHV.BlockLogic, 64);
        fwritetext(fidbhv, BHV.CondLogic, 64);
        fwritetext(fidbhv, BHV.BlockSelectFunction, 64);
        fwritetext(fidbhv, BHV.CondSelectFunction, 64);
        fwrite(fidbhv, BHV.VideoRefreshRate, 'double');
		fwrite(fidbhv, BHV.ActualVideoRefreshRate, 'double');
        fwrite(fidbhv, BHV.VideoBufferPages, 'uint16');
        fwrite(fidbhv, BHV.ScreenXresolution, 'uint16');
        fwrite(fidbhv, BHV.ScreenYresolution, 'uint16');
        fwrite(fidbhv, BHV.ViewingDistance, 'double');
        fwrite(fidbhv, BHV.PixelsPerDegree, 'double');
        fwritetext(fidbhv, BHV.AnalogInputType, 32);
        fwrite(fidbhv, BHV.AnalogInputFrequency, 'double');
        if BHV.AnalogInputDuplication,
            fwritetext(fidbhv, 'On', 32);
        else
            fwritetext(fidbhv, 'Off', 32);
        end
        fwritetext(fidbhv, BHV.EyeSignalCalibrationMethod, 32);
        if isempty(BHV.EyeTransform),
            fwrite(fidbhv, 0, 'uint8');
        else
            fwrite(fidbhv, 1, 'uint8');
            fwrite(fidbhv, BHV.EyeTransform.ndims_in, 'uint16');
            fwrite(fidbhv, BHV.EyeTransform.ndims_out, 'uint16');
            fwritetext(fidbhv, ['@' char(BHV.EyeTransform.forward_fcn)], 64);
            fwritetext(fidbhv, ['@' char(BHV.EyeTransform.inverse_fcn)], 64);
            tsize = numel(BHV.EyeTransform.tdata.T);
            fwrite(fidbhv, tsize, 'uint16');
            fwrite(fidbhv, reshape(BHV.EyeTransform.tdata.T, tsize, 1), 'double');
            fwrite(fidbhv, reshape(BHV.EyeTransform.tdata.Tinv, tsize, 1), 'double');
        end
        fwritetext(fidbhv, BHV.JoystickCalibrationMethod, 32);
        if isempty(BHV.JoyTransform),
            fwrite(fidbhv, 0, 'uint8');
        else
            fwrite(fidbhv, 1, 'uint8');
            fwrite(fidbhv, BHV.JoyTransform.ndims_in, 'uint16');
            fwrite(fidbhv, BHV.JoyTransform.ndims_out, 'uint16');
            fwritetext(fidbhv, ['@' char(BHV.JoyTransform.forward_fcn)], 64);
            fwritetext(fidbhv, ['@' char(BHV.JoyTransform.inverse_fcn)], 64);
            tsize = numel(BHV.JoyTransform.tdata.T);
            fwrite(fidbhv, tsize, 'uint16');
            fwrite(fidbhv, reshape(BHV.JoyTransform.tdata.T, tsize, 1), 'double');
            fwrite(fidbhv, reshape(BHV.JoyTransform.tdata.Tinv, tsize, 1), 'double');
        end
        fwritetext(fidbhv, BHV.PhotoDiode, 12);
        
        fwrite(fidbhv, BHV.ScreenBackgroundColor, 'double');
        fwrite(fidbhv, BHV.EyeTraceColor, 'double');
        fwrite(fidbhv, BHV.JoyTraceColor, 'double');
        
        fwrite(fidbhv, Stimuli.PIC.NumStim, 'uint16');
        if Stimuli.PIC.NumStim > 0,
            fwritetext(fidbhv, Stimuli.PIC.Name, 128);
            fwrite(fidbhv, Stimuli.PIC.Size, 'uint16');
            fwrite(fidbhv, Stimuli.PIC.Data, 'uint8');
        end
        
        fwrite(fidbhv, Stimuli.MOV.NumStim, 'uint16');
        if Stimuli.MOV.NumStim > 0,
            fwritetext(fidbhv, Stimuli.MOV.Name, 128);
            fwrite(fidbhv, Stimuli.MOV.Size, 'uint16');
            for i = 1:Stimuli.MOV.NumStim,
                fwrite(fidbhv, Stimuli.MOV.Data{i}, 'uint8');
            end
        end
        
        fwrite(fidbhv, BHV.Padding, 'uint8');
        numtrialpointer = ftell(fidbhv);
        fwrite(fidbhv, BHV.NumTrials, 'uint16');
        
    case 2, %write trial
        
        %should be called as: bhvwrite(2, bhvfid, WriteData(trial));
        fwrite(fidbhv, WriteData.TrialNumber, 'uint16');
        numc = length(WriteData.AbsoluteTrialStartTime);
        fwrite(fidbhv, numc, 'uint8');
        fwrite(fidbhv, WriteData.AbsoluteTrialStartTime, 'double');
        fwrite(fidbhv, WriteData.BlockNumber, 'uint16');
        fwrite(fidbhv, WriteData.CondNumber, 'uint16');
        fwrite(fidbhv, WriteData.TrialError, 'uint16');
        fwrite(fidbhv, round(WriteData.CycleRate), 'uint16');
        fwrite(fidbhv, WriteData.NumCodes, 'uint16');
        fwrite(fidbhv, WriteData.CodeNumbers{:}, 'uint16');
        %%%%% Version 3.0 (prior had been uint16)
        fwrite(fidbhv, WriteData.CodeTimes{:}, 'uint32');
        %%%%%
        if isempty(WriteData.EyeSignal),
            numxeyepoints = 0;
            numyeyepoints = 0;
            xeye = [];
            yeye = [];
        else
            [rows cols] = size(WriteData.EyeSignal);
            numxeyepoints = rows;
            xeye = WriteData.EyeSignal(:, 1);
            if cols > 1,
                numyeyepoints = numxeyepoints;
                yeye = WriteData.EyeSignal(:, 2);
            else
                numyeyepoints = 0;
                yeye = [];
            end
        end
        fwrite(fidbhv, numxeyepoints, 'uint32');
        fwrite(fidbhv, xeye, 'float32');
        fwrite(fidbhv, numyeyepoints, 'uint32');
        fwrite(fidbhv, yeye, 'float32');
        if isempty(WriteData.Joystick),
            numxjoypoints = 0;
            numyjoypoints = 0;
            xjoy = [];
            yjoy = [];
        else
            [rows cols] = size(WriteData.Joystick);
            numxjoypoints = rows;
            xjoy = WriteData.Joystick(:, 1);
            if cols > 1,
                numyjoypoints = numxjoypoints;
                yjoy = WriteData.Joystick(:, 2);
            else
                numyjoypoints = 0;
                yjoy = [];
            end
        end
        fwrite(fidbhv, numxjoypoints, 'uint32');
        fwrite(fidbhv, xjoy, 'float32');
        fwrite(fidbhv, numyjoypoints, 'uint32');
        fwrite(fidbhv, yjoy, 'float32');
        
        %%%%% Versions > 3.2
        if (isfield(WriteData, 'TouchSignal'))

            if isempty(WriteData.TouchSignal),
                numxtouchpoints = 0;
                numytouchpoints = 0;
                xtouch = [];
                ytouch = [];
            else
                [rows cols] = size(WriteData.TouchSignal);
                numxtouchpoints = rows;
                xtouch = WriteData.TouchSignal(:, 1);
                if cols > 1,
                    numytouchpoints = numxtouchpoints;
                    ytouch = WriteData.TouchSignal(:, 2);
                else
                    numytouchpoints = 0;
                    ytouch = [];
                end
            end
            fwrite(fidbhv, numxtouchpoints, 'uint32');
            fwrite(fidbhv, xtouch, 'float32');
            fwrite(fidbhv, numytouchpoints, 'uint32');
            fwrite(fidbhv, ytouch, 'float32');
        end
        
        %%%%% Versions > 3.3
        if (isfield(WriteData, 'MouseSignal'))

            if isempty(WriteData.MouseSignal),
                numxmousepoints = 0;
                numymousepoints = 0;
                xmouse = [];
                ymouse = [];
            else
                [rows cols] = size(WriteData.MouseSignal);
                numxmousepoints = rows;
                xmouse = WriteData.MouseSignal(:, 1);
                if cols > 1,
                    numymousepoints = numxmousepoints;
                    ymouse = WriteData.MouseSignal(:, 2);
                else
                    numymousepoints = 0;
                    ymouse = [];
                end
            end
            fwrite(fidbhv, numxmousepoints, 'uint32');
            fwrite(fidbhv, xmouse, 'float32');
            fwrite(fidbhv, numymousepoints, 'uint32');
            fwrite(fidbhv, ymouse, 'float32');
        end
 
       %%%%% Versions > 2.5
        for i = 1:9,
            gname = sprintf('Gen%i', i);
            if ~isfield(WriteData,'GeneralAnalog') || isempty(WriteData.GeneralAnalog.(gname)),
                numgenpoints = 0;
                gen = [];
            else
                rows = length(WriteData.GeneralAnalog.(gname));
                numgenpoints = rows;
                gen = WriteData.GeneralAnalog.(gname);
            end
            fwrite(fidbhv, numgenpoints, 'uint32');
            fwrite(fidbhv, gen, 'float32');
        end
        %%%%%
        
        if isempty(WriteData.PhotoDiode),
            numpdpoints = 0;
            pd = [];
        else
            numpdpoints = length(WriteData.PhotoDiode);
            pd = WriteData.PhotoDiode;
        end
        fwrite(fidbhv, numpdpoints, 'uint32');
        fwrite(fidbhv, pd, 'float32');

        if isnan(WriteData.ReactionTime),
            rt = -1;
        else
            rt = WriteData.ReactionTime;
        end
        fwrite(fidbhv, rt, 'int16');
        
        %ObjectStatusRecord
        obstat = WriteData.ObjectStatusRecord;
        if isempty(obstat),
            togglecount = 0;
            fwrite(fidbhv, togglecount, 'uint32');
        else
            togglecount = length(obstat);
            fwrite(fidbhv, togglecount, 'uint32');
            for i = 1:togglecount,
                numbits = length(obstat(i).Status);
                statval = obstat(i).Status;
                stattime = obstat(i).Time;
                fwrite(fidbhv, numbits, 'uint32');
                fwrite(fidbhv, statval, 'uint8');
                fwrite(fidbhv, stattime, 'uint32');
                if any(statval > 1),
                    numfields = length(obstat(i).Data);
                    fwrite(fidbhv, numfields, 'uint8');
                    for fnum = 1:numfields,
                        d = obstat(i).Data{fnum};
                        datacount = length(d);
                        fwrite(fidbhv, datacount, 'uint32');
                        fwrite(fidbhv, d, 'double');
                    end
                end
            end
        end
        rstat = WriteData.RewardRecord;
        if isempty(rstat),
            rcount = 0;
            fwrite(fidbhv, rcount, 'uint32');
        else
            rcount = length(rstat.StartTimes);
            fwrite(fidbhv, rcount, 'uint32');
            fwrite(fidbhv, rstat.StartTimes, 'uint32');
            fwrite(fidbhv, rstat.EndTimes, 'uint32');
        end
        
        %%%%% Version 2.7
        varnames = fields(WriteData.UserVars);
        fwrite(fidbhv, length(varnames), 'uint8');
        for i = 1:length(varnames),
            varn = varnames{i};
            varv = WriteData.UserVars.(varn);
            fwritetext(fidbhv, varn, 32);
            if isempty(varv),
                fwritetext(fidbhv, 'e', 1);
            elseif isnumeric(varv),
                fwritetext(fidbhv, 'd', 1);
                fwrite(fidbhv, length(varv), 'uint8');
                fwrite(fidbhv, varv, 'double');
            elseif ischar(varv),
                fwritetext(fidbhv, 'c', 1);
                fwritetext(fidbhv, varv, 128);
            else
                fwritetext(fidbhv, 'e', 1);
            end
        end
        %%%%%
        
        %write dummy footer
        beginfooter = ftell(fidbhv);
        
        BHV.NumBehavioralCodesUsed = 0;
        BHV.CodeNumbersUsed = [];
        BHV.CodeNamesUsed = '';
        BHV.NumTrials = WriteData.TrialNumber;
        BHV.FinishTime = datestr(now);
        
        fwrite(fidbhv, BHV.NumBehavioralCodesUsed, 'uint16');
        fwrite(fidbhv, BHV.CodeNumbersUsed, 'uint16');
        
        VarChanges = trackvarchanges(-1);
        numf = 0;
        if isstruct(VarChanges),
            fn = fieldnames(VarChanges);
            numf = length(fn);
        end
        fwrite(fidbhv, numf, 'uint16');
        for i = 1:numf,
            fwritetext(fidbhv, fn{i}, 64);
            n = length(VarChanges.(fn{i}).Trial);
            fwrite(fidbhv, n, 'uint16');
            fwrite(fidbhv, VarChanges.(fn{i}).Trial, 'uint16');
            fwrite(fidbhv, VarChanges.(fn{i}).Value, 'double');
        end
        
        fwritetext(fidbhv, BHV.FinishTime, 32);
        fseek(fidbhv, numtrialpointer, -1);
        fwrite(fidbhv, BHV.NumTrials, 'uint16');
        fseek(fidbhv, beginfooter, -1);
        
    case 3, %write footer
        
        %should be called as: bhvwrite(3, bhvfid, Codes, BehavioralCodes, numtrials);
        Codes = WriteData; %codes actually used
        BehavioralCodes = varargin{1}; %full list
        
        if isempty(BehavioralCodes) || isempty(Codes),
            BHV.NumBehavioralCodesUsed = 0;
            BHV.CodeNumbersUsed = [];
            BHV.CodeNamesUsed = {};
        else
            codes_used = unique(Codes.CodeNumbers);
            f = find(ismember(BehavioralCodes.CodeNumbers, codes_used));
            BHV.NumBehavioralCodesUsed = length(f);
            BHV.CodeNumbersUsed = BehavioralCodes.CodeNumbers(f);
            BHV.CodeNamesUsed = BehavioralCodes.CodeNames(f);
        end
        BHV.NumTrials = varargin{2};
        BHV.FinishTime = datestr(now);
        
        fwrite(fidbhv, BHV.NumBehavioralCodesUsed, 'uint16');
        fwrite(fidbhv, BHV.CodeNumbersUsed, 'uint16');
        fwritetext(fidbhv, BHV.CodeNamesUsed, 64);
        
        VarChanges = trackvarchanges(-1);
        numf = 0;
        if isstruct(VarChanges),
            fn = fieldnames(VarChanges);
            numf = length(fn);
        end
        fwrite(fidbhv, numf, 'uint16');
        for i = 1:numf,
            fwritetext(fidbhv, fn{i}, 64);
            n = length(VarChanges.(fn{i}).Trial);
            fwrite(fidbhv, n, 'uint16');
            fwrite(fidbhv, VarChanges.(fn{i}).Trial, 'uint16');
            fwrite(fidbhv, VarChanges.(fn{i}).Value, 'double');
        end
        
        fwritetext(fidbhv, BHV.FinishTime, 32);
        fseek(fidbhv, numtrialpointer, -1);
        fwrite(fidbhv, BHV.NumTrials, 'uint16');
        fseek(fidbhv, 0, 1);
    case 4, %check for file version
        status = bhvfileversion;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function status = fwritetext(fid, inputstring, paddedlength)

if ~iscell(inputstring),
    inputstring = cellstr(inputstring);
end
for i = 1:length(inputstring),
    str = inputstring{i};
    if length(str) > paddedlength,
        str = str(1:paddedlength);
    end
    str2 = repmat(' ', 1, paddedlength);
    str2(1:length(str)) = str;
    status = fwrite(fid, str2, 'uchar');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [picnames, picsizes, pics, movnames, movsizes, movs] = getcondpics(Conditions)

pics = {''};
numpics = 0;
movs = {''};
nummovs = 0;
for cond = 1:length(Conditions),
    TaskObject = Conditions(cond).TaskObject;
    for obnum = 1:length(TaskObject),
        if strcmp(TaskObject(obnum).Type, 'pic'),
            numpics = numpics + 1;
            n = TaskObject(obnum).Name;
            picfiles{numpics} = n;
            [pname fname] = fileparts(n);
            n = fname;
            picnames{numpics} = n;
        elseif strcmp(TaskObject(obnum).Type, 'mov'),
            nummovs = nummovs + 1;
            n = TaskObject(obnum).Name;
            movfiles{nummovs} = n;
            [pname fname] = fileparts(n);
            n = fname;
            movnames{nummovs} = n;
        end
    end
end

if ~numpics,
    picnames = [];
    picsizes = [];
    pics = [];
else
    [picnames i] = unique(picnames);
    picfiles = picfiles(i);
    numpics = length(picnames);
    picsizes = cell(numpics, 1);
    for picnum = 1:numpics,
        pics{picnum} = imread(picfiles{picnum});
        picsizes{picnum} = size(pics{picnum});
    end
end

if ~nummovs,
    movnames = [];
    movsizes = [];
    movs = [];
else
    [movnames, i] = unique(movnames);
    movfiles = movfiles(i);
    nummovs = length(movnames);
    movsizes = cell(nummovs, 1);
    for movnum = 1:nummovs,
        if verLessThan('matlab', '8')
            reader = mmreader(movfiles{movnum}); %#ok<DMMR>
        else
            reader = VideoReader(movfiles{movnum}); %#ok<TNMLP>
        end
        numframes = get(reader, 'numberOfFrames');
        M = squeeze(read(reader,1));
        movs{movnum} = M;
        movsizes{movnum} = [size(M) numframes];
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [RawTaskObject, TimingFile, CondInBlock, Info] = parsecondfile(condfile)

RawTaskObject = {};
TimingFile = {};
CondInBlock = {};
Info = {};
conds = load_conditions(condfile);
if iscell(conds),
    return;
end
condnum = 0;
for i = 1:length(conds),
    condnum = condnum + 1;
    p = conds(condnum).TaskObject;
    for j = 1:length(p),
        RawTaskObject{condnum, j} = p(j).RawText;
    end
    TimingFile{condnum} = conds(condnum).TimingFile;
    CondInBlock{condnum} = conds(condnum).CondInBlock;
    Info{condnum} = conds(condnum).RawInfo;
end

% fid = fopen(condfile);
% fgetl(fid); %header
% 
% condnum = 0;
% txt = fgetl(fid);
% while txt ~= -1,
%     if txt(1) ~= '%' && ~isempty(deblank(txt)), %allows for comments if first character in a line is a "%" and for blank lines
%         condnum = condnum + 1;
%         p = parse(txt);
%         for i = 5:size(p, 1),
%             RawTaskObject(condnum, i-4) = {deblank(p(i, :))};
%         end
%     end
%     txt = fgetl(fid);
% end
% 
% fclose(fid);