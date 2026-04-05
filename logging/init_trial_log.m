function trial = init_trial_log(config, ui, layout)
%INIT_TRIAL_LOG Initialize per-game log struct.

trial = struct();
trial.game_id = char(java.util.UUID.randomUUID);
trial.start_datetime = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'));
trial.end_datetime = '';
trial.result = 'ongoing';
trial.aborted = false;

trial.first_player = config.game.first_player;
trial.human_player = config.game.human_player;
trial.agent_player = config.game.agent_player;

trial.screen_info = struct();
trial.screen_info.width_px = ui.screen_rect(3);
trial.screen_info.height_px = ui.screen_rect(4);
trial.screen_info.width_cm = layout.screen_width_cm;
trial.screen_info.height_cm = layout.screen_height_cm;
trial.viewing_distance_cm = config.display.viewing_distance_cm;

trial.config_snapshot = config;
trial.marker_events = struct([]);
trial.moves = struct([]);
trial.illegal_clicks = struct([]);
trial.illegal_click_count = 0;
end
