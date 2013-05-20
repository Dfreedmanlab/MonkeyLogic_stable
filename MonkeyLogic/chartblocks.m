function chartblocks(varargin)
% called from monkeylogic main menu
% Created by WA, 1/5/07

switchval = varargin{1};
if isnumeric(switchval),
    switch switchval,
        case 1,
            cp = get(gca, 'currentpoint');
            cp = cp(1, 1:2);
            condnum = floor(cp(1));
            blocknum = floor(cp(2));
            C = get(gcf, 'userdata');
            c = C(condnum);
            TOnames = {c.TaskObject.RawText};
            for tonum = 1:length(TOnames),
                TOnames{tonum} = sprintf('%i:  %s', tonum, TOnames{tonum});
            end
            set(findobj(gcf, 'tag', 'taskobjectlistbox'), 'string', TOnames);            
            cib = c.CondInBlock;
            if ismember(blocknum, cib),
                blkstr = sprintf(' Occurs in Block #%i', blocknum);
            else
                blkstr = sprintf(' Does NOT occur in Block #%i', blocknum);
            end
            prelimtxt = ['\r\n Condition #%i\r\n' blkstr '\r\n Timing File: %s\r\n Relative Frequency: %i'];
            txt = sprintf(prelimtxt, condnum, c.TimingFile, c.RelativeFrequency);
            set(findobj(gcf, 'tag', 'conditiondetails'), 'string', txt, 'horizontalalignment', 'left', 'fontsize', 10);
    end
    return
end

fname = varargin{1};
C = load_conditions(fname);
[pathname condfilename ext] = fileparts(fname);

numconditions = length(C);
BlockSpec = cell(numconditions, 1);
TFiles = cell(numconditions, 1);
for cnum = 1:numconditions,
    BlockSpec{cnum} = C(cnum).CondInBlock;
    TFiles{cnum} = C(cnum).TimingFile;
end
[blocktypes blocklist] = sortblocks(BlockSpec);
numblocks = max(blocklist);

utfiles = unique(TFiles);
tfindex = zeros(numconditions, 1);
for cnum = 1:numconditions,
    tfindex(cnum) = strmatch(TFiles{cnum}, utfiles, 'exact');
end

numtfiles = length(utfiles);
if numtfiles == 1,
    cvals = 1;
else
    cvals = linspace(0.5, 1.5, numtfiles);
end

bc = zeros(numblocks + 1, numconditions + 1) * NaN;
for bnum = 1:numblocks,
    usedconds = blocktypes{bnum};
    bc(bnum, usedconds) = cvals(tfindex(usedconds));
end

fig = findobj('tag', 'chartblocksfigure');
if ~isempty(fig),
    figure(fig);
    clf;
else
    figure
end
figx = 800;
figy = 600;
set(gcf, 'position', [200 200 figx figy], 'color', [1 1 1], 'userdata', C, 'tag', 'chartblocksfigure', 'numbertitle', 'off', 'name', sprintf('Block Chart for %s', [condfilename ext]), 'menubar', 'none');
h = pcolor(bc);
set(h, 'buttondownfcn', 'chartblocks(1)');
caxis([0 2]);
yspace = ceil(numblocks/10);
xspace = ceil(numconditions/10);
yticks = 1:yspace:numblocks;
xticks = 1:xspace:numconditions;
if numconditions*numblocks > 1000,
    shading('flat');
else
    shading('faceted');
end
set(gca, 'position', [.07 .1 .58 .75], 'xtick', 1.5:xspace:numconditions+0.5, 'ytick', 1.5:yspace:numblocks+0.5, 'xticklabel', xticks, 'yticklabel', yticks, 'ydir', 'reverse', 'xaxislocation', 'top');
h(1)= xlabel('Condition #');
h(2) = ylabel('Block #');
set(h, 'fontsize', 12, 'fontweight', 'bold');

ybase = 58;
xbase = 540;
uicontrol('style', 'frame', 'position', [xbase ybase 240 455], 'backgroundcolor', [0.85 0.85 0.8]);
uicontrol('style', 'text', 'position', [xbase+5 ybase+5 230 445], 'tag', 'conditiondetails', 'string', sprintf('\r\n\r\nClick on a condition to the left for details'), 'fontsize', 14);
uicontrol('style', 'listbox', 'position', [xbase+10 ybase+10 220 300], 'string', 'TaskObject List...', 'tag', 'taskobjectlistbox', 'backgroundcolor', [.95 .94 .95]);
