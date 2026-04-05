function trial = log_illegal_click(trial, player, row, col, t, move_count)
%LOG_ILLEGAL_CLICK Append one illegal click record.

entry.player = player;
entry.row = row;
entry.col = col;
entry.time = t;
entry.move_count = move_count;

if isempty(trial.illegal_clicks)
    trial.illegal_clicks = entry;
else
    trial.illegal_clicks(end + 1) = entry;
end

trial.illegal_click_count = trial.illegal_click_count + 1;
end
