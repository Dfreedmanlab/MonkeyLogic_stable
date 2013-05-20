function [lhs1] = xglgetmode_mexgen (rhs1, rhs2, rhs3)
% XGLGETMODE    Get a video mode specification for a device
%
% M=XGLGETMODE(D,PF,N) returns an array of four values that specify
% the device's Nth video mode for pixel format PF.  The total number
% of video modes for a device must first be determined by
% XGLTOTALMODES.  The array of mode values returned are as follows:
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
% Note that the mode value M(4) will be set to the same value passed
% to the function in PF.
%
% See also XGLTOTALMODES, XGLCURRENTMODE

% Mexgen generated this file on Fri Oct 26 11:41:42 2007
% DO NOT EDIT!

[lhs1] = xglmex (14, rhs1, rhs2, rhs3);
