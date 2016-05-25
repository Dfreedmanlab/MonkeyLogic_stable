% This is an example MonkeyLogic task that demonstrates very basic use of a
% mouse to select stimulus.
%
% During trials, a red dot will follow the cursor which is controlled by a
% mouse. When the left mouse button is pressed
% the red dot will appear as filled. Users can use this to toggle stimulus.
% 
% Moving the mouse controlled cursor over one of two square
% shaped stimuli will cause them to be selected (switch from not filled to
% filled colors).
% 
% April 14, 2016   Last Modified by Edward Ryklin(edward@ryklinsoftware.com)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

scene_timer = tic;
windowSize = 1.5; % in degrees of visual angle (DVA)
fixDuration = 10; % duration in milliseconds to test for a touch/fixation
   
mouseLocationNotFilled      = 1;
mouseLocationFilled         = 2;
mouseTargetLeftNotFilled    = 3;
mouseTargetLeftFilled       = 4;
mouseTargetRightNotFilled   = 5;
mouseTargetRightFilled      = 6;

ontargetCursor = 0;
ontargetLeftTarget = 0;
ontargetRightTarget = 0;

numdev = xgldevices;
for devicenum = 1:numdev,
	xglshowcursor(devicenum, 0);
end

while toc(scene_timer) < 10
    
    [x, y] = mouse_position();
   	reposition_object(mouseLocationNotFilled,x,y);  %x and %y are in DVA (degrees of visual angle, not pixels)
    reposition_object(mouseLocationFilled,x,y);     %x and %y are in DVA (degrees of visual angle, not pixels)
    toggleobject(mouseLocationNotFilled, 'Status', 'on');
   
    ontargetCursor          = eyejoytrack('acquiremouse', mouseLocationNotFilled,     windowSize, fixDuration);     % it does not matter if you track the filled or not filled target since they overlap eachother in space
    ontargetLeftTarget      = eyejoytrack('acquiremouse', mouseTargetLeftNotFilled,   windowSize, fixDuration);   % it does not matter if you track the filled or not filled target since they overlap eachother in space
    ontargetRightTarget     = eyejoytrack('acquiremouse', mouseTargetRightNotFilled,  windowSize, fixDuration);  % it does not matter if you track the filled or not filled target since they overlap eachother in space

    if (ontargetCursor)
       toggleobject(mouseLocationNotFilled, 'Status', 'off');
       toggleobject(mouseLocationFilled, 'Status', 'on');
    else 
       toggleobject(mouseLocationNotFilled, 'Status', 'on');
       toggleobject(mouseLocationFilled, 'Status', 'off');
    end

    if (ontargetLeftTarget)
       toggleobject(mouseTargetLeftNotFilled, 'Status', 'off');
       toggleobject(mouseTargetLeftFilled, 'Status', 'on');
       trialerror(0);
    else 
       toggleobject(mouseTargetLeftNotFilled, 'Status', 'on');
       toggleobject(mouseTargetLeftFilled, 'Status', 'off');
    end
    
    if (ontargetRightTarget)
       toggleobject(mouseTargetRightNotFilled, 'Status', 'off');
       toggleobject(mouseTargetRightFilled, 'Status', 'on');
       trialerror(0);
    else 
       toggleobject(mouseTargetRightNotFilled, 'Status', 'on');
       toggleobject(mouseTargetRightFilled, 'Status', 'off');
    end
    
    idle(20);  % if this idle command is missing there will be a buffer overrun error when the trial completes

end
numdev = xgldevices;
for devicenum = 1:numdev,
	xglshowcursor(devicenum, 1);
end

set_iti(3000);