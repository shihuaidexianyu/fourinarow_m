function draw_start_screen(ui, layout, config)
%DRAW_START_SCREEN Draw start page.

Screen('FillRect', ui.win, ui.colors.bg);

draw_text(ui.win, config.ui.title_text, 'center', layout.title_y, ui.colors.text);
draw_text(ui.win, config.ui.instruction_text, 'center', layout.title_y + 45, ui.colors.text);

start_label = 'START';
if isfield(config.ui, 'start_button_text')
    start_label = config.ui.start_button_text;
end
draw_buttons(ui, struct('start_game', layout.start_button), {'start_game'}, {start_label}, 'start', config);

if config.ui.show_config_summary
    human_color = ternary(config.game.human_player==1, '黑方', '白方');
    agent_color = ternary(config.game.agent_player==1, '黑方', '白方');
    first_color = ternary(config.game.first_player==1, '黑方', '白方');
    summary = sprintf(['棋盘：%d×%d（自由落点）\n' ...
        '人类：%s    电脑：%s\n' ...
        '先手：%s'], ...
        config.game.rows, config.game.cols, human_color, agent_color, first_color);
    draw_text(ui.win, summary, 'center', layout.start_button(4) + 30, ui.colors.text);
end
end

function out = ternary(cond, a, b)
if cond
    out = a;
else
    out = b;
end
end
