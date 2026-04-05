function config = load_config()
%LOAD_CONFIG Hardcoded v1 configuration for PTB four-in-a-row.

config.game.rows = 4;
config.game.cols = 9;
config.game.connect_n = 4;
config.game.first_player = 1; % 1 black, 2 white
config.game.human_player = 1;
config.game.agent_player = 2;

if config.game.human_player == config.game.agent_player
    error('ConfigError:PlayerColorConflict', ...
        'human_player and agent_player must be different.');
end

config.display.cell_deg = 2.0;
config.display.piece_ratio = 0.85;
config.display.viewing_distance_cm = 60;
config.display.use_manual_screen_size = false;
config.display.manual_screen_width_cm = [];
config.display.manual_screen_height_cm = [];
config.display.screen_index = max(Screen('Screens'));
config.display.fullscreen = true;

config.ui.illegal_message_duration_sec = 0.8;
config.ui.title_text = '四子棋';
config.ui.instruction_text = '请点击开始按钮进入对局。';
config.ui.show_config_summary = true;
config.ui.hide_cursor = false;
config.ui.turn_black_text = '轮到：黑方';
config.ui.turn_white_text = '轮到：白方';
config.ui.illegal_text = '非法动作，请重试';
config.ui.black_win_text = '黑方获胜';
config.ui.white_win_text = '白方获胜';
config.ui.draw_text = '平局';
config.ui.game_over_text = '游戏结束';
config.ui.start_button_text = '开始';
config.ui.replay_button_text = '再来一局';
config.ui.back_button_text = '返回开始界面';
config.ui.exit_button_text = '退出程序';
config.ui.exit_confirm_text = '是否退出游戏？\n\nY：退出    N：继续';
config.ui.result_hint_text = '点击按钮继续，或按 ESC 退出。';

config.marker.enable = true;
config.marker.enable_illegal_click_marker = true;
config.marker.callback = @send_marker_stub;

config.agent.type = 'random';
config.agent.move_delay_sec = 0.0;

config.logging.enable = true;
config.logging.save_dir = 'logs';
config.logging.version = 'v1';

config.events = marker_name_to_code();
end
