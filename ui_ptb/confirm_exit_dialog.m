function should_exit = confirm_exit_dialog(ui)
%CONFIRM_EXIT_DIALOG Simple ESC confirmation overlay.

should_exit = false;

Screen('FillRect', ui.win, ui.colors.bg);
DrawFormattedText(ui.win, '确认退出？\n\nY: 退出    N: 继续', 'center', 'center', ui.colors.text);
Screen('Flip', ui.win);

while true
    [~, ~, keyCode] = KbCheck;
    if keyCode(KbName('Y')) || keyCode(KbName('y'))
        should_exit = true;
        break;
    end
    if keyCode(KbName('N')) || keyCode(KbName('n')) || keyCode(KbName('ESCAPE'))
        break;
    end
    WaitSecs(0.01);
end
end
