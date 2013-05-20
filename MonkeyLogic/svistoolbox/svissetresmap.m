function svissetresmap_mexgen (rhs1, rhs2)
% SVISSETRESMAP Set a codec's resolution map
%
% SVISSETRESMAP(C,R) sets codec C's resolution map to image R.
%
% The image R must be of type UINT8.
%
% Pixels in R represent image resolution values where 255 is
% the highest resolution and 0 is the lowest resolution.
%
% SEE ALSO: SVISCODEC, SVISRESMAP

% Mexgen generated this file on Wed Dec 05 09:43:30 2007
% DO NOT EDIT!

svismex (3, rhs1, rhs2);
