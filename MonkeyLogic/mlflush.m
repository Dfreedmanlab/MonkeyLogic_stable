%mlflush


mlvideo('flush');
daqreset;
if verLessThan('matlab', '8')
    sound clear;
else
    clear sound;
end
clear all;
fclose all;
close all;
