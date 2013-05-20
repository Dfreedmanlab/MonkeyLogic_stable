function [lhs1] = xglcreatebuffer_mexgen (rhs1, rhs2)
% XGLCREATEBUFFER   Create an offscreen memory buffer.
%
% [B]=XGLCREATEBUFFER(D,[W H PF]) will create an offscreen memory
% buffer on device D with dimensions W x H in the pixel format
% specified by PF.
%
% Ultimately you will be copying pixels to the buffer and then
% blitting it to video memory, so make sure hardware conversion is
% supported for the specified pixel format.
%
% Note that you can pass a mode vector [W H PF F] returned from
% XGLGETMODE or XGLCURRENTMODE to the XGLCREATEBUFFER function, but
% the F parameter, monitor frequency, will be ignored.
%
% Also note that many devices require that the buffer width be a
% multiple of some power of 2, like 8 or 16.  If you specify a width
% that is not supported, the device might create the buffer but give
% you erroneous results.
%
% See also XGLHWCONVERSION, XGLCOPYBUFFER, XGLBLIT, XGLGETMODE

% Mexgen generated this file on Fri Oct 26 11:41:42 2007
% DO NOT EDIT!

[lhs1] = xglmex (21, rhs1, rhs2);
