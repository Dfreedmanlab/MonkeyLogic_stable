% This is an example MonkeyLogic task that demonstrates very basic use of
% an eyetracker to select a stimulus
%
% Moving your gaze over one of two square
% shaped stimuli will cause them to be selected (switch from not filled to
% filled colors). 
% 
% April 14, 2016   Last Modified by Edward Ryklin(edward@ryklinsoftware.com)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

windowSize = 1.5;   % in degrees of visual angle (DVA) I believe this is the diameter (not radius)
fixDuration = 5000; % duration in milliseconds to test for a fixation
   
gazeTargetLeftNotFilled    = 1;
gazeTargetLeftFilled       = 2;
gazeTargetRightNotFilled   = 3;
gazeTargetRightFilled      = 4;

ontargetLeftTarget = 0;
ontargetRightTarget = 0;

%showcursor('on'); % warning: displaying the cursor on the stimulus display will increase the max latency.

scene_timer = tic;
target_fixed = [0, 0];

toggleobject(gazeTargetLeftNotFilled, 'Status', 'on');
toggleobject(gazeTargetRightNotFilled, 'Status', 'on');

while toc(scene_timer) < 10

    ontargets = eyejoytrack('acquirefix', [gazeTargetLeftNotFilled gazeTargetRightNotFilled],  windowSize, fixDuration);     % it does not matter if you track the filled or not filled target since they overlap eachother in space

    if (ontargets == 1)
        toggleobject(gazeTargetLeftNotFilled, 'Status', 'off');
        toggleobject(gazeTargetLeftFilled, 'Status', 'on');
        target_fixed(1) = 1;
    end

    if (ontargets == 2)
        toggleobject(gazeTargetRightNotFilled, 'Status', 'off');
        toggleobject(gazeTargetRightFilled, 'Status', 'on');
        target_fixed(2) = 1;
    end

    idle(20);  % if this idle command is missing there will be a buffer overrun error when the trial completes

    if ( (target_fixed(1) == 1) && (target_fixed(2) == 1) )
        trialerror(0);
        break;
    end
end

set_iti(3000);