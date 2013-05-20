function output = parse_object(input, varargin)

sepchar = 9; %tab

if ~isempty(varargin),
    sp = varargin{:};
    if strcmpi(sp, 'space'),
        sepchar = 32;
    elseif isnumeric(sp),
        sepchar = sp;
    else
        sepchar = double(sp(1));
    end
end

input = double(input);
tabs = find(input == sepchar);
if isempty(tabs),
   output = {deblank(char(input))};
   return
end

while min(tabs == 1),
   input = input(2:length(input));
   tabs = find(input == sepchar);
end
% frame input with tabs:
il = length(input);
new_input = zeros(il+2, 1);
new_input(2:il+1) = input;
input = new_input;
input(1) = sepchar;
input(il+2) = sepchar;
tabs = find(input == sepchar);
input = char(input);

item_counter = 0;
tab_counter = 1;

while tab_counter < length(tabs),
   if (tabs(tab_counter+1) - tabs(tab_counter)) > 1,
      item = input(tabs(tab_counter)+1:tabs(tab_counter+1)-1);
      if size(item, 1) > size(item, 2),
          item = item';
      end
      item_counter = item_counter + 1;
      while strcmp(item(1), ' '),
          item = item(2:length(item));
      end
      output{item_counter} = deblank(item);
   end
   tab_counter = tab_counter + 1;
end

