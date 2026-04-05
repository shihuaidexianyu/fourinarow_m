function draw_buttons(ui, button_map, ids, labels, screen_name, config)
%DRAW_BUTTONS Draw one or more rectangular buttons.

if nargin < 6
    config = struct();
end

for i = 1:numel(ids)
    id = ids{i};
    rect = button_map.(id);

    Screen('FillRect', ui.win, ui.button_style.fill, rect);
    Screen('FrameRect', ui.win, ui.button_style.border, rect, 2);

    label = labels{i};
    if ischar(label)
        label = double(label);
    end
    tb = Screen('TextBounds', ui.win, label);
    tw = tb(3) - tb(1);
    th = tb(4) - tb(2);
    tx = rect(1) + round((rect(3) - rect(1) - tw) / 2);
    ty = rect(2) + round((rect(4) - rect(2) - th) / 2);
    Screen('DrawText', ui.win, label, tx, ty, ui.button_style.text);
end

if strcmp(screen_name, 'result')
    hint = 'Click a button to continue, or press ESC to exit.';
    if isfield(config, 'ui') && isfield(config.ui, 'result_hint_text')
        hint = config.ui.result_hint_text;
    end
    draw_text(ui.win, hint, 'center', button_map.exit_game(4)+25, ui.colors.text);
end
end
