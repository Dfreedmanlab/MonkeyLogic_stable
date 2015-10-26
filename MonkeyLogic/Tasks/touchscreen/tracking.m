% This is an example MonkeyLogic task that demonstrates very basic use of a
% touchscreen or mouse to select stimulus
% During trials, a red dot will follow the cursor which is controlled by a
% mouse or touchscreen. When the left mouse button is pressed, or
% touchscreen is depressed the red dot will appear as filled.
% 
% Moving the mouse/touchscreen controlled cursor over one of two square
% shaped stimuli will cause them to be selected (switch from not filled to
% filled colors).
% 
% Currently, this code assumes that the cursor data is piped into the eye
% tracker cahnnel, which allows us to use the eye_position function to get
% x,y data, and eyejoytrack to find if the cursor is ontarget. Future
% versions will have separate functions such as touchscreen_position and
% touchtrack(), or something similar.

% Oct 26, 2015   Last Modified by Edward Ryklin(edward@ryklinsoftware.com)

scene_timer = tic;
windowSize = 1.5; % in degrees of visual angle (DVA)
fixDuration = 50; % duration in milliseconds to test for a touch/fixation
   
touchLocationNotFilled      = 1;
touchLocationFilled         = 2;
touchTargetLeftNotFilled    = 3;
touchTargetLeftFilled       = 4;
touchTargetRightNotFilled   = 5;
touchTargetRightFilled      = 6;

ontargetCursor = 0;
ontargetLeftTarget = 0;
ontargetRightTarget = 0;

numdev = xgldevices;
for devicenum = 1:numdev,
	xglshowcursor(devicenum, 0);
end

while toc(scene_timer) < 10
    
    [x, y] = eye_position();
   	reposition_object(touchLocationNotFilled,x,y);  %x and %y are in DVA (degrees of visual angle, not pixels)
    reposition_object(touchLocationFilled,x,y);     %x and %y are in DVA (degrees of visual angle, not pixels)
    toggleobject(touchLocationNotFilled, 'Status', 'on');
   
%{
    ontargetCursor          = eyejoytrack('acquirefix', touchLocationNotFilled,     windowSize, fixDuration);     % it does not matter if you track the filled or not filled target since they overlap eachother in space
    ontargetLeftTarget      = eyejoytrack('acquirefix', touchTargetLeftNotFilled,   windowSize, fixDuration);   % it does not matter if you track the filled or not filled target since they overlap eachother in space
    ontargetRightTarget     = eyejoytrack('acquirefix', touchTargetRightNotFilled,  windowSize, fixDuration);  % it does not matter if you track the filled or not filled target since they overlap eachother in space
%}
    if (ontargetCursor)
       toggleobject(touchLocationNotFilled, 'Status', 'off');
       toggleobject(touchLocationFilled, 'Status', 'on');
    else 
       toggleobject(touchLocationNotFilled, 'Status', 'on');
       toggleobject(touchLocationFilled, 'Status', 'off');
    end


    if (ontargetLeftTarget)
       toggleobject(touchTargetLeftNotFilled, 'Status', 'off');
       toggleobject(touchTargetLeftFilled, 'Status', 'on');
    else 
       toggleobject(touchTargetLeftNotFilled, 'Status', 'on');
       toggleobject(touchTargetLeftFilled, 'Status', 'off');
    end
    
    if (ontargetRightTarget)
       toggleobject(touchTargetRightNotFilled, 'Status', 'off');
       toggleobject(touchTargetRightFilled, 'Status', 'on');
    else 
       toggleobject(touchTargetRightNotFilled, 'Status', 'on');
       toggleobject(touchTargetRightFilled, 'Status', 'off');
    end
    
    idle(20);  % if this idle command is missing there will be a buffer overrun error when the trial completes

end
numdev = xgldevices;
for devicenum = 1:numdev,
	xglshowcursor(devicenum, 1);
end

set_iti(0);