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
    DrawFormattedText(ui.win, label, 'center', 'center', ui.button_style.text, [], [], [], [], [], rect);
end

if strcmp(screen_name, 'result')
    hint = 'Click a button to continue, or press ESC to exit.';
    if isfield(config, 'ui') && isfield(config.ui, 'result_hint_text')
        hint = config.ui.result_hint_text;
    end
    draw_text(ui.win, hint, 'center', button_map.exit_game(4)+25, ui.colors.text);
end
end
