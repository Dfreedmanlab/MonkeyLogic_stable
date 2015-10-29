% This is an example MonkeyLogic task that demonstrates very basic use of
% an analog joystick to select one of two targets
%
% Two targest will appear (one above and one below the center of the
% screen). Moving the joystick to either target will cause the trial to
% end.
% 
% showcursor is set to on, so a small gray colored filled disc will appear on the
% stimulus display; which represents the location of the joystick.
%
% Make sure the joystick is mapped in the GUI to analog inputs, or else
% this task will cause an error to appear. 
%
% If you wish to use an eyetracker instead of a joystick you need to change 
% the 'acquiretarget' command to 'acquirefix', or else you will get an
% error.
%
% Oct 29, 2015   Last Modified by Edward Ryklin(edward@ryklinsoftware.com)


left = 1;           %left target number
right = 2;          %right target number
windowSize = 1.5;   %degrees of visual angle surrounding the target. I believe this is the diameter (not radius)
duration = 3000;    %in milliseconds

toggleobject([left right], 'Status', 'on');
showcursor('on');
ontarget = eyejoytrack('acquiretarget', [left right], windowSize, duration);
if ~ontarget,
     trialerror(4); % no response
     toggleobject([left right], 'Status', 'off');
     set_iti(10);
     return
end

showcursor('off');

set_iti(0);