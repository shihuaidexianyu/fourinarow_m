function draw_result_screen(ui, layout, state, ~)
%DRAW_RESULT_SCREEN Draw final board and result actions.

Screen('FillRect', ui.win, ui.colors.bg);
draw_board(ui, layout);
draw_pieces(ui, layout, state);

switch state.result
    case 'black_win'
        title = 'Black wins';
    case 'white_win'
        title = 'White wins';
    case 'draw'
        title = 'Draw';
    otherwise
        title = 'Game Over';
end

DrawFormattedText(ui.win, title, 'center', layout.title_y, ui.colors.text);

draw_buttons(ui, layout.result_buttons, ...
    {'replay', 'back_to_start', 'exit_game'}, ...
    {'Play Again', 'Back to Start', 'Exit'}, ...
    'result');
end
