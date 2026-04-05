function is_valid = is_valid_action(state, action)
%IS_VALID_ACTION Check action validity.

if state.game_over
    is_valid = false;
    return;
end

if ~isstruct(action) || ~isfield(action, 'row') || ~isfield(action, 'col')
    is_valid = false;
    return;
end

row = action.row;
col = action.col;

if ~isscalar(row) || ~isscalar(col) || row ~= floor(row) || col ~= floor(col)
    is_valid = false;
    return;
end

rows = size(state.board, 1);
cols = size(state.board, 2);
if row < 1 || row > rows || col < 1 || col > cols
    is_valid = false;
    return;
end

is_valid = (state.board(row, col) == 0);
end
