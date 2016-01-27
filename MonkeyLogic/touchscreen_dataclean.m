function [cleaned_data] = touchscreen_dataclean(data_stream)

%data_stream = [-180 -180 -180 -180 -180 -180 -180 1 2 3 -180 -180 1 2 3 -180 2 -180 -180 -180 -180 -180 -180]; %test case
% -180 is the BLANK value to replace with a valid sample

if (length(find(data_stream~=-180)) > 2)
    cleaned_data = interp1(find(data_stream~=-180),data_stream(data_stream~=-180), 1:length(data_stream),'nearest','extrap');
else 
    indexes = find(data_stream~=-180);
    
    if (isempty(indexes))
        cleaned_data =  0;
    else
        cleaned_data = data_stream(indexes);
    end
end
% end of function