function draw_start_screen(ui, layout, config)
%DRAW_START_SCREEN Draw start page.

Screen('FillRect', ui.win, ui.colors.bg);

DrawFormattedText(ui.win, config.ui.title_text, 'center', layout.title_y, ui.colors.text);
DrawFormattedText(ui.win, config.ui.instruction_text, 'center', layout.title_y + 45, ui.colors.text);

draw_buttons(ui, struct('start_game', layout.start_button), {'start_game'}, {'开始'}, 'start');

if config.ui.show_config_summary
    human_color = ternary(config.game.human_player==1, '黑', '白');
    agent_color = ternary(config.game.agent_player==1, '黑', '白');
    first_color = ternary(config.game.first_player==1, '黑', '白');
    summary = sprintf(['棋盘: %dx%d (自由落点)\n' ...
        'human: %s, agent: %s\n' ...
        '先手: %s'], ...
        config.game.rows, config.game.cols, human_color, agent_color, first_color);
    DrawFormattedText(ui.win, summary, 'center', layout.start_button(4) + 30, ui.colors.text);
end
end

function out = ternary(cond, a, b)
if cond
    out = a;
else
    out = b;
end
end
