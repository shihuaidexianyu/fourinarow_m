function main_loop(config)
%MAIN_LOOP 程序主循环 / 状态机驱动。
%   键盘模式流程：start_screen -> fixed_trials -> auto_result -> cleanup。
%   ESC 可在任意阶段中止。

% 检查 Psychtoolbox 是否可用
if ~exist('Screen', 'file')
    error('DependencyError:PsychtoolboxMissing', ...
        'Psychtoolbox Screen function is not available.');
end

trial_log = [];
cleanup_obj = onCleanup(@safe_cleanup); %#ok<NASGU>  % 异常退出时确保 PTB 资源释放

try
    ui = open_window_and_init_ui(config);           % 打开 PTB 窗口
    layout = compute_visual_layout(ui, config);     % 计算棋盘/按钮布局
    total_trials = config.game.num_trials;
    experiment_id = char(java.util.UUID.randomUUID);

    % ===== 开始页：仅键盘控制 =====
    draw_start_screen(ui, layout, config);
    [~, start_stimulus_time] = Screen('Flip', ui.win);
    start_choice = wait_start_choice(config.controls);

    if strcmp(start_choice, 'abort')
        emit_marker(config, 'game_abort_esc', GetSecs(), struct('result', 'aborted', 'phase', 'start_screen'));
        return;
    end

    emit_marker(config, 'session_enter_game', start_stimulus_time, ...
        struct('experiment_id', experiment_id, 'total_trials', total_trials));

    % ===== 固定 trials 主循环 =====
    for trial_index = 1:total_trials
        state = init_game(config);
        trial_log = init_trial_log(config, ui, layout, experiment_id, trial_index, total_trials);
        human_cursor = init_cursor_from_board(state.board);

        [config, trial_log] = emit_and_log(config, trial_log, 'game_start', GetSecs(), ...
            struct('experiment_id', experiment_id, 'trial_index', trial_index, 'total_trials', total_trials));

        transient_ui = struct();
        transient_ui.illegal_until = -inf;  % 非法提示过期时刻（初始无提示）

        while ~state.game_over
            transient_ui.status_text = ternary(state.current_player==1, config.ui.turn_black_text, config.ui.turn_white_text);
            if state.current_player == config.game.human_player
                transient_ui.selected_cell = [human_cursor.row, human_cursor.col];
            else
                transient_ui.selected_cell = [];
            end

            draw_game_screen(ui, layout, state, transient_ui, config);
            [~, board_ready_time] = Screen('Flip', ui.win);

            % 构造传给 player 的观察量
            obs.board = state.board;
            obs.current_player = state.current_player;
            obs.legal_actions = get_legal_actions(state);
            obs.last_action = state.last_action;
            obs.move_count = state.move_count;
            obs.game_over = state.game_over;

            response_t0 = board_ready_time;  % 反应时起点 = 棋盘刷新完成时刻

            % 调用当前玩家
            if state.current_player == config.game.human_player
                runtime_context = struct('ui', ui, 'layout', layout, 'state', state, ...
                    'transient_ui', transient_ui, 'config', config, 'cursor', human_cursor);
                [action, meta, human_cursor] = human_keyboard_player_play(obs, config.controls, runtime_context);
                actor = 'human';
            else
                [action, meta] = call_agent_player(obs, config.agent, struct());
                if config.agent.move_delay_sec > 0
                    WaitSecs(config.agent.move_delay_sec);
                end
                actor = 'agent';
            end

            % ---- 空动作处理（中止或非法输入）----
            if isempty(action)
                if isfield(meta, 'aborted') && meta.aborted
                    [config, trial_log] = emit_and_log(config, trial_log, 'game_abort_esc', GetSecs(), struct('result', 'aborted', 'trial_index', trial_index));
                    state.result = 'aborted';
                    state.game_over = true;
                    break;
                end

                if isfield(meta, 'is_illegal') && meta.is_illegal
                    trial_log = log_illegal_click(trial_log, state.current_player, ...
                        meta.illegal_row, meta.illegal_col, meta.illegal_time, state.move_count);
                    if config.marker.enable_illegal_click_marker
                        payload = struct('player', state.current_player, 'row', meta.illegal_row, 'col', meta.illegal_col, ...
                            'move_count', state.move_count, 'is_illegal', true, 'trial_index', trial_index);
                        [config, trial_log] = emit_and_log(config, trial_log, 'response_illegal_click', meta.illegal_time, payload);
                    end
                    transient_ui.status_text = config.ui.illegal_text;
                    transient_ui.illegal_until = GetSecs() + config.ui.illegal_message_duration_sec;
                end
                continue;
            end

            % ---- 合法落子 ----
            response_time = GetSecs();
            rt = response_time - response_t0;

            if strcmp(actor, 'human')
                [config, trial_log] = emit_and_log(config, trial_log, 'response_human_move', response_time, ...
                    struct('player', state.current_player, 'row', action.row, 'col', action.col, ...
                    'move_count', state.move_count + 1, 'rt', rt, 'result', 'ongoing', 'trial_index', trial_index));
            else
                [config, trial_log] = emit_and_log(config, trial_log, 'response_agent_move', response_time, ...
                    struct('player', state.current_player, 'row', action.row, 'col', action.col, ...
                    'move_count', state.move_count + 1, 'rt', rt, 'result', 'ongoing', 'trial_index', trial_index));
            end

            [next_state, apply_info] = apply_action(state, action);
            move_player = state.current_player;
            state = next_state;

            if state.current_player == config.game.human_player
                transient_ui.selected_cell = [human_cursor.row, human_cursor.col];
            else
                transient_ui.selected_cell = [];
            end
            draw_game_screen(ui, layout, state, transient_ui, config);
            [~, stimulus_time] = Screen('Flip', ui.win);

            if strcmp(actor, 'human')
                [config, trial_log] = emit_and_log(config, trial_log, 'stimulus_human_move_shown', stimulus_time, struct('trial_index', trial_index));
            else
                [config, trial_log] = emit_and_log(config, trial_log, 'stimulus_agent_move_shown', stimulus_time, struct('trial_index', trial_index));
            end

            trial_log = log_move(trial_log, state, move_player, action, rt, response_time, stimulus_time);

            if apply_info.is_win || apply_info.is_draw
                break;
            end
        end

        % 结果页（自动推进，支持 ESC 中止）
        if strcmp(state.result, 'black_win')
            [config, trial_log] = emit_and_log(config, trial_log, 'game_end_black_win', GetSecs(), struct('result', state.result, 'move_count', state.move_count, 'trial_index', trial_index));
        elseif strcmp(state.result, 'white_win')
            [config, trial_log] = emit_and_log(config, trial_log, 'game_end_white_win', GetSecs(), struct('result', state.result, 'move_count', state.move_count, 'trial_index', trial_index));
        elseif strcmp(state.result, 'draw')
            [config, trial_log] = emit_and_log(config, trial_log, 'game_end_draw', GetSecs(), struct('result', state.result, 'move_count', state.move_count, 'trial_index', trial_index));
        end

        draw_result_screen(ui, layout, state, config);
        [~, result_stim_time] = Screen('Flip', ui.win);
        [config, trial_log] = emit_and_log(config, trial_log, 'stimulus_result_shown', result_stim_time, ...
            struct('result', state.result, 'trial_index', trial_index));

        aborted_on_result = wait_duration_or_abort(config.ui.result_display_duration_sec, config.controls.abort);
        if aborted_on_result
            [config, trial_log] = emit_and_log(config, trial_log, 'game_abort_esc', GetSecs(), ...
                struct('result', 'aborted', 'phase', 'result', 'trial_index', trial_index));
            state.result = 'aborted';
            state.game_over = true;
        end

        trial_log = finalize_trial_log(trial_log, state);
        save_trial_log(trial_log, config);
        trial_log = [];

        if strcmp(state.result, 'aborted')
            break;
        end
    end

catch ME
    % 异常退出时尝试保存日志
    if ~isempty(trial_log)
        try
            trial_log.aborted = true;
            trial_log.result = 'aborted';
            trial_log.error = ME.message;
            save_trial_log(trial_log, config);
        catch
        end
    end

    rethrow(ME);
end
end

%% ---- 内部辅助函数 ----

function safe_cleanup()
%SAFE_CLEANUP 确保 PTB 资源被释放（优先级、光标、窗口）。
try Priority(0); catch, end
try ShowCursor;   catch, end
try sca;          catch, end
end

function [config_out, trial_log] = emit_and_log(config_in, trial_log, event_name, timestamp, payload)
%EMIT_AND_LOG 同时发送 marker 并写入日志。
config_out = config_in;
emit_marker(config_in, event_name, timestamp, payload);

if ~isempty(trial_log) && isfield(config_in, 'events') && isa(config_in.events, 'containers.Map') && isKey(config_in.events, event_name)
    code = config_in.events(event_name);
    trial_log = log_marker_event(trial_log, code, event_name, timestamp, payload);
end
end

function out = ternary(cond, a, b)
%TERNARY 三目运算辅助。
if cond, out = a; else, out = b; end
end

function choice = wait_start_choice(controls)
%WAIT_START_CHOICE 开始页等待按键：确认开始 / ESC 中止。
keycodes = build_control_keycodes(controls);

while true
    [is_down, ~, key_code] = KbCheck;
    if is_down
        if any(key_code(keycodes.abort))
            choice = 'abort';
            wait_key_release();
            return;
        end
        if any(key_code(keycodes.confirm))
            choice = 'start';
            wait_key_release();
            return;
        end
        wait_key_release();
    end
    WaitSecs(0.005);
end
end

function aborted = wait_duration_or_abort(duration_sec, abort_keys)
%WAIT_DURATION_OR_ABORT 停留一段时间；期间若按 ESC 则返回中止。
aborted = false;
if duration_sec <= 0
    return;
end

abort_codes = key_names_to_codes(abort_keys);
t_end = GetSecs() + duration_sec;

while GetSecs() < t_end
    [is_down, ~, key_code] = KbCheck;
    if is_down && any(key_code(abort_codes))
        aborted = true;
        wait_key_release();
        return;
    end
    WaitSecs(0.005);
end
end

function cursor = init_cursor_from_board(board)
%INIT_CURSOR_FROM_BOARD 初始化键盘光标位置。
idx = find(board == 0, 1, 'first');
if isempty(idx)
    cursor = struct('row', 1, 'col', 1);
    return;
end
[row, col] = ind2sub(size(board), idx);
cursor = struct('row', row, 'col', col);
end

function keycodes = build_control_keycodes(controls)
%BUILD_CONTROL_KEYCODES 解析配置中的控制键到 keycode。
keycodes = struct();
keycodes.confirm = key_names_to_codes(controls.confirm);
keycodes.abort = key_names_to_codes(controls.abort);
end

function codes = key_names_to_codes(names)
%KEY_NAMES_TO_CODES 支持 char/string/cellstr。
if ischar(names) || isstring(names)
    names = {char(names)};
end

codes = [];
for i = 1:numel(names)
    name_i = char(names{i});
    code_i = KbName(name_i);
    if isempty(code_i) || any(isnan(code_i))
        error('ConfigError:InvalidKeyName', 'Invalid key name in config.controls: %s', name_i);
    end
    codes = [codes, code_i(:)']; %#ok<AGROW>
end
codes = unique(codes);
end

function wait_key_release()
%WAIT_KEY_RELEASE 等待全部按键释放，用于去抖。
while KbCheck
    WaitSecs(0.005);
end
end

function [action, meta] = call_agent_player(obs, agent_config, runtime_context)
%CALL_AGENT_PLAYER 统一可替换 agent 调用入口。
% 支持：
%   1) agent_config.player_fn = @your_agent_play
%   2) agent_config.player_fn = 'your_agent_play'

if isfield(agent_config, 'player_fn') && ~isempty(agent_config.player_fn)
    fn = agent_config.player_fn;
else
    error('AgentError:NoAgentConfigured', ...
        'Agent is not configured. Set config.agent.player_fn to a valid agent function.');
end

if ischar(fn) || isstring(fn)
    fn = str2func(char(fn));
end

if ~isa(fn, 'function_handle')
    error('AgentError:InvalidFunction', ...
        'config.agent.player_fn must be a function handle or function name string.');
end

[action, meta] = fn(obs, agent_config, runtime_context);
end
