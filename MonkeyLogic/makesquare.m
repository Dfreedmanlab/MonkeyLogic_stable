function sqr = makesquare(sz, rgb, fillflag, varargin)
%SYNTAX:
%        sqr = makesquare(size, rbg, fillflag, [rotation], [bgcolor])
%
% Size is in pixels.  Rotation is optional and is in degrees. bgcolor is
% optional and is specified as an RGB triplet (must specify rotation if
% will specify bgcolor).

if length(sz) == 1,
    xs = round(sz);
    ys = round(sz);
else
    xs = round(sz(1));
    ys = round(sz(2));
end

sqr = ones(ys, xs);

if fillflag == 0,
    bordersz = round(0.15 * min([xs ys]));
    sqr(bordersz:(ys-bordersz+1), bordersz:(xs-bordersz+1)) = 0;
end

if ~isempty(varargin),
    if length(varargin) == 1 && length(varargin{1}) == 1,
        theta = varargin{1};
        bgcolor = [0 0 0];
    elseif length(varargin) == 1 && length(varargin{1}) > 1,
        bgcolor = varargin{1};
        theta = 0;
    elseif length(varargin) == 2 && length(varargin{1}) == 1,
        theta = varargin{1};
        bgcolor = varargin{2};
    elseif length(varargin) == 2 && length(varargin{1}) > 1,
        bgcolor = varargin{1};
        theta = varargin{2};
    end
else
    theta = 0;
    bgcolor = [0 0 0];
end

if theta > 0,
    mtheta = mod(theta, 90);
    if mtheta > 45,
        mtheta = abs(mtheta - 90);
    end
    gfactor = 1 + (abs(tan(pi*mtheta/180)));
    bxs = round(gfactor*xs);
    bys = round(gfactor*ys);
    x1 = round(xs*(gfactor-1)/2);
    y1 = round(ys*(gfactor-1)/2);
    bsqr = zeros(bys, bxs);
    bsqr(y1+1:y1+ys, x1+1:x1+xs) = sqr;
    sqr = imrotate(bsqr, theta, 'crop');
end

if max(max(sqr)) > 0,
    sqr = sqr./max(max(sqr));
end
sqr = repmat(sqr, [1 1 3]);
sqr(:, :, 1) = sqr(:, :, 1).*(rgb(1) - bgcolor(1)) + bgcolor(1);
sqr(:, :, 2) = sqr(:, :, 2).*(rgb(2) - bgcolor(2)) + bgcolor(2);
sqr(:, :, 3) = sqr(:, :, 3).*(rgb(3) - bgcolor(3)) + bgcolor(3);

