function C = initstim(fname, ScreenInfo)
% Created 8/23/08 -WA

P = getpref('MonkeyLogic');
sourcefile = [P.Directories.BaseDirectory fname];
disp(sprintf('<<< MonkeyLogic >>> initstim is looking for %s', sourcefile));
[pname fname ext] = fileparts(sourcefile);
processedfile = [pname filesep fname '_preprocessed.mat'];
if strcmpi(ext, '.avi'),
    if verLessThan('matlab', '8')
        reader = mmreader(sourcefile); %#ok<DMMR>
    else
        reader = VideoReader(sourcefile); 
    end
    numframes = get(reader,'numberOfFrames');
    MOV = read(reader);
    
    yis = get(reader, 'height');
    xis = get(reader, 'width');
    C.Name = sourcefile; C.Type = 'mov';
    C.Xpos = 0; C.Ypos = 0; C.Xsize = xis; C.Ysize = yis;
    C.NumFrames = numframes; C.InitFrame = 0; C.StartFrame = 1; C.Status = 0; C.NumPositions = 1; C.StartPosition = 1; C.MovieStep = 1; C.PositionStep = 1;

    if ~exist(processedfile, 'file'),
        str = sprintf('Please Wait: optimizing %s', fname);

        [pimdata pxis pyis pxisbuf pyisbuf] = pad_image(MOV(:,:,:,1), ScreenInfo.ModVal, ScreenInfo.BackgroundColor);
        M = uint32(zeros([pxisbuf*pyisbuf numframes]));
        
        for framenumber = 1:numframes,
            if mod(framenumber, 2),
                str = [str '.'];
                disp(sprintf(str))
            end
            [imdata xis yis xisbuf yisbuf] = pad_image(MOV(:,:,:,framenumber), ScreenInfo.ModVal, ScreenInfo.BackgroundColor);   %#ok<NASGU,NASGU>
            imdata = double(imdata);
            if ~any(imdata(:) > 1),
                imdata = ceil(255*imdata);
            end
            M(:,framenumber) = uint32(xglrgb8(imdata(:, :, 1)', imdata(:, :, 2)', imdata(:, :, 3)'));
        end

        bgc = xglrgb8(floor(255*ScreenInfo.BackgroundColor(1)),floor(255*ScreenInfo.BackgroundColor(2)),floor(255*ScreenInfo.BackgroundColor(3)));
        M = M + uint32((M==0)*bgc);
        
        save(processedfile, 'M', 'xis', 'yis', 'xisbuf', 'yisbuf');
    end
    
elseif strcmpi(ext, '.jpg') || strcmpi(ext, '.jpeg') || strcmpi(ext, '.bmp') || strcmpi(ext, '.tiff') || strcmpi(ext, '.gif'),
    PIC = imread(sourcefile);
    yis = size(PIC, 1);
    xis = size(PIC, 2);
    C.Name = sourcefile; C.Type = 'pic';
    C.Xpos = 0; C.Ypos = 0; C.Xsize = xis; C.Ysize = yis;
    C.NumFrames = 1; C.InitFrame = 0; C.StartFrame = 1; C.Status = 0; C.NumPositions = 1; C.StartPosition = 1; C.MovieStep = 1; C.PositionStep = 1;
    
    [imdata xis yis xisbuf yisbuf] = pad_image(PIC, ScreenInfo.ModVal, ScreenInfo.BackgroundColor);   %#ok<NASGU,NASGU>
    imdata = double(imdata);
    if ~any(imdata(:) > 1),
        imdata = ceil(255*imdata);
    end
    cimdata1 = imdata(:, :, 1);
    cimdata2 = imdata(:, :, 2);
    cimdata3 = imdata(:, :, 3);
    cimdata1(cimdata1 == ScreenInfo.BackgroundColor(1)) = NaN;
    cimdata2(cimdata2 == ScreenInfo.BackgroundColor(2)) = NaN;
    cimdata3(cimdata3 == ScreenInfo.BackgroundColor(3)) = NaN;
    cocolor = ([nanmean(nanmean(cimdata1)) nanmean(nanmean(cimdata2)) nanmean(nanmean(cimdata3))]);
    cocolor(isnan(cocolor)) = 0; %#ok<NASGU>
    imdata = uint32(xglrgb8(imdata(:, :, 1)', imdata(:, :, 2)', imdata(:, :, 3)')); %#ok<NASGU>

    save(processedfile, 'imdata', 'xis', 'yis', 'xisbuf', 'yisbuf', 'cocolor');
end
