function result = mlkbd(fxn, varargin)
%SYNTAX LIST:
%  mlkbd('mlinit');
%  mlkbd('init');
%  mlkbd('flush');
%  mlkbd('getkey');
%  mlkbd('release');

result = [];
fxn = lower(fxn);
switch fxn
    case 'mlinit',
        
        %nothing (for now)

    case 'init',
        
        kbdinit;
        
    case 'flush',
        
        kbdflush;
        
    case 'getkey',
        
        result = kbdgetkey;
        
    case 'release',
        
        kbdrelease;
        
end
