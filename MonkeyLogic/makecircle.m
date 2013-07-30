function crc = makecircle(diameter, rgb, fillflag, varargin)
%SYNTAX:
%        crc = makecircle(diameter, [r g b], fillflag, bgcolor)
%
% diameter is in pixels. bgcolor is background color (optional).
%
% created by WA 7/06
% last modified 9/3/06 -WA

radius = 0.5 * diameter;
r2 = round(1.2 * radius);
i = -r2:1:r2;
[x y] = meshgrid(i);

crc = sqrt((x.^2) + (y.^2));

if fillflag == 0,
    thresh = 0;
    crc = radius - abs((radius - crc).^2);
    crc = crc.*(crc > thresh);
else
    inner = double(crc < radius);
    outer = double(crc >= radius);
    outer = radius - (outer.*(abs(crc - radius).^2));
    outer = outer.*(outer >= 0);
    crc = inner + outer;
end

crc = crc./max(max(crc));
crc = repmat(crc, [1 1 3]);

if isempty(varargin),
    crc(:, :, 1) = crc(:, :, 1).*rgb(1);
    crc(:, :, 2) = crc(:, :, 2).*rgb(2);
    crc(:, :, 3) = crc(:, :, 3).*rgb(3);
else
    bgcolor = varargin{1};
    crc(:, :, 1) = crc(:, :, 1).*(rgb(1) - bgcolor(1)) + bgcolor(1);
    crc(:, :, 2) = crc(:, :, 2).*(rgb(2) - bgcolor(2)) + bgcolor(2);
    crc(:, :, 3) = crc(:, :, 3).*(rgb(3) - bgcolor(3)) + bgcolor(3);
end