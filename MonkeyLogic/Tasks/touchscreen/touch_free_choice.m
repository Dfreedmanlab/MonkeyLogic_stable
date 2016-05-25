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
% April 14, 2016   Last Modified by Edward Ryklin(edward@ryklinsoftware.com)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

windowSize = 1.5;   % in degrees of visual angle (DVA) I believe this is the diameter (not radius)
fixDuration = 5000; % duration in milliseconds to test for a touch/fixation
   
touchTargetLeftNotFilled    = 1;
touchTargetLeftFilled       = 2;
touchTargetRightNotFilled   = 3;
touchTargetRightFilled      = 4;

numdev = xgldevices;
for devicenum = 1:numdev,
	xglshowcursor(devicenum, 0);
end

%showcursor('on'); % warning: displaying the cursor on the stimulus display will increase the max latency.

scene_timer = tic;

toggleobject(touchTargetLeftNotFilled, 'Status', 'on');
toggleobject(touchTargetRightNotFilled, 'Status', 'on');

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