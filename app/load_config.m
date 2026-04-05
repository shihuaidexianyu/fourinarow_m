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
config.ui.title_text = 'Four-in-a-Row';
config.ui.instruction_text = 'Click START to begin.';
config.ui.show_config_summary = true;

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
