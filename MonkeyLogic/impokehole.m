function outputimage = impokehole(inputimage, holeradius)
% SYNTAX:
%        cdata = impokehole(inputimagefile, holeradius)
%
% This function pokes a hole into the center of the specified image
% (intended for placing a fixation spot into that space during task
% execution).  The input variable holeradius is in pixels. Use imwrite 
% to save the cdata as an image file (e.g., jpg) if it is satisfactory.
%
% Created by WA 3/14/07

c = imread(inputimage);
[y x z] = size(c);
halfy = ceil(y/2);
halfx = ceil(x/2);

[X Y] = meshgrid(-halfx:halfx, -halfy:halfy);
R = sqrt((X.^2) + (Y.^2));
D = 1./(1+exp(-((R-(0.5*holeradius))/(0.1*holeradius))));
D = D(2:y+1, 2:x+1);
D = repmat(D, [1 1 3]);
outputimage = uint8(round(D.*double(c)));

figure;
image(outputimage);
axis equal;
axis off;
