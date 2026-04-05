function state = init_game(config)
%INIT_GAME Initialize game state.

rows = config.game.rows;
cols = config.game.cols;

state.board = zeros(rows, cols);
state.connect_n = config.game.connect_n;
state.current_player = config.game.first_player;
state.first_player = config.game.first_player;
state.move_count = 0;
state.last_action = [];
state.game_over = false;
state.result = 'ongoing';
state.winning_cells = zeros(0, 2);
state.winning_line = struct('start_row', [], 'start_col', [], 'end_row', [], 'end_col', []);
end
