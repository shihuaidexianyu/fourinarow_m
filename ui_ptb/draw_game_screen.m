function draw_game_screen(ui, layout, state, transient_ui, config)
%DRAW_GAME_SCREEN Draw board, pieces and status text.

if nargin < 4
    transient_ui = struct();
end
if nargin < 5
    config = struct();
end

Screen('FillRect', ui.win, ui.colors.bg);
draw_board(ui, layout);
draw_pieces(ui, layout, state);

status_text = '';
if isfield(transient_ui, 'status_text')
    status_text = transient_ui.status_text;
end

if isfield(transient_ui, 'illegal_until') && GetSecs() <= transient_ui.illegal_until
    if isfield(config, 'ui') && isfield(config.ui, 'illegal_text')
        status_text = config.ui.illegal_text;
    else
        status_text = 'Illegal move. Please try again.';
    end
end

if isempty(status_text)
    if state.current_player == 1
        if isfield(config, 'ui') && isfield(config.ui, 'turn_black_text')
            status_text = config.ui.turn_black_text;
        else
            status_text = 'Turn: Black';
        end
    else
        if isfield(config, 'ui') && isfield(config.ui, 'turn_white_text')
            status_text = config.ui.turn_white_text;
        else
            status_text = 'Turn: White';
        end
    end
end

draw_text(ui.win, status_text, 'center', layout.status_y, ui.colors.text);
end
