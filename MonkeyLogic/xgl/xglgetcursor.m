function [lhs1] = xglgetcursor_mexgen ()
% XGLGETCURSOR   Get the cursor position.
%
% XGLGETCURSOR will get an x y pair that specifies the current cursor
% position.  On a multimonitor display, use XGLRECT to determine the
% cursor position relative to a given display.
%
% Cursor functions do not require initialization with XGLINIT.
%
% See also XGLSETCURSOR

% Mexgen generated this file on Mon Feb 18 08:10:36 2013
% DO NOT EDIT!

[lhs1] = xglmex (27);
