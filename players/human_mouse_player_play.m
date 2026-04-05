function [action, meta] = human_mouse_player_play(obs, player_config, runtime_context)
%HUMAN_MOUSE_PLAYER_PLAY Full click rule: press and release in same cell.

ui = runtime_context.ui;
layout = runtime_context.layout;
action = [];
meta = struct('aborted', false, 'is_illegal', false);

while true
    [~, ~, keyCode] = KbCheck;
    if keyCode(KbName('ESCAPE'))
        meta.aborted = true;
        return;
    end

    [mx, my, buttons] = GetMouse(ui.win);
    if buttons(1)
        down_cell = hit_test_cell(layout, mx, my);

        while any(buttons)
            [mx2, my2, buttons] = GetMouse(ui.win);
            WaitSecs(0.005);
        end

        up_cell = hit_test_cell(layout, mx2, my2);

        if ~isempty(down_cell) && ~isempty(up_cell) && all(down_cell == up_cell)
            row = down_cell(1);
            col = down_cell(2);
            if obs.board(row, col) == 0
                action.row = row;
                action.col = col;
                return;
            else
                meta.is_illegal = true;
                meta.illegal_row = row;
                meta.illegal_col = col;
                meta.illegal_time = GetSecs();
                return;
            end
        end
    end

    WaitSecs(0.005);
end
end
