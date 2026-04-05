function should_exit = confirm_exit_dialog(ui, config)
%CONFIRM_EXIT_DIALOG ESC 退出确认对话框。
%   按 Y 确认退出，按 N 或 ESC 取消。

if nargin < 2, config = struct(); end

should_exit = false;

% 对话框文字
dialog_text = 'Exit game?\n\nY: Exit    N: Continue';
if isfield(config, 'ui') && isfield(config.ui, 'exit_confirm_text')
    dialog_text = config.ui.exit_confirm_text;
end

Screen('FillRect', ui.win, ui.colors.bg);
draw_text(ui.win, dialog_text, 'center', 'center', ui.colors.text);
Screen('Flip', ui.win);

KbReleaseWait;  % 等待之前的按键释放，防止 ESC 残留导致立即关闭

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
