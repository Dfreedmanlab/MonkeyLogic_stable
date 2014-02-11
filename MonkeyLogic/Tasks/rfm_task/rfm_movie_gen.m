clear all

% rectangle properties
rXv = [0 4 4 0];
rYv = [4 4 0 0];
dViewAngle = 8; % increment change in view angle degrees
                % don't need this now. Size will be set using the figure
                % size.
                
% parameters
ratios = [2/3 1/3 1/6]; % aspect ratio = 1:ratio
rgb = [1 1 1; 1/2 1/2 1/2; 0 0 0]; % gray-scale color palatte
rotAngle = 22.5; % rotation angles
numSizes = 1;
numShapes = 1;
numColors = length(rgb);
numRatios = length(ratios);
numRots = 8;

nFrames = numColors*numSizes*numShapes*numRatios*numRots;

% Preallocate movie structure.
mov(1:nFrames) = struct('cdata', [],...
                        'colormap', []);


% start up figure for image capture                    
figure;
pos = get(gcf,'Position');
set(gcf,'Position',[pos(1:2) 128 128]);
hold on;
axis([0 4 0 4]);
set(gca, 'nextplot','replacechildren');
set(gca, 'Visible','Off');
set(gcf, 'Color',[0 0 0]);
defViewAngle = get(gca,'CameraViewAngle') + 2;

shapeCounter = 0;
x = rXv;
y = rYv;
for rot = 1:numRots
	rotCounter = (rot - 1)*(numColors*numSizes*numRatios);
	camroll(rotAngle); % rotate camera for rotated stimulus
	for ratio = 1:numRatios
		ratioCounter = (ratio - 1)*(numColors*numSizes);
		for size = 1:numSizes
% 			set(gca,'CameraViewAngle',defViewAngle + dViewAngle); % change camera field of view to change stimulus size
                                                                  % don't need this anymore 
			sizeCounter = (size-1)*numColors;
			for color = 1:numColors
				patch(x,y*ratios(ratio),rgb(color,:))
				axis equal;
				mov(color+sizeCounter+ratioCounter+rotCounter+shapeCounter) = getframe(gcf);
				set(findobj('Type','patch'),'Visible','Off');
			end
		end
	end
end

movie2avi(mov, 'rfm_mov5.avi','Compression','indeo5');
