function success = monkeylogic_alert(aswitch, TrialRecord, Alerts)
%
% This function is called by monkeylogic to send an update or alert
% to the user.  The way in which this alert is sent is up to the individual
% end-user (e.g., text message, page, etc).

% aswitch = 1: BlockUpdates
% aswitch = 2: Infrequent non-error event
% aswitch = 3: User-defined criteria and alert message
% aswitch = 4: Error event

success = 1;
if ~Alerts.Enable,
    return
end

if aswitch == 1, %standard update after each block
    
    if ~Alerts.BlockUpdates,
        return
    end
    
    trial = TrialRecord.CurrentTrialNumber - 1; %already updated to unplayed next trial in monkeylogic, so back up one trial
    if trial == 0,
        return
    end
    overall_correct = sum(~TrialRecord.TrialErrors)/trial;
    lastblocknumber = TrialRecord.BlockCount(length(TrialRecord.BlockCount));
    lastblock = find(TrialRecord.BlockCount == lastblocknumber);
    bnumtrials = length(lastblock);
    bperformance = TrialRecord.TrialErrors(lastblock);
    lastblock_correct = sum(~bperformance)/bnumtrials;
    lastblock_noresponse = sum(bperformance == 1)/bnumtrials;
    lastblock_late = sum(bperformance == 2)/bnumtrials;
    lastblock_brokefix = sum(bperformance == 3)/bnumtrials;
    lastblock_nofix = sum(bperformance == 4)/bnumtrials;
    lastblock_early = sum(bperformance == 5)/bnumtrials;
    lastblock_incorrect = sum(bperformance == 6)/bnumtrials;

    alertstring = sprintf('MonkeyLogic Update: Last Block (#%i): %2.0f%% correct, %2.0f%% no response, %2.0f%% late, %2.0f%% broke fix, %2.0f%% no fix, %2.0f%% early, %2.0f%% incorrect. Overall: %2.0f%% correct', lastblocknumber, lastblock_correct, lastblock_noresponse, lastblock_late, lastblock_brokefix, lastblock_nofix, lastblock_early, lastblock_incorrect, overall_correct);
    
elseif aswitch == 2, %infrequent, non-error, event
    
    alertstring = TrialRecord;
    alertstring = ['MonkeyLogic Alert: ' alertstring];
    
elseif aswitch == 3, %user-defined criteria (if any)
    
    if ~Alerts.UserCriteria,
        return
    end
    
    try
        alertstring = feval(Alerts.UserCriteriaFunctionName, TrialRecord);
    catch
        success = 0;
        return
    end
    
elseif aswitch == 4, %error event
    
    if ~Alerts.ErrorAlerts,
        return
    end
    
    alertstring = TrialRecord;
    alertstring = ['MonkeyLogic Error: ' alertstring];
    
end

if ~isempty(alertstring),
    try
        feval(Alerts.FunctionName, alertstring);
    catch
        success = 0;
        return
    end
end
