function [action, meta] = human_mouse_player_play(obs, player_config, runtime_context)
%HUMAN_MOUSE_PLAYER_PLAY Full click rule: press and release in same cell.

ui = runtime_context.ui;
layout = runtime_context.layout;
action = [];
meta = struct('aborted', false, 'is_illegal', false);

if nargin < 2
    player_config = struct();
end

duration = 0.8;
if isfield(player_config, 'ui') && isfield(player_config.ui, 'illegal_message_duration_sec')
    duration = player_config.ui.illegal_message_duration_sec;
end

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

                transient.status_text = 'Illegal move. Please try again.';
                transient.illegal_until = GetSecs() + duration;
                draw_game_screen(ui, layout, struct( ...
                    'board', obs.board, ...
                    'current_player', obs.current_player, ...
                    'winning_cells', zeros(0,2), ...
                    'result', 'ongoing', ...
                    'game_over', false), transient);
                Screen('Flip', ui.win);
            end
        end
    end

    WaitSecs(0.005);
end
end
