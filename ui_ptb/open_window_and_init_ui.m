function ui = open_window_and_init_ui(config)
%OPEN_WINDOW_AND_INIT_UI Open PTB window and initialize style.

PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference', 'VBLTimestampingMode', -1);

bg = [0.5, 0.5, 0.5];
white = [1, 1, 1];
black = [0, 0, 0];
line_col = [0.08, 0.08, 0.08];
accent = [1.0, 0.31, 0.0];

screen_idx = config.display.screen_index;
if config.display.fullscreen
    [win, rect] = PsychImaging('OpenWindow', screen_idx, bg);
else
    [win, rect] = PsychImaging('OpenWindow', screen_idx, bg, [100, 100, 1200, 900]);
end

HideCursor(win);
Screen('TextFont', win, 'Microsoft YaHei UI');
Screen('TextSize', win, 28);

ui.win = win;
ui.screen_rect = rect;
ui.colors.bg = bg;
ui.colors.white = white;
ui.colors.black = black;
ui.colors.grid = line_col;
ui.colors.highlight = accent;
ui.colors.text = [0.04, 0.04, 0.04];

ui.button_style.fill = [0.82, 0.82, 0.82];
ui.button_style.border = [0.2, 0.2, 0.2];
ui.button_style.text = [0.08, 0.08, 0.08];

Priority(MaxPriority(win));
end
