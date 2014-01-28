function kbdkeycode ()
% KBDKEYCODE    Interactively display keyboard scancodes
%
% This function will display keyboard scancode numbers as you type.
%
% Pressing ESC will terminate the function.
%
% This function does not require a call to kbdinit prior to its use.
% Rather, kbdinit and kbdrelease are called from within the function.

% Copyright (C) 2003-2006
% Center for Perceptual Systems
% University of Texas at Austin
%
% jsp Tue Sep  2 16:55:34 CDT 2003

fprintf('Press any key to display that key''s scancode\n');
fprintf('Or press ESC to terminate\n');
kbdinit;
while 1
    a=kbdgetkey;
    if not(size(a)==0)
        fprintf('keyboard scancode = %d\n',a);
        if a==1 % 1 == ESC
            break
        end
    end
end
kbdrelease;
