% This is an example MonkeyLogic task that demonstrates very basic use of
% the getkeypress function to control trial execution.

% A stimulus is toggled on and off to create a flicker during the trial.
% Pressing the spacebar will break the trial loop, turn off the stimulus
% and run the ITI.
%
% Note: the optional corresponding configuratin file (keyboard1_cfg.mat)
% will assign the eyetracker x and y to the analog inputs. Therefore,
% analog data will be collected during the trial, but it will not control
% trial execution (using eyejoytrack). You can unmap the eyetracker in the
% GUI without impacting trial execution.
% 
% April 05, 2016   Last Modified by Edward Ryklin(edward@ryklinsoftware.com)

targetNumber   = 1;
scene_timer = tic;
duration = 100;
disp('You can press the spacebar to skip to the next trial');

while toc(scene_timer) < duration
    
    idle(20);
    toggleobject(targetNumber, 'Status', 'on');
    idle(20);
    toggleobject(targetNumber, 'Status', 'off');
        
    scancode = getkeypress(duration);
    
    if ( scancode == 57 )
        break;
    end

end
toggleobject(targetNumber, 'Status', 'off');
trialerror(7);
set_iti(1500); % in milliseconds
