function main_loop(config)
%MAIN_LOOP State machine driver for v1 game.

if ~exist('Screen', 'file')
    error('DependencyError:PsychtoolboxMissing', ...
        'Psychtoolbox Screen function is not available.');
end

trial_log = [];
cleanup_obj = onCleanup(@safe_cleanup); %#ok<NASGU>

try
    ui = open_window_and_init_ui(config);
    layout = compute_visual_layout(ui, config);

    state_name = 'wait_start';
    is_running = true;

    while is_running
        switch state_name
            case 'wait_start'
                draw_start_screen(ui, layout, config);
                [~, stimulus_time] = Screen('Flip', ui.win);

                clicked = false;
                while ~clicked
                    [mx, my, buttons] = GetMouse(ui.win);
                    if buttons(1)
                        b = hit_test_button(layout, mx, my, 'start');
                        if strcmp(b, 'start_game')
                            clicked = true;
                        end
                        WaitSecs(0.05);
                    end

                    [~, ~, keyCode] = KbCheck;
                    if keyCode(KbName('ESCAPE'))
                        if confirm_exit_dialog(ui)
                            emit_marker(config, 'game_abort_esc', GetSecs(), struct('result', 'aborted'));
                            is_running = false;
                            state_name = 'cleanup';
                            break;
                        end
                        WaitSecs(0.1);
                    end
                end

                if ~is_running
                    continue;
                end

                state = init_game(config);
                trial_log = init_trial_log(config, ui, layout);

                [config, trial_log] = emit_and_log(config, trial_log, 'session_enter_game', stimulus_time, struct());
                [config, trial_log] = emit_and_log(config, trial_log, 'game_start', GetSecs(), struct());
                state_name = 'in_game';

            case 'in_game'
                transient_ui.illegal_until = -inf;

                while ~state.game_over
                    transient_ui.status_text = sprintf('Turn: %s', ternary(state.current_player==1, 'Black', 'White'));
                    draw_game_screen(ui, layout, state, transient_ui);
                    [~, board_ready_time] = Screen('Flip', ui.win);

                    obs.board = state.board;
                    obs.current_player = state.current_player;
                    obs.legal_actions = get_legal_actions(state);
                    obs.last_action = state.last_action;
                    obs.move_count = state.move_count;
                    obs.game_over = state.game_over;

                    response_t0 = board_ready_time;

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

                    if isempty(action)
                        if isfield(meta, 'aborted') && meta.aborted
                            [config, trial_log] = emit_and_log(config, trial_log, 'game_abort_esc', GetSecs(), struct('result', 'aborted'));
                            state.result = 'aborted';
                            state.game_over = true;
                            break;
                        end

                        if isfield(meta, 'is_illegal') && meta.is_illegal
                            trial_log = log_illegal_click(trial_log, state.current_player, ...
                                meta.illegal_row, meta.illegal_col, meta.illegal_time, state.move_count);
                            if config.marker.enable_illegal_click_marker
                                payload = struct('player', state.current_player, 'row', meta.illegal_row, 'col', meta.illegal_col, ...
                                    'move_count', state.move_count, 'is_illegal', true);
                                [config, trial_log] = emit_and_log(config, trial_log, 'response_illegal_click', meta.illegal_time, payload);
                            end
                            transient_ui.status_text = 'Illegal move. Please try again.';
                            transient_ui.illegal_until = GetSecs() + config.ui.illegal_message_duration_sec;
                        end
                        continue;
                    end

                    response_time = GetSecs();
                    rt = response_time - response_t0;

                    if strcmp(actor, 'human')
                        [config, trial_log] = emit_and_log(config, trial_log, 'response_human_move', response_time, ...
                            struct('player', state.current_player, 'row', action.row, 'col', action.col, ...
                            'move_count', state.move_count + 1, 'rt', rt, 'result', 'ongoing'));
                    else
                        [config, trial_log] = emit_and_log(config, trial_log, 'response_agent_move', response_time, ...
                            struct('player', state.current_player, 'row', action.row, 'col', action.col, ...
                            'move_count', state.move_count + 1, 'rt', rt, 'result', 'ongoing'));
                    end

                    [next_state, apply_info] = apply_action(state, action);
                    move_player = state.current_player;
                    state = next_state;

                    draw_game_screen(ui, layout, state, transient_ui);
                    [~, stimulus_time] = Screen('Flip', ui.win);

                    if strcmp(actor, 'human')
                        [config, trial_log] = emit_and_log(config, trial_log, 'stimulus_human_move_shown', stimulus_time, struct());
                    else
                        [config, trial_log] = emit_and_log(config, trial_log, 'stimulus_agent_move_shown', stimulus_time, struct());
                    end

                    trial_log = log_move(trial_log, state, move_player, action, rt, response_time, stimulus_time);

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

            case 'result'
                if strcmp(state.result, 'black_win')
                    [config, trial_log] = emit_and_log(config, trial_log, 'game_end_black_win', GetSecs(), struct('result', state.result, 'move_count', state.move_count));
                elseif strcmp(state.result, 'white_win')
                    [config, trial_log] = emit_and_log(config, trial_log, 'game_end_white_win', GetSecs(), struct('result', state.result, 'move_count', state.move_count));
                elseif strcmp(state.result, 'draw')
                    [config, trial_log] = emit_and_log(config, trial_log, 'game_end_draw', GetSecs(), struct('result', state.result, 'move_count', state.move_count));
                end

                draw_result_screen(ui, layout, state, struct());
                [~, result_stim_time] = Screen('Flip', ui.win);
                [config, trial_log] = emit_and_log(config, trial_log, 'stimulus_result_shown', result_stim_time, struct('result', state.result));

                waiting = true;
                while waiting
                    [mx, my, buttons] = GetMouse(ui.win);
                    if buttons(1)
                        b = hit_test_button(layout, mx, my, 'result');
                        switch b
                            case 'replay'
                                trial_log = finalize_trial_log(trial_log, state);
                                save_trial_log(trial_log, config);
                                state = init_game(config);
                                trial_log = init_trial_log(config, ui, layout);
                                state_name = 'in_game';
                                waiting = false;
                            case 'back_to_start'
                                trial_log = finalize_trial_log(trial_log, state);
                                save_trial_log(trial_log, config);
                                trial_log = [];
                                state_name = 'wait_start';
                                waiting = false;
                            case 'exit_game'
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
                        if confirm_exit_dialog(ui)
                            state_name = 'cleanup';
                            is_running = false;
                            waiting = false;
                        end
                        WaitSecs(0.1);
                    end
                end

            case 'cleanup'
                is_running = false;

            otherwise
                error('StateError:UnknownState', 'Unknown state: %s', state_name);
        end
    end

    if ~isempty(trial_log)
        trial_log = finalize_trial_log(trial_log, state);
        save_trial_log(trial_log, config);
    end

catch ME
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

function safe_cleanup()
try
    Priority(0);
catch
end

try
    ShowCursor;
catch
end

try
    sca;
catch
end
end

function [config_out, trial_log] = emit_and_log(config_in, trial_log, event_name, timestamp, payload)
config_out = config_in;
emit_marker(config_in, event_name, timestamp, payload);

if ~isempty(trial_log) && isfield(config_in, 'events') && isa(config_in.events, 'containers.Map') && isKey(config_in.events, event_name)
    code = config_in.events(event_name);
    trial_log = log_marker_event(trial_log, code, event_name, timestamp, payload);
end
end

function out = ternary(cond, a, b)
if cond
    out = a;
else
    out = b;
end
end
