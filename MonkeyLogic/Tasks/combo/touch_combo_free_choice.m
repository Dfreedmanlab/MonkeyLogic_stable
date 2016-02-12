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
fixDuration = 5000; % duration in milliseconds to test for a touch/fixation
   
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

toggleobject(touchTargetLeftNotFilled, 'Status', 'on');
toggleobject(touchTargetRightNotFilled, 'Status', 'on');

while toc(scene_timer) < 10

    ontarget = eyejoytrack('touchtarget', [touchTargetLeftNotFilled touchTargetRightNotFilled], windowSize, 'acquirefix', [touchTargetLeftNotFilled touchTargetRightNotFilled], windowSize, fixDuration);

    if (ontarget(1) == 1)
        toggleobject(touchTargetLeftNotFilled, 'Status', 'off');
        toggleobject(touchTargetLeftFilled, 'Status', 'on');
        trialerror(0);
        disp('<<< MonkeyLogic >>> Target 1 Selected with Controller 1');
        break;
    end

    if (ontarget(2) == 1)
        toggleobject(touchTargetLeftNotFilled, 'Status', 'off');
        toggleobject(touchTargetLeftFilled, 'Status', 'on');
        trialerror(0);
        disp('<<< MonkeyLogic >>> Target 1 Selected with Controller 2');
        break;
    end
    
    if (ontarget(1) == 2)
        toggleobject(touchTargetRightNotFilled, 'Status', 'off');
        toggleobject(touchTargetRightFilled, 'Status', 'on');
        trialerror(1);
        disp('<<< MonkeyLogic >>> Target 2 Selected with Controller 1');
        break;
    end

    if (ontarget(2) == 2)
        toggleobject(touchTargetRightNotFilled, 'Status', 'off');
        toggleobject(touchTargetRightFilled, 'Status', 'on');
        trialerror(1);
        disp('<<< MonkeyLogic >>> Target 2 Selected with Controller 2');
        break;
    end
    
    idle(20);  % if this idle command is missing there will be a buffer overrun error when the trial completes
    
end

numdev = xgldevices;
for devicenum = 1:numdev,
	xglshowcursor(devicenum, 1);
end

set_iti(750); % in milliseconds