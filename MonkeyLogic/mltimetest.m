%mltimetest.m
%launched from "MonkeyLogic Latency Test" button in main menu

pic = 1;
mov = 2;
t = (1000*TaskObject(mov).NumFrames/ScreenInfo.RefreshRate) - 50;

toggleobject(pic);
idle(500);
toggleobject([pic mov]);
idle(t);
eyejoytrack(-6, 1); %turn benchmark ON
toggleobject(mov, 'MovieStep', -1, 'status', 'on');
idle(t);
toggleobject(mov, 'status', 'off');
T{1} = eyejoytrack(-6, 0); %turn benchmark OFF and retrieve data
idle(500);

eyejoytrack(-6, 1); %turn benchmark ON
toggleobject(pic);
idle(1000);
T{2} = eyejoytrack(-6, 0); %turn benchmark OFF and retrieve data
toggleobject(pic);
trialerror(0);
rt = T;

