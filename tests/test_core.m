function test_core()
%TEST_CORE Basic deterministic tests for core logic.

project_root = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(project_root));

config = load_config();
state = init_game(config);

assert(all(size(state.board) == [4, 9]), 'Board size mismatch');
assert(state.current_player == config.game.first_player, 'First player mismatch');

legal = get_legal_actions(state);
assert(size(legal, 1) == 36, 'Initial legal move count should be 36');

action = struct('row', 1, 'col', 1);
assert(is_valid_action(state, action), 'Expected valid action');

[next_state, info] = apply_action(state, action);
assert(next_state.board(1, 1) == state.current_player, 'Piece not applied');
assert(next_state.move_count == 1, 'Move count not incremented');
assert(~info.is_win && ~info.is_draw, 'Unexpected terminal after first move');

% Horizontal win for black.
state = init_game(config);
state.current_player = 1;
state.board(2, 1:3) = 1;
state.move_count = 3;
[state2, info2] = apply_action(state, struct('row', 2, 'col', 4));
assert(info2.is_win, 'Expected horizontal win');
assert(strcmp(state2.result, 'black_win'), 'Expected black_win');
assert(size(state2.winning_cells, 1) >= 4, 'Winning cells should include full line');

% Vertical win for white.
state = init_game(config);
state.current_player = 2;
state.board(1:3, 7) = 2;
state.move_count = 3;
[state2, info2] = apply_action(state, struct('row', 4, 'col', 7));
assert(info2.is_win, 'Expected vertical win');
assert(strcmp(state2.result, 'white_win'), 'Expected white_win');

% Main diagonal win.
state = init_game(config);
state.current_player = 1;
state.board(1,1)=1; state.board(2,2)=1; state.board(3,3)=1;
state.move_count = 3;
info2 = apply_and_get_info(state, struct('row', 4, 'col', 4));
assert(info2.is_win, 'Expected main diagonal win');

% Anti-diagonal win.
state = init_game(config);
state.current_player = 2;
state.board(1,4)=2; state.board(2,3)=2; state.board(3,2)=2;
state.move_count = 3;
info2 = apply_and_get_info(state, struct('row', 4, 'col', 1));
assert(info2.is_win, 'Expected anti-diagonal win');

% Longer-than-4 line returns full segment.
state = init_game(config);
state.current_player = 1;
state.board(2,1:4) = 1;
state.move_count = 4;
info2 = apply_and_get_info(state, struct('row', 2, 'col', 5));
assert(info2.is_win, 'Expected win for length 5');
assert(size(info2.winning_cells, 1) == 5, 'Expected full 5-cell winning segment');

% Draw check.
state = init_game(config);
pattern = [1 2 1 2 1 2 1 2 1; 2 1 2 1 2 1 2 1 2; 1 2 1 2 1 2 1 2 1; 2 1 2 1 2 1 2 1 2];
state.board = pattern;
state.game_over = false;
assert(check_draw(state), 'Expected draw on full board');

% Invalid action rejection.
state = init_game(config);
state.board(1,1) = 1;
assert(~is_valid_action(state, struct('row',1,'col',1)), 'Occupied cell should be invalid');

disp('test_core passed.');
end

function info = apply_and_get_info(state, action)
[~, info] = apply_action(state, action);
end
