function varargout = trackvarchanges(trial)
%tracks changes made to "editable" variables for storage in the BHV data file
%modified 2/4/13 - DF (to fix editable variables bug)
persistent VarChanges
    
if trial == -1,
    varargout{1} = VarChanges;
    return
end

if trial == -2			%This tells monkeylogic to clear VarChanges. Usually called when an experiment is aborted or at the end of an experiment.
	clear VarChanges;
	return
end

VV = get(findobj('tag', 'loadbutton'), 'userdata');
fn = fieldnames(VV);
numf = length(fn);

if isempty(VarChanges),
    for i = 1:numf,
        VarChanges.(fn{i}).Trial = [];
        VarChanges.(fn{i}).Value = [];
    end
end
for i = 1:numf,
    currentval = VV.(fn{i});
    if isfield(VarChanges, fn{i}),
        tlist = VarChanges.(fn{i}).Trial;
        vlist = VarChanges.(fn{i}).Value;
        appendflag = 1;
        if ~isempty(tlist),
            if currentval == vlist(length(vlist)),
                appendflag = 0;
            end
        end
        if appendflag,
            tlist = [tlist trial]; %#ok<AGROW>
            vlist = [vlist currentval]; %#ok<AGROW>
            VarChanges.(fn{i}).Trial = tlist;
            VarChanges.(fn{i}).Value = vlist;
        end
    end
end
