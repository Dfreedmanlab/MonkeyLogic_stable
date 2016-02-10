% mllog will write a message to a log file and simultaneously output the same message to the console
%
%   February 5, 2016         Created by Edward Ryklin (edward@ryklinsoftware.com)
%

classdef mllog < handle

    properties %(Access = protected)
        fid = -1;
        numLines = -1;
    end % end of properties
    
    methods ( Access = 'public' )
                
        function obj = mllog(fileName)
            obj.openLogFile(fileName);
        end
        
        function delete(obj)
            obj.closeLogFile();
        end
        
        function openLogFile(obj, fileName)

            if (obj.fid > 0)
                obj.closeLogFile();
            end
            
            dirs = getpref('MonkeyLogic', 'Directories');
            logFileName = strcat(dirs.RunTimeDirectory, fileName);
            
            obj.fid = fopen(logFileName, 'w');
            obj.numLines = 0;
            if (obj.fid)
                obj.logMessage(sprintf('<<< %s.m >>> Created a new log file %s', class(obj), datestr(now)) );
            else 
                obj.logMessage(sprintf('<<< %s.m >>> Did not create a log file!', class(obj) ));
            end
        end
        
        function logMessage(obj, message)
            
            disp(message); % send message to Matlab Console if it exists
            
            obj.numLines = obj.numLines + 1;
            if (obj.fid > 0)   % send message to file if it exists
                message = sprintf('%i %s\r\n', obj.numLines, message);
                fprintf(obj.fid, message);
            else 
                fprintf('<<< %s.m >>> Did not log that message to file!\n', class(obj));
            end
        end
        
        function closeLogFile(obj)
            if (obj.fid > 0)
                obj.logMessage(sprintf('<<< %s.m >>> Closing log file %s', class(obj), datestr(now)));
                fclose(obj.fid);
            end
            obj.fid = 0;
        end
            
    end % end of methods

end % end of classdef mllog

