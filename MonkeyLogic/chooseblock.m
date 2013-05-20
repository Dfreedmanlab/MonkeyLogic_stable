function chooseblock
%can be called from MonkeyLogic when paused by pressing [B]
%
%Created by WA, 07/23/08
%Last modified 08/11/08 -WA (to default to current block)

set(findobj('tag', 'allblocks'), 'userdata', []);
f = findobj('tag', 'runblocks');
bstring = get(f, 'string');
b = str2double(bstring);
k = 1;
f = findobj('tag', 'blockno');
if ~isempty(f),
    currentblock = str2double(get(f, 'string'));
    f = (currentblock == b);
    if any(f),
        k = find(f);
    end
end

figure
bgc = [.8 .85 .87];
set(gcf, 'tag', 'chooseblock', 'position', [400 400 120 250], 'numbertitle', 'off', 'name', '', 'menubar', 'none', 'color', bgc);
uicontrol('style', 'text', 'position', [5 225 110 18], 'string', 'Choose Block', 'backgroundcolor', bgc, 'fontweight', 'bold', 'fontsize', 11);
uicontrol('style', 'listbox', 'tag', 'blocklistbox', 'position', [30 75 60 145], 'string', bstring, 'userdata', b ,'backgroundcolor', [1 1 1], 'value', k);
uicontrol('style', 'pushbutton', 'position', [10 40 100 25], 'string', 'Select', 'callback', @chooseblockcallback);
uicontrol('style', 'pushbutton', 'position', [10 10 100 25], 'string', 'Cancel', 'callback', 'delete(gcf)');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function chooseblockcallback(varargin)

f = findobj(gcf, 'tag', 'blocklistbox');
blist = get(f, 'userdata');
bval = get(f, 'value');
b = blist(bval);
set(findobj('tag', 'allblocks'), 'userdata', b);
delete(findobj('tag', 'chooseblock'));
