function config = load_config()
%LOAD_CONFIG 硬编码的 v1 配置。
%   所有实验参数集中在此文件中修改。

% ---- 游戏规则 ----
config.game.rows = 4;                  % 棋盘行数
config.game.cols = 9;                  % 棋盘列数
config.game.connect_n = 4;             % 连几子获胜
config.game.first_player = 1;          % 先手：1=黑方, 2=白方
config.game.human_player = 1;          % 人类执子
config.game.agent_player = 2;          % 电脑执子

if config.game.human_player == config.game.agent_player
    error('ConfigError:PlayerColorConflict', ...
        'human_player and agent_player must be different.');
end

% ---- 显示参数 ----
config.display.cell_deg = 2.0;                     % 每格视角大小（度）
config.display.piece_ratio = 0.85;                  % 棋子直径占格子边长比例
config.display.viewing_distance_cm = 60;            % 观察距离（厘米）
config.display.use_manual_screen_size = false;       % 是否手动指定屏幕物理尺寸
config.display.manual_screen_width_cm = [];          % 手动屏幕宽度（厘米）
config.display.manual_screen_height_cm = [];         % 手动屏幕高度（厘米）
config.display.screen_index = max(Screen('Screens'));% 使用的屏幕编号
config.display.fullscreen = true;                    % 是否全屏

% ---- 界面文本 ----
config.ui.illegal_message_duration_sec = 0.8;       % 非法动作提示时长（秒）
config.ui.title_text = '四子棋';
config.ui.instruction_text = '请点击开始按钮进入对局。';
config.ui.show_config_summary = true;               % 开始页是否显示配置摘要
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

% ---- Marker / EEG 打标 ----
config.marker.enable = true;                        % 是否启用 marker
config.marker.enable_illegal_click_marker = true;   % 非法点击是否打 marker
config.marker.callback = @send_marker_stub;         % marker 回调函数（默认为控制台打印）

% ---- Agent ----
config.agent.type = 'random';                       % 电脑策略类型（兼容字段）
config.agent.player_fn = @random_agent_play;        % 可替换 agent：函数句柄或函数名字符串
config.agent.move_delay_sec = 0.0;                  % 电脑落子后额外延迟（秒）

% ---- 日志 ----
config.logging.enable = true;
config.logging.save_dir = 'logs';                   % 日志保存目录（相对路径，run_game 会转为绝对）
config.logging.version = 'v1';

% ---- 事件码映射表 ----
config.events = marker_name_to_code();
end
