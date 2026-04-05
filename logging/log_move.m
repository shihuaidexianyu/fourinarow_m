function trial = log_move(trial, state, player, action, rt, response_time, stimulus_time)
%LOG_MOVE Append one legal move record.

entry.player = player;
entry.row = action.row;
entry.col = action.col;
entry.rt = rt;
entry.response_time = response_time;
entry.stimulus_time = stimulus_time;
entry.move_count = state.move_count;
entry.board_after = state.board;

if isempty(trial.moves)
    trial.moves = entry;
else
    trial.moves(end + 1) = entry;
end
end
