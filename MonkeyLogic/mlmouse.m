%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% mlmouse.m
% Created by Edward Ryklin April 13, 2016
%
% Interfaces with the NIMH daqtoolbox to acquire mouse samples for
% MonkeyLogic
%
% Can get 1 sample (current mouse location), or all samples within a
% timespan. Typical usage is to first start acquisition then sometime later
% stop it and grab the entire range of data.
%
% Before using, initialize and set the pixels per degree and screen
% dimensions (which should already be scaled for the appropriate monitor
% number). See mlvideo.m which initializes mlmouse automatically.
%
% When grabbing data from a touchscreen, the left mouse button down signal
% is used to determine if contact was made. Otherwise, mouse samples are
% filtered out with the NaN value.
% 
% To test this program independent of ML, follow these instructions:
%
% 1) mlmouse('init', 30); % assume 30 pixels per degree for testing
%
% 2) mlmouse('setmode', 1920, 1200); % enter your screen dimensions. If you
%    are using a second monitor, you will need to compute the offset yourself
%    (like -1920, or where ever it's located in space)
%
% 3) mlmouse('start'); % confirmation message will be printed in the matlab
%    command line
%
% 4) You can now start calling all of the mouse 'get' functions.
%
% 5) Don't forget to call mlmouse('stop') when you are done
%
% 6) plot(mlmouse('getallmousedata_degrees')) % will show a graph of all
%    your mouse activity from the moment mlmouse('start') was called.
%
% 7) data = mlmouse('getallmousedata_degrees')); plot(data(:,1), datda(:,2))
%    will display a cartesian plot of your mouse behavior, which is probably
%    would you want to see.
%
% Final note; there are mouse and touch functions. The difference is that
% the touch functions expect that the left mouse button is down while
% dragging the mouse. This simulates typical and basic touchscreen behavior.
% It works by nulling out those samples in the data stream which did not
% have a corresponding left button down sample. The timestamp of each
% sample is also recorded and supplied for option use.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data = mlmouse(fxn, varargin)

fxn = lower(fxn);

persistent screen_x;
persistent screen_y;
persistent x_touch;
persistent y_touch;
persistent screen_ppd;
persistent mouse;
persistent mouse_started;
persistent mouse_initialized;
persistent mouse_modeset;
persistent logger;

logger = log4m.getLogger('monkeylogic.log');
logger.setCommandWindowLevel(logger.ALL); 
logger.setLogLevel(logger.ALL);

switch fxn
            
    case 'init',
        mouse_initialized = true;
        logger.info('mlmouse.m', '<<< MonkeyLogic >>> Touchscreen/Mouse Initialized.');
        mouse = pointingdevice;

        x_touch = nan;
        y_touch = nan;
        screen_ppd = varargin{1};
        data = [];
        if (mouse_started == true)
            stop(mouse);	% stop sampling
            mouse_started = false;  % make sure it's stoppped
            result = 1;
        else 
            mouse_started = false;  % make sure it's stoppped
            result = 0;
        end
    case 'setmode',
        if (~isempty(varargin))
            screen_x = varargin{1};
            screen_y = varargin{2};
            result = 1;
        end
        mouse_modeset = true;
        logger.info('mlmouse.m', '<<< MonkeyLogic >>> Touchscreen/Mouse Mode Set.');
        data = [];
        result = 0;
    case 'start'
        
        if isempty(mouse_initialized) || isempty(mouse_modeset)
            logger.info('mlmouse.m', '<<< MonkeyLogic >>> Mouse is not initialized.');
        end
        
        if (mouse_started == false)
            start(mouse);	% start sampling
            logger.info('mlmouse.m', '<<< MonkeyLogic >>> Mouse acquisition has started.');
            mouse_started = true;
            result = 1;
        end 
        data = [];
        result = 0;
    case 'stop'
        if (mouse_started == true)
            stop(mouse);	% stop sampling
            logger.info('mlmouse.m', '<<< MonkeyLogic >>> Mouse acquisition has stopped.');
            result = 1;
        end
        mouse_started = false;
        data = [];
        result = 0;
    case 'getmousebuttons'
        if (mouse_started == false)
            start(mouse);	% start sampling
            mouse_started = true;
        end
        
        %logger.info('mlmouse.m', '<<< MonkeyLogic >>> getmousebuttons');
        [x,y,left,right,timestamp] = decodemouse(getsample(mouse));
        data = [left right];
        result = 1;

    case 'getmouse_pix'
        if (mouse_started == false)
            start(mouse);	% start sampling
            mouse_started = true;
        end
        
        %logger.info('mlmouse.m', '<<< MonkeyLogic >>> getmouse_pix');
        [x,y,left,right,timestamp] = decodemouse(getsample(mouse));

        data = [x y];

        result = 1;

    case 'gettouch_pix'
        if (mouse_started == false)
            start(mouse);	% start sampling
            mouse_started = true;
        end
        
        %logger.info('mlmouse.m', '<<< MonkeyLogic >>> getmouse_pix');
        [x,y,left,right,timestamp] = decodemouse(getsample(mouse));

        if ( (left == 1) || (right == 1) ) % update touch location only if left or right mouse button is down
            
            x_touch =  (x - screen_x)/screen_ppd;
            y_touch = -(y - screen_y)/screen_ppd;
        
        else
            x_touch = nan; %out of bounds
            y_touch = nan; %out of bounds
        end

        data(1) = x_touch;
        data(2) = y_touch;
        
        result = 1;

    case 'getmouse_degrees'
        if (mouse_started == false)
            start(mouse);	% start sampling
            mouse_started = true;
        end
        
        %logger.info('mlmouse.m', '<<< MonkeyLogic >>> getmouse_degrees');
        [x,y,left,right,timestamp] = decodemouse(getsample(mouse));
		
        data(1) =  (x - screen_x)/screen_ppd;
        data(2) = -(y - screen_y)/screen_ppd;
             
        result = 1;
        
    case 'gettouch_degrees'
        if (mouse_started == false)
            start(mouse);	% start sampling
            mouse_started = true;
        end
        
        %logger.info('mlmouse.m', '<<< MonkeyLogic >>> gettouch_degrees');
        [x,y,left,right,timestamp] = decodemouse(getsample(mouse));

        if ( (left == 1) || (right == 1) ) % update touch location only if left or right mouse button is down
            
            x_touch =  (x - screen_x)/screen_ppd;
            y_touch = -(y - screen_y)/screen_ppd;
        
        else
            x_touch = nan; %out of bounds
            y_touch = nan; %out of bounds
        end

        data(1) = x_touch;
        data(2) = y_touch;
        
        result = 1;
    case 'getallmousedata_pix'
        %logger.info('mlmouse.m', '<<< MonkeyLogic >>> getallmousedata_pix');
        [x,y,left,right,timestamp] = decodemouse(getdata(mouse));
        
        data = [x y];
        
        result = 1;

    case 'getalltouchdata_pix'
        %logger.info('mlmouse.m', '<<< MonkeyLogic >>> getalltouchdata_pix');
        [x,y,left,right,timestamp] = decodemouse(getdata(mouse));

        no_contact_made_indexes = find(left==0);
          
        data = [(x - screen_x)/screen_ppd -(y - screen_y)/screen_ppd] ;
        data(no_contact_made_indexes, :) = NaN;
       
        result = 1;
    
    case 'getallmousedata_degrees'
        %logger.info('mlmouse.m', '<<< MonkeyLogic >>> getallmousedata_degrees');
        [x,y,left,right,timestamp] = decodemouse(getdata(mouse));
        
        data = [(x - screen_x)/screen_ppd -(y - screen_y)/screen_ppd] ;
        
        result = 1;

    case 'getalltouchdata_degrees'
        %logger.info('mlmouse.m', '<<< MonkeyLogic >>> getalltouchdata_degrees');
        [x,y,left,right,timestamp] = decodemouse(getdata(mouse));
       
        no_contact_made_indexes = find(left==0);
          
        data = [(x - screen_x)/screen_ppd -(y - screen_y)/screen_ppd] ;
        data(no_contact_made_indexes, :) = NaN;
       
        result = 1;
        
    otherwise
        logger.info('mlmouse.m', '<<< MonkeyLogic >>> That command does not exist');
        data = [];
        result = 0;
        
end