% This is an example MonkeyLogic task that demonstrates very basic use of
% an eyetracker to select stimulus
%
% During trials, a red dot will follow the cursor which is controlled by
% an eyetracker. When the gaze fixates the red dot will appear as filled.
% 
% Moving your gaze over one of two square
% shaped stimuli will cause them to be selected (switch from not filled to
% filled colors).
% 
% Nov 19, 2015   Last Modified by Edward Ryklin(edward@ryklinsoftware.com)

scene_timer = tic;
windowSize = 1.5; % in degrees of visual angle (DVA)
fixDuration = 10; % duration in milliseconds to test for a fixation
   
gazeLocationNotFilled      = 1;
gazeLocationFilled         = 2;
gazeTargetLeftNotFilled    = 3;
gazeTargetLeftFilled       = 4;
gazeTargetRightNotFilled   = 5;
gazeTargetRightFilled      = 6;

ontargetCursor = 0;
ontargetLeftTarget = 0;
ontargetRightTarget = 0;

while toc(scene_timer) < 10
    
    [x, y] = eye_position();
   	reposition_object(gazeLocationNotFilled,x,y);  %x and %y are in DVA (degrees of visual angle, not pixels)
    reposition_object(gazeLocationFilled,x,y);     %x and %y are in DVA (degrees of visual angle, not pixels)
    toggleobject(gazeLocationNotFilled, 'Status', 'on');
   
    ontargetCursor          = eyejoytrack('acquirefix', gazeLocationNotFilled,     windowSize, fixDuration);  % it does not matter if you track the filled or not filled target since they overlap eachother in space
    ontargetLeftTarget      = eyejoytrack('acquirefix', gazeTargetLeftNotFilled,   windowSize, fixDuration);  % it does not matter if you track the filled or not filled target since they overlap eachother in space
    ontargetRightTarget     = eyejoytrack('acquirefix', gazeTargetRightNotFilled,  windowSize, fixDuration);  % it does not matter if you track the filled or not filled target since they overlap eachother in space

    if (ontargetCursor)
       toggleobject(gazeLocationNotFilled, 'Status', 'off');
       toggleobject(gazeLocationFilled, 'Status', 'on');
    else 
       toggleobject(gazeLocationNotFilled, 'Status', 'on');
       toggleobject(gazeLocationFilled, 'Status', 'off');
    end

    if (ontargetLeftTarget)
       toggleobject(gazeTargetLeftNotFilled, 'Status', 'off');
       toggleobject(gazeTargetLeftFilled, 'Status', 'on');
       trialerror(0);
    else 
       toggleobject(gazeTargetLeftNotFilled, 'Status', 'on');
       toggleobject(gazeTargetLeftFilled, 'Status', 'off');
    end
    
    if (ontargetRightTarget)
       toggleobject(gazeTargetRightNotFilled, 'Status', 'off');
       toggleobject(gazeTargetRightFilled, 'Status', 'on');
       trialerror(0);
    else 
       toggleobject(gazeTargetRightNotFilled, 'Status', 'on');
       toggleobject(gazeTargetRightFilled, 'Status', 'off');
    end
    
    idle(20);  % if this idle command is missing there will be a buffer overrun error when the trial completes

end

set_iti(3000);