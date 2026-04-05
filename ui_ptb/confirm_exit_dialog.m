function should_exit = confirm_exit_dialog(ui, config)
%CONFIRM_EXIT_DIALOG Simple ESC confirmation overlay.

if nargin < 2
    config = struct();
end

should_exit = false;

dialog_text = 'Exit game?\n\nY: Exit    N: Continue';
if isfield(config, 'ui') && isfield(config.ui, 'exit_confirm_text')
    dialog_text = config.ui.exit_confirm_text;
end

Screen('FillRect', ui.win, ui.colors.bg);
draw_text(ui.win, dialog_text, 'center', 'center', ui.colors.text);
Screen('Flip', ui.win);

KbReleaseWait;

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
