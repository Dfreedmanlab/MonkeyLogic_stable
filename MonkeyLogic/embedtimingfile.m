function runtimescript = embedtimingfile(timingfile, trialholder)
%SYNTAX
%         runtimescript = embedtimingfile(timingfile, trialholder)
%
% Created by WA, July, 2006
% Modified 7/25/08 -WA
% Modified 9/08/08 -SM (to handle block comments)
logger = log4m.getLogger('monkeylogic.log');

[pname funcname] = fileparts(timingfile);
funcname = [funcname '_runtime'];

numsubfunctions = 0;
str1 = sprintf('TrialData = end_trial;\r\n');
str2 = sprintf('TrialData.ReactionTime = rt;\r\n');
str3 = sprintf('TrialData.TrialRecord = TrialRecord;\r\n');
end_of_trial_code = strvcat(str1, str2, str3);

fid1 = fopen(timingfile, 'r');
if fid1 < 0,
    error('*** Unable to open timing file %s ***', timingfile);
end

%VV will contain the editable variables stored in the loadbutton object
loadbutton = findobj('tag', 'loadbutton');
if ~isempty(loadbutton),
    VV = get(loadbutton, 'userdata');
else
    VV = struct;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% REWARD
if ~isfield(VV,'reward_dur'),
    VV.reward_dur = 120;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
vvfn = fieldnames(VV);

eof = 0;
trialtext = [];
numlines = 0;
blockcomment = false;
while ~eof,
    t = fgetl(fid1);
    if t == -1,
        if numsubfunctions == 0,
            numlines = numlines + 1;
            trialtext = strvcat(trialtext, end_of_trial_code);
        end
        eof = 1;
    elseif ~isempty(deblank(t)),
        t = deblank(t);
        while double(t(1)) == 32 || double(t(1)) == 9, %remove inital blanks & tabs
            t = t(2:length(t));
        end
        if ~blockcomment && length(t)==2 && all(t=='%{'),
            blockcomment = true;
        end
        if ~blockcomment,
            if (length(t) > 10 && strcmp(t(1:11), 'abort_trial')) || ((length(t) == 6 || length(t) == 7) && strcmp(t(1:6), 'return')),
                numlines = numlines + 2;
                trialtext = strvcat(trialtext, end_of_trial_code);
                trialtext = strvcat(trialtext, sprintf('return;\r\n'));
            elseif length(t) > 8 && strcmp(t(1:9), 'function '),
                numsubfunctions = numsubfunctions + 1;
                if numsubfunctions == 1, %only add end-trial command if at the end of the main function
                    numlines = numlines + 1;
                    trialtext = strvcat(trialtext, end_of_trial_code);
                end
                numlines = numlines + 1;
                trialtext = strvcat(trialtext, t);
            elseif length(t) > 8 && strcmp(t(1:9), 'editable('),
                varnames = eval(t);
                for i = 1:length(varnames),
                    VV.(varnames{i}) = [];
                end      
                vvfn = fieldnames(VV);
            else
                skipline = 0;
                if ~isempty(vvfn) && any(strfind(t, '=')), %check to see if this is a value declaration for an online editable variable
                    indx = min(strfind(t, '='));
                    vname = deblank(t(1:indx-1));
                    if strmatch(vname, vvfn, 'exact'),
                        skipline = 1;
                        try
                            eval(t);
                        catch
                            keyboard
                            error('Editable variable %s cannot be evaluated because it relies on other, non-editable variables', vname);
                        end
                        VV.(vname) = eval(vname);
                    end
                end
                if ~skipline,
                    numlines = numlines + 1;
                    trialtext = strvcat(trialtext, t);
                end
            end
        end
        if blockcomment && length(t)==2 && all(t=='%}'),
            blockcomment = false;
        end
    end
end
fclose(fid1);
set(loadbutton, 'userdata', VV);
for i = length(vvfn):-1:1,
    txtline = sprintf('%s = VV.%s;', vvfn{i}, vvfn{i});
    trialtext = strvcat(txtline, trialtext);
end
trialtext = strvcat('VV = get(findobj(''tag'', ''loadbutton''), ''userdata'');', trialtext);

insertpoint = [];
fid2 = fopen(trialholder, 'r');
eof = 0;
holdertext = [];
linenumber = 0;
while eof == 0,
    t = fgetl(fid2);
    if t == -1,
        eof = 1;
    else
        linenumber = linenumber + 1;
        if linenumber == 1,
            t = strrep(t, 'trialholder', funcname);
        end
        holdertext = strvcat(holdertext, t);
        if strcmp(t, '%INSERT TRIAL POINT********************************************************'),
            insertpoint = linenumber;
            holdertext = strvcat(holdertext, trialtext);
        end
    end
end
fclose(fid2);

if isempty(insertpoint),
    error('*** "TrialHolder.m" does not contain the expected timing script insertion point ***')
end

dot = find(timingfile == '.', 1, 'last');
if isempty(dot),
    dot = length(timingfile) + 1;
end
runtimescript = [timingfile(1:dot-1) '_runtime.m'];
f = find(runtimescript == filesep);
if ~isempty(f),
    runtimescript = runtimescript(max(f)+1:length(runtimescript));
end

runtimedir = which('monkeylogic');
f = find(runtimedir == filesep);
if ~isempty(f),
    runtimedir = [runtimedir(1:max(f)) 'runtime'];
else
    runtimedir = [runtimedir filesep 'runtime'];
end

if ~exist(runtimedir, 'dir'),
    disp('*** No "runtime" directory exists within the MonkeyLogic directory - will attempt to create one ***');
    success = mkdir(runtimedir);
    if ~success
        error('*** Unable to create "runtime" directory within the MonkeyLogic directory - you must create it manually ***');
    else
        logger.info('embedtimingfile.m', sprintf('<<< MonkeyLogic >>> Created %s', runtimedir));
        addpath(runtimedir);
    end
end

runtimescript = [runtimedir filesep runtimescript];
if exist(runtimescript, 'file'),
	delete(runtimescript);
end

fid3 = fopen(runtimescript, 'w');
blockcomment = false;
for i = 1:size(holdertext, 1),
    txt = deblank(holdertext(i, :));
    if ~blockcomment && length(txt)==2 && all(txt=='%{'),
        blockcomment = true;
    end
    if ~blockcomment && ~isempty(txt) && txt(1) ~= '%', %leave out comments
        count = fprintf(fid3, '%s\r', txt);
        if count < length(txt),
            fclose(fid3);
            error('**** Error creating runtime function ***')
        end
    end
    if blockcomment && length(txt)==2 && all(txt=='%}'),
        blockcomment = false;
    end
end
fclose(fid3);

%**************************************************************************
function varnames = editable(varargin) %#ok<DEFNU>

count = 1;
for i = 1:length(varargin),
    v = varargin{i};
    if ~iscell(v),
        varnames(count) = {v}; %#ok<AGROW>
        count = count + 1;
    else
        for ii = 1:length(v),
            varnames(count) = v(ii); %#ok<AGROW>
            count = count + 1;
        end
    end
end

