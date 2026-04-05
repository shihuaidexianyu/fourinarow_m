function layout = compute_visual_layout(ui, config)
%COMPUTE_VISUAL_LAYOUT Compute board/button rectangles from visual angle.

screen_w_px = ui.screen_rect(3);
screen_h_px = ui.screen_rect(4);

if config.display.use_manual_screen_size
    screen_w_cm = config.display.manual_screen_width_cm;
    screen_h_cm = config.display.manual_screen_height_cm;
else
    [screen_w_mm, screen_h_mm] = Screen('DisplaySize', config.display.screen_index);
    screen_w_cm = screen_w_mm / 10;
    screen_h_cm = screen_h_mm / 10;
end

if isempty(screen_w_cm) || isempty(screen_h_cm) || screen_w_cm <= 0 || screen_h_cm <= 0
    error('DisplayError:ScreenPhysicalSizeInvalid', ...
        'Invalid physical screen size: width=%.4fcm height=%.4fcm', screen_w_cm, screen_h_cm);
end

px_per_cm_x = screen_w_px / screen_w_cm;
px_per_cm_y = screen_h_px / screen_h_cm;
px_per_cm = min(px_per_cm_x, px_per_cm_y);

cell_cm = deg2cm(config.display.cell_deg, config.display.viewing_distance_cm);
cell_px = cm2px(cell_cm, px_per_cm);
piece_diameter_px = max(6, round(config.display.piece_ratio * cell_px));

board_w_px = config.game.cols * cell_px;
board_h_px = config.game.rows * cell_px;

title_h = 80;
status_h = 70;
button_h = 200;
margin_h = 80;
reserved_h = title_h + status_h + button_h + margin_h;

assert_display_fits(screen_w_px, screen_h_px, board_w_px, board_h_px, reserved_h, struct( ...
    'screen_w_cm', screen_w_cm, ...
    'screen_h_cm', screen_h_cm, ...
    'distance_cm', config.display.viewing_distance_cm, ...
    'cell_deg', config.display.cell_deg));

board_left = round((screen_w_px - board_w_px) / 2);
board_top = round((screen_h_px - board_h_px) / 2);
board_rect = [board_left, board_top, board_left + board_w_px, board_top + board_h_px];

cell_rects = zeros(config.game.rows, config.game.cols, 4);
for r = 1:config.game.rows
    for c = 1:config.game.cols
        l = board_left + (c - 1) * cell_px;
        t = board_top + (r - 1) * cell_px;
        cell_rects(r, c, :) = [l, t, l + cell_px, t + cell_px];
    end
end

btn_w = 320;
btn_h = 68;
btn_gap = 24;
start_btn = [round((screen_w_px - btn_w)/2), round(board_rect(4) + 48), ...
    round((screen_w_px - btn_w)/2) + btn_w, round(board_rect(4) + 48) + btn_h];

res_btn_top = round(board_rect(4) + 48);
result_buttons.replay = [round((screen_w_px - btn_w)/2), res_btn_top, ...
    round((screen_w_px - btn_w)/2)+btn_w, res_btn_top+btn_h];
result_buttons.back_to_start = [round((screen_w_px - btn_w)/2), res_btn_top + btn_h + btn_gap, ...
    round((screen_w_px - btn_w)/2)+btn_w, res_btn_top + 2*btn_h + btn_gap];
result_buttons.exit_game = [round((screen_w_px - btn_w)/2), res_btn_top + 2*(btn_h + btn_gap), ...
    round((screen_w_px - btn_w)/2)+btn_w, res_btn_top + 3*btn_h + 2*btn_gap];

layout.screen_width_cm = screen_w_cm;
layout.screen_height_cm = screen_h_cm;
layout.px_per_cm = px_per_cm;
layout.cell_size_px = cell_px;
layout.piece_diameter_px = piece_diameter_px;
layout.board_rect = board_rect;
layout.cell_rects = cell_rects;
layout.start_button = start_btn;
layout.result_buttons = result_buttons;
layout.title_y = board_rect(2) - 90;
layout.status_y = board_rect(4) + 18;
end
