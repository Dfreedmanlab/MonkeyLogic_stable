fix = 1;
mov = 2;

toggleobject(fix);
ontarget = eyejoytrack('acquirefix', fix, 360, 5000);
if ~ontarget,
     trialerror(4); % no fixation
     toggleobject(fixation_point)
     return
end

%toggleobject(mov)
ontarget = eyejoytrack(-7,mov,360,10000);
if ~ontarget,
    trialerror(4);
    toggleobject(mov)
    return
end