% This is an example MonkeyLogic task that demonstrates very basic use of
% an eyetracker to select a stimulus
%
% Moving your gaze over one of two square
% shaped stimuli will cause them to be selected (switch from not filled to
% filled colors). 
% 
% February 01, 2016   Last Modified by Edward Ryklin(edward@ryklinsoftware.com)

windowSize = 1.5;   % in degrees of visual angle (DVA) I believe this is the diameter (not radius)
fixDuration = 2000; % duration in milliseconds to test for a fixation
holdDuration = 5000;

gazeTargetLeftNotFilled    = 1;
gazeTargetLeftFilled       = 2;
gazeTargetRightNotFilled   = 3;
gazeTargetRightFilled      = 4;

ontargetLeftTarget = 0;
ontargetRightTarget = 0;

showcursor('on');
scene_timer = tic;

toggleobject(gazeTargetLeftNotFilled, 'Status', 'on');
toggleobject(gazeTargetRightNotFilled, 'Status', 'on');
toggleobject(gazeTargetLeftFilled, 'Status', 'off');
toggleobject(gazeTargetRightFilled, 'Status', 'off');

ontargets = eyejoytrack('acquirefix', [gazeTargetLeftNotFilled gazeTargetRightNotFilled],  windowSize, fixDuration);     % it does not matter if you track the filled or not filled target since they overlap eachother in space

if (ontargets == 1)

	toggleobject(gazeTargetLeftNotFilled, 'Status', 'off');
    toggleobject(gazeTargetLeftFilled, 'Status', 'on');
    disp('<<< eyetracking3.m >>> Object 1 acquirefix');

    ontargets = eyejoytrack('holdfix', gazeTargetLeftFilled,  windowSize, holdDuration);     % it does not matter if you track the filled or not filled target since they overlap eachother in space

    if (ontargets == 1)
    	trialerror(1);
        disp('<<< eyetracking3.m >>> Object 1 holdfix');
	end
        
end

if (ontargets == 2)
        
	toggleobject(gazeTargetRightNotFilled, 'Status', 'off');
    toggleobject(gazeTargetRightFilled, 'Status', 'on');
    disp('<<< eyetracking3.m >>> Object 2 acquirefix');

    ontargets = eyejoytrack('holdfix', gazeTargetRightFilled,  windowSize, holdDuration);     % it does not matter if you track the filled or not filled target since they overlap eachother in space

    if (ontargets == 1)
    	trialerror(2);
        disp('<<< eyetracking3.m >>> Object 2 holdfix');
	end
        
end

set_iti(750); % in milliseconds