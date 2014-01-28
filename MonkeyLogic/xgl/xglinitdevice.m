function xglinitdevice_mexgen (rhs1, rhs2, rhs3)
% XGLINITDEVICE Initialize the specified device.
%
% XGLINITDEVICE(D,M,B) will initialize graphics device number D.
% When a device is initialized, it will be placed into the video mode
% specified by the array M.  The mode array M should contain the
% following values:
%
%
%   M(1) Width in pixels
%   M(2) Height in pixels
%   M(3) Pixel format specifier
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
% The parameter B specifies the number of backbuffers that should be
% allocated to the device.
%
% Note that a frontbuffer is also allocated when the device is
% initialized.  Therefore, for triple buffering, specify only two
% backbuffers.
%
% See also XGLTOTALMODES, XGLGETMODE

% Mexgen generated this file on Mon Feb 18 08:10:36 2013
% DO NOT EDIT!

xglmex (16, rhs1, rhs2, rhs3);
