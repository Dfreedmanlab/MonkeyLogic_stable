function [lhs1] = xgldevices_mexgen ()
% XGLDEVICES    Return the number of graphics devices in the system.
%
% Call this function to determine how many graphics devices are in
% the system.  A dual head controller will be detected as two separate
% devices.
%
% See also XGLINIT

% Mexgen generated this file on Fri Oct 26 11:41:42 2007
% DO NOT EDIT!

[lhs1] = xglmex (9);
