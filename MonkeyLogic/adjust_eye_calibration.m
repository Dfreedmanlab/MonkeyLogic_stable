function newTform = adjust_eye_calibration(eyedata, Txy, DaqInfo, oldTform, adjustfraction, maxradius, minfixtime, sigma, targetlist)
%created by WA, February, 2007
%last modified 6/25/07 -WA

%PARAMETERS:
calthresh = 3; %degrees within which a standard calibration point will be tossed out.
adjustfraction = adjustfraction/100; %eye adjustment fraction (0 to 1)
velthresh = 2; %no. of standard deviations of eye velocity below which is considered fixation
% *** sigma:
% sigma for eye velocity smoothing gaussian (milliseconds)
% *** maxradius:
% the radius within which any fixations will be considered as landing on 
% the same visual object (in degrees of visual angle)
% *** minfixtime:
% the minimum time they eyes must be ~stationary to count as a fixation

newTform = oldTform;
if isempty(eyedata),
    return
end

thisisonlyatest = 0;
if isempty(Txy),
    return
elseif Txy(1) == -99999,
    thisisonlyatest = 1;
end
frq = DaqInfo.AnalogInput.SampleRate;
if isempty(targetlist),
    xcal = [-5 5 5 -5 0]; %default calibration points
    ycal = [5 5 -5 -5 0];
else
    xcal = targetlist(:, 1)';
    ycal = targetlist(:, 2)';
end
numcal = length(xcal);

%smooth eye data and calculate eye velocities
x = eyedata(:, 1);
y = eyedata(:, 2);
numdatapoints = length(x);
halfwin = ceil(3*frq*sigma/1000);
k = -halfwin:halfwin;
smoothkernel = exp(-(k.^2)/(sigma^2));
smoothkernel = smoothkernel/sum(smoothkernel);
x = conv(x, smoothkernel);
y = conv(y, smoothkernel);
x = x(halfwin:numdatapoints-halfwin);
y = y(halfwin:numdatapoints-halfwin);
v = frq*realsqrt((diff(x).^2) + (diff(y).^2));

%find fixations
saccadethreshold = velthresh*std(v);
fixation = v < saccadethreshold;
disp('fixation')
size(fixation)
disp('v')
size(v)

fixation = cat(1, 0, fixation, 0);
dfix = diff(fixation);
startfix = find(dfix == 1);
endfix = find(dfix == -1);

%expand saccade detection area to compensate for smoothing artifact
if max(startfix) > max(endfix),
    endfix = cat(1, endfix, length(x));
end
if min(endfix) < min(startfix),
    startfix = cat(1, 1, startfix);
end
sacshift = ceil(1.5*sigma);
startfix = startfix + sacshift;
endfix = endfix - sacshift;
indx = (endfix > startfix) & (startfix < length(x)) & (endfix > 1);
startfix = startfix(indx);
endfix = endfix(indx);
if max(startfix) > max(endfix), %need to repeat now that points are shifted
    endfix = cat(1, endfix, length(x));
end
if min(endfix) < min(startfix),
    startfix = cat(1, 1, startfix);
end

%select fixations with length > minfixtime
minfixpoints = minfixtime*frq/1000;
fixtime = endfix - startfix;
longfix = fixtime > minfixpoints;
startfix = startfix(longfix);
endfix = endfix(longfix);
numfix = length(startfix);

%Get average fixation positions
xfix = zeros(1, numfix);
yfix = zeros(1, numfix);
for i = 1:numfix,
    xfix(i) = mean(x(startfix(i):endfix(i)));
    yfix(i) = mean(y(startfix(i):endfix(i)));
end

%calculate distance between fix locations and pics, and select < maxradius
numpics = size(Txy, 1);
xpic = Txy(:, 1);
ypic = Txy(:, 2);
XP = repmat(xpic, 1, numfix);
YP = repmat(ypic, 1, numfix);
XF = repmat(xfix, numpics, 1);
YF = repmat(yfix, numpics, 1);
Xdiff = XP - XF;
Ydiff = YP - YF;
D = realsqrt((Xdiff.^2) + (Ydiff.^2));
M = D < maxradius;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  Should eliminate ambiguous fixations.
try    
    whichfixs = find(sum(M, 1)==1);
    numfix = length(whichfixs);
    xfix = xfix(whichfixs);
    yfix = yfix(whichfixs);
    XP = repmat(xpic, 1, numfix);
    YP = repmat(ypic, 1, numfix);
    XF = repmat(xfix, numpics, 1);
    YF = repmat(yfix, numpics, 1);
    if isempty(XP) && isempty(XF),
        return
    end
    Xdiff = XP - XF;
    Ydiff = YP - YF;
    D = realsqrt((Xdiff.^2) + (Ydiff.^2));
    M = D < maxradius;
catch Err
    fprintf('adjust_eye_calibration error.\n');
    fprintf('%s\n',getReport(Err));
    XP
    XF
    error('Monkeylogic escaped.');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
whichpics = find(any(M, 2));
numvalidfixations = length(whichpics);
xpic_visits = xpic(whichpics);
ypic_visits = ypic(whichpics);

%adjust fixations by a fraction & avg multiple fixations on same object:
XF = XF + (1-adjustfraction)*Xdiff;
YF = YF + (1-adjustfraction)*Ydiff;
NaNmask = zeros(size(XF))*NaN;
NaNmask(M) = 1;
XF = XF.*NaNmask;
YF = YF.*NaNmask;
XF = XF(whichpics, :);
YF = YF(whichpics, :);
xfix_adjusted = nanmean(XF, 2);
yfix_adjusted = nanmean(YF, 2);
[ixfix iyfix] = tforminv(oldTform, xfix_adjusted, yfix_adjusted);

%calculate distance between fixated pics and default calibration points
%...toss out default points that are < calthresh degrees from any pics
%...the remaining default calibration points will anchor the new transform
xpcal = repmat(xpic, 1, numcal);
ypcal = repmat(ypic, 1, numcal);
xfcal = repmat(xcal, numpics, 1);
yfcal = repmat(ycal, numpics, 1);
dcal = realsqrt(((xpcal-xfcal).^2) + ((ypcal-yfcal).^2));
rcal = dcal > calthresh;
usecal = any(rcal, 1);
xcal = xcal(usecal)';
ycal = ycal(usecal)';
[ixcal iycal] = tforminv(oldTform, xcal, ycal);

%create input (ip) & reference (cp) transform arrays
cp = cat(1, [xpic_visits ypic_visits], [xcal ycal]);
ip = cat(1, [ixfix iyfix], [ixcal iycal]);

numvalidfixations = numvalidfixations + length(xcal);
if numvalidfixations < 4 && ~thisisonlyatest, %not enough points to make at least a projective transform
    return
end

newTform = cp2tform(ip, cp, 'projective');

if ~thisisonlyatest,
    %plot original fix locations (red) and adjusted locations (green)
    axes(findobj('tag', 'replica'));
    [xfixraw yfixraw] = tforminv(oldTform, xfix, yfix);
    [xfixnew yfixnew] = tformfwd(newTform, xfixraw, yfixraw);
    h = zeros(1, 3);
    h(1) = plot(xcal, ycal, 'bo');
    set(h(1), 'markersize', 10, 'linewidth', 2.5);
    if ~isempty(xfix),
        h(2) = plot(xfix, yfix, 'r.');
        h(3) = plot(xfixnew, yfixnew, 'g.');
        set(h(2), 'markersize', 30);
        set(h(3), 'markersize', 25);
    end
    drawnow;
else
    newTform = struct;
    newTform.CalPoints = [xcal ycal];
    newTform.FixPoints = [xfix' yfix'];
    newTform.SaccadeThreshold = saccadethreshold;
    newTform.RawEyeData = eyedata;
    newTform.SmoothedEyeData = [x y];
    newTform.EyeVelocity = v;
    newTform.StartFixation = startfix;
    newTform.EndFixation = endfix;
    %save('c:\data\aec.mat');
    %pause(5);
end
