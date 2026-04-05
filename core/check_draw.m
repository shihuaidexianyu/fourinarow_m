function is_draw = check_draw(state)
%CHECK_DRAW True when board is full and no winner yet.

is_draw = ~any(state.board(:) == 0) && ~state.game_over;
end
