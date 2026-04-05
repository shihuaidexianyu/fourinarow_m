function draw_game_screen(ui, layout, state, transient_ui)
%DRAW_GAME_SCREEN Draw board, pieces and status text.

if nargin < 4
    transient_ui = struct();
end

Screen('FillRect', ui.win, ui.colors.bg);
draw_board(ui, layout);
draw_pieces(ui, layout, state);

status_text = '';
if isfield(transient_ui, 'status_text')
    status_text = transient_ui.status_text;
end

if isfield(transient_ui, 'illegal_until') && GetSecs() <= transient_ui.illegal_until
    status_text = 'Illegal move. Please try again.';
end

if isempty(status_text)
    if state.current_player == 1
        status_text = 'Turn: Black';
    else
        status_text = 'Turn: White';
    end
end

DrawFormattedText(ui.win, status_text, 'center', layout.status_y, ui.colors.text);
end
