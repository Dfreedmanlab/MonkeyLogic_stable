% XGL Mexgen File
%
% jsp Thu Sep 15 18:30:01 CDT 2005 Creation

minversion(1.0)
handlers('xglhandlers.cpp')
entrypoint('xglmex')

function [double]=xglpfgs
% XGLPFGS   Grayscale pixel format value.
%
% XGLPFGS returns the value of the grayscale pixel format.
%
% See also XGLTOTALMODES
end

function [double]=xglpfrgb8
% XGLPFRGB8 RGB8 pixel format value.
%
% XGLPFRGB8 returns the value of the 8-bit per channel RGB pixel
% format.
%
% See also XGLTOTALMODES
end

function [double]=xglpfyv12
% XGLPFYV12 YV12 pixel format value.
%
% XGLPFYV12 returns the value of the yv12 pixel format.
%
% See also XGLTOTALMODES
end

function [double]=xglpfrgb10
% XGLPFRGB10    RGB10 pixel format value.
%
% XGLPFRGB10 returns the value of the 10-bit per channel RGB pixel
% format.
%
% See also XGLTOTALMODES
end

function [double]=xglpfrgbf32
% XGLPFRGBF32   RGBF32 pixel format value.
%
% XGLPFRGBF32 returns the value of the floating point, 32-bit per
% channel pixel format.
%
% See also XGLTOTALMODES
end

function [double]=xglrgb8(double,double,double)
% XGLRGB8   Convert RGB values to RGB8 values.
%
% XGLRGB8(R,G,B) converts the 8-bit per channel RGB vectors in R, G
% and B to a vector containing RGB8 values.
%
% See also XGLCLEAR
end

function [double]=xglrgb10(double,double,double)
% XGLRGB10  Convert RGB values to RGB10 values.
%
% XGLRGB10(R,G,B) converts the 8-bit per channel RGB vectors in R, G
% and B to a vector containing RGB10 values.
%
% See also XGLCLEAR
end

function xglinit(varargin)
% XGLINIT   Initialize the xgl library.
%
% You must call this function before calling other xgl library functions.
%
% See also XGLRELEASE
end

function xglrelease
% XGLRELEASE    Release the xgl library.
%
% See also XGLINIT
end

function [double]=xgldevices
% XGLDEVICES    Return the number of graphics devices in the system.
%
% Call this function to determine how many graphics devices are in
% the system.  A dual head controller will be detected as two separate
% devices.
%
% See also XGLINIT
end

function [char]=xglinfo(double)
% XGLINFO   Get device info.
%
% XGLINFO(D) will get graphics device info in the form of a text
% string for graphics device number D.  The device number is 1-based
% and must be between 1 and the number returned from XGLDEVICES.
%
% See also XGLINITDEVICE
end

function [double]=xglrect(double)
% XGLRECT   Get device screen desktop rectangle.
%
% XGLRECT(D) will get the desktop position of the specified device.
% The rectangle is returned in a 4 element row vector and specifies
% the x and y coordinates of the screen offset and the width and
% height of the monitor (in that order).
%
% This desktop rectangle is used in multimonitor systems to determine
% the monitors' positions relative to one another.  Use this function
% also to determine if a device has an attached monitor.  If a device
% does not have an attached monitor, the width and height will be 0.
%
% See also XGLINITDEVICE
end

function [double]=xgltotalmodes(double,double)
% XGLTOTALMODES Get the total number of modes for a device.
%
% XGLTOTALMODES(D,PF) will return a scalar that indicates the number of
% modes available for device D.  The PF parameter specifies the pixel
% format of the mode.
%
% The following XGLPF* functions return values for the following
% pixel formats:
%
%   XGLPFGS         Grayscale
%   XGLPFRGB8       32 bit RGB
%   XGLPFYV12       12 bit planar YUV
%   XGLPFRGB10      32 bit, 10 bit per channel RGB
%   XGLPFRGBF16     64 bit, 16 bit per channel floating point RGB
%
% See also XGLGETMODE
end

function [double]=xglcurrentmode(double)
% XGLCURRENTMODE    Get the device's current video mode
%
% M=XGLCURRENTMODE(D) returns an array of four values that specify the
% device's current video mode.  The array values specify the
% following:  
%
%   M(1) Width in pixels
%   M(2) Height in pixels
%   M(3) Pixel format value
%   M(4) Video refresh rate
%
% The following XGLPF* functions return values for the following
% pixel formats:
%
%   XGLPFGS         Grayscale
%   XGLPFRGB8       32 bit RGB
%   XGLPFYV12       12 bit planar YUV
%   XGLPFRGB10      32 bit, 10 bit per channel RGB
%   XGLPFRGBF16     64 bit, 16 bit per channel floating point RGB
%
% See also XGLTOTALMODES, XGLGETMODE
end

function [double]=xglgetmode(double,double,double)
% XGLGETMODE    Get a video mode specification for a device
%
% M=XGLGETMODE(D,PF,N) returns an array of four values that specify
% the device's Nth video mode for pixel format PF.  The total number
% of video modes for a device must first be determined by
% XGLTOTALMODES.  The array of mode values returned are as follows:
%
%   M(1) Width in pixels
%   M(2) Height in pixels
%   M(3) Pixel format value
%   M(4) Video refresh rate
%
% The following XGLPF* functions return values for the following
% pixel formats:
%
%   XGLPFGS         Grayscale
%   XGLPFRGB8       32 bit RGB
%   XGLPFYV12       12 bit planar YUV
%   XGLPFRGB10      32 bit, 10 bit per channel RGB
%   XGLPFRGBF16     64 bit, 16 bit per channel floating point RGB
%
% Note that the mode value M(4) will be set to the same value passed
% to the function in PF.
%
% See also XGLTOTALMODES, XGLCURRENTMODE
end

function [logical]=xglhwconversion(double,double,double)
% XGLHWCONVERSION   Determine hardware conversion support
%
% XGLHWCONVERSION(D,PF1,PF2) returns a logical value indicating whether
% or not hardware conversion from pixel format PF1 to PF2 is supported
% on device D.
%
% The following XGLPF* functions return values for the following
% pixel formats:
%
%   XGLPFGS         Grayscale
%   XGLPFRGB8       32 bit RGB
%   XGLPFYV12       12 bit planar YUV
%   XGLPFRGB10      32 bit, 10 bit per channel RGB
%   XGLPFRGBF16     64 bit, 16 bit per channel floating point RGB
%
% See also XGLTOTALMODES, XGLGETMODE, XGLBLIT
end

function xglinitdevice(double,double,double)
% XGLINITDEVICE Initialize the specified device.
%
% XGLINITDEVICE(D,M,B) will initialize graphics device number D.
% When a device is initialized, it will be placed into the video mode
% specified by the array M.  The mode array M should contain the
% following values:
%
%
%   M(1) Width in pixels
%   M(2) Height in pixels
%   M(3) Pixel format specifier
%   M(4) Video refresh rate
%
% The following XGLPF* functions return values for the following
% pixel formats:
%
%   XGLPFGS         Grayscale
%   XGLPFRGB8       32 bit RGB
%   XGLPFYV12       12 bit planar YUV
%   XGLPFRGB10      32 bit, 10 bit per channel RGB
%   XGLPFRGBF16     64 bit, 16 bit per channel floating point RGB
%
% The parameter B specifies the number of backbuffers that should be
% allocated to the device.
%
% Note that a frontbuffer is also allocated when the device is
% initialized.  Therefore, for triple buffering, specify only two
% backbuffers.
%
% See also XGLTOTALMODES, XGLGETMODE
end

function xglreleasedevice(double)
% XGLRELEASEDEVICE  Release the specified device.
%
% XGLRELEASEDEVICE(D) will release graphics device number D.
% Devices must be released when they are no longer being used.
%
% When a device is released, its video mode is restored to the mode it
% was in before the call the XGLINITDEVICE.
%
% See also XGLDEVICES, XGLINITDEVICE
end

function xglclear(double,double,double)
% XGLCLEAR  Clear a device's backbuffer.
%
% XGLCLEAR(D,B,RGB) will clear device D's backbuffer number B to the
% color specifed by RGB.
%
% See also XGLINITDEVICE, XGLFLIP
end

function xglflip(double)
% XGLFLIP  Flip the backbuffer.
%
% XGLFLIP(D) will make backbuffer 1 on device D the frontbuffer and
% renumber all the backbuffers in the device's swap chain.
%
% See also XGLINITDEVICE, XGLCLEAR, XGLBLIT
end

function [logical,double]=xglgetrasterstatus(double)
% XGLGETRASTERSTATUS    Get the state of the current raster
%
% [VB,SL]=XGLGETRASTERSTATUS(D) will get the raster status for device
% D.  VB indicates whether or not the raster is currently within a
% vertical blank.  If VB is false, then SL incicates the scanline that
% the device is currently drawing.
%
% See also XGLBLIT
end

function [double]=xglcreatebuffer(double,double)
% XGLCREATEBUFFER   Create an offscreen memory buffer.
%
% [B]=XGLCREATEBUFFER(D,[W H PF]) will create an offscreen memory
% buffer on device D with dimensions W x H in the pixel format
% specified by PF.
%
% Ultimately you will be copying pixels to the buffer and then
% blitting it to video memory, so make sure hardware conversion is
% supported for the specified pixel format.
%
% Note that you can pass a mode vector [W H PF F] returned from
% XGLGETMODE or XGLCURRENTMODE to the XGLCREATEBUFFER function, but
% the F parameter, monitor frequency, will be ignored.
%
% Also note that many devices require that the buffer width be a
% multiple of some power of 2, like 8 or 16.  If you specify a width
% that is not supported, the device might create the buffer but give
% you erroneous results.
%
% See also XGLHWCONVERSION, XGLCOPYBUFFER, XGLBLIT, XGLGETMODE
end

function xglreleasebuffer(double,double)
% XGLRELEASEBUFFER  Release an offscreen memory buffer.
%
% XGLRELEASEBUFFER(D,B) will release an offscreen memory buffer on
% device D with buffer handle B.  The buffer must have been created
% previously with XGLCREATEBUFFER.
%
% See also XGLCREATEBUFFER, XGLRELEASEBUFFERS
end

function xglreleasebuffers(double)
% XGLRELEASEBUFFERS Release all offscreen memory buffers.
%
% XGLRELEASEBUFFERS(D) will release all offscreen memory buffers on
% device D.  The buffers must have been created previously with
% XGLCREATEBUFFER.
%
% See also XGLCREATEBUFFER, XGLRELEASEBUFFER
end

function xglclearbuffer(double,double,double)
% XGLCLEARBUFFER    Clear a device's offscreen memory buffer.
%
% XGLCLEARBUFFER(D,H,RGB) will clear device D's offscreen memory
% buffer whose handle is specified by H to the color specifed by RGB.
%
% See also XGLCREATEBUFFER, XGLHWCONVERSION
end

function xglcopybuffer(double,double,any)
% XGLCOPYBUFFER Copy pixels to offscreen memory.
%
% XGLCOPYBUFFER(D,H,P) will copy pixels to the buffer on device D with
% buffer handle H from the buffer in P.  P may contain uint8 grayscale
% values in the range [0, 255], uint32 values obtained from the RGB
% pixel conversion functions, or single precision floating point
% values in the range [0, 1.0].
%
% See also XGLCREATEBUFFER, XGLBLIT, XGLHWCONVERSION, XGLRGB8,
% XGLRGB10
end

function xglblit(double,double,varargin)
% XGLBLIT   Blit offscreen memory to video memory.
%
% XGLBLIT(D,H[,R]) will blit offscreen memory in the buffer designated
% by H to device D's backbuffer.
%
% You may optionally specify a destination rectangle, R.  If R is
% omitted, the buffer is blitted to the entire screen.
%
% Call XGLFLIP to display the contents of the device's backbuffer.
%
% See also XGLCREATEBUFFER, XGLCOPYBUFFER, XGLHWCONVERSION, XGLFLIP
end

function [double]=xglgetcursor
% XGLGETCURSOR   Get the cursor position.
%
% XGLGETCURSOR will get an x y pair that specifies the current cursor
% position.  On a multimonitor display, use XGLRECT to determine the
% cursor position relative to a given display.
%
% Cursor functions do not require initialization with XGLINIT.
%
% See also XGLSETCURSOR
end

function xglsetcursor(double)
% XGLSETCURSOR  Set the cursor position.
%
% XGLSETCURSOR(P) will change the cursor's position to P(1), P(2).
%
% Cursor functions do not require initialization with XGLINIT.
%
% See also XGLGETCURSOR
end

function xglshowcursor(double,double)
% XGLSHOWCURSOR Toggle the cursor.
%
% XGLSHOWCURSOR(D,F) will turn the cursor on device D to visible if F
% is non-zero and to not visible if F is zero.
%
% See also XGLGETCURSOR, XGLSETCURSOR
end

function xglsetlut(double,double)
% XGLSETLUT Set a device's lookup, or gamma, table.
%
% XGLSETLUT(D,LUT) will set device D's lookup table to the 256x3 array
% of doubles in LUT.
%
% Values in LUT should range from 0.0 to 1.0.
end

function [double]=xgltotalfonts(double)
% XGLTOTALFONTS Get the number of fonts available.
%
% XGLTOTALFONTS(D) will return the number of fonts available on device
% D.
end

function [char]=xglfontname(double,double)
% XGLFONTNAME   Get a font name.
%
% XGLFONTNAME(D,F) will return the name of font number F on device D.
end

function xglsetfont(double,double)
% XGLSETFONT    Set the current font.
%
% XGLSETFONT(D,F) will set the current font on device D to font number
% F.
%
% See also XGLTOTALFONTS, XGLFONTNAME
end

function xglsetpointsize(double,double)
% XGLSETPOINTSIZE   Set the current text point size.
%
% XGLSETPOINTSIZE(D,P) will set the current point size on device D to
% P.
%
% See also XGLTOTALFONTS
end

function xglsetescapement(double,double)
% XGLSETESCAPEMENT  Set text escapement
%
% XGLSETESCAPEMENT(D,DEG) will set the current text escapement on
% device D to DEG degrees.
%
% See also XGLSETPOINTSIZE
end

function xglsettextcolor(double,double)
% XGLSETTEXTCOLOR   Set the current text color.
%
% XGLSETTEXTCOLOR(D,RGB) will set the current text color on device D to
% the rgb value specified by RGB.
%
% See also XGLTOTALFONTS, XGLFONTNAME, XGLSETFONT
end

function xglsetbgcolor(double,double)
% XGLSETBGCOLOR Set the current text background color.
%
% XGLSETBGCOLOR(D,RGB) will set the current text background color on
% device D to the rgb value specified by RGB.
%
% See also XGLSETTEXTCOLOR, XGLSETBGTRANS
end

function xglsetbgtrans(double,double)
% XGLSETBGTRANS Set the current text background transparency.
%
% XGLSETBGTRANS(D,T) will set the current text background transparency
% to transparent if T is non-zero and to opaque if T is zero.
%
% See also XGLSETTEXTCOLOR, XGLSETBGCOLOR
end

function xglsetitalic(double,double)
% XGLSETITALIC  Set text italics attribute
%
% XGLSETITALIC(D,F) will set the current text italic attribute for
% device D, according to parameter F.
%
% See also XGLSETUNDERLINE, XGLSETSTRIKEOUT
end

function xglsetunderline(double,double)
% XGLSETUNDERLINE   Set text underline attribute
%
% XGLSETUNDERLINE(D,F) will set the current text underline
% attribute for device D, according to parameter F.
%
% See also XGLSETITALIC, XGLSETSTRIKEOUT
end

function xglsetstrikeout(double,double)
% XGLSETSTRIKEOUT   Set text strikeout attribute
%
% XGLSETSTRIKEOUT(D,F) will set the current text strikeout attribute
% for device D, according to parameter F.
%
% See also XGLSETITALIC, XGLSETUNDERLINE
end

function [double]=xgltextwidth(double,char)
% XGLTEXTWIDTH  Get the width in pixels of a text string.
%
% XGLTEXTWIDTH(D,T) will return the width in pixels on the device D of
% the text string in T.  The width depends on the current font and
% point size.
%
% See also XGLSETFONT, XGLSETPOINTSIZE, XGLTEXTHEIGHT
end

function [double]=xgltextheight(double)
% XGLTEXTHEIGHT  Get the height in pixels of text.
%
% XGLTEXTHEIGHT(D) will return the height in pixels of text drawn on
% device D.
%
% See also XGLSETFONT, XGLSETPOINTSIZE, XGLTEXTWIDTH
end

function xgltext(double,double,char)
% XGLTEXT   Draw text.
%
% XGLTEXT(D,[X Y],S) will draw the text in S on device D at pixel X, Y.
%
% See also XGLSETFONT, XGLSETPOINTSIZE, XGLTEXTWIDTH
end

function xglmouse_buttonstate()
% XGLMOUSE_BUTTONSTATE   returns the state of the mouse buttons
%
% 0 left mouse button is up
% 1 left mouse button is down
% 0 right mouse button is up
% 1 right mouse button is down
%
end
