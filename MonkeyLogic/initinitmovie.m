function C = initinitmovie(fname, ScreenInfo)
% Created 8/23/08 -WA


P = getpref('MonkeyLogic');
sourcefile = [P.Directories.BaseDirectory fname];
[pname fname] = fileparts(sourcefile);
processedfile = [pname filesep fname '_preprocessed.mat'];

C.Name = sourcefile; C.Type = 'mov';
C.Xpos = 0; C.Ypos = 0; C.Xsize = 315; C.Ysize = 315;
C.NumFrames = 61; C.InitFrame = 0; C.StartFrame = 1; C.Status = 0; C.NumPositions = 1; C.StartPosition = 1; C.MovieStep = 1; C.PositionStep = 1;

if ~exist(processedfile, 'file'),
    str = '.';
    fprintf('First time movie initialization (will not encounter again)\n');
    reader = mmreader(sourcefile);
    MOV = read(reader);
    for framenumber = 1:length(MOV),
        str = [str '.']; %#ok<AGROW>
        fprintf(str);
        [imdata xis yis xisbuf yisbuf] = pad_image(MOV(:,:,:,framenumber), ScreenInfo.ModVal, ScreenInfo.BackgroundColor);   %#ok<ASGLU,NASGU>
        imdata = double(imdata);
        if ~any(imdata(:) > 1),
            imdata = ceil(255*imdata);
        end
        M{framenumber} = uint32(rgbval(imdata(:, :, 1)', imdata(:, :, 2)', imdata(:, :, 3)')); %#ok<AGROW,NASGU>
    end
    save(processedfile, 'M', 'xis', 'yis', 'xisbuf', 'yisbuf');
end

function rgb = rgbval(r,g,b)
z = 65536*r+256*g+b;
rgb = z(:)';