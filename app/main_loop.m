function main_loop(config)
%MAIN_LOOP 程序主循环 / 状态机驱动。
%   状态流转：wait_start -> in_game -> result -> cleanup
%   ESC 直接退出（无二次确认）。

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

    state_name = 'wait_start';
    is_running = true;

    while is_running
        switch state_name

            % ============ 等待开局 ============
            case 'wait_start'
                draw_start_screen(ui, layout, config);
                [~, stimulus_time] = Screen('Flip', ui.win);

                clicked = false;
                while ~clicked
                    % 检测鼠标点击"开始"按钮
                    [mx, my, buttons] = GetMouse(ui.win);
                    if buttons(1)
                        b = hit_test_button(layout, mx, my, 'start');
                        if strcmp(b, 'start_game')
                            clicked = true;
                        end
                        WaitSecs(0.05);
                    end

                    % 检测 ESC 退出（直接退出）
                    [~, ~, keyCode] = KbCheck;
                    if keyCode(KbName('ESCAPE'))
                        emit_marker(config, 'game_abort_esc', GetSecs(), struct('result', 'aborted'));
                        is_running = false;
                        state_name = 'cleanup';
                        WaitSecs(0.1);
                        break;
                    end
                end

                if ~is_running
                    continue;
                end

                % 初始化游戏状态与日志
                state = init_game(config);
                trial_log = init_trial_log(config, ui, layout);

                [config, trial_log] = emit_and_log(config, trial_log, 'session_enter_game', stimulus_time, struct());
                [config, trial_log] = emit_and_log(config, trial_log, 'game_start', GetSecs(), struct());
                state_name = 'in_game';

            % ============ 对局中 ============
            case 'in_game'
                transient_ui.illegal_until = -inf;  % 非法提示过期时刻（初始无提示）

                while ~state.game_over
                    % 更新状态栏文字（每轮刷新，避免切换玩家后文字过时）
                    transient_ui.status_text = ternary(state.current_player==1, config.ui.turn_black_text, config.ui.turn_white_text);
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
                        [action, meta] = human_mouse_player_play(obs, config, struct('ui', ui, 'layout', layout));
                        actor = 'human';
                    else
                        [action, meta] = random_agent_play(obs, config.agent, struct());
                        if config.agent.move_delay_sec > 0
                            WaitSecs(config.agent.move_delay_sec);
                        end
                        actor = 'agent';
                    end

                    % ---- 空动作处理（中止或非法点击）----
                    if isempty(action)
                        % ESC 中止
                        if isfield(meta, 'aborted') && meta.aborted
                            [config, trial_log] = emit_and_log(config, trial_log, 'game_abort_esc', GetSecs(), struct('result', 'aborted'));
                            state.result = 'aborted';
                            state.game_over = true;
                            break;
                        end

                        % 非法点击：记录日志 + marker，显示提示
                        if isfield(meta, 'is_illegal') && meta.is_illegal
                            trial_log = log_illegal_click(trial_log, state.current_player, ...
                                meta.illegal_row, meta.illegal_col, meta.illegal_time, state.move_count);
                            if config.marker.enable_illegal_click_marker
                                payload = struct('player', state.current_player, 'row', meta.illegal_row, 'col', meta.illegal_col, ...
                                    'move_count', state.move_count, 'is_illegal', true);
                                [config, trial_log] = emit_and_log(config, trial_log, 'response_illegal_click', meta.illegal_time, payload);
                            end
                            transient_ui.status_text = config.ui.illegal_text;
                            transient_ui.illegal_until = GetSecs() + config.ui.illegal_message_duration_sec;
                        end
                        continue;  % 重新等待玩家输入
                    end

                    % ---- 合法落子 ----
                    response_time = GetSecs();
                    rt = response_time - response_t0;   % 反应时

                    % 发送 response marker
                    if strcmp(actor, 'human')
                        [config, trial_log] = emit_and_log(config, trial_log, 'response_human_move', response_time, ...
                            struct('player', state.current_player, 'row', action.row, 'col', action.col, ...
                            'move_count', state.move_count + 1, 'rt', rt, 'result', 'ongoing'));
                    else
                        [config, trial_log] = emit_and_log(config, trial_log, 'response_agent_move', response_time, ...
                            struct('player', state.current_player, 'row', action.row, 'col', action.col, ...
                            'move_count', state.move_count + 1, 'rt', rt, 'result', 'ongoing'));
                    end

                    % 应用动作、更新状态
                    [next_state, apply_info] = apply_action(state, action);
                    move_player = state.current_player;
                    state = next_state;

                    % 刷新棋盘画面并获取 stimulus 时间戳
                    draw_game_screen(ui, layout, state, transient_ui, config);
                    [~, stimulus_time] = Screen('Flip', ui.win);

                    % 发送 stimulus marker
                    if strcmp(actor, 'human')
                        [config, trial_log] = emit_and_log(config, trial_log, 'stimulus_human_move_shown', stimulus_time, struct());
                    else
                        [config, trial_log] = emit_and_log(config, trial_log, 'stimulus_agent_move_shown', stimulus_time, struct());
                    end

                    % 写入动作日志
                    trial_log = log_move(trial_log, state, move_player, action, rt, response_time, stimulus_time);

                    % 检查终局
                    if apply_info.is_win || apply_info.is_draw
                        state_name = 'result';
                        break;
                    end
                end

                if strcmp(state.result, 'aborted')
                    state_name = 'cleanup';
                elseif state.game_over
                    state_name = 'result';
                end

            % ============ 结果展示 ============
            case 'result'
                % 发送游戏结束 marker
                if strcmp(state.result, 'black_win')
                    [config, trial_log] = emit_and_log(config, trial_log, 'game_end_black_win', GetSecs(), struct('result', state.result, 'move_count', state.move_count));
                elseif strcmp(state.result, 'white_win')
                    [config, trial_log] = emit_and_log(config, trial_log, 'game_end_white_win', GetSecs(), struct('result', state.result, 'move_count', state.move_count));
                elseif strcmp(state.result, 'draw')
                    [config, trial_log] = emit_and_log(config, trial_log, 'game_end_draw', GetSecs(), struct('result', state.result, 'move_count', state.move_count));
                end

                draw_result_screen(ui, layout, state, config);
                [~, result_stim_time] = Screen('Flip', ui.win);
                [config, trial_log] = emit_and_log(config, trial_log, 'stimulus_result_shown', result_stim_time, struct('result', state.result));

                % 等待用户点击按钮
                waiting = true;
                while waiting
                    [mx, my, buttons] = GetMouse(ui.win);
                    if buttons(1)
                        b = hit_test_button(layout, mx, my, 'result');
                        switch b
                            case 'replay'           % 再来一局
                                trial_log = finalize_trial_log(trial_log, state);
                                save_trial_log(trial_log, config);
                                state = init_game(config);
                                trial_log = init_trial_log(config, ui, layout);
                                state_name = 'in_game';
                                waiting = false;
                            case 'back_to_start'    % 返回开始界面
                                trial_log = finalize_trial_log(trial_log, state);
                                save_trial_log(trial_log, config);
                                trial_log = [];
                                state_name = 'wait_start';
                                waiting = false;
                            case 'exit_game'        % 退出程序
                                trial_log = finalize_trial_log(trial_log, state);
                                save_trial_log(trial_log, config);
                                state_name = 'cleanup';
                                is_running = false;
                                waiting = false;
                        end
                        WaitSecs(0.08);
                    end

                    [~, ~, keyCode] = KbCheck;
                    if keyCode(KbName('ESCAPE'))
                        [config, trial_log] = emit_and_log(config, trial_log, 'game_abort_esc', GetSecs(), struct('result', 'aborted'));
                        state.result = 'aborted';
                        state_name = 'cleanup';
                        is_running = false;
                        waiting = false;
                        WaitSecs(0.1);
                    end
                end

            % ============ 清理 ============
            case 'cleanup'
                is_running = false;

            otherwise
                error('StateError:UnknownState', 'Unknown state: %s', state_name);
        end
    end

    % 正常退出时保存尚未保存的日志
    if ~isempty(trial_log)
        trial_log = finalize_trial_log(trial_log, state);
        save_trial_log(trial_log, config);
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
