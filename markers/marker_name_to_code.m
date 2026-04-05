function event_map = marker_name_to_code()
%MARKER_NAME_TO_CODE Fixed event code mapping.

event_map = containers.Map();
event_map('session_enter_game') = 101;
event_map('game_start') = 102;
event_map('game_abort_esc') = 103;

event_map('response_human_move') = 201;
event_map('response_illegal_click') = 202;
event_map('response_agent_move') = 301;

event_map('stimulus_human_move_shown') = 401;
event_map('stimulus_agent_move_shown') = 402;
event_map('stimulus_result_shown') = 403;

event_map('game_end_black_win') = 501;
event_map('game_end_white_win') = 502;
event_map('game_end_draw') = 503;
end
