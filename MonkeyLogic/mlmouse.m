function data = mlmouse(fxn, varargin)
%SYNTAX LIST:
%  mlvideo('init');
%
%  Created by ER April, 2016

fxn = lower(fxn);

persistent screen_x;
persistent screen_y;
persistent x_touch;
persistent y_touch;
persistent screen_ppd;
persistent mouse;
persistent mouse_started;
persistent logger;

logger = log4m.getLogger('monkeylogic.log');
logger.setCommandWindowLevel(logger.ALL); 
logger.setLogLevel(logger.ALL);

switch fxn
            
    case 'setmode',
        if (~isempty(varargin))
            screen_x = varargin{1};
            screen_y = varargin{2};
            result = 1;
        end
        logger.info('mlmouse.m', '<<< MonkeyLogic >>> Touchscreen/Mouse Mode Set.');
        data = [];
        result = 0;
    case 'init',
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

    case 'start'
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
        data(1) = left;
        data(2) = right;
        result = 1;

    case 'getmouse_pix'
        if (mouse_started == false)
            start(mouse);	% start sampling
            mouse_started = true;
        end
        
        %logger.info('mlmouse.m', '<<< MonkeyLogic >>> getmouse_pix');
        [x,y,left,right,timestamp] = decodemouse(getsample(mouse));

        data(1) = x;
        data(2) = y;

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
        logger.info('mlmouse.m', '<<< MonkeyLogic >>> getallmousedata_pix');
        [x,y,left,right,timestamp] = decodemouse(getdata(mouse));
        
        data = [x y];
        
        result = 1;

    case 'getalltouchdata_pix'
        logger.info('mlmouse.m', '<<< MonkeyLogic >>> getalltouchdata_pix');
        [x,y,left,right,timestamp] = decodemouse(getdata(mouse));

        data = [x y];
        
        result = 1;
    
    case 'getallmousedata_degrees'
        logger.info('mlmouse.m', '<<< MonkeyLogic >>> getallmousedata_degrees');
        [x,y,left,right,timestamp] = decodemouse(getdata(mouse));
        
        data = [(x - screen_x)/screen_ppd -(y - screen_y)/screen_ppd] ;
        
        result = 1;

    case 'getalltouchdata_degrees'
        logger.info('mlmouse.m', '<<< MonkeyLogic >>> getalltouchdata_degrees');
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