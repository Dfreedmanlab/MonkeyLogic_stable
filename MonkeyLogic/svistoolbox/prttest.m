function prttest
% PRTTEST   Test priority functions.

% Copyright (C) 2003 Center for Perceptual Systems
%
% jsp Created Wed Aug 13 15:39:14 CDT 2003

disp 'Testing prtinit...';
prtinit;
disp 'Testing prtrelease...';
prtrelease;
disp 'Testing prtrealtime...';
prtrealtime;
disp 'Testing prthigh...';
prthigh;
disp 'Testing prtnormal...';
prtnormal;
disp 'Testing prtisnormal...';
prtrealtime;
if prtisnormal
    error 'failed';
end
prtnormal;
if not(prtisnormal)
    error 'failed';
end
disp 'Success';
clear functions;
