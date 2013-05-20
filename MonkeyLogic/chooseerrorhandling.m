function chooseerrorhandling
%can be called from MonkeyLogic when paused by pressing [X]
%
%Created by WA, 8/05/08

k = get(findobj('tag', 'errorlogic'), 'value');
figure
bgc = [.8 .85 .87];
set(gcf, 'tag', 'chooseerrorhandling', 'position', [400 400 200 170], 'numbertitle', 'off', 'name', '', 'menubar', 'none', 'color', bgc);
uicontrol('style', 'text', 'position', [50 145 100 18], 'string', 'On Errors:', 'backgroundcolor', bgc, 'fontweight', 'bold', 'fontsize', 11, 'horizontalalignment', 'center');
uicontrol('style', 'listbox', 'tag', 'errorlistbox', 'position', [25 80 150 60], 'string', {'Ignore' 'Re-try immediately' 'Re-try delayed'}, 'backgroundcolor', [1 1 1], 'value', k);
uicontrol('style', 'pushbutton', 'position', [50 40 100 25], 'string', 'Select', 'callback', @chooseerrorcallback);
uicontrol('style', 'pushbutton', 'position', [50 10 100 25], 'string', 'Cancel', 'callback', 'delete(gcf)');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function chooseerrorcallback(varargin)

k = get(findobj(gcf, 'tag', 'errorlistbox'), 'value');
set(findobj('tag', 'errorlogic'), 'value', k);
delete(findobj('tag', 'chooseerrorhandling'));
