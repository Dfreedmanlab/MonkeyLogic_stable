function success = set_ml_preferences

success = 0;
d = which('monkeylogic');
if isempty(d),
    pname = uigetdir(pwd, 'Please indicate the location of the MonkeyLogic files...');
    if pname(1) == 0,
        return
    end
    addpath(pname);
else
    pname = fileparts(d);
end

basedir = [pname filesep];
runtimedir = [basedir 'runtime' filesep];

pname = uigetdir(basedir, 'Please select the experiment directory...');
if pname(1) == 0,
    return
end
expdir = [pname filesep];

MLPrefs.Directories.BaseDirectory = basedir;
MLPrefs.Directories.RunTimeDirectory = runtimedir;
MLPrefs.Directories.ExperimentDirectory = expdir;
setpref('MonkeyLogic', 'Directories', MLPrefs.Directories);
if ispref('MonkeyLogic', 'Directories'),
    success = 1;
    MLPrefs.Directories
else
    disp('*** Unable to set directory preferences ***')
end

