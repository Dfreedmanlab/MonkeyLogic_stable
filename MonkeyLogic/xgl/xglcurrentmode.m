function [lhs1] = xglcurrentmode_mexgen (rhs1)
% XGLCURRENTMODE    Get the device's current video mode
%
% M=XGLCURRENTMODE(D) returns an array of four values that specify the
% device's current video mode.  The array values specify the
% following:  
%
%   M(1) Width in pixels
%   M(2) Height in pixels
%   M(3) Pixel format value
%   M(4) Video refresh rate
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
% See also XGLTOTALMODES, XGLGETMODE

% Mexgen generated this file on Mon Feb 18 08:10:36 2013
% DO NOT EDIT!

[lhs1] = xglmex (13, rhs1);
