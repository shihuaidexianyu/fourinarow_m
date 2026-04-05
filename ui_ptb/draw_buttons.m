function draw_buttons(ui, button_map, ids, labels, screen_name)
%DRAW_BUTTONS Draw one or more rectangular buttons.

for i = 1:numel(ids)
    id = ids{i};
    rect = button_map.(id);

    Screen('FillRect', ui.win, ui.button_style.fill, rect);
    Screen('FrameRect', ui.win, ui.button_style.border, rect, 2);

    DrawFormattedText(ui.win, labels{i}, 'center', 'center', ui.button_style.text, [], [], [], [], [], rect);
end

if strcmp(screen_name, 'result')
    DrawFormattedText(ui.win, '点击按钮继续，或按 ESC 退出', 'center', button_map.exit_game(4)+25, ui.colors.text);
end
end
