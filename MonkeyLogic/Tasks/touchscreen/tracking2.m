% This is an example MonkeyLogic task that demonstrates very basic use of a
% touchscreen or mouse to select stimulus
%
% Moving the mouse/touchscreen controlled cursor over one of two square
% shaped stimuli will cause them to be selected (switch from not filled to
% filled colors). Unlike the other tracking sample, this one will terminate
% the trial after a selection is made all the alloted time period is
% expired.
% 
% The position of the cursor is displayed using showcursor('on')
% This task is much more efficient than the other sample. However, it can
% not display any advanced touch location stimuli.
%
% Currently, this code assumes that the cursor data is piped into the eye
% tracker channel, which allows us to use the eye_position() function to get
% x,y data, and eyejoytrack() to determine if the cursor is ontarget. Future
% versions will have separate functions such as touchscreen_position() and
% touchtrack(), or something similar.

% Oct 29, 2015   Last Modified by Edward Ryklin(edward@ryklinsoftware.com)

windowSize = 1.5;   % in degrees of visual angle (DVA) I believe this is the diameter (not radius)
fixDuration = 5000; % duration in milliseconds to test for a touch/fixation
   
touchTargetLeftNotFilled    = 1;
touchTargetLeftFilled       = 2;
touchTargetRightNotFilled   = 3;
touchTargetRightFilled      = 4;

ontargetLeftTarget = 0;
ontargetRightTarget = 0;

numdev = xgldevices;
for devicenum = 1:numdev,
	xglshowcursor(devicenum, 0);
end

showcursor('on');
scene_timer = tic;
target_touched = [0, 0];

toggleobject(touchTargetLeftNotFilled, 'Status', 'on');
toggleobject(touchTargetRightNotFilled, 'Status', 'on');

while toc(scene_timer) < 10

    ontargets = eyejoytrack('acquirefix', [touchTargetLeftNotFilled touchTargetRightNotFilled],  windowSize, fixDuration);     % it does not matter if you track the filled or not filled target since they overlap eachother in space

    if (ontargets == 1)
        toggleobject(touchTargetLeftNotFilled, 'Status', 'off');
        toggleobject(touchTargetLeftFilled, 'Status', 'on');
        target_touched(1) = 1;
    end

    if (ontargets == 2)
        toggleobject(touchTargetRightNotFilled, 'Status', 'off');
        toggleobject(touchTargetRightFilled, 'Status', 'on');
        target_touched(2) = 1;
    end

    idle(20);  % if this idle command is missing there will be a buffer overrun error when the trial completes

    if ( (target_touched(1) == 1) && (target_touched(2) == 1) )
        trialerror(0);
        break;
    end
end

numdev = xgldevices;
for devicenum = 1:numdev,
	xglshowcursor(devicenum, 1);
end

set_iti(3000);