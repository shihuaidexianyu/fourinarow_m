function draw_result_screen(ui, layout, state, config)
%DRAW_RESULT_SCREEN Draw final board and result actions.

if nargin < 4
    config = struct();
end

Screen('FillRect', ui.win, ui.colors.bg);
draw_board(ui, layout);
draw_pieces(ui, layout, state);

has_ui_cfg = isfield(config, 'ui');

switch state.result
    case 'black_win'
        title = get_cfg_text(config, has_ui_cfg, 'black_win_text', 'Black wins');
    case 'white_win'
        title = get_cfg_text(config, has_ui_cfg, 'white_win_text', 'White wins');
    case 'draw'
        title = get_cfg_text(config, has_ui_cfg, 'draw_text', 'Draw');
    otherwise
        title = get_cfg_text(config, has_ui_cfg, 'game_over_text', 'Game Over');
end

draw_text(ui.win, title, 'center', layout.title_y, ui.colors.text);

labels = { ...
    get_cfg_text(config, has_ui_cfg, 'replay_button_text', 'Play Again'), ...
    get_cfg_text(config, has_ui_cfg, 'back_button_text', 'Back to Start'), ...
    get_cfg_text(config, has_ui_cfg, 'exit_button_text', 'Exit')};

draw_buttons(ui, layout.result_buttons, ...
    {'replay', 'back_to_start', 'exit_game'}, ...
    labels, ...
    'result', config);
end

function out = get_cfg_text(config, has_ui_cfg, field_name, fallback)
if has_ui_cfg && isfield(config.ui, field_name)
    out = config.ui.(field_name);
else
    out = fallback;
end
end
