fix = 1;
mov1 = 2;
mov2 = 3;
mov3 = 4;
mov4 = 5;
mov5 = 6;

toggleobject(fix);
ontarget = eyejoytrack('acquirefix', fix, 360, 5000);
if ~ontarget,
     trialerror(4); % no fixation
     toggleobject(fixation_point);
     return
end

ontarget = eyejoytrack(-7,mov1,360,10000);
if ~ontarget
    trialerror(4);
    toggleobject([mov1 mov2 mov3 mov4 mov5], 'status', 'off');
    return
end