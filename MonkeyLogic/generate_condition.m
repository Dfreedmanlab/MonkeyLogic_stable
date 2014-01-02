function textline = generate_condition(varargin)
%SYNTAX:
%        textline = generate_condition(parameter, value)
%
% This function generates a line of the conditions file text-file according
% to parameter/value pairs provided to it.  The possible parameters are:
%
%   PARAMETER:          EXPECTED VALUE:
%
%   'Condition'         condition number (scalar integer)
%
%   'Block'             block or blocks in which this condition can occur
%                       (scalar or vector of integers)
%
%   'Frequency'         relative likelihood this condition might be
%                       selected at random (baseline frequency = 1)
%                       (positive scalar)
%
%   'TimingFile'        name of timing file to be run with this condition
%                       (string)
%
%   'Info'              User info for this condition
%                       (structure, to be converted to parameter-value pairs)
%
%   'TaskObject'        TaskObject information (structure) as:
%
%                           TaskObject(n).Type
%                           TaskObject(n).Arg{k}
%
%                       in which n is the TaskObject number and the field Arg 
%                       is a cell array containing each of the arguments for the 
%                       indicated TaskObject type.
%
%   'Header'            will cause this function to return a header; value
%                       to specify here is the number of TaskObject labels
%                       to generate. Note that only a header-line will be returned
%                       if this parameter is specified, regardless of any other 
%                       provided parameter / value pairs.  (scalar)
%
%   'FID'               If this is specified, the condition line text will
%                       be printed to the file specified by this File-ID.
%
%
% Created by WA 9/3/06
% Last modified 9/11/06 -WA
% Major re-write 7/26/12 -WA

numpairs = length(varargin)/2;
if numpairs ~= round(numpairs),
    error('Arguments to "generate_condition" must come in parameter / value pairs');
end

params = {'FID' 'Header' 'Condition' 'Block' 'Frequency' 'TimingFile' 'Info' 'TaskObject'};

fid = [];
cond_number = 1;
relative_frequency = 1;
timing_file = 'timingfile';
itxt = '';
cinb = 1;
TOstring = {'fix(0,0)'};

for pnum = 1:numpairs,
    pstring = varargin{(2*pnum)-1};
    pmatch = strcmpi(pstring, params);
    if ~any(pmatch),
        error('Unrecognized "generate_condition" parameter %s', pstring);
    end
    pindx = find(pmatch);
    pval = varargin{2*pnum};
    if pindx == 1, %FID
        fid = pval;
    elseif pindx == 2, %Header
		if numpairs > 2
			error('Only expect two parameters when the ''header'' parameter is specified: the ''header'' parameter, and the ''fid'' parameter.');
		end
        numTO = pval;
        textline = sprintf('Condition\tInfo\tFrequency\tBlock\tTiming File');
        for i = 1:numTO,
            textline = sprintf('%s\tTaskObject#%i', textline, i);
        end
        textline = strcat(textline, '\n');
		if isempty(fid),
			try
				pstring = varargin{2 * pnum + 1};
			catch ME
				fprintf('Error thrown by matlab: %s', ME.message);
				error('''FID'' parameter not specified with ''Header'' parameter.');
			end
			if find(strcmpi(pstring, params)) ~= 1					%check if next parameter is the fid. If not, throw error.
				error('Parameter following the ''Header'' parameter must be the ''FID'' parameter');
			else													%If it is, then read in fid
				fid = varargin{2 * pnum + 2};
			end
		end
		fprintf(fid, textline);										%So now we have the file id, we can print to it and return.
		return
    elseif pindx == 3, %Condition
        cond_number = pval;
    elseif pindx == 4, %Block
        cinb = pval;
        [h w] = size(cinb);
        if h > w,
            cinb = cinb';
        end
    elseif pindx == 5, %Frequency
        relative_frequency = pval;
        if relative_frequency < 0,
            error('Relative_frequency must be >= 0');
        end
    elseif pindx == 6, %TimingFile
        timing_file = pval;
    elseif pindx == 7, %Info
        cinfo = pval;
        if ~isstruct(cinfo),
            error('Info field must be provided as a structure.');
        end
        fn = fieldnames(cinfo);
        n = length(fn);
        itxt = '';
        for i = 1:n,
            str1 = fn{i};
            val = cinfo.(str1);
            if ischar(val),
                str2 = sprintf('''%s''', val);
            else
                str2 = sprintf('%1.2f ', val); %may be vector, so can't include brackets
                str2 = ['[' str2 ']'];
            end
            if i < n,
                postcomma = ',';
            else
                postcomma = '';
            end
            itxt = sprintf('%s''%s'', %s%s ', itxt, str1, str2, postcomma);
        end
        
    elseif pindx == 8, %TaskObject
        TaskObject = pval;
        if ~isstruct(TaskObject),
            error('TaskObject must be provided as a structure.');
        end
        fn = fieldnames(TaskObject);
        numfields = length(fn);
        ftype = find(strcmpi(fn, 'Type'), 1);
        farg = find(strcmpi('Arg', fn), 1);        
        if isempty(ftype) || isempty(farg) || numfields ~= 2,
            error('"generate_condition" requires two and only two fields for TaskObject: "Type" and "Arg"');
        end
        for i = 1:length(TaskObject),
            numargs = length(TaskObject(i).Arg);
            txt = {};
            for j = 1:numargs,
                if j == numargs,
                    txtsep = ')';
                else
                    txtsep = ',';
                end
                thisarg = TaskObject(i).Arg{j};
                if ischar(thisarg),
                    txt{j} = sprintf('%s%s', thisarg, txtsep);
                elseif length(thisarg) > 1,
                    txt{j} = ['[' sprintf('%3.3f ', thisarg) ']' txtsep];
                else
                    txt{j} = sprintf('%3.3f%s', thisarg, txtsep);
                end
            end
            TOstring{i} = sprintf('%s(%s', TaskObject(i).Type, strcat(txt{:}));
            TOstring{i} = strcat(TOstring{i}, '\t');
        end
    else
        error('Unrecognized parameter for "generate_condition"');
    end
end


rf = sprintf('%i ', relative_frequency);
cinb = sprintf('%i ', cinb);
txtstr = strcat('%i\t%s\t%s\t%s\t%s\t', strcat(TOstring{:}), '\r\n');
textline = sprintf(txtstr, cond_number, itxt, rf, cinb, timing_file);

if ~isempty(fid),
    fprintf(fid, txtstr, cond_number, itxt, rf, cinb, timing_file);
end

