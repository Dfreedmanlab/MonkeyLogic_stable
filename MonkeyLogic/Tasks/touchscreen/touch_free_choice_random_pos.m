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
% Jan 28, 2016   Last Modified by Edward Ryklin(edward@ryklinsoftware.com)
%
% NOTE : Please make sure that the Enable Mouse/System Keys option located 
% in the Advanced system menu is set to ON

windowSize = 1.5;   % in degrees of visual angle (DVA) I believe this is the diameter (not radius)
fixDuration = 2000; % duration in milliseconds to test for a touch/fixation
   
touchTargetLeftNotFilled    = 1;
touchTargetLeftFilled       = 2;
touchTargetRightNotFilled   = 3;
touchTargetRightFilled      = 4;

numdev = xgldevices;
for devicenum = 1:numdev,
	xglshowcursor(devicenum, 0);
end

showcursor('on');
scene_timer = tic;
locations = [1 2];
coordsX = [-5 5];
coordsY = [ 0 0];
random_locations = locations(randperm(length(locations)));

reposition_object(touchTargetLeftNotFilled,	coordsX(random_locations(1)), coordsY(random_locations(1)));  %x and %y are in DVA (degrees of visual angle, not pixels)
reposition_object(touchTargetRightNotFilled,coordsX(random_locations(2)), coordsY(random_locations(2)));  %x and %y are in DVA (degrees of visual angle, not pixels)
reposition_object(touchTargetLeftFilled,	coordsX(random_locations(1)), coordsY(random_locations(1)));  %x and %y are in DVA (degrees of visual angle, not pixels)
reposition_object(touchTargetRightFilled,	coordsX(random_locations(2)), coordsY(random_locations(2)));  %x and %y are in DVA (degrees of visual angle, not pixels)

    
toggleobject(touchTargetLeftNotFilled, 'Status', 'on');
toggleobject(touchTargetRightNotFilled, 'Status', 'on');
toggleobject(touchTargetLeftFilled, 'Status', 'off');
toggleobject(touchTargetRightFilled, 'Status', 'off');

while toc(scene_timer) < 10

    ontargets = eyejoytrack('touchtarget', [touchTargetLeftNotFilled touchTargetRightNotFilled],  windowSize, fixDuration);     % it does not matter if you track the filled or not filled target since they overlap eachother in space

    if (ontargets == 1)
        toggleobject(touchTargetLeftNotFilled, 'Status', 'off');
        toggleobject(touchTargetLeftFilled, 'Status', 'on');
        trialerror(0);
        disp('<<< MonkeyLogic >>> Target 1 Selected');
        break;
    end

    if (ontargets == 2)
        toggleobject(touchTargetRightNotFilled, 'Status', 'off');
        toggleobject(touchTargetRightFilled, 'Status', 'on');
        trialerror(1);
        disp('<<< MonkeyLogic >>> Target 2 Selected');
        break;
    end
    
    idle(20);  % if this idle command is missing there will be a buffer overrun error when the trial completes
    
end

numdev = xgldevices;
for devicenum = 1:numdev,
	xglshowcursor(devicenum, 1);
end

set_iti(750); % in milliseconds