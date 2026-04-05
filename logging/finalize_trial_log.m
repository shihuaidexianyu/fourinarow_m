function trial = finalize_trial_log(trial, state)
%FINALIZE_TRIAL_LOG Finalize result and end time.

trial.end_datetime = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'));

if nargin >= 2 && ~isempty(state)
    trial.result = state.result;
    trial.aborted = strcmp(state.result, 'aborted');
end
end
