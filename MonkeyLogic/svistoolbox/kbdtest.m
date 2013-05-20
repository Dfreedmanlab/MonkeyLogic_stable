function kbdtest ()
% KBDTEST   Test kbd library functions.

% Copyright (C) 2003-2006
% Center for Perceptual Systems
% University of Texas at Austin
%
% jsp Mon Aug 11 13:43:02 CDT 2003

DEBUG=0;

fprintf('Testing kbdinit...\n');
kbdinit(DEBUG)
fprintf('Testing kbdgetkey...\n');
fprintf('Press Any Key\n');
while (1)
    k=kbdgetkey;
    if (not(isempty(k)))
        break;
    end
end
fprintf('Scancode = %d\n',k);
fprintf('Testing kbdflush...\n');
kbdflush;
fprintf('Testing kbdrelease...\n');
fprintf('Testing kbdpcscancodes...\n');
kbdpcscancodes
kbdrelease

%kbdinit(DEBUG)
%fprintf('\nkbdinit has been called\n\n');
%fprintf('All keystrokes will be ignored\n\n');
%fprintf('In order to release the kbd library and\n');
%fprintf('restore the Matlab command line, you must:\n\n');
%fprintf('1. PRESS ALT-F12...\n');
%k=input('2. Press ENTER...\n');
%kbdrelease
%fprintf('Success\n');

clear functions;
