function [next_state, apply_info] = apply_action(state, action)
%APPLY_ACTION Apply one valid action and update terminal flags.

if ~is_valid_action(state, action)
    error('GameError:InvalidAction', 'Invalid action row=%d col=%d', action.row, action.col);
end

next_state = state;
player = state.current_player;
next_state.board(action.row, action.col) = player;
next_state.last_action = action;
next_state.move_count = state.move_count + 1;

[is_win, winning_cells, winning_line] = check_winner(next_state, action);
if is_win
    next_state.game_over = true;
    if player == 1
        next_state.result = 'black_win';
    else
        next_state.result = 'white_win';
    end
    next_state.winning_cells = winning_cells;
    next_state.winning_line = winning_line;
    apply_info.is_win = true;
    apply_info.is_draw = false;
    apply_info.result = next_state.result;
    apply_info.winning_cells = winning_cells;
    apply_info.winning_line = winning_line;
    return;
end

is_draw = check_draw(next_state);
if is_draw
    next_state.game_over = true;
    next_state.result = 'draw';
else
    next_state.current_player = 3 - state.current_player;
end

apply_info.is_win = false;
apply_info.is_draw = is_draw;
apply_info.result = next_state.result;
apply_info.winning_cells = next_state.winning_cells;
apply_info.winning_line = next_state.winning_line;
end
