function [lhs1, lhs2] = xglgetrasterstatus_mexgen (rhs1)
% XGLGETRASTERSTATUS    Get the state of the current raster
%
% [VB,SL]=XGLGETRASTERSTATUS(D) will get the raster status for device
% D.  VB indicates whether or not the raster is currently within a
% vertical blank.  If VB is false, then SL incicates the scanline that
% the device is currently drawing.
%
% See also XGLBLIT

% Mexgen generated this file on Mon Feb 18 08:10:36 2013
% DO NOT EDIT!

[lhs1, lhs2] = xglmex (20, rhs1);
