left = 1;           %left target number
right = 2;          %right target number
windowSize = 1.5;   %degrees of visual angle surrounding the target. I believe this is the diameter (not radius)
duration = 3000;    %in milliseconds

toggleobject([left right], 'Status', 'on');

ontarget = eyejoytrack('acquirefix', [left right], windowSize, duration);
if ~ontarget,
     trialerror(4); % no response
     toggleobject([left right], 'Status', 'off');
     set_iti(10);
     return
end


set_iti(0);