function prtinit ()
% PRTINIT	Set a keyboard hook, ALT-F12, for returning to normal priority.
% 
% PRTINIT will set a keyboard hook.  This is a safeguard against losing
% processor control when a process is running with realtime priority.
% 
% It is not necessary to call this function before calling other
% functions in the library.
% 
% SEE ALSO: PRTRELEASE, PRTREALTIME
% 
% EXAMPLES: EXSTABILIZE, EXLATENCY

% Mexgen generated this file on Wed Apr 21 14:07:32 2004
% DO NOT EDIT!

prtmex (0);
