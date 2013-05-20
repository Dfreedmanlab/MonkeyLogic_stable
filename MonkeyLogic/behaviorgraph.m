function behaviorgraph(varargin)
%SYNTAX:
%        behaviorgraph([datafile])
%
% Plots performance over trials.  Datafile is optional.
%
% Created by WA, 9/06
% Last modified 9/18/07 --WA

if ~ispref('MonkeyLogic', 'Directories'),
    success = set_ml_directories;
    if ~success,
        return
    end
end
MLPrefs.Directories = getpref('MonkeyLogic', 'Directories');
if isempty(varargin),
    [fname pname] =  uigetfile([MLPrefs.Directories.ExperimentDirectory '*.bhv'], 'Choose BHV file');
    if fname(1) == 0,
        return
    end
    inputfile = [pname fname];
else
    inputfile = varargin{1};
    if strcmp(inputfile, 'CurrentFile'),
        mlmainmenu = findobj('tag', 'monkeylogicmainmenu');
        if isempty(mlmainmenu),
            return
        end
        inputfile = get(findobj(mlmainmenu, 'tag', 'datafile'), 'userdata');
        if ~exist(inputfile, 'file'),
            return
        end
    end
    if isempty(inputfile == filesep),
        inputfile = [MLPrefs.Directories.ExperimentDirectory inputfile];
    end
end
bhv = bhv_read(inputfile);
te = bhv.TrialError;
bnum = bhv.BlockNumber;
bswitch = find(diff(bnum));

smoothwin = 10;
if length(te) < 5*smoothwin,
    disp('Not enough data to plot.')
    return
end
colororder = [0 1 0; 0 1 1; 1 1 0; 0 0 1; 0.5 0.5 0.5; 1 0 1; 1 0 0; .3 .7 .5; .7 .2 .5; .5 .5 1; .75 .75 .5];
corder(1, 1:11, 1:3) = colororder;
lte = length(te);
yarray1 = zeros(lte, 12);
for i = 0:10,
    r = smooth(double(te == i), smoothwin, 'gauss');
    yarray1(1:lte, i+2) = yarray1(1:lte, i+1) + r;
end
xarray1 = (1:lte)';
xarray1 = repmat(xarray1, 1, 12);

xarray2 = flipud(xarray1);
yarray2 = flipud(yarray1);

x = cat(1, xarray1(:, 1:11), xarray2(:, 2:12));
y = cat(1, yarray1(:, 1:11), yarray2(:, 2:12));

warning off
figure
scrnsz = get(0, 'screensize');
set(gcf, 'color', [1 1 1], 'position', [50 450 scrnsz(3)-100 350], 'numbertitle', 'off', 'name', 'Behavior Summary', 'color', [.85 .85 1]);
patch(x, y, corder);
set(gca, 'xlim', [1 lte], 'ylim', [0 1], 'position' ,[0.05 0.13 .92 .8], 'box', 'on');
hline(1) = line([0 lte], [0.5 0.5]);
set(hline(1), 'color', [0.7 0.7 0.7], 'linewidth', 2);
hline(2) = line([0 lte], [0.25 0.25]);
hline(3) = line([0 lte], [0.75 0.75]);
set(hline([2 3]), 'color', [0.7 0.7 0.7], 'linewidth', 1);
h = zeros(length(bswitch), 1);
ht = h;
texty = 0.05;
for i = 1:length(bswitch),
    x1 = bswitch(i);
    h(i) = line([x1 x1], [0 1]);
    if i > 1,
        x2 = bswitch(i-1);
    else
        x2 = 0;
    end
    xm = (x1 + x2)/2;
    ht(i) = text(xm, texty, num2str(bhv.BlockOrder(i)));
end
if ~isempty(h),
    xm = (bswitch(i) + length(bhv.TrialNumber))/2;
    ht(i+1) = text(xm, texty, num2str(bhv.BlockOrder(i+1)));
    set(h, 'color', [1 1 1], 'linewidth', 2);
else
    xm = length(bhv.TrialNumber)/2;
    ht = text(xm, texty, num2str(bhv.BlockOrder));
end
set(ht, 'horizontalalignment', 'center', 'color', [1 1 1], 'fontweight', 'bold', 'fontsize', 14);

f = find(inputfile == filesep);
if ~isempty(f),
    inputfile = inputfile(max(f)+1:length(inputfile));
end
title(inputfile);
xlabel('Trial number');
ylabel('Fraction correct');
warning on
