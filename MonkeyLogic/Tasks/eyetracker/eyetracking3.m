% This is an example MonkeyLogic task that demonstrates very basic use of
% an eyetracker to select a stimulus
%
% Moving your gaze over one of two square
% shaped stimuli will cause them to be selected (switch from not filled to
% filled colors). 
% 
% April 12, 2016   Last Modified by Edward Ryklin(edward@ryklinsoftware.com)

windowSize = 1.5;   % in degrees of visual angle (DVA) I believe this is the diameter (not radius)
fixDuration = 5000; % duration in milliseconds to test for a fixation
holdDuration = 750;

gazeTargetLeftNotFilled    = 1;
gazeTargetLeftFilled       = 2;
gazeTargetRightNotFilled   = 3;
gazeTargetRightFilled      = 4;

ontargetLeftTarget = 0;
ontargetRightTarget = 0;

%showcursor('on'); % warning: displaying the cursor on the stimulus display will increase the max latency. 

toggleobject(gazeTargetLeftNotFilled, 'Status', 'on');
toggleobject(gazeTargetRightNotFilled, 'Status', 'on');
toggleobject(gazeTargetLeftFilled, 'Status', 'off');
toggleobject(gazeTargetRightFilled, 'Status', 'off');

ontargets = eyejoytrack('acquirefix', [gazeTargetLeftNotFilled gazeTargetRightNotFilled],  windowSize, fixDuration);     % it does not matter if you track the filled or not filled target since they overlap eachother in space

if (ontargets == 1)

    disp('<<< eyetracking3.m >>> Object 1 acquirefix');

    toggleobject(gazeTargetRightNotFilled, 'Status', 'off'); % TURN OFF THE OTHER TARGET TO INDICATE THAT YOU HAVE SELECTED THE CORRECT OBJECT

    ontargets = eyejoytrack('holdfix', gazeTargetLeftFilled,  windowSize, holdDuration);     % it does not matter if you track the filled or not filled target since they overlap eachother in space

    if (ontargets == 1)
        toggleobject(gazeTargetLeftNotFilled, 'Status', 'off');
        toggleobject(gazeTargetLeftFilled, 'Status', 'on');
    	trialerror(1);
        disp('<<< eyetracking3.m >>> Object 1 holdfix');
    else 
    	trialerror(3);
        disp('<<< eyetracking3.m >>> Object 1 premature holdfix');
	end
        
end

if (ontargets == 2)
        
    disp('<<< eyetracking3.m >>> Object 2 acquirefix');

    toggleobject(gazeTargetLeftNotFilled, 'Status', 'off'); % TURN OFF THE OTHER TARGET TO INDICATE THAT YOU HAVE SELECTED THE CORRECT OBJECT

    ontargets = eyejoytrack('holdfix', gazeTargetRightFilled,  windowSize, holdDuration);     % it does not matter if you track the filled or not filled target since they overlap eachother in space

    if (ontargets == 1)
        toggleobject(gazeTargetRightNotFilled, 'Status', 'off');
        toggleobject(gazeTargetRightFilled, 'Status', 'on');
    	trialerror(2);
        disp('<<< eyetracking3.m >>> Object 2 holdfix');
    else 
    	trialerror(4);
        disp('<<< eyetracking3.m >>> Object 3 premature holdfix');
	end
        
end

set_iti(750); % in milliseconds