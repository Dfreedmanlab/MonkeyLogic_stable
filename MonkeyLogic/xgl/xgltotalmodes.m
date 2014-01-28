function [lhs1] = xgltotalmodes_mexgen (rhs1, rhs2)
% XGLTOTALMODES Get the total number of modes for a device.
%
% XGLTOTALMODES(D,PF) will return a scalar that indicates the number of
% modes available for device D.  The PF parameter specifies the pixel
% format of the mode.
%
% The following XGLPF* functions return values for the following
% pixel formats:
%
%   XGLPFGS         Grayscale
%   XGLPFRGB8       32 bit RGB
%   XGLPFYV12       12 bit planar YUV
%   XGLPFRGB10      32 bit, 10 bit per channel RGB
%   XGLPFRGBF16     64 bit, 16 bit per channel floating point RGB
%
% See also XGLGETMODE

% Mexgen generated this file on Mon Feb 18 08:10:36 2013
% DO NOT EDIT!

[lhs1] = xglmex (12, rhs1, rhs2);
