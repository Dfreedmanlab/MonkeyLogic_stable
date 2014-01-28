function [lhs1] = kbdgetkey_mexgen ()
% KBDGETKEY Get a saved keystroke.
%
% KBDGETKEY will return a keystroke that was saved since a call to
% KBDINIT.  The key is then removed from the buffer containing saved
% keystrokes.
%
% If no key is available, the function will return an empty scalar.
%
% The value returned is a PC scancode value that corresponds to a key
% on a PC keyboard.  This allows you to detect key depresses that may
% not be associated with an alphanumeric symbol.  For example, with
% this function, you can detect depresses of the arrow keys or the ALT
% and CTRL keys.
%
% See also KBDINIT, KBDRELEASE, KBDKEYCODE, KBDPCSCANCODES

% Mexgen generated this file on Wed Nov  6 12:05:31 2013
% DO NOT EDIT!

[lhs1] = kbdmex (3);
