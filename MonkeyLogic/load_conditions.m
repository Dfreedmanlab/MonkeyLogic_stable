function [Conditions, cerror] = load_conditions(varargin)
%SYNTAX:
%        Conditions = load_conditions(filename)
%
% Reads "conditions" text file, in which the first line is assumed to be a
% header.  If no filename is specified, the user will be prompted to select
% one.  See www.monkeylogic.net for information on the structure of
% conditions text files.
%
% The returned structure, Conditions, will have as many elements as
% conditions. The field, TaskObject, will have as many elements as there
% are TaskObjects in that condition.  So, for instance,
% Conditions(11).TaskObject(5) is the 5th TaskObject in condition #11.
% 
% Created by WA July, 2006
% Modified 9/06/07 -WA
% Modified 8/19/08 -WA (to handle non-integer RelativeFrequency values)
% 

cerror = '';
Conditions = struct;

if ~ispref('MonkeyLogic', 'Directories'),
    success = set_ml_preferences;
    if ~success,
        return
    end
end
MLPrefs.Directories = getpref('MonkeyLogic', 'Directories');

if isempty(varargin),
    [fname pname] = uigetfile([MLPrefs.Directories.ExperimentDirectory '*.txt'], 'Select Conditions file...');
    if pname == 0, return; end
    txtfile = [pname fname];
    [pnamediscard fname ext] = fileparts(txtfile);
    MLPrefs.Directories.ExperimentDirectory = pname;
    setpref('MonkeyLogic', 'Directories', MLPrefs.Directories);
else
    txtfile = varargin{:};
    [pname fname ext] = fileparts(txtfile);
    if isempty(pname),
        pname = MLPrefs.Directories.ExperimentDirectory;
    else
        pname = [pname filesep];
    end
    if isempty(ext),
        ext = '.txt';
    end
    txtfile = [pname fname ext];
end

fid = fopen(txtfile);
if fid < 1,
    cerror = 'Unable to open Conditions file';
    return
end

header = fgetl(fid);
if header == -1,
    cerror = 'Empty Conditions file';
    return
end
if length(header) > 7 && strcmpi(header(1:8), 'function'),
    Conditions = {[fname ext]};
    return
end

h = parse_object(header);
column_order = {'Condition','Frequency','Block','Timing File','Info'};
nonTaskCols = length(column_order);
columns = zeros(1,length(h));
i=1;
while i <= length(columns),
    if i <= length(column_order),
        match = column_order{i};
    else
        match = ['TaskObject#' sprintf('%i',i-length(column_order))];
    end
    j=1;
    while ~strcmpi(h{j},match),
        j=j+1;
        if j > length(h),
            j=-1;
            nonTaskCols = nonTaskCols-1;
            columns = [columns -1];
            break;
        end
    end
    columns(i)=j;
    i=i+1;
    if i > length(h)+5,
        cerror = 'Unable to parse conditions file header.';
        fprintf('Valid columns are "Condition", "Frequency", "Block", "Timing File", "Info", and "TaskObject#1" through TaskObject#N".\n');
        return
    end
end

numconds = 0;
txt = fgetl(fid);
if txt == -1,
    cerror = 'Only one line found in conditions file (assumed to be a header)';
    return
end

sinebank = [];
while txt ~= -1,
    if txt(1) ~= '%' && ~isempty(deblank(txt)), %allows for comments if first character in a line is a "%" and for blank lines
        numconds = numconds + 1;
        p = parse_object(txt);
        
        % Check condition number (one to n, without gaps)
        if columns(1) == -1,
            condnum = numconds;
        else
            condnum = p{columns(1)};
            try
                condnum = eval(condnum);
            catch
                cerror = 'Condition number column must contain a single integer.';
                return
            end
            if condnum ~= numconds,
                cerror = sprintf('Non-continuous or out-of-order condition numbers found on line %i', numconds + 1);
                return
            end
        end
    
        % Read "relative frequency" of this condition
        if columns(2) == -1,
            RelativeFrequency(condnum) = 1;
        else
            rf = p{columns(2)};
            try
                rf = eval(rf);
            catch
                cerror = 'Relative frequency of a condition must be a numeric value';
                return
            end
            if length(rf) > 1,
                cerror = 'Relative frequency of a condition must be scalar';
                return
            end
            RelativeFrequency(condnum) = rf;
        end
        
        % Read in which blocks each condition can occur ("cond in block") -
        % should be either 'all' or a matlab-style array: [b1 b2 b3:b4]
        % "0" is the same as "all."
        if columns(3) == -1,
            cib = 'all';
        else
            cib = p{columns(3)};
        end
        if length(cib) >= 3 &&  strcmpi(cib(1:3), 'all'),
            BlockSpec{condnum} = 0;
        else
            try
                BlockSpec{condnum} = eval(['[' deblank(cib) ']']);
            catch
                cerror = sprintf('Cannot evaluate "Cond-in-Block" field in condition #%i', condnum);
                return
            end
        end
        
        if columns(4) == -1,
            cerror = 'Must contain a Timing File column';
            return
        end
        timingfile = p{columns(4)};
        if ~ischar(timingfile),
            cerror = 'Timing File must be a string name of the ".m" script running the experiment';
            return
        end
        dot = find(timingfile == '.');
        if ~isempty(dot) && ~strcmp(timingfile(dot:length(timingfile)), '.m'),
            cerror = 'Timing File must be a ".m" matlab script';
            return
        elseif isempty(dot),
            timingfile = [timingfile '.m'];
        end
        TFiles{condnum} = timingfile;
        
        if columns(5) == -1,
            info{condnum} = struct;
            rawinfo{condnum} = '';
        else
            info{condnum} = eval(sprintf('struct(%s)',p{columns(5)}));
            rawinfo{condnum} = p{columns(5)};
        end
        
        % Read Task Objects
        clear TaskObject
        TaskObject(1:100) = struct('Type', '', 'Name', '', 'RawText', '', 'FunctionName', '', 'Xpos', [], 'Ypos', [], 'Xsize', -1, 'Ysize', -1, 'Radius', [], 'Color', [], 'FillFlag', [], 'WaveForm', [], 'Freq', [], 'NBits', [], 'OutputPort', []);
        for obnum = 1:(length(p))-nonTaskCols,
            object = p{columns(obnum+length(column_order))};
            object = object(object ~= '"'); %remove quotes that might have been added by Excel
            if length(object) < 5, %3 chars for type then at least opening & closing parentheses
                cerror = sprintf('Unrecognized option in condition #%i', condnum);
            end
            obtype = lower(object(1:3));
            TaskObject(obnum).Type = obtype;
            TaskObject(obnum).RawText = object;
            op = find(object == '(');
            if ~isempty(op),
                cp = find(object == ')');
                if isempty(cp),
                    cerror = sprintf('Opening but no closing parenthesis found in condition #%i', condnum);
                    return
                end
                if cp == op+1,
                    cerror = sprintf('No attributes found for taskobject %i in condition #%i', taskobjectloop-1, condnum);
                    return
                end
                attributes = parse_object(object(op+1:cp-1), double(','));
                numatt = length(attributes);
                if strcmp(obtype, 'fix'), %fixation target - syntax: fix(xpos, ypos)
    
                    if numatt < 2,
                        cerror = sprintf('Must have 2 attributes (x, y) for task object of type FIX in condition #%i', condnum);
                        return
                    end
                    try
                        xpos = str2double(attributes{1});
                    catch
                        cerror = sprintf('First attribute for FIX objects must be the x-position (condition #%i)', condnum);
                        return
                    end
                    TaskObject(obnum).Xpos = xpos;
                    try
                        ypos = str2double(attributes{2});
                    catch
                        cerror = sprintf('Second attribute for FIX objects must be the y-position (condition #%i)', condnum);
                        return
                    end
                    TaskObject(obnum).Ypos = ypos;
    
                elseif strcmp(obtype, 'pic'), %image file - syntax: pic(picname, xpos, ypos)
    
                    if numatt < 3,
                        cerror = sprintf('Must have at least 3 attributes (name, x, y) for task object of type PIC in condition #%i', condnum);
                        return
                    end
                    name = attributes{1};
                    if isempty(name),
                        cerror = sprintf('Error: empty name string found in condition #%i', condnum);
                        return
                    end
                    % append jpg or bmp if exists (preference given to jpg)
                    guessjpg = [MLPrefs.Directories.ExperimentDirectory name '.jpg'];
                    guessjpeg = [MLPrefs.Directories.ExperimentDirectory name '.jpeg'];
                    guessbmp = [MLPrefs.Directories.ExperimentDirectory name '.bmp'];
                    guessgif = [MLPrefs.Directories.ExperimentDirectory name '.gif'];
                    if exist(guessjpg, 'file'),
                        name = guessjpg;
                    elseif exist(guessjpeg, 'file'),
                        name = guessjpeg;
                    elseif exist(guessbmp, 'file'),
                        name = guessbmp;
                    elseif exist(guessgif, 'file'),
                        name = guessgif;
                    else
                        cerror = sprintf('Unable to find image file %s in condition #%i', name, condnum);
                        return
                    end
                    TaskObject(obnum).Name = name;
    
                    try
                        xpos = str2double(attributes{2});
                    catch
                        cerror = sprintf('Second attribute for PIC objects must be the x-position (condition #%i)', condnum);
                        return
                    end
                    TaskObject(obnum).Xpos = xpos;
                    try
                        ypos = str2double(attributes{3});
                    catch
                        cerror = sprintf('Third attribute for PIC objects must be the y-position (condition #%i)', condnum);
                        return
                    end
                    TaskObject(obnum).Ypos = ypos;
                    
                    if(numatt>3)
                        try
                            width = str2double(attributes{4});
                        catch
                            cerror = sprintf('Fourth attribute for PIC objects must be the width (condition #%i)', condnum);
                            return
                        end
                        TaskObject(obnum).Xsize = width;
                        try
                            height = str2double(attributes{5});
                        catch
                            cerror = sprintf('Fifth attribute for PIC objects must be the height (condition #%i)', condnum);
                            return
                        end
                        TaskObject(obnum).Ysize = height;
                    end
                    
                elseif strcmp(obtype, 'gen'),
                    
                    if numatt > 3 || numatt == 2,
                        cerror = sprintf('Must have 1 or 3 arguments, function name & optionally xpos & ypos, for "gen" object (condition #%i)', condnum);
                        return
                    end
                    fname = attributes{1};
                    pname = MLPrefs.Directories.ExperimentDirectory;
                    ext = '.m';
                    funcname = [pname fname ext];
                    if ~exist(funcname, 'file'),
                        disp(sprintf('Warning: File generation function "%s" not found', funcname));
                    end
                    TaskObject(obnum).FunctionName = funcname;
                    
                    if numatt > 1,
                        try
                            xpos = str2double(attributes{2});
                        catch
                            cerror = sprintf('Second attribute for PIC objects must be the x-position (condition #%i)', condnum);
                            return
                        end
                        TaskObject(obnum).Xpos = xpos;
                        try
                            ypos = str2double(attributes{3});
                        catch
                            cerror = sprintf('Third attribute for PIC objects must be the y-position (condition #%i)', condnum);
                            return
                        end
                        TaskObject(obnum).Ypos = ypos;
                    else
                        TaskObject(obnum).Xpos = NaN;
                        TaskObject(obnum).Ypos = NaN;
					end
        
                elseif strcmp(obtype, 'snd'), %sound (can be generated sine-wave or read from .mat or .wav file) - syntax: snd(sndfile) or snd("sin", duration, frequency, nbits)
    
                    sndfile = attributes{1};
                    if numatt > 1,
    
                        if strcmpi(sndfile, 'sin'),
                            if numatt < 3 || numatt > 4,
                                cerror = sprintf('Expect 2 or 3 numeric attributes for sine wave (duration, frequency, nbits = 8 or 16)');
                                return
                            else
                                try
                                    dur = str2double(attributes{2});
                                    cps = str2double(attributes{3});
                                catch
                                    cerror = sprintf('After "sin" next attributes must be numeric (duration (sec) and frequency) in condition #%i', condnum);
                                    return
                                end
                            end
                            if numatt == 4,
                                try
                                    nbits = str2double(attributes{4});
                                catch
                                    cerror = sprintf('After frequency, next value expected to be nbits (8 or 16) in condition #%i', condnum);
                                    return
                                end
                                if nbits ~=8 && nbits ~= 16,
                                    cerror = sprintf('*** NBits for SND-sine must be 8 or 16 in condition #%i', condnum);
                                    return
                                end
                            else
                                nbits = 16;
                            end
                        else
                            cerror = sprintf('Expect only one filename attribute (unless "sin") for SND object in condition #%i', condnum);
                            return
                        end
    
                        fs = 44100;
                        sampsine = fs/cps;
                        totcycles = dur * cps;
                        y = sin(0:(2*pi)/sampsine:(totcycles*2*pi));
    
                        %check to see if identical sine wave already exists 
                        %(for naming purposes)
    
                        if isempty(sinebank),
                            sinebank(1, 1:2) = [dur cps];
                            snum = 1;
                        else
                            snum = find((sinebank(:, 1) == dur) & (sinebank(:, 2) == cps));
                            if isempty(snum),
                                snum = size(sinebank, 1) + 1;
                                sinebank(snum, 1:2) = [dur cps];
                            end
                        end
    
                        sndfile = ['sin' num2str(snum)];
    
                    else %numatt == 1 - expect sound file name if only one argument
    
                        dot = find(sndfile == '.');
                        ftype = 0;
                        if isempty(dot),
                            guesswav = [MLPrefs.Directories.ExperimentDirectory sndfile '.wav'];
                            guessmat = [MLPrefs.Directories.ExperimentDirectory sndfile '.mat'];
                            if exist(guesswav, 'file'),
                                sndfile = guesswav;
                                ftype = 1;
                            elseif exist(guessmat, 'file'),
                                sndfile = guessmat;
                                ftype = 2;
                            else
                                cerror = sprintf('Unable to find sound file %s in condition #%i', name, condnum);
                                return
                            end
                        else
                            if strcmp(sndfile(dot:dot+3), '.wav'),
                                ftype = 1;
                            elseif strcmp(sndfile(dot:dot+3), '.mat'),
                                ftype = 2;
                            end
                        end
                        if ftype == 1,
                            [y fs nbits] = wavread(sndfile);
                        elseif ftype == 2,
                            snddata = load(sndfile);
                            try
                                y = snddata.y;
                                fs = snddata.fs;
                            catch
                                cerror = 'MAT file containing sound data must contain the variables "y" & "fs" for waveform & frequency';
                                return
                            end
                            try
                                nbits = snddata.nbits;
                                if nbits ~=8 && nbits ~= 16,
                                    cerror = sprintf('NBits for SND must be 8 or 16 in condition #%i', condnum);
                                    return
                                end
                            catch
                                nbits = 16;
                            end
                        else
                            cerror = sprintf('Unable to read sound file %s in condition #%i', sndfile, condnum);
                            return
                        end
    
                    end
    
                    TaskObject(obnum).Name = sndfile;
                    TaskObject(obnum).WaveForm = y;
                    TaskObject(obnum).Freq = fs;
                    TaskObject(obnum).NBits = nbits;
    
                elseif strcmp(obtype, 'mov'), %movie
                    
                    if numatt < 3,
                        cerror = sprintf('Must have at least 3 attributes (name, x, y) for object "MOV" object in condition #%i', condnum);
                        return
                    end
                    name = attributes{1};
                    if isempty(name),
                        cerror = sprintf('Error: empty name string found in condition #%i', condnum);
                        return
                    end
                    % see if AVI file exists
                    guessavi = [MLPrefs.Directories.ExperimentDirectory name '.avi'];
                    if exist(guessavi, 'file'),
                        name = guessavi;
                    else
                        cerror = sprintf('Unable to find movie (AVI) file %s in condition #%i', name, condnum);
                        return
                    end
                    TaskObject(obnum).Name = name;
    
                    try
                        xpos = str2double(attributes{2});
                    catch
                        cerror = sprintf('Second attribute for MOV objects must be the x-position (condition #%i)', condnum);
                        return
                    end
                    TaskObject(obnum).Xpos = xpos;
                    try
                        ypos = str2double(attributes{3});
                    catch
                        cerror = sprintf('Third attribute for MOV objects must be the y-position (condition #%i)', condnum);
                        return
                    end
                    TaskObject(obnum).Ypos = ypos;
    
                elseif strcmp(obtype, 'crc'), %circle - syntax: crc(diameter, rgb, fillflag, xpos, ypos)
                    
                    if numatt ~= 5,
                        cerror = sprintf('Incorrect number of attributes for crc object in condition #%i', condnum);
                        return
                    end
                    try
                        radius = str2double(attributes{1});
                        rgb = eval(attributes{2});
                        fillflag = str2double(attributes{3});
                        xpos = str2double(attributes{4});
                        ypos = str2double(attributes{5});
                    catch
                        cerror = sprintf('Unable to parse attributes for crc object in condition #%i', condnum);
                        return
                    end
                    if length(rgb) ~= 3 || fillflag < 0 || fillflag > 1 || ischar(radius) || ischar(rgb) || ischar(fillflag) || ischar(xpos) || ischar(ypos),
                        cerror = sprintf('Unable to parse attributes for crc object in condition #%i ***', condnum);
                        return
                    end
                    TaskObject(obnum).Radius = radius;
                    TaskObject(obnum).Color = rgb;
                    TaskObject(obnum).FillFlag = fillflag;
                    TaskObject(obnum).Xpos = xpos;
                    TaskObject(obnum).Ypos = ypos;
                    TaskObject(obnum).Name = 'Circle';
    
                elseif strcmp(obtype, 'sqr'), %sqaure - syntax: sqr(size, rgb, fillflag, xpos, ypos)
                    
                    if numatt ~= 5,
                        cerror = sprintf('Incorrect number of attributes for sqr object in condition #%i', condnum);
                        return
                    end
                    try
                        sz = eval(attributes{1});
                        rgb = eval(attributes{2});
                        fillflag = str2double(attributes{3});
                        xpos = str2double(attributes{4});
                        ypos = str2double(attributes{5});
                    catch
                        cerror = sprintf('Unable to parse attributes for sqr object in condition #%i', condnum);
                        return
                    end
                    if length(sz) > 2 || length(rgb) ~= 3 || fillflag < 0 || fillflag > 1 || ischar(sz) || ischar(rgb) || ischar(fillflag) || ischar(xpos) || ischar(ypos),
                        cerror = sprintf('Unable to parse attributes for crc object in condition #%i', condnum);
                        return
                    end
                    if length(sz) == 1,
                        xsize = sz;
                        ysize = sz;
                    else
                        xsize = sz(1);
                        ysize = sz(2);
                    end
                    TaskObject(obnum).Xsize = xsize;
                    TaskObject(obnum).Ysize = ysize;
                    TaskObject(obnum).Color = rgb;
                    TaskObject(obnum).FillFlag = fillflag;
                    TaskObject(obnum).Xpos = xpos;
                    TaskObject(obnum).Ypos = ypos;
                    TaskObject(obnum).Name = 'Square';
    
                elseif strcmp(obtype, 'stm'), %stimulation - syntax: (outputport, datasource)
    
                    if numatt == 1 || numatt > 2,
                        cerror = sprintf('STM object must have 2 attributes: output-port and datasource (MAT file) in condition %i', condnum);
                    end
                    ch = str2double(attributes{1});
                    if ch > 2 || ch < 1 || ch ~= round(ch),
                        cerror = sprintf('STM output ports must be either 1 or 2 (condition #%i)', condnum);
                        return
                    end
                    matfile = attributes{2};
                    datasource = matfile;
                    [pname fname ext] = fileparts(matfile);
                    if isempty(pname),
                        pname = MLPrefs.Directories.ExperimentDirectory;
                    else
                        pname = [pname filesep];
                    end
                    if isempty(ext),
                        ext = '.mat';
                    end
                    matfile = [pname fname ext];
                    if ~exist(matfile, 'file'),
                        cerror = sprintf('Unable to find STM data file %s in condition #%i', matfile, condnum);
                        return
                    end
                    stimdata = load(matfile);
                    wf_found = 1;
                    fs_found = 1;
                    if isfield(stimdata, 'y'),
                        y = stimdata.y;
                    elseif isfield(stimdata, 'Y'),
                        y = stimdata.Y;
                    elseif isfield(stimdata, 'WaveForm'),
                        y = stimdata.WaveForm;
                    elseif isfield(stimdata, 'waveform'),
                        y = stimdata.waveform;
                    else
                        wf_found = 0;
                    end
                    if isfield(stimdata, 'fs'),
                        fs = stimdata.fs;
                    elseif isfield(stimdata, 'FS'),
                        fs = stimdata.FS;
                    elseif isfield(stimdata, 'Fs'),
                        fs = stimdata.Fs;
                    elseif isfield(Stimdata, 'Frequency'),
                        fs = stimdata.Frequency;
                    elseif isfield(Stimdata, 'Freq'),
                        fs = stimdata.Freq;
                    elseif isfield(Stimdata, 'freq'),
                        fs = stimdata.freq;
                    else
                        fs_found = 0;
                    end
                    if ~wf_found || ~fs_found,
                        cerror = 'MAT file containing STM data must contain the variables "y" & "fs" for waveform & frequency';
                        return
                    end
                    
                    TaskObject(obnum).WaveForm = y;
                    TaskObject(obnum).Freq = fs;
                    TaskObject(obnum).OutputPort = ch;
                    TaskObject(obnum).Name = sprintf('STM: %s >> Port %i', datasource, ch);
                    
                elseif strcmp(obtype, 'ttl'), %TTL pulse - syntax: ttl(outputport)
                    
                    if numatt > 1,
                        cerror = sprintf('Unrecognized extra attributes for TTL object in condition #%i', condnum);
                        return
                    end
                    
                    ch = str2double(attributes{1});
                    if ch > 4 || ch < 1 || ch ~= round(ch),
                        cerror = sprintf('TTL output port must be an integer from 1 to 4 (condition #%i) ***', condnum);
                        return
                    end
                    TaskObject(obnum).OutputPort = ch;
                    TaskObject(obnum).Name = sprintf('TTL%i', ch);
                    
                else
                    cerror = sprintf('Unrecognized task object type in condition #%i', condnum);
                end
            end
        end
        Conditions(condnum).TimingFile = TFiles{condnum};
        Conditions(condnum).RelativeFrequency = RelativeFrequency(condnum);
        Conditions(condnum).CondInBlock = BlockSpec{condnum};
        Conditions(condnum).Info = info{condnum};
        Conditions(condnum).RawInfo = rawinfo{condnum};
        Conditions(condnum).TaskObject = TaskObject(1:obnum);
    end
    txt = fgetl(fid);
end

%Convert RelativeFrequency values to integers:
rf = cat(1, Conditions.RelativeFrequency);
k = 1;
while any(k*rf ~= round(k*rf)),
    k = k + 1;
end
rf = k*rf;
rf(rf < 0) = 0;
for i = 1:condnum,
    Conditions(i).RelativeFrequency = rf(i);
end

%make certain number of timing files == expected (catch typos)
tfarray = strvcat(TFiles{:});
tfarray = unique(tfarray, 'rows');
s1 = size(tfarray, 1);

%make certain timing files exist
exst = zeros(s1, 1);
for i = 1:s1,
    exst(i) = exist([MLPrefs.Directories.ExperimentDirectory tfarray(i, :)], 'file');
end
if any(~exst),    
    disp('Warning: Did not find one or more timing files in the experiment directory...')
end