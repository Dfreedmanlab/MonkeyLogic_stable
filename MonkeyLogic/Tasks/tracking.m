% This is an example MonkeyLogic task that shows how to use MouseTracker.
% During trials, a red dot and a blue dot follow the mouse cursor when the
% cursor is in the control screen and the subject screen, respectively.
% Clicking with the left mouse button will cause the blue dot to toggle 
% between a filled shape and circular outline.
%
%   Jul 8, 2015         Written by Jaewon Hwang (jaewon.hwang@hotmail.com)
%   Aug 5, 2015         Modified by Edward Ryklin(edward@ryklinsoftware.com)

%disp(sprintf('<<< MonkeyLogic >>> Timing Script %0.2f\n', 1.3));
a = MouseTracker(ScreenInfo);

scene_timer = tic;
while toc(scene_timer) < 10
    toggleobject(5, 'Status', 'on');
    toggleobject(6, 'Status', 'on');

    
    [x1,y1,left_button,right_button] = a.GetCursorPos('control');  % red
    reposition_object(1,x1,y1);  %x1 and %y1 are in DVA (degrees of visual angle, not pixels)
    reposition_object(2,x1,y1);  %x1 and %y1 are in DVA (degrees of visual angle, not pixels)

    [x2,y2,left_button,right_button] = a.GetCursorPos('subject');  % blue
    reposition_object(3,x2,y2);  %x2 and %y2 are in DVA (degrees of visual angle, not pixels)
    reposition_object(4,x2,y2);  %x2 and %y2 are in DVA (degrees of visual angle, not pixels)

    if (right_button==0)  % right mouse button is up
        toggleobject(1,'Status','on');
        toggleobject(2,'Status','off');
     
    elseif (right_button==1) % right mouse button is down
        toggleobject(1,'Status','off');
        toggleobject(2,'Status','on');
    end
    
    if (left_button==0)  % left mouse button is up
        toggleobject(3,'Status','on');
        toggleobject(4,'Status','off');
     
    elseif (left_button==1) % left mouse button is down
        toggleobject(3,'Status','off');
        toggleobject(4,'Status','on');
    end
    
    idle(20);
end

set_iti(0);