% This is an example MonkeyLogic task that demonstrates very basic use of
% an eyetracker to select a stimulus
%
% Moving your gaze over one of two square
% shaped stimuli will cause them to be selected (switch from not filled to
% filled colors). 
% 
% Nov 19, 2015   Last Modified by Edward Ryklin(edward@ryklinsoftware.com)

windowSize = 1.5;   % in degrees of visual angle (DVA) I believe this is the diameter (not radius)
fixDuration = 2000; % duration in milliseconds to test for a fixation
holdDuration = 500;

gazeTargetLeftNotFilled    = 1;
gazeTargetLeftFilled       = 2;
gazeTargetRightNotFilled   = 3;
gazeTargetRightFilled      = 4;

ontargetLeftTarget = 0;
ontargetRightTarget = 0;

showcursor('on');
scene_timer = tic;
target_fixed = [0, 0];

toggleobject(gazeTargetLeftNotFilled, 'Status', 'on');
toggleobject(gazeTargetRightNotFilled, 'Status', 'on');

ontargets = eyejoytrack('acquirefix', [gazeTargetLeftNotFilled gazeTargetRightNotFilled],  windowSize, fixDuration);     % it does not matter if you track the filled or not filled target since they overlap eachother in space

if (ontargets == 1)

	toggleobject(gazeTargetLeftNotFilled, 'Status', 'off');
    toggleobject(gazeTargetLeftFilled, 'Status', 'on');
    target_fixed(1) = 1;
    disp('<<< MonkeyLogic >>> Target 1 Fixed');

    ontargets = eyejoytrack('holdfix', gazeTargetLeftFilled,  windowSize, holdDuration);     % it does not matter if you track the filled or not filled target since they overlap eachother in space

    if (ontargets == 1)
    	trialerror(1);
        disp('<<< MonkeyLogic >>> Target 1 held');
	end
        
end

if (ontargets == 2)
        
	toggleobject(gazeTargetRightNotFilled, 'Status', 'off');
    toggleobject(gazeTargetRightFilled, 'Status', 'on');
    target_fixed(2) = 1;
    disp('<<< MonkeyLogic >>> Target 2 Fixed');

    ontargets = eyejoytrack('holdfix', gazeTargetRightFilled,  windowSize, holdDuration);     % it does not matter if you track the filled or not filled target since they overlap eachother in space

    if (ontargets == 1)
    	trialerror(2);
        disp('<<< MonkeyLogic >>> Target 2 held');
	end
        
end

set_iti(750);