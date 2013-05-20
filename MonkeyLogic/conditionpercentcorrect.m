function pc = conditionpercentcorrect(bhvfile)
    bhv = bhv_read(bhvfile);
    
    conditions = unique(bhv.ConditionNumber)';
    
    pc = zeros(length(conditions),2);
    
    for i = 1:length(conditions)
        pc(i,1) = i;
        pc(i,2) = length(find(bhv.ConditionNumber == conditions(i) & bhv.TrialError == 0))/length(find(bhv.ConditionNumber == conditions(i)));
    end
end