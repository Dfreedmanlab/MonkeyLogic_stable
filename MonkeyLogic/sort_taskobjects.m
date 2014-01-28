function UniqueTaskObjects = sort_taskobjects(Conditions)
%
% Created by WA, July, 2006
% Modified 12/15/06 -WA
% Last modified 8/13/08 -WA (to include movies)

stimnum = 0;
for cond = 1:length(Conditions),
   TaskObject = Conditions(cond).TaskObject;
   %TaskObject = orderfields(TaskObject);
   for tonum = 1:length(TaskObject),
       stimnum = stimnum + 1;
       AllTaskObjects(stimnum) = TaskObject(tonum);
   end
end

TOtypes = cellstr(strvcat(AllTaskObjects.Type)); %works because "type" is always 3 chars
%recognized types are: fix, pic, snd, crc, sqr, mov, stm, ttl, gen

UFIX = [];
f = find(strcmpi(TOtypes, 'fix'));
if ~isempty(f),
    UFIX = AllTaskObjects(f(1));
end

UPIC = [];
f = find(strcmpi(TOtypes, 'pic'));
if ~isempty(f),
    PIC = AllTaskObjects(f);
    UPIC = uniquestructs(PIC, 'Name');
end

USND = [];
f = find(strcmpi(TOtypes, 'snd'));
if ~isempty(f),
    SND = AllTaskObjects(f);
    USND = uniquestructs(SND, 'WaveForm', 'Freq');
end

USTM = [];
f = find(strcmpi(TOtypes, 'stm'));
if ~isempty(f),
    STM = AllTaskObjects(f);
    USTM = uniquestructs(STM, 'Name', 'OutputPort');
end

UCRC = [];
f = find(strcmpi(TOtypes, 'crc'));
if ~isempty(f),
    CRC = AllTaskObjects(f);
    UCRC = uniquestructs(CRC, 'Radius', 'Color', 'FillFlag');
end

USQR = [];
f = find(strcmpi(TOtypes, 'sqr'));
if ~isempty(f),
    SQR = AllTaskObjects(f);
    USQR = uniquestructs(SQR, 'Xsize', 'Ysize', 'Color', 'FillFlag');
end

UMOV = [];
f = find(strcmpi(TOtypes, 'mov'));
if ~isempty(f),
    MOV = AllTaskObjects(f);
    UMOV = uniquestructs(MOV, 'Name');
end

UGEN = [];
f = find(strcmpi(TOtypes, 'gen'));
if ~isempty(f),
    GEN = AllTaskObjects(f);
    UGEN = uniquestructs(GEN, 'FunctionName');
end

UTTL = [];
f = find(strcmpi(TOtypes, 'ttl'));
if ~isempty(f),
    TTL = AllTaskObjects(f);
    UTTL = uniquestructs(TTL, 'OutputPort');
end

%UniqueTaskObjects = AllTaskObjects(uindx);
UniqueTaskObjects = cat(2, UFIX, UPIC, UMOV, USND, USTM, UCRC, USQR, UGEN, UTTL);

for i = 1:length(UniqueTaskObjects),
    obname = UniqueTaskObjects(i).Name;
    obname = stripfilename(obname);
    UOB = UniqueTaskObjects(i);
    switch UOB.Type,
        case 'fix',
            txt = sprintf('Fix: Default');
        case 'pic',
            xs = UOB.Xsize;
            ys = UOB.Ysize;
            if xs == -1,
                img = imread(UOB.Name);
                ys = size(img, 1);
                xs = size(img, 2);
            end
            txt = sprintf('Pic: %s  [%i x %i]', obname, xs, ys);
        case 'gen',
            funcname = UniqueTaskObjects(i).FunctionName;
            [p funcname e] = fileparts(funcname);
            txt = sprintf('Gen: %s', funcname);
        case 'mov',
%             mov = aviread(UOB.Name);
%             [ys xs zs] = size(mov(1).cdata); %#ok<NASGU> zs needed to get correct dimensions into xs and ys
%             numframes = length(mov);
%             txt = sprintf('Mov: %s [%i x %i] %i Frames', obname, xs, ys, numframes);
            
            if verLessThan('matlab', '8')
                reader = mmreader(UOB.Name); %#ok<DMMR>
            else
                reader = VideoReader(UOB.Name);  %#ok<TNMLP>
            end
            txt = sprintf('Mov: %s [%i x %i] %i Frames', obname, get(reader, 'width'), get(reader, 'height'), get(reader, 'numberOfFrames'));
        case 'snd',
            dur = length(UOB.WaveForm) / UOB.Freq;
            txt = sprintf('Snd: %s (%2.1f sec)', obname, dur);
        case 'crc',
            if UOB.FillFlag == 1,
                obname = 'Solid';
            else
                obname = 'Outline';
            end
            txt = sprintf('Crc: %s r=%3.2f rgb=[%1.2f %1.2f %1.2f]', obname, UOB.Radius, UOB.Color(1), UOB.Color(2), UOB.Color(3));
        case 'sqr',
            if UOB.FillFlag == 1,
                obname = 'Solid';
            else
                obname = 'Outline';
            end
            txt = sprintf('Sqr: %s [%2.2f x %2.2f] rgb = [%1.2f %1.2f %1.2f]', obname, UOB.Xsize, UOB.Ysize, UOB.Color(1), UOB.Color(2), UOB.Color(3));
        case 'stm',
            dur = length(UOB.WaveForm) / UOB.Freq;
            txt = sprintf('%s (%2.1f sec)', obname, dur);
        case 'ttl',
            txt = sprintf('TTL: >> Port %i', UOB.OutputPort);
    end %case
    UniqueTaskObjects(i).Description = txt;
end

function [Ustruct, Uindx] = uniquestructs(S, varargin)

logarray = zeros(length(S), length(varargin));

for i = 1:length(varargin),
    fname = varargin{i};
    sampleS = S(1).(fname);
    if isnumeric(sampleS),
        if isscalar(sampleS),
            fval = cat(1, S(:).(fname));
            [b indx j] = unique(fval, 'rows');
        elseif isvector(sampleS),
			v = zeros(1, length(S));
            for k = 1:length(S),
                v(k) = mean(S(k).(fname));
            end
            fval = v';
            [b indx j] = unique(fval, 'rows');
        else
            maxsize = zeros(length(size(sampleS)));
            for k = 1:length(S),
                maxsize = max( [maxsize ; size(S(k).(fname))] );
            end
            shapes = cell(1,length(S));
            for k = 1:length(S),
                v = S(k).(fname);
                shapes{k} = size(v);
                v = padarray(v,maxsize-size(v),NaN,'post');
                S(k).(fname) = v;
            end
            d = length(maxsize)+1;
            fval = cat(d, S(:).(fname));
            [b indx j] = unique_dim(fval, d);
            for k = 1:length(S),
                v = S(k).(fname);
                v = v(~isnan(v));
                v = reshape(v,shapes{k});
                S(k).(fname) = v;
            end
%         else
%             error('uniquestructs unable to handle non-scalar, non-vector, numeric fields.');
         end
    else
        fval = cat(1, {S(:).(fname)});
        [b indx j] = unique(fval);
    end
    logarray(:, i) = j';
end

[b Uindx j] = unique(logarray, 'rows');
Ustruct = S(Uindx);

indxarray = j(Uindx);
for i = 1:size(b, 1),
    xp = cat(1, S(j == i).Xpos);
    yp = cat(1, S(j == i).Ypos);
    Ustruct(indxarray == i).Xpos = xp;
    Ustruct(indxarray == i).Ypos = yp;
end

function fnameresult = stripfilename(fname)

f = find(fname == filesep);
if ~isempty(f),
    fname = fname(max(f)+1:length(fname));
end
dot = find(fname == '.');
if ~isempty(dot),
    fname = fname(1:dot-1);
end
fnameresult = fname;

function [B, I, J] = unique_dim(A, d)

s = size(A);
sd = size(A,d);
n = length(s);

Ad = shiftdim(A,n-d);
l = prod(s(1:length(s)~=d));
shape = size(Ad);
shape = shape(1:end-1);

U = cell(1,sd);
I = [];
J = [];
for i=1:sd,
    ia = 1 + (i-1)*l;
    ib = i*l;
    Ai = Ad(ia:ib);
    for j=1:length(U)
        if isempty(U{j}),
            U{j} = Ai;
            I(end+1)=i; %#ok<AGROW>
            J(end+1)=j; %#ok<AGROW>
            break;
        end
        eq = (U{j} == Ai);
        while ~isscalar(eq),
            eq = all(eq);
        end
        if eq,
            J(end+1)=j; %#ok<AGROW>
            break;
        end
    end
end
B = [];
for i=1:length(I),
    u = reshape(U{i},shape);
    B = cat(n,B,u);
end
B = shiftdim(B,d);