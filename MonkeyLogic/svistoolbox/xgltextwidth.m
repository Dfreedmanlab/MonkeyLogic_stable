function [lhs1] = xgltextwidth_mexgen (rhs1, rhs2)
% XGLTEXTWIDTH  Get the width in pixels of a text string.
%
% XGLTEXTWIDTH(D,T) will return the width in pixels on the device D of
% the text string in T.  The width depends on the current font and
% point size.
%
% See also XGLSETFONT, XGLSETPOINTSIZE, XGLTEXTHEIGHT

% Mexgen generated this file on Fri Oct 26 11:41:42 2007
% DO NOT EDIT!

[lhs1] = xglmex (42, rhs1, rhs2);
