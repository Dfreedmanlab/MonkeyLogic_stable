function xglreleasedevice_mexgen (rhs1)
% XGLRELEASEDEVICE  Release the specified device.
%
% XGLRELEASEDEVICE(D) will release graphics device number D.
% Devices must be released when they are no longer being used.
%
% When a device is released, its video mode is restored to the mode it
% was in before the call the XGLINITDEVICE.
%
% See also XGLDEVICES, XGLINITDEVICE

% Mexgen generated this file on Mon Feb 18 08:10:36 2013
% DO NOT EDIT!

xglmex (17, rhs1);
