function ui = open_window_and_init_ui(config)
%OPEN_WINDOW_AND_INIT_UI Open PTB window and initialize style.

PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 1);

bg = [128, 128, 128];
white = [255, 255, 255];
black = [0, 0, 0];
line_col = [20, 20, 20];
accent = [255, 80, 0];

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
ui.colors.text = [10, 10, 10];

ui.button_style.fill = [210, 210, 210];
ui.button_style.border = [50, 50, 50];
ui.button_style.text = [20, 20, 20];

Priority(MaxPriority(win));
end
