% Build kbd mex files

% Copyright (C) 2006-2007
% Center for Perceptual Systems
% University of Texas at Austin
%
% jsp Wed Aug  9 14:15:58 CDT 2006

% mgsyntax('kbd.mg')
% mgm('kbd.mg')
% mgentry('kbd.mg')
% mgcpp('kbd.mg')

switch mexext
    case 'mexw64'
    archdir='x64';
    case 'mexw32'
    archdir='x86';
    otherwise
    error('Unknown architecture');
end

fprintf('Compiling for %s\n',archdir);

cmd=['mex -I''C:/Program Files (x86)/Microsoft DirectX SDK (April 2006)/Include/'' '...
     '-L''C:/Program Files (x86)/Microsoft DirectX SDK (June 2010)/Lib/%s/'' '...
     '-l''dinput8'' '...
     '-l''dxguid'' '...
     '-D%s '...
     'kbdmex.cpp kbdhandlers.cpp'];
cmd=sprintf(cmd,archdir,upper(mexext));
fprintf('Evaluating "%s"\n',cmd)
eval(cmd)

fprintf('Done\n')
