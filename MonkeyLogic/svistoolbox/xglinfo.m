function [lhs1] = xglinfo_mexgen (rhs1)
% XGLINFO   Get device info.
%
% XGLINFO(D) will get graphics device info in the form of a text
% string for graphics device number D.  The device number is 1-based
% and must be between 1 and the number returned from XGLDEVICES.
%
% See also XGLINITDEVICE

% Mexgen generated this file on Fri Oct 26 11:41:42 2007
% DO NOT EDIT!

[lhs1] = xglmex (10, rhs1);
