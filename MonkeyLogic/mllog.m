% mllog will write a message to a log file and simultaneously output the same message to the console
%
%   February 5, 2016         Created by Edward Ryklin (edward@ryklinsoftware.com)
%

classdef mllog < handle

    properties %(Access = protected)
        fid = 0;
        numLines = 0;
    end % end of properties
    
    methods
                
        function obj = mllog()
            obj.openLogFile();
        end
        
        function delete(obj)
            obj.closeLogFile();
        end
        
        function openLogFile(obj)

            if (obj.fid)
                obj.closeLogFile();
            end
            
            dirs = getpref('MonkeyLogic', 'Directories');
            fileName = strcat(dirs.RunTimeDirectory, 'ML.log');
            
            obj.fid = fopen(fileName, 'w');
            obj.numLines = 0;
            if (obj.fid)
                obj.logMessage(sprintf('<<< %s.m >>> Created a new log file %s', class(obj), datestr(now)) );
            else 
                obj.logMessage(sprintf('<<< %s.m >>> Did not create a log file!', class(obj) ));
            end
        end
        
        function logMessage(obj, message)
            
            disp(message); % send message to Matlab Console if it exists
            
            if (obj.fid > 0)   % send message to file if it exists
                message = sprintf('%s\r\n', message);
                fprintf(obj.fid, message);
                obj.numLines = obj.numLines + 1;
            else 
                obj.logMessage(sprintf('<<< %s.m >>> Did not log that message to file!', class(obj)));
            end
        end
        
        function closeLogFile(obj)
            if (obj.fid)
                obj.logMessage(sprintf('<<< %s.m >>> Closing log file %s', class(obj), datestr(now)));
                fclose(obj.fid);
            end
            obj.fid = 0;
        end
            
    end % end of methods

end % end of classdef ML_Log

