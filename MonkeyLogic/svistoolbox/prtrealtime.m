function prtrealtime ()
% PRTREALTIME	Set the process priority to realtime.
% 
% PRTREALTIME will change the current process' priority
% to realtime mode.
% 
% WARNING: USE THIS FUNCTION WITH CAUTION.
% 
% A process should not be set to realtime priority for an extended
% period of time.  Therefore, it is advisable to use this function only
% within a Matlab script or function and to pair it with a call to
% PRTNORMAL.
% 
% SEE ALSO: PRTINIT, PRTNORMAL
% 
% EXAMPLES: EXSTABILIZE, EXLATENCY

% Mexgen generated this file on Wed Apr 21 14:07:32 2004
% DO NOT EDIT!

prtmex (3);
