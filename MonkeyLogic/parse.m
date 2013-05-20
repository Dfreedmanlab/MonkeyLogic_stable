function output = parse(input, varargin)
% separates tab-delimited info, the optional argument 'space' will use
% spaces instead of the default use of tabs.  If a number is included as
% the optional input, the character 'char(num)' will be used as the
% separator (for example, 44 for comma-delimited text).  A single 
% separator character can also be specified as a string, (e.g., a 
% comma as ',').
%
% created Spring, 1997  --WA
% last modified 8/30/07 --WA

sepchar = 9;

if ~isempty(varargin),
    sp = varargin{:};
    if strcmpi(sp, 'space'),
        sepchar = 32;
    elseif isnumeric(sp),
        sepchar = sp;
    elseif length(sepchar) == 1,
        sepchar = double(sepchar);
    else
        error('Unknown option using "parse"...');
    end
end

input = double(input);
tabs = find(input == sepchar);
if isempty(tabs),
    output = deblank(char(input));
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
output = zeros(length(tabs)-1, max(diff(tabs)));
output = output + 32;
output = char(output);

item_counter = 0;
tab_counter = 1;

while tab_counter < length(tabs),
    if (tabs(tab_counter+1) - tabs(tab_counter)) > 1,
        item = input(tabs(tab_counter)+1:tabs(tab_counter+1)-1);
        item_counter = item_counter + 1;
        output(item_counter, 1:length(item)) = item;
    end
    tab_counter = tab_counter + 1;
end

output = output(1:item_counter, :);
output = deblank(output);