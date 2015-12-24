% This is an example MonkeyLogic task that demonstrates very basic use of a
% a mouse to select stimulus.
%
% Moving the mouse controlled cursor over one of two square
% shaped stimuli will cause them to be selected (switch from not filled to
% filled colors), if the appropriate mouse button is also clicked. 
% Unlike the mouse2 sample, this one demonstrates the additional condition
% of a mouse click over the stimulus to actuate the remaining functions.
% 
% The position of the cursor is displayed using showcursor('on')
%
% Dec 24, 2015   Last Modified by Edward Ryklin(edward@ryklinsoftware.com)

windowSize = 1.5;   % in degrees of visual angle (DVA) I believe this is the diameter (not radius)
fixDuration = 5000; % duration in milliseconds to test for a touch/fixation
   
mouseTargetLeftNotFilled    = 1;
mouseTargetLeftFilled       = 2;
mouseTargetRightNotFilled   = 3;
mouseTargetRightFilled      = 4;

ontargetLeftTarget = 0;
ontargetRightTarget = 0;

numdev = xgldevices;
for devicenum = 1:numdev,
	xglshowcursor(devicenum, 0);
end

showcursor('on');
scene_timer = tic;
target_selected = [0, 0];

toggleobject(mouseTargetLeftNotFilled, 'Status', 'on');
toggleobject(mouseTargetRightNotFilled, 'Status', 'on');

while toc(scene_timer) < 10

    ontargets = eyejoytrack('acquiremouse', [mouseTargetLeftNotFilled mouseTargetRightNotFilled],  windowSize, fixDuration);     % it does not matter if you track the filled or not filled target since they overlap eachother in space
    mouse_state = mlvideo('getmousebuttons');   % get Button State
   	left_button = mouse_state(1);               % get Button State Left
    right_button = mouse_state(2);              % get Button State Right

        
    if (ontargets == 1) && (left_button == 1)
        toggleobject(mouseTargetLeftNotFilled, 'Status', 'off');
        toggleobject(mouseTargetLeftFilled, 'Status', 'on');
        target_selected(1) = 1;
    end

    if (ontargets == 2) && (right_button == 1)
        toggleobject(mouseTargetRightNotFilled, 'Status', 'off');
        toggleobject(mouseTargetRightFilled, 'Status', 'on');
        target_selected(2) = 1;
    end

    idle(20);  % if this idle command is missing there will be a buffer overrun error when the trial completes

    if ( (target_selected(1) == 1) && (target_selected(2) == 1) )
        trialerror(0);
        break;
    end
end

numdev = xgldevices;
for devicenum = 1:numdev,
	xglshowcursor(devicenum, 1);
end

set_iti(3000);