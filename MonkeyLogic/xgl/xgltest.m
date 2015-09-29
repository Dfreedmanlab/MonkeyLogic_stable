function xgltest
% XGLTEST   Test graphics functions.
%
% This function will test all of the xgl* functions.  It may take a
% few minutes to run, during which time your monitor will change
% modes, flash different colors, display text, and so on.

% Copyright (C) 2003-2006 Center for Perceptual Systems
%
% jsp Tue Aug 26 08:10:06 CDT 2003 Created
% jsp Fri Oct  7 12:16:47 CDT 2005 Rewrite for D3D9

test_initrelease
test_devices
test_deviceinfo
test_rect
test_totalmodes
test_getmode
test_getcurrentmode
test_hwconversion

d=input('Enter the device number (1-indexed): ');

xglinit
if d>xgldevices | d<1
    error('Invalid device number')
end
xglrelease

tests={...
'ALL',...
'test_init_release_device(d)',...
'test_clear_flip(d)',...
'test_rasterstatus(d)',...
'test_create_release_buffer(d)',...
'test_clearbuffer(d)',...
'test_copybuffer(d)',...
'test_stretchblit(d)',...
'test_cursor(d)',...
'test_gamma(d)',...
'test_text(d)',...
};

for j=1:size(tests,2)
    fprintf('%d: %s\n',j,tests{j})
end

n=input('Enter the test number: ');

if n==1
    for j=2:size(tests,2)
        eval(tests{j});
    end
else
    eval(tests{n});
end

disp 'Success';
clear functions;

%-------------------------------------------------------------------------------

function test_initrelease
disp 'Testing xglinit/release';
xglinit;
xglrelease;

%-------------------------------------------------------------------------------

function test_devices
disp 'Testing xgldevices';
xglinit;
devices=xgldevices;
fprintf('%d devices found\n',devices);
xglrelease;

%-------------------------------------------------------------------------------

function test_deviceinfo

disp 'Testing xgldeviceinfo';

xglinit;

for i=1:xgldevices
    s=xglinfo(i);
    fprintf('Device %d''s info string is ''%s''\n', i, s); 
end

xglrelease;

%-------------------------------------------------------------------------------

function test_rect

disp 'Testing xglrect';

xglinit;

for i=1:xgldevices
    rect=xglrect(i);
    fprintf('Device %d''s desktop coordinates are (%d, %d) - (%d, %d)\n', i, rect(1), rect(2), rect(1)+rect(3), rect(2)+rect(4)); 
end

xglrelease;

%-------------------------------------------------------------------------------

function test_totalmodes

disp 'Testing xgltotalmodes';

xglinit;

for i=1:xgldevices
    m=xgltotalmodes(i,2);
    fprintf('Device %d has %d total 32 bit RGB modes\n', i, m);
end

xglrelease;

%-------------------------------------------------------------------------------

function test_getcurrentmode

disp 'Testing xglcurrentgetmode';

xglinit;

for i=1:xgldevices
    m=xglcurrentmode(i);
    fprintf('Device %d''s current mode: %d X %d, pixel format %d @ %d Hz\n',i,m(1),m(2),m(3),m(4));
end

xglrelease;

%-------------------------------------------------------------------------------

function test_getmode

disp 'Testing xglgetmode';

xglinit;

for i=1:xgldevices
    for j=1:5
        for k=1:xgltotalmodes(i,j)
            m=xglgetmode(i,j,k);
            fprintf('Device %d, pf %d, mode %d: %d X %d @ %d Hz\n',i,j,k,m(1),m(2),m(4));
        end
    end
end

xglrelease;

%-------------------------------------------------------------------------------

function pf=pixelformats
% Helper function for enumerating pixel formats

pf=[xglpfgs xglpfrgb8 xglpfyv12 xglpfrgb10 xglpfrgbf32];


%-------------------------------------------------------------------------------

function test_hwconversion

disp 'Testing xglhwconversion';

xglinit;

for i=1:xgldevices
    for j=pixelformats
        for k=pixelformats
            f=xglhwconversion(i,j,k);
            if (f)
                s='supported';
            else
                s='unsupported';
            end
            fprintf('Device %d hardware conversion from pixel format %d to pixel format %d: %s\n',i,j,k,s);
        end
    end
end

xglrelease;

%-------------------------------------------------------------------------------

function test_init_release_device(i)

disp 'Testing xglinitdevice and xglreleasedevice';

xglinit;

    m=xglcurrentmode(i);
    fprintf('Initializing device %d\n',i);
    xglinitdevice(i,m,2); % triple buffer
    xglreleasedevice(i);

xglrelease;

%-------------------------------------------------------------------------------

function test_clear_flip(i)

disp 'Testing xglclear and xglflip';

xglinit;

    m=xglcurrentmode(i);
    fprintf('Initializing device %d\n',i);
    xglinitdevice(i,m,2); % triple buffer
    fprintf('Clearing and flipping device %d\n',i);
    tic;
    while (toc<0.5)
        xglclear(i,1,xglrgb8(255,0,0)); % red
        xglflip(i);
    end
    tic;
    while (toc<0.5)
        xglclear(i,1,xglrgb8(0,255,0)); % green
        xglflip(i);
    end
    tic;
    while (toc<0.5)
        xglclear(i,1,xglrgb8(0,0,255)); % blue
        xglflip(i);
    end
    xglreleasedevice(i);

xglrelease;

%-------------------------------------------------------------------------------

function test_rasterstatus(i)

disp 'Testing xglrasterstatus';

xglinit;

    m=xglcurrentmode(i);
    fprintf('Initializing device %d\n',i);
    xglinitdevice(i,m,2); % triple buffer
    fprintf('Clearing and flipping device %d\n',i);
    fprintf('Getting raster status on device %d\n',i);
    sl=[];
    xglclear(i,1,xglrgb8(255,255,0)); % yellow
    xglflip(i);
    tic;
    [vb,l]=xglgetrasterstatus(i);
    while (not(vb))
        if length(sl)>10000 % Failsafe
            break
        end
        sl=[sl l];
        [vb,l]=xglgetrasterstatus(i);
    end
    while (toc<0.5)
    end
    xglreleasedevice(i);
    fprintf('The raster was checked on the following scanlines: ');
    fprintf(' %d',sl);
    fprintf('\n');

xglrelease;

%-------------------------------------------------------------------------------

function test_create_release_buffer(i)

disp 'Testing xglcreate/releasebuffer';

xglinit;

w=640;
h=480;
buffers=10;

m=xglcurrentmode(i);
j=xglpfrgb8;

fprintf('Pixel format %d, backbuffer format %d\n',j,j);
fprintf('Initializing device %d\n',i);
xglinitdevice(i,m,2); % triple buffer
fprintf('Creating %d buffers\n',buffers);
% We can do it like this...
for l=1:buffers
    b=xglcreatebuffer(i,[w h j]);
end
% ...and then release them all
fprintf('Releasing buffers\n');
xglreleasebuffers(i);
% Or we can save off the handles, which we probably
% would need later...
fprintf('Creating %d buffers\n',buffers);
b=[];
for l=1:buffers
    b=[b xglcreatebuffer(i,[w h j])];
end
% ...and then release them one by one.
fprintf('Releasing buffers\n');
for l=b
    xglreleasebuffer(i,l);
end
xglreleasedevice(i);

xglrelease;

%-------------------------------------------------------------------------------

function test_clearbuffer(i)

disp 'Testing xglclearbuffer';

xglinit;

w=640;
h=480;
buffers=10;
m=xglcurrentmode(i);
j=xglpfrgb8;

fprintf('Pixel format %d, backbuffer format %d\n',j,j);
fprintf('Initializing device %d\n',i);
xglinitdevice(i,m,2); % triple buffer
fprintf('Creating %d buffers\n',buffers);
b=[];
for l=1:buffers
    b=[b xglcreatebuffer(i,[w h j])];
end
fprintf('Clearing buffers\n');
for l=b
    rgb=xglrgb8(255,0,255); % violet
    xglclearbuffer(i,l,rgb);
end
fprintf('Blitting buffers\n');
for l=b
    xglblit(i,l);
    xglflip(i);
end
fprintf('Releasing buffers\n');
for l=b
    xglreleasebuffer(i,l);
end
xglreleasedevice(i);

xglrelease;

%-------------------------------------------------------------------------------

function buf=fill_buffer(w,h,pf)

% Compute distance
[dx,dy]=meshgrid(-1:2/(h-1):1,-1:2/(w-1):1);
d=sqrt(dx.^2+dy.^2);

% Fill y, u, and v buffers
y=1-d; % 0,1
% We want u on the x axis, but remember that Matlab switches the
% meaning of x and y in physical memory, so we swap u and v.
v=dx/2; % -0.5,0.5
u=dy/2; % -0.5,0.5

i=find(y<0);
y(i)=0;
u(i)=0;
v(i)=0;

% Create downsampled u and v
u2=u(1:2:end,1:2:end);
v2=v(1:2:end,1:2:end);

% Compute RGB values
rgb=clryuv2rgb(cat(3,y,u,v));
% clamp to [0,1.0]
r=rgb(:,:,1); r(find(r>1))=1.0; r(find(r<0))=0;
g=rgb(:,:,2); g(find(g>1))=1.0; g(find(g<0))=0;
b=rgb(:,:,3); b(find(b>1))=1.0; b(find(b<0))=0;

switch pf
    case xglpfgs
    buf=uint8(y*255);
    case xglpfrgb8
    buf=uint32(xglrgb8(r*255,g*255,b*255));
    case xglpfyv12
    buf=uint8(cat(1,y(:)*255,u2(:)*255+128,v2(:)*255+128));
    case xglpfrgb10
    buf=uint32(xglrgb10(r*1024,g*1024,b*1024));
    case xglpfrgbf32
    % make an alpha channel
    a=ones(size(y));
    % cat it to the image
    rgba=cat(3,rgb,a);
    % rearrange the dimensions so that pixels become interlaced
    rgba=permute(rgba,[3 1 2]);
    buf=single(rgba);
    otherwise
    error('Unknown pixel format');
end

%-------------------------------------------------------------------------------

function test_copybuffer(i)

disp 'Testing xglcopybuffer';

xglinit;

w=640;
h=480;
buffers=10;
m=xglcurrentmode(i);
j=xglpfrgb8;

fprintf('Pixel format %d, backbuffer format %d\n',j,j);
fprintf('Initializing device %d\n',i);
xglinitdevice(i,m,2); % triple buffer
fprintf('Creating %d buffers\n',buffers);
b=[];
for l=1:buffers
    b=[b xglcreatebuffer(i,[w h j])];
end
buf=fill_buffer(w,h,j);
fprintf('Copying buffers\n');
for l=b
    xglcopybuffer(i,l,buf);
end
l=0;
fprintf('Blitting buffers\n');
tic;
while toc<0.5
    l=l+1;
    xglblit(i,b(l));
    xglflip(i);
    l=mod(l,buffers);
end
fprintf('Releasing buffers\n');
for l=b
    xglreleasebuffer(i,l);
end
xglreleasedevice(i);

xglrelease;

%-------------------------------------------------------------------------------

function test_stretchblit(i)

disp 'Testing xglblit';

% Read an image.
%
% Note that in memory the image is transposed.
image=imread('c17.ppm');
% Get its width and height
iw=size(image,2);
ih=size(image,1);

% We could send a buffer of uint32's that we have transposed like this...
%
% Separate out the channels
%r=image(:,:,1);
%g=image(:,:,2);
%b=image(:,:,3);
%image=uint32(xglrgb8(double(r'),double(g'),double(b')));

% ...or we could send uint8's that we have arranged correctly.  Notice
% that on an Intel machine, a uint32's byte order is reversed in
% physical memory, so argb values should be arrange as b, g, r, a.
%
% Also, notice that the values get transposed when we permute the
% dimensions, so there is no need to separate out the channels.
%
% Create an alpha channel
a=zeros(size(image(:,:,1)));
% Cat the image in reverse order and then call permute in order to
% interlace the rgb values.
image=permute(cat(3,flipdim(image,3),a),[3 2 1]);

xglinit;

    m=xglcurrentmode(i);
    fprintf('Initializing device %d\n',i);
    xglinitdevice(i,m,2); % triple buffer
    fprintf('Creating an offscreen buffer\n');
    b=xglcreatebuffer(i,[iw ih xglpfrgb8]);
    fprintf('Copying image to buffer\n');
    xglcopybuffer(i,b,image);
    fprintf('Stretch blitting buffer\n');
    tic;
    ct=toc;
    while ct<2
        w=m(1)*ct/2;
        h=m(2)*ct/2;
        % Width and height may not be zero
        if w<1 w=1; end
        if h<1 h=1; end
        % Center the image on the screen
        x=m(1)/2-w/2;
        y=m(2)/2-h/2;
        % Blit it
        xglclear(i,1,xglrgb8(128,128,128));
        xglblit(i,b,[x y w h]);
        xglflip(i);
        ct=toc; % ensure that toc is<2 throughout the loop body
    end
    xglreleasebuffer(i,b);
    xglreleasedevice(i);

xglrelease;

%-------------------------------------------------------------------------------

function test_gamma(i)

disp 'Testing xglsetgamma';

w=640;
h=480;

% Draw a vertical ramp
a=[0:1/(h-1):1.0];
a=[a;a;a;a];
buf=repmat(a,[w 1]);

xglinit;

    m=xglcurrentmode(i);
    xglinitdevice(i,m,2); % triple buffer
    b=xglcreatebuffer(i,[w h xglpfrgb8]);
    xglcopybuffer(i,b,uint8(buf*255));
    xglblit(i,b);
    xglflip(i);
    tic; while toc<0.5; end;
    a=[0:1/255:1];
    lut=[a;a;a]';
    % Set the gamma table
    lg=lut.^2.2;
    fprintf('Setting gamma table\n');
    xglsetlut(i,lg);
    % Pause for a while
    tic; while toc<0.5; end;
    xglsetlut(i,lut);

xglrelease;

%-------------------------------------------------------------------------------

function test_text(i)

disp 'Testing xgl text routines';

xglinit;

    m=xglcurrentmode(i);
    xglinitdevice(i,m,2); % triple buffer
    disp 'Testing fontnames';
    for j=1:xgltotalfonts(i)
        fprintf('Device %d, font %d: %s\n',i,j,xglfontname(i,j));
    end
    arialfont=-1;
    disp 'Searching for arial font';
    for j=1:xgltotalfonts(i)
        if strcmp(lower(xglfontname(i,j)),'arial')
            arialfont=j;
            break;
        end
    end
    if arialfont==-1
        error('Could not find a font named ''arial''');
    end
    xglsetfont(i,arialfont);
    xglsetpointsize(i,100);
    disp 'Testing text colors';
    s='Red';
    dx=xgltextwidth(i,s);
    dy=xgltextheight(i);
    x=m(1)/2-dx/2;
    y=m(2)/2-dy/2;
    xglsettextcolor(i,xglrgb8(255,0,0));
    tic
    while toc<0.5
        xglclear(i,1,xglrgb8(255,255,255));
        xgltext(i,[x y],s);
        xglflip(i);
    end
    s='Green';
    dx=xgltextwidth(i,s);
    dy=xgltextheight(i);
    x=m(1)/2-dx/2;
    y=m(2)/2-dy/2;
    xglsettextcolor(i,xglrgb8(0,255,0));
    tic
    while toc<0.5
        xglclear(i,1,xglrgb8(255,255,255));
        xgltext(i,[x y],s);
        xglflip(i);
    end
    s='Blue';
    dx=xgltextwidth(i,s);
    dy=xgltextheight(i);
    x=m(1)/2-dx/2;
    y=m(2)/2-dy/2;
    xglsettextcolor(i,xglrgb8(0,0,255));
    tic
    while toc<0.5
        xglclear(i,1,xglrgb8(255,255,255));
        xgltext(i,[x y],s);
        xglflip(i);
    end
    s='Red on Blue/Green';
    dx=xgltextwidth(i,s);
    dy=xgltextheight(i);
    x=m(1)/2-dx/2;
    y=m(2)/2-dy/2;
    xglsettextcolor(i,xglrgb8(255,0,0));
    xglsetbgcolor(i,xglrgb8(0,255,255));
    tic
    while toc<0.5
        xglclear(i,1,xglrgb8(255,255,255));
        xgltext(i,[x y],s);
        xglflip(i);
    end
    s='Green on Purple';
    dx=xgltextwidth(i,s);
    dy=xgltextheight(i);
    x=m(1)/2-dx/2;
    y=m(2)/2-dy/2;
    xglsettextcolor(i,xglrgb8(0,255,0));
    xglsetbgcolor(i,xglrgb8(255,0,255));
    tic
    while toc<0.5
        xglclear(i,1,xglrgb8(255,255,255));
        xgltext(i,[x y],s);
        xglflip(i);
    end
    s='Blue on Yellow';
    dx=xgltextwidth(i,s);
    dy=xgltextheight(i);
    x=m(1)/2-dx/2;
    y=m(2)/2-dy/2;
    xglsettextcolor(i,xglrgb8(0,0,255));
    xglsetbgcolor(i,xglrgb8(255,255,0));
    tic
    while toc<0.5
        xglclear(i,1,xglrgb8(255,255,255));
        xgltext(i,[x y],s);
        xglflip(i);
    end
    s='Black on Transparent';
    dx=xgltextwidth(i,s);
    dy=xgltextheight(i);
    x=m(1)/2-dx/2;
    y=m(2)/2-dy/2;
    xglsettextcolor(i,xglrgb8(0,0,0));
    xglsetbgcolor(i,xglrgb8(0,0,0));
    xglsetbgtrans(i,1);
    tic
    while toc<0.5
        xglclear(i,1,xglrgb8(128,128,128));
        xgltext(i,[x y],s);
        xglflip(i);
    end
    disp 'Testing text attributes';
    s='Italic';
    dx=xgltextwidth(i,s);
    dy=xgltextheight(i);
    x=m(1)/2-dx/2;
    y=m(2)/2-dy/2;
    xglsettextcolor(i,xglrgb8(0,0,0));
    xglsetbgcolor(i,xglrgb8(255,255,255));
    xglsetbgtrans(i,0);
    xglsetitalic(i,1);
    xglsetunderline(i,0);
    xglsetstrikeout(i,0);
    tic
    while toc<0.5
        xglclear(i,1,xglrgb8(255,255,255));
        xgltext(i,[x y],s);
        xglflip(i);
    end
    s='Underline';
    dx=xgltextwidth(i,s);
    dy=xgltextheight(i);
    x=m(1)/2-dx/2;
    y=m(2)/2-dy/2;
    xglsettextcolor(i,xglrgb8(0,0,0));
    xglsetbgcolor(i,xglrgb8(255,255,255));
    xglsetitalic(i,0);
    xglsetunderline(i,1);
    xglsetstrikeout(i,0);
    tic
    while toc<0.5
        xglclear(i,1,xglrgb8(255,255,255));
        xgltext(i,[x y],s);
        xglflip(i);
    end
    s='Strikeout';
    dx=xgltextwidth(i,s);
    dy=xgltextheight(i);
    x=m(1)/2-dx/2;
    y=m(2)/2-dy/2;
    xglsettextcolor(i,xglrgb8(0,0,0));
    xglsetbgcolor(i,xglrgb8(255,255,255));
    xglsetitalic(i,0);
    xglsetunderline(i,0);
    xglsetstrikeout(i,1);
    tic
    while toc<0.5
        xglclear(i,1,xglrgb8(255,255,255));
        xgltext(i,[x y],s);
        xglflip(i);
    end
    s='Everything';
    dx=xgltextwidth(i,s);
    dy=xgltextheight(i);
    x=m(1)/2-dx/2;
    y=m(2)/2-dy/2;
    xglsettextcolor(i,xglrgb8(0,0,0));
    xglsetbgcolor(i,xglrgb8(255,255,255));
    xglsetitalic(i,1);
    xglsetunderline(i,1);
    xglsetstrikeout(i,1);
    tic
    while toc<0.5
        xglclear(i,1,xglrgb8(255,255,255));
        xgltext(i,[x y],s);
        xglflip(i);
    end
    s='Nothing';
    dx=xgltextwidth(i,s);
    dy=xgltextheight(i);
    x=m(1)/2-dx/2;
    y=m(2)/2-dy/2;
    xglsettextcolor(i,xglrgb8(0,0,0));
    xglsetbgcolor(i,xglrgb8(255,255,255));
    xglsetitalic(i,0);
    xglsetunderline(i,0);
    xglsetstrikeout(i,0);
    tic
    while toc<0.5
        xglclear(i,1,xglrgb8(255,255,255));
        xgltext(i,[x y],s);
        xglflip(i);
    end
    disp 'Testing text placement';
    s='Top Left';
    dx=xgltextwidth(i,s);
    dy=xgltextheight(i);
    x=0;
    y=0;
    tic
    while toc<0.5
        xglclear(i,1,xglrgb8(255,255,255));
        xgltext(i,[x y],s);
        xglflip(i);
    end
    s='Top Right';
    dx=xgltextwidth(i,s);
    dy=xgltextheight(i);
    x=m(1)-dx;
    y=0;
    tic
    while toc<0.5
        xglclear(i,1,xglrgb8(255,255,255));
        xgltext(i,[x y],s);
        xglflip(i);
    end
    s='Bottom Left';
    dx=xgltextwidth(i,s);
    dy=xgltextheight(i);
    x=0;
    y=m(2)-dy;
    tic
    while toc<0.5
        xglclear(i,1,xglrgb8(255,255,255));
        xgltext(i,[x y],s);
        xglflip(i);
    end
    s='Bottom Right';
    dx=xgltextwidth(i,s);
    dy=xgltextheight(i);
    x=m(1)-dx;
    y=m(2)-dy;
    tic
    while toc<0.5
        xglclear(i,1,xglrgb8(255,255,255));
        xgltext(i,[x y],s);
        xglflip(i);
    end
    disp 'Testing font sizes';
    xglsettextcolor(i,xglrgb8(0,0,0));
    xglsetbgcolor(i,xglrgb8(255,255,255));
    xglsetbgtrans(i,0);
    for j=1:10:xgltotalfonts(i)
        s=sprintf('Font # %d: %s',j,xglfontname(i,j));
        xglsetfont(i,j);
        tic
        while toc<0.5
            xglsetpointsize(i,toc*100);
            dx=xgltextwidth(i,s);
            dy=xgltextheight(i);
            x=m(1)/2-dx/2;
            y=m(2)/2-dy/2;
            xglclear(i,1,xglrgb8(255,255,255));
            xgltext(i,[x y],s);
            xglflip(i);
        end
    end
    disp 'Testing font escapements';
    xglsettextcolor(i,xglrgb8(0,0,0));
    xglsetbgcolor(i,xglrgb8(255,255,255));
    xglsetbgtrans(i,0);
    xglsetpointsize(i,30);
    for j=1:10:xgltotalfonts(i)
        s=sprintf('Font # %d: %s',j,xglfontname(i,j));
        xglsetfont(i,j);
        x=m(1)/2;
        y=m(2)/2;
        tic
        T=0.5;
        while toc<T
            xglsetescapement(i,toc*360/T);
            xglclear(i,1,xglrgb8(255,255,255));
            xgltext(i,[x y],s);
            xglflip(i);
        end
    end
    xglreleasedevice(i);

xglrelease;

%-------------------------------------------------------------------------------

function test_cursor(i)

disp 'Testing xglgetcursor';

xy=xglgetcursor;

disp 'Testing xglsetcursor';

xglsetcursor([0,0]);
xglsetcursor([1000,700]);

% Restore it
xglsetcursor(xy);

disp 'Testing xglshowcursor';

xglinit;

    m=xglcurrentmode(i);
    xglinitdevice(i,m,2);

    % Turn off the cursor
    xglshowcursor(i,0);

    tic; while toc<0.5; end;

    % Turn on the cursor
    xglshowcursor(i,1);

xglrelease;

function rgb=clryuv2rgb(yuv)

% ITU.BT-601 Y’CbCr
m = [1  0.000  1.403
     1 -0.344 -0.714
     1  1.773  0.000]';

s = size(yuv);
rgb = reshape(reshape(yuv, [s(1) * s(2) s(3)]) * m, s);
