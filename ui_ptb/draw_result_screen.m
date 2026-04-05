function draw_result_screen(ui, layout, state, ~)
%DRAW_RESULT_SCREEN Draw final board and result actions.

Screen('FillRect', ui.win, ui.colors.bg);
draw_board(ui, layout);
draw_pieces(ui, layout, state);

switch state.result
    case 'black_win'
        title = '黑方胜利';
    case 'white_win'
        title = '白方胜利';
    case 'draw'
        title = '平局';
    otherwise
        title = '对局结束';
end

DrawFormattedText(ui.win, title, 'center', layout.title_y, ui.colors.text);

draw_buttons(ui, layout.result_buttons, ...
    {'replay', 'back_to_start', 'exit_game'}, ...
    {'再来一局', '返回开始界面', '退出程序'}, ...
    'result');
end
