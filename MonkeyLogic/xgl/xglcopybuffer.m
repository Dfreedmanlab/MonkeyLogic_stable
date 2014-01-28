function xglcopybuffer_mexgen (rhs1, rhs2, rhs3)
% XGLCOPYBUFFER Copy pixels to offscreen memory.
%
% XGLCOPYBUFFER(D,H,P) will copy pixels to the buffer on device D with
% buffer handle H from the buffer in P.  P may contain uint8 grayscale
% values in the range [0, 255], uint32 values obtained from the RGB
% pixel conversion functions, or single precision floating point
% values in the range [0, 1.0].
%
% See also XGLCREATEBUFFER, XGLBLIT, XGLHWCONVERSION, XGLRGB8,
% XGLRGB10

% Mexgen generated this file on Mon Feb 18 08:10:36 2013
% DO NOT EDIT!

xglmex (25, rhs1, rhs2, rhs3);
