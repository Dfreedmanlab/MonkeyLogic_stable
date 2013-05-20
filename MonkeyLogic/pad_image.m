function [padded_image, xis, yis, xbuf, ybuf] = pad_image(imdata, modval, varargin)
% Internal monkeylogic function.
% Created by WA, 1/18/08.
% Modified 5/1/08 -WA (to stretch, rather than corner-blit, images - results in minimal blank-space around images)
% Modified 7/25/08 -WA (to allow x- or y-dimension of image to be 1, and to skip this routine if xis & yis == modval)
% Modified 8/21/08 -WA (to make certain inputs for interpolation are of
% type "double"
[yis xis zis] = size(imdata);

if xis == 1 || yis == 1, %if xis or yis == 1, need to expand slightly for interp, below
    if ~isempty(varargin),
        bgcolor = varargin{1};
    else
        bgcolor = [0 0 0];
    end
    c(1, 1, 1:3) = bgcolor;
    if yis == 1,
        padding = repmat(c, 1, xis);
        imdata = cat(1, padding, imdata, padding);
        yis = 3;
    end
    if xis == 1,
        padding = repmat(c, yis, 1);
        imdata = cat(2, padding, imdata, padding);
        xis = 3;
    end
end

if ~mod(xis, modval) && ~mod(yis, modval), %no need to resize image
    xbuf = xis;
    ybuf = yis;
else %stretch image to be multiple of modval on each side
    modx = mod(xis, modval);
    difx = 0;
    if modx > 0,
        difx = modval-modx;
    end

    mody = mod(yis, modval);
    dify = 0;
    if mody > 0,
        dify = modval-mody;
    end

    xbuf = xis + difx;
    ybuf = yis + dify;

    [x y] = meshgrid(1:(xis-1)/(xbuf-1):xis, 1:(yis-1)/(ybuf-1):yis);
    zi = cell(zis, 1);
	if ~isa(imdata, 'double'),
        imdata = double(imdata);
	end
	
	for i = 1:zis,
        zi{i} = interp2(imdata(:, :, i), x, y);
	end
	
    imdata = cat(3, zi{:});
end

if max(max(max(imdata))) <= 1,
    imdata = imdata * 255;
end
imdata = floor(imdata);
padded_image = uint8(imdata);