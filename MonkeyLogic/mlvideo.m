function result = mlvideo(fxn, varargin)
%SYNTAX LIST:
%  mlvideo('mlinit');
%  mlvideo('init');
%  devices = mlvideo('devices');
%  mlvideo('initdevice', devicenum);
%  mlvideo('setmode', devicenum, screen_x_size, screen_y_size, bytesperpixel, refreshrate, bufferpages);
%  mlvideo('restoremode', devicenum);
%  mlvideo('releasedevice', devicenum);
%  buffer = mlvideo('createbuffer', devicenum, x_size, y_size, bytesperpixel);
%  mlvideo('copybuffer', devicenum, buffer, imagedata);
%  mlvideo('releasebuffer', buffer);
%  mlvideo('blit', buffer, screen_x_position, screen_y_position, image_x_size, image_y_size);
%  mlvideo('flip', devicenum);
%  mlvideo('clear', devicenum, backgroundcolor);
%  vblank = mlvideo('verticalblank', devicenum);
%  rasterline = mlvideo('rasterline', devicenum);
%  rasterline = mlvideo('waitflip', devicenum, raster_threshold);
%  mouseposition = mlvideo('getmouse')
%  mlvideo('setmouse', P)
%
%  This function requires the following video operations to be available:
%  1) Get the number of video devices
%  2) Initialize the screen resolution, bit-depth, refresh rate, and # of buffer pages
%  3) Create video buffer
%  4) Copy data to video buffer
%  5) Blit a buffer
%  6) Flip screen
%  7) Clear the back-buffer
%  8) Get vertical blank status
%  9) Get current raster line
% 10) Release a video buffer
% 11) Release a video device
% 12) Toggle the visibility of the mouse cursor
% 13) Get the mouse's position
% 14) Set the mouse's position
%
%  Created by WA January, 2008
%  Modified 8/12/08 -WA (added 'waitflip' fxn)

result = [];
fxn = lower(fxn);

persistent x_touch;
persistent y_touch;
persistent screen_ppd;

persistent logger;

logger = log4m.getLogger('monkeylogic.log');
logger.setCommandWindowLevel(logger.ALL); 
logger.setLogLevel(logger.ALL);

switch fxn
            
    case 'waitflip',
        %this function flips when it's ok to draw based upon two
        %criteria: 1) not vertical blank and 2) raster-line <= thresh; it
        %returns the raster-line at which the flip was called.  This
        %avoids multiple calls to "mlvideo."
        
        devicenum = varargin{1};
        thresh = varargin{2};
        
        vb = 1; 
        result = 0;
        while vb || result > thresh,
            [vb result] = xglgetrasterstatus(devicenum);
        end
        xglflip(devicenum);
        
    case 'verticalblank',
        
        devicenum = varargin{1};
        
        result = xglgetrasterstatus(devicenum);
        
    case 'rasterline',
        
        devicenum = varargin{1};
        
        [vb result] = xglgetrasterstatus(devicenum);
        
    case 'flip',
        
        devicenum = varargin{1};
        
        xglflip(devicenum);
        
    case 'mlinit',
        
        if exist('xglinit', 'file'),
            svidir = which('xglinit');
            svipath = fileparts(svidir);
            svidaq = [svipath filesep 'daqmex.dll'];
            if exist(svidaq, 'file'),
                evalstr = sprintf('!rename %s %s', svidaq, [svidaq(1:length(svidaq)-4) '_inactive.dll']);
                eval(evalstr); %rename daqmex which comes with SVI toolbox, as it interferes with the Matlab DAQ toolbox library by the same name
            end
        end

    case 'init',
        logger.info('mlvideo.m', '<<< MonkeyLogic >>> Initialized XGL - DirectX 9 fullscreen graphics layer for Matlab...');

        xglrelease;
        xglinit;
        
        x_touch = nan;
        y_touch = nan;
        if (~isempty(varargin))
            screen_ppd = varargin{1};
        end
        
    case 'devices',
        
        result = xgldevices;
        
    case 'initdevice',
        
        return
        
    case 'setmode',
        
        devicenum = varargin{1};
        screen_x_size = varargin{2};
        screen_y_size = varargin{3};
        bytesperpixel = varargin{4};
        refreshrate = varargin{5};
        bufferpages = varargin{6};
                
        if bytesperpixel == 3 || bytesperpixel == 4,
        	pf = xglpfrgb8;
        elseif bytesperpixel == 1,
            pf = xglpfgs;
        else
            error('Unsupported value for bytes per pixel');
        end

        xglinitdevice(devicenum, [screen_x_size screen_y_size pf refreshrate], bufferpages);
        xglflip(devicenum);
        xglflip(devicenum);
        
    case 'restoremode',
        
        return
    
    case 'releasedevice',
        
        devicenum = varargin{1};
        
        xglreleasedevice(devicenum);
        
    case 'release',
        
        xglrelease;
        x_touch = nan;
        y_touch = nan;
        
    case 'createbuffer',
        
        devicenum = varargin{1};
        xsize = varargin{2};
        ysize = varargin{3};
        bytesperpixel = varargin{4};
        
        if bytesperpixel == 3 || bytesperpixel == 4,
        	pf = xglpfrgb8;
        elseif bytesperpixel == 1,
            pf = xglpfgs;
        else
            error('Unsupported value for bytes per pixel');
        end
        
        result = xglcreatebuffer(devicenum, [xsize ysize pf]);
        
    case 'copybuffer',
        
        devicenum = varargin{1};
        buffer = double(varargin{2});
        imdata = varargin{3};
        
        if ~isa(imdata, 'uint32'),
            imdata = double(imdata);
            if ~any(imdata(:) > 1),
                imdata = ceil(255*imdata);
            end
            imdata = uint32(xglrgb8(imdata(:, :, 1)', imdata(:, :, 2)', imdata(:, :, 3)'));
        end
        
        xglcopybuffer(devicenum, buffer, imdata);
        
    case 'releasebuffer',
        
        devicenum = varargin{1};
        buffer = double(varargin{2});
        
        xglreleasebuffer(devicenum, buffer);
        
    case 'blit',
        
        devicenum = varargin{1};
        buffer = double(varargin{2});
        if length(varargin) > 2,
            screen_x_pos = varargin{3};
            screen_y_pos = varargin{4};
            image_x_size = varargin{5};
            image_y_size = varargin{6};
            
            xgl_pos = [xglrect(1); xglrect(2)]; % monitor positions by XGL

            width = xgl_pos(2,3);
            height = xgl_pos(2,4);
                       
            if (screen_x_pos < 0), screen_x_pos = 0; end
            if (screen_y_pos < 0), screen_y_pos = 0;end
            if (screen_x_pos >= width-image_x_size), screen_x_pos = width-image_x_size; end
            if (screen_y_pos >= height-image_y_size), screen_y_pos = height-image_y_size; end

            xglblit(devicenum, buffer, [screen_x_pos screen_y_pos image_x_size image_y_size]);
        else
            xglblit(devicenum, buffer);
        end
                
    case 'clear',
        
        devicenum = varargin{1};
        bgcolor = varargin{2};
        backbuffernum = 1;
        
        %xglclear(devicenum, backbuffernum, uint32(xglrgb8(bgcolor(1), bgcolor(2), bgcolor(3))));
        if max(bgcolor)<=1 && max(bgcolor) > 0
            bgcolor = bgcolor*255;
        end
        xglclear(devicenum, backbuffernum, rgbval(bgcolor));
        
    case 'showcursor',  % this will shows/hides the arrow pointer
        
        devicenum = varargin{1};
        val = varargin{2};
        
        xglshowcursor(devicenum, val);
        
    case 'flush',
        
        xglinit;
        numdev = xgldevices;
        for devicenum = 1:numdev,
            xglshowcursor(devicenum, 1);
            xglreleasedevice(devicenum);
        end
        xglrelease;
		
    case 'getmousebuttons'
		result = xglgetcursor_buttonstate;		
    
    case 'getmouse_pix'
		result = xglgetcursor;

	case 'getmouse'
		pos = xglgetcursor;

        xgl_pos = [xglrect(1); xglrect(2)]; % monitor positions by XGL

        obj.sub_offset_x = xgl_pos(2,1) + xgl_pos(2,3)/2;
        obj.sub_offset_y = xgl_pos(2,2) + xgl_pos(2,4)/2;
        obj.sub_ppd_x = screen_ppd;
        obj.sub_ppd_y = screen_ppd;
        
        result(1) =  (pos(1) - obj.sub_offset_x)/obj.sub_ppd_x;
        result(2) = -(pos(2) - obj.sub_offset_y)/obj.sub_ppd_y;
        
    case 'gettouch'

        mouse_state = xglgetcursor_buttonstate; %lets call xgl directly to get mouse button status

        left_button = mouse_state(1); % get Button State Left
        right_button = mouse_state(2); % get Button State Right

        if ( (left_button == 1) || (right_button == 1) ) % update touch location only if left or right mouse button is down

            pos = xglgetcursor; %get coordinates of touch

            xgl_pos = [xglrect(1); xglrect(2)]; % monitor positions by XGL

            obj.sub_offset_x = xgl_pos(2,1) + xgl_pos(2,3)/2; % finds the center pixels of the subject screen
            obj.sub_offset_y = xgl_pos(2,2) + xgl_pos(2,4)/2;
            obj.sub_ppd_x = screen_ppd;
            obj.sub_ppd_y = screen_ppd;

            x_touch = (pos(1) - obj.sub_offset_x)/obj.sub_ppd_x;
            y_touch = -(pos(2) - obj.sub_offset_y)/obj.sub_ppd_y;
        else
            x_touch = nan; %out of bounds
            y_touch = nan; %out of bounds
        end

        result(1) = x_touch;
        result(2) = y_touch;
        
    case 'setmouse'
		P = varargin{1};
		xglsetcursor(P);
end

function rgb = rgbval(rgb_in)

alpha = 0;
r = rgb_in(1);
g = rgb_in(2);
b = rgb_in(3);
rgb = bin2dec([dec2bin(alpha, 8) dec2bin(r, 8) dec2bin(g, 8) dec2bin(b, 8)]);
