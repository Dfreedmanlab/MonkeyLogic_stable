function xglblit_mexgen (rhs1, rhs2, varargin)
% XGLBLIT   Blit offscreen memory to video memory.
%
% XGLBLIT(D,H[,R]) will blit offscreen memory in the buffer designated
% by H to device D's backbuffer.
%
% You may optionally specify a destination rectangle, R.  If R is
% omitted, the buffer is blitted to the entire screen.
%
% Call XGLFLIP to display the contents of the device's backbuffer.
%
% See also XGLCREATEBUFFER, XGLCOPYBUFFER, XGLHWCONVERSION, XGLFLIP

% Mexgen generated this file on Fri Oct 26 11:41:42 2007
% DO NOT EDIT!

xglmex (26, rhs1, rhs2, varargin{:});
