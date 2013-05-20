function output = smooth(inpt, window, kernel_type)
% Smoothing function: 
% output = smooth(inpt, window, type)
% "Type" should be set to 'gauss' for a gaussian kernel or to 'boxcar'
% for a simple moving window average.  "Window" is the total kernel width.
% Input array must be one-dimensional.
%
% last modified November, 1999  -- WA

inpt_dims = ndims(inpt);
inpt_size = size(inpt);
if inpt_dims > 2 || min(inpt_size) > 1,
   disp('Input array is too large.');
   return
end

if window < 1 || (window ~= round(window)),
   error('********** Invalid smooth window argument **********');
   return
end

if window == 1,
   output = inpt;
   return
end

if strcmp(kernel_type(1:3), 'bin'),
   if inpt_size(1) > inpt_size(2),
      inpt = inpt';
      toggle_dims = 1;
   else
      toggle_dims = 0;
   end
   output = bin_data(inpt, window);
   if toggle_dims == 1,
      output = output';
   end
   return
end

if inpt_size(2) > inpt_size(1),
   inpt = inpt';
   toggle_dims = 1;
else
   toggle_dims = 0;
end

if window/2 ~= round(window/2),
   window = window + 1;
end
halfwin = window/2;

inpt_length = length(inpt);

if strcmp(kernel_type(1:5), 'gauss'),
   x = -window:window;
   kernel = exp(-(x.^2)/((window/2)^2));
   window = round(1.5*window);
else
   kernel = ones(window, 1);
end
kernel = kernel/sum(kernel);

mn1 = mean(inpt(1:halfwin));
mn2 = mean(inpt((inpt_length-halfwin):inpt_length));
padded(halfwin+1:inpt_length+halfwin) = inpt;
padded(1:halfwin) = ones(halfwin, 1)*mn1;;
padded(length(padded)+1:length(padded)+halfwin) = ones(halfwin, 1)*mn2;

output = conv(padded, kernel);
output = output(window+1:inpt_length+window);

if toggle_dims == 0,
   output = output';
end
