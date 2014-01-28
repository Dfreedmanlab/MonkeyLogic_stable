function [lhs1] = xgldevices_mexgen ()
% XGLDEVICES    Return the number of graphics devices in the system.
%
% Call this function to determine how many graphics devices are in
% the system.  A dual head controller will be detected as two separate
% devices.
%
% See also XGLINIT

% Mexgen generated this file on Mon Feb 18 08:10:36 2013
% DO NOT EDIT!

[lhs1] = xglmex (9);
