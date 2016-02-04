% This is an example MonkeyLogic task that demonstrates very basic use of a
% touchscreen to select stimulus.
%
% Moving the mouse/touchscreen controlled cursor over one of two square
% shaped stimuli will cause them to be selected (switch from not filled to
% filled colors). Unlike the other tracking sample, this one will terminate
% the trial only after both stimuli are selected.
% 
% The position of the cursor is displayed using showcursor('on')
% This task is much more efficient than the other sample. However, it can
% not display any advanced touch location stimuli.
%
% February 04, 2016   Last Modified by Edward Ryklin(edward@ryklinsoftware.com)
%
% This will automatically enable the cursor, replicating the same behavior
% achieved if enabling the Mouse/System Keys option in the advanced menu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dirs = getpref('MonkeyLogic', 'Directories');
message = sprintf('%smlhelper --cursor-enable',dirs.BaseDirectory);
system(message);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

windowSize = 1.5;   % in degrees of visual angle (DVA) I believe this is the diameter (not radius)
fixDuration = 2000; % duration in milliseconds to test for a touch/fixation
   
touchTarget1Empty = 1;
touchTarget2Empty = 2;
touchTarget3Empty = 3;
touchTarget4Empty = 4;
touchTarget1Full = 5;
touchTarget2Full = 6;
touchTarget3Full = 7;
touchTarget4Full = 8;

numdev = xgldevices;
for devicenum = 1:numdev,
	xglshowcursor(devicenum, 0);
end

showcursor('on');
scene_timer = tic;
coordsX = [5 -5  5 -5];
coordsY = [5  5 -5 -5];

locations = [1 2 3 4];
random_locations = locations(randperm(length(locations)));

reposition_object(touchTarget1Empty,coordsX(random_locations(1)), coordsY(random_locations(1)));  %x and %y are in DVA (degrees of visual angle, not pixels)
reposition_object(touchTarget2Empty,coordsX(random_locations(2)), coordsY(random_locations(2)));  %x and %y are in DVA (degrees of visual angle, not pixels)
reposition_object(touchTarget3Empty,coordsX(random_locations(3)), coordsY(random_locations(3)));  %x and %y are in DVA (degrees of visual angle, not pixels)
reposition_object(touchTarget4Empty,coordsX(random_locations(4)), coordsY(random_locations(4)));  %x and %y are in DVA (degrees of visual angle, not pixels)
reposition_object(touchTarget1Full, coordsX(random_locations(1)), coordsY(random_locations(1)));  %x and %y are in DVA (degrees of visual angle, not pixels)
reposition_object(touchTarget2Full, coordsX(random_locations(2)), coordsY(random_locations(2)));  %x and %y are in DVA (degrees of visual angle, not pixels)
reposition_object(touchTarget3Full, coordsX(random_locations(3)), coordsY(random_locations(3)));  %x and %y are in DVA (degrees of visual angle, not pixels)
reposition_object(touchTarget4Full, coordsX(random_locations(4)), coordsY(random_locations(4)));  %x and %y are in DVA (degrees of visual angle, not pixels)

toggleobject(touchTarget1Empty, 'Status', 'on');
toggleobject(touchTarget2Empty, 'Status', 'on');
toggleobject(touchTarget3Empty, 'Status', 'on');
toggleobject(touchTarget4Empty, 'Status', 'on');
toggleobject(touchTarget1Full, 'Status', 'off');
toggleobject(touchTarget2Full, 'Status', 'off');
toggleobject(touchTarget3Full, 'Status', 'off');
toggleobject(touchTarget4Full, 'Status', 'off');

while toc(scene_timer) < 10

    ontargets = eyejoytrack('touchtarget', [touchTarget1Empty touchTarget2Empty touchTarget3Empty touchTarget4Empty],  windowSize, fixDuration);     % it does not matter if you track the filled or not filled target since they overlap eachother in space

    if (ontargets == 1)
        toggleobject(touchTarget1Empty, 'Status', 'off');
        toggleobject(touchTarget1Full, 'Status', 'on');
        trialerror(0);
        disp('<<< MonkeyLogic >>> Target 1 Selected');
        break;
    end

    if (ontargets == 2)
        toggleobject(touchTarget2Empty, 'Status', 'off');
        toggleobject(touchTarget2Full, 'Status', 'on');
        trialerror(1);
        disp('<<< MonkeyLogic >>> Target 2 Selected');
        break;
    end
    
    if (ontargets == 3)
        toggleobject(touchTarget3Empty, 'Status', 'off');
        toggleobject(touchTarget3Full, 'Status', 'on');
        trialerror(2);
        disp('<<< MonkeyLogic >>> Target 3 Selected');
        break;
    end
    
    if (ontargets == 4)
        toggleobject(touchTarget4Empty, 'Status', 'off');
        toggleobject(touchTarget4Full, 'Status', 'on');
        trialerror(3);
        disp('<<< MonkeyLogic >>> Target 4 Selected');
        break;
    end
    
    idle(20);  % if this idle command is missing there will be a buffer overrun error when the trial completes
    
end

numdev = xgldevices;
for devicenum = 1:numdev,
	xglshowcursor(devicenum, 1);
end

set_iti(750); % in milliseconds