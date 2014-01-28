function [lhs1] = xglhwconversion_mexgen (rhs1, rhs2, rhs3)
% XGLHWCONVERSION   Determine hardware conversion support
%
% XGLHWCONVERSION(D,PF1,PF2) returns a logical value indicating whether
% or not hardware conversion from pixel format PF1 to PF2 is supported
% on device D.
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
% See also XGLTOTALMODES, XGLGETMODE, XGLBLIT

% Mexgen generated this file on Mon Feb 18 08:10:36 2013
% DO NOT EDIT!

[lhs1] = xglmex (15, rhs1, rhs2, rhs3);
