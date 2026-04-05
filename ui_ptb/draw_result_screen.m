function draw_result_screen(ui, layout, state, config)
%DRAW_RESULT_SCREEN 绘制结果页：棋盘（含高亮）、结果文字、自动进入下一局提示。

if nargin < 4, config = struct(); end

Screen('FillRect', ui.win, ui.colors.bg);
draw_board(ui, layout);
draw_pieces(ui, layout, state);   % 含胜利高亮

has_ui_cfg = isfield(config, 'ui');

% ---- 结果标题 ----
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

hint = get_cfg_text(config, has_ui_cfg, 'result_hint_text', 'Auto continue to next trial, or press ESC to exit.');
draw_text(ui.win, hint, 'center', layout.status_y, ui.colors.text);
end

function out = get_cfg_text(config, has_ui_cfg, field_name, fallback)
%GET_CFG_TEXT 从 config.ui 读取文本，不存在则返回 fallback。
if has_ui_cfg && isfield(config.ui, field_name)
    out = config.ui.(field_name);
else
    out = fallback;
end
end
