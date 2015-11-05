function [cleaned_data] = touchscreen_dataclean(ex)

%ex = [-180 -180 -180 -180 -180 -180 -180 1 2 3 -180 -180 1 2 3 -180 2 -180 -180 -180 -180 -180 -180] %test case
%disp('starting touchscreen_dataclean')

exout = find (ex == -180);  % -180 is the BLANK value to replace with a valid sample

index = 1;
updateto = [];
groupfound = 0;

for index = 1:length(ex)
    
    if ( ex(index) == -180)
        groupfound = 1;
    else
        if (groupfound == 1)
            updateto = [updateto ex(index)];
        end
        groupfound = 0;
    end
end

%last value was also -180 and so groupfound was not terminated
if (groupfound == 1)
	updateto = [updateto updateto(length(updateto))];
    groupfound = 0;
end

index2 = 1;
for index=1:length(ex)
    
    if (ex(index) == -180)
        groupfound = 1;
        ex(index) = updateto(index2);
    else
        if (groupfound)
            index2 = index2+1;
            groupfound = 0;
    	end
    end
end

cleaned_data = ex;

% end of function

%'under utilization of labor resources;