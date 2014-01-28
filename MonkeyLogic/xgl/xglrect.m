function [lhs1] = xglrect_mexgen (rhs1)
% XGLRECT   Get device screen desktop rectangle.
%
% XGLRECT(D) will get the desktop position of the specified device.
% The rectangle is returned in a 4 element row vector and specifies
% the x and y coordinates of the screen offset and the width and
% height of the monitor (in that order).
%
% This desktop rectangle is used in multimonitor systems to determine
% the monitors' positions relative to one another.  Use this function
% also to determine if a device has an attached monitor.  If a device
% does not have an attached monitor, the width and height will be 0.
%
% See also XGLINITDEVICE

% Mexgen generated this file on Mon Feb 18 08:10:36 2013
% DO NOT EDIT!

[lhs1] = xglmex (11, rhs1);
