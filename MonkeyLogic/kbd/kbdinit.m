function kbdinit_mexgen (varargin)
% KBDINIT   Begin saving keystrokes.
%
% KBDINIT will begin saving keystrokes from the keyboard.
% Keystrokes will not be passed to the matlab command line.
%
% WARNING: DO NOT CALL THIS FUNCTION FROM THE MATLAB COMMAND LINE.
%
% Only call this function from a matlab script or function in which it is
% paired with a call to KBDRELEASE.
%
% If you call this function from the command line, all keyboard data
% will be redirected, rendering the command line inoperable.
%
% See also KBDGETKEY, KBDRELEASE

% Mexgen generated this file on Wed Nov  6 12:05:31 2013
% DO NOT EDIT!

kbdmex (0, varargin{:});
