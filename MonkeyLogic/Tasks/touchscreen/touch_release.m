% This is an example MonkeyLogic task that demonstrates very basic use of a
% touchscreen to select stimulus.
%
% Moving the mouse/touchscreen controlled cursor over one of two square
% shaped stimuli, then clicking and releasing,
% will cause that stimuli to be selected (switch from not filled to
% filled colors). 
% 
% The position of the cursor is displayed using showcursor('on'). 
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
fixDuration = 5000; % duration in milliseconds to test for a fixation
holdDuration = 750;
   
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

toggleobject(touchTargetLeftNotFilled, 'Status', 'on');
toggleobject(touchTargetRightNotFilled, 'Status', 'on');
toggleobject(touchTargetLeftFilled, 'Status', 'off');
toggleobject(touchTargetRightFilled, 'Status', 'off');

ontargets = eyejoytrack('touchtarget', [touchTargetLeftNotFilled touchTargetRightNotFilled], windowSize, fixDuration);     % it does not matter if you track the filled or not filled target since they overlap eachother in space

if (ontargets == 1)

    disp('<<< touch_release.m >>> Object 1 touchtarget');

    toggleobject(touchTargetRightNotFilled, 'Status', 'off'); % TURN OFF THE OTHER TARGET TO INDICATE THAT YOU HAVE SELECTED THE CORRECT OBJECT

    ontargets = eyejoytrack('releasetarget', touchTargetLeftFilled,  windowSize, holdDuration);     % it does not matter if you track the filled or not filled target since they overlap eachother in space

    if (ontargets == 1)
        toggleobject(touchTargetLeftNotFilled, 'Status', 'off');
        toggleobject(touchTargetLeftFilled, 'Status', 'on');
    	trialerror(1);
        disp('<<< touch_release.m >>> Object 1 releasetarget');
    else 
    	trialerror(3);
        disp('<<< touch_release.m >>> Object 1 premature release');
	end
        
end

if (ontargets == 2)
        
    disp('<<< touch_release.m >>> Object 2 touchtarget');

    toggleobject(touchTargetLeftNotFilled, 'Status', 'off'); % TURN OFF THE OTHER TARGET TO INDICATE THAT YOU HAVE SELECTED THE CORRECT OBJECT

    ontargets = eyejoytrack('releasetarget', touchTargetRightFilled,  windowSize, holdDuration);     % it does not matter if you track the filled or not filled target since they overlap eachother in space

    if (ontargets == 1)
        toggleobject(touchTargetRightNotFilled, 'Status', 'off');
        toggleobject(touchTargetRightFilled, 'Status', 'on');
    	trialerror(2);
        disp('<<< touch_release.m >>> Object 2 releasetarget');
    else 
    	trialerror(4);
        disp('<<< touch_release.m >>> Object 2 premature release');
	end
        
end


numdev = xgldevices;
for devicenum = 1:numdev,
	xglshowcursor(devicenum, 1);
end

set_iti(3000); % in milliseconds