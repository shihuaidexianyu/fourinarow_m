function draw_start_screen(ui, ~, config)
%DRAW_START_SCREEN 绘制开始页：标题、实验说明、配置摘要与键盘提示。

Screen('FillRect', ui.win, ui.colors.bg);

% 使用顺序布局避免多行文本重叠
y = 60;
[~, y_after_title] = draw_text(ui.win, config.ui.title_text, 'center', y, ui.colors.text);

y = y_after_title + 18;
[~, y_after_instruction] = draw_text(ui.win, config.ui.instruction_text, 'center', y, ui.colors.text);

% 配置摘要
if config.ui.show_config_summary
    human_color = ternary(config.game.human_player==1, '黑方', '白方');
    agent_color = ternary(config.game.agent_player==1, '黑方', '白方');
    first_color = ternary(config.game.first_player==1, '黑方', '白方');
    summary = sprintf(['棋盘：%d×%d（自由落点）\n' ...
        '人类：%s    电脑：%s\n' ...
        '先手：%s'], ...
        config.game.rows, config.game.cols, human_color, agent_color, first_color);
    y = y_after_instruction + 20;
    [~, y_after_summary] = draw_text(ui.win, summary, 'center', y, ui.colors.text);
else
    y_after_summary = y_after_instruction;
end

if isfield(config.ui, 'start_hint_text')
    y = y_after_summary + 22;
    draw_text(ui.win, config.ui.start_hint_text, 'center', y, ui.colors.text);
end
end

function out = ternary(cond, a, b)
if cond, out = a; else, out = b; end
end
