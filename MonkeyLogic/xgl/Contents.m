% XGL Toolbox
%
% Version 1.2
% Mon, Sep 21, 2015  5:00:00 PM
%
% Copyright (C) 2015
% Jeffrey S. Perry
% Wilson S. Geisler
% Center for Perceptual Systems
% University of Texas at Austin
%
% XGLINIT               Initialize the xgl library.
% XGLRELEASE            Release the xgl library.
% XGLINFO               Get device info.
% XGLRECT               Get device screen desktop rectangle.
% XGLDEVICES            Return the number of graphics devices in the system.
% XGLTOTALMODES         Get the total number of modes for a device.
% XGLCURRENTMODE        Get the device's current video mode
% XGLGETMODE            Get a video mode specification for a device
% XGLHWCONVERSION       Determine hardware conversion support
% XGLINITDEVICE         Initialize the specified device.
% XGLRELEASEDEVICE      Release the specified device.
% XGLSETLUT             Set a device's lookup, or gamma, table.
%
% XGLCREATEBUFFER       Create an offscreen memory buffer.
% XGLRELEASEBUFFER      Release an offscreen memory buffer.
% XGLRELEASEBUFFERS     Release all offscreen memory buffers.
% XGLCLEARBUFFER        Clear a device's offscreen memory buffer.
% XGLCOPYBUFFER         Copy pixels to offscreen memory.
% XGLCLEAR              Clear a device's backbuffer.
% XGLBLIT               Blit offscreen memory to video memory.
% XGLFLIP               Flip the backbuffer.
% XGLGETRASTERSTATUS    Get the state of the current raster
%
% XGLPFGS               Grayscale pixel format value.
% XGLPFRGB10            RGB10 pixel format value.
% XGLPFRGB8             RGB8 pixel format value.
% XGLPFRGBF32           RGBF32 pixel format value.
% XGLPFYV12             YV12 pixel format value.
% XGLRGB10              Convert RGB values to RGB10 values.
% XGLRGB8               Convert RGB values to RGB8 values.
%
% XGLTOTALFONTS         Get the number of fonts available.
% XGLFONTNAME           Get a font name.
% XGLTEXTHEIGHT         Get the height in pixels of text.
% XGLTEXTWIDTH          Get the width in pixels of a text string.
% XGLSETBGCOLOR         Set the current text background color.
% XGLSETBGTRANS         Set the current text background transparency.
% XGLSETCURSOR          Set the cursor position.
% XGLSETESCAPEMENT      Set text escapement
% XGLSETFONT            Set the current font.
% XGLSETITALIC          Set text italics attribute
% XGLSETPOINTSIZE       Set the current text point size.
% XGLSETSTRIKEOUT       Set text strikeout attribute
% XGLSETTEXTCOLOR       Set the current text color.
% XGLSETUNDERLINE       Set text underline attribute
% XGLTEXT               Draw text.
%
% XGLGETCURSOR          Get the cursor position.
% XGLSHOWCURSOR         Toggle the cursor.
%
% XGLTEST               Test graphics functions
%
% Contact: jsp@mail.utexas.edu

% History
% -------
% jsp Wed Aug 13 14:44:53 CDT 2003 Created
% jsp Mon Oct 17 15:29:25 CDT 2005 Updated
% jsp Thu Oct 19 11:25:03 CDT 2006 Updated
% jsp Thu Nov 07  8:06:39 CDT 2013 Updated
% er Mon Sep 21  5:10:00 EST 2015 Updated
