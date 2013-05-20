function changevars(VV)
% This function allows on-line editing of appropriately declared timing 
% file variables (declared using the "editable" command).
% Created by VY, April, 2008
% Last modified 4/9/08 -WA

vnames = fieldnames(VV);
if isempty(vnames),
    return
end
numvars = length(vnames);
vvals = cell(numvars, 1);
for ii = 1:numvars,
    vvals{ii} = VV.(vnames{ii});
end

editfig = dialog('Name','Edit Timing File Variables','tag','edittfvars');
bgcol = [.7 .75 .7];
set(editfig, 'color', bgcol);
figpos = get(editfig, 'Position');
w = figpos(3);
h = 125 + (23*numvars);
figpos(4) = h;
figpos(2)=figpos(2)-130;  % move the window down 125 pixels so that it fits on the screen
                         % if there are many editable variables
set(editfig, 'position', figpos)
varpanel = uipanel(editfig,'BackgroundColor','white','Visible','on','Units','pixels','Position',[20,70,w-40,3+numvars*24]);
pansize = get(varpanel,'Position'); 
pansize = pansize([3 4]);
vertsize = 20;
spacing = 3;

for ii = 1:numvars,
    uicontrol(varpanel,'tag',sprintf('tbox%n',ii),'Style','text','String', vnames{ii},...
        'Position',[spacing, pansize(2)-ii*(vertsize+spacing),pansize(1)/2 - 2*spacing, vertsize], 'tag', 'tbox');
    uicontrol(varpanel,'tag',sprintf('ebox%n',ii),'Style','edit','String',vvals{ii},...
        'Position',[pansize(1)/2+spacing, pansize(2)-ii*(vertsize+spacing),pansize(1)/2 - 2*spacing, vertsize],...
        'Callback', @EditButtonCallback, 'ButtonDownFcn', @EditingIndicatorCallback,...
        'Enable', 'inactive' ,'BackgroundColor',[1 1 1],'ForegroundColor',[0 0 0], 'tag', 'ebox');
end
tw = 70;
uicontrol(editfig, 'style', 'text', 'position', [round((w/4)-(tw/2))+5 h-27 70 20], 'string', 'Variable', 'fontangle', 'italic', 'fontweight', 'bold', 'fontsize', 12, 'backgroundcolor', bgcol, 'horizontalalignment', 'center');
uicontrol(editfig, 'style', 'text', 'position', [round((3*w/4)-(tw/2))-10 h-27 70 20], 'string', 'Value', 'fontangle', 'italic', 'fontweight', 'bold', 'fontsize', 12, 'backgroundcolor', bgcol, 'horizontalalignment', 'center');
uicontrol(editfig,'tag', 'CancelButton',...
    'Position', [w/2-110,20,100,40],...
    'Style','pushbutton', 'String', 'Cancel', 'Callback', @EditCallback);
uicontrol(editfig,'tag', 'SaveButton',...
    'Position', [w/2+10,20,100,40], 'enable', 'off',...
    'Style','pushbutton', 'String', 'Save and Close', 'Callback', @EditCallback);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function EditCallback(varargin)
switch get(gcbo,'tag'),
    case 'CancelButton'
        close(findobj('tag', 'edittfvars'));
    case 'SaveButton'
        VV = get(findobj('tag', 'loadbutton'), 'userdata');
        tbox_handles = findobj(gcf, 'tag', 'tbox');
        ebox_handles = findobj(gcf, 'tag', 'ebox');
        for i = 1:length(tbox_handles),
            vname = get(tbox_handles(i), 'string');
            vval = str2num(get(ebox_handles(i),'String')); %#ok<ST2NM>
            if isempty(vval),
                set(ebox_handles(i), 'string', num2str(VV.(vname)), 'backgroundcolor', [.7 .5 .5]);
                return
            else
                VV.(vname) = vval;
            end
        end
        set(findobj('tag', 'loadbutton'), 'userdata', VV);
        close(findobj('tag', 'edittfvars'));
end
end

function EditingIndicatorCallback(varargin)
h = findobj(gcf, 'tag', 'ebox');
set(h,'BackgroundColor',[1 1 1]);
set(h,'ForegroundColor',[.2 .2 .2]);
set(h,'Enable','inactive');
set(gcbo,'BackgroundColor',[.2 .2 .2]);  %this is here so you know that you hit "enter"
set(gcbo,'ForegroundColor',[1 1 1]);
set(gcbo,'Enable','on');
end

function EditButtonCallback(varargin)
set(gcbo,'BackgroundColor',[1 1 1]);
set(gcbo,'ForegroundColor',[.2 .2 .2]);
set(gcbo,'Enable','inactive');
set(findobj(gcf, 'tag', 'SaveButton'), 'enable', 'on');
end

