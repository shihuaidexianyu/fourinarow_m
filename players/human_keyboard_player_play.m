function [action, meta, cursor] = human_keyboard_player_play(obs, player_config, runtime_context)
%HUMAN_KEYBOARD_PLAYER_PLAY 人类键盘输入适配器。
%   方向键移动选中格，确认键提交落子，ESC 中止。
%   返回值：
%     action  - 合法动作 struct(.row,.col)，非法或中止时为 []
%     meta    - .aborted=true 表示 ESC 中止；.is_illegal=true 表示确认到已占用格
%     cursor  - 本次输入结束后的光标位置 struct('row',r,'col',c)

ui = runtime_context.ui;
layout = runtime_context.layout;
state = runtime_context.state;
transient_ui = runtime_context.transient_ui;
config = runtime_context.config;

action = [];
meta = struct('aborted', false, 'is_illegal', false);

if isfield(runtime_context, 'cursor') && ~isempty(runtime_context.cursor)
    cursor = runtime_context.cursor;
else
    cursor = default_cursor(obs.board);
end

keycodes = build_keycode_map(player_config);

while true
    [is_down, key_time, key_code] = KbCheck;
    if ~is_down
        WaitSecs(0.005);
        continue;
    end

    % ESC 中止
    if any(key_code(keycodes.abort))
        meta.aborted = true;
        wait_key_release();
        return;
    end

    moved = false;

    % 确认落子
    if any(key_code(keycodes.confirm))
        row = cursor.row;
        col = cursor.col;
        if obs.board(row, col) == 0
            action.row = row;
            action.col = col;
        else
            meta.is_illegal = true;
            meta.illegal_row = row;
            meta.illegal_col = col;
            meta.illegal_time = key_time;
        end
        wait_key_release();
        return;
    end

    % 光标移动
    if any(key_code(keycodes.up))
        cursor.row = max(1, cursor.row - 1);
        moved = true;
    elseif any(key_code(keycodes.down))
        cursor.row = min(size(obs.board, 1), cursor.row + 1);
        moved = true;
    elseif any(key_code(keycodes.left))
        cursor.col = max(1, cursor.col - 1);
        moved = true;
    elseif any(key_code(keycodes.right))
        cursor.col = min(size(obs.board, 2), cursor.col + 1);
        moved = true;
    end

    if moved
        transient_ui.selected_cell = [cursor.row, cursor.col];
        draw_game_screen(ui, layout, state, transient_ui, config);
        Screen('Flip', ui.win);
    end

    wait_key_release();
end
end

function cursor = default_cursor(board)
%DEFAULT_CURSOR 默认光标：优先首个空格，否则左上角。
idx = find(board == 0, 1, 'first');
if isempty(idx)
    cursor = struct('row', 1, 'col', 1);
    return;
end
[row, col] = ind2sub(size(board), idx);
cursor = struct('row', row, 'col', col);
end

function keycodes = build_keycode_map(controls)
%BUILD_KEYCODE_MAP 将配置的键名映射为 PTB 键码索引数组。
keycodes = struct();
keycodes.up = key_names_to_codes(controls.up);
keycodes.down = key_names_to_codes(controls.down);
keycodes.left = key_names_to_codes(controls.left);
keycodes.right = key_names_to_codes(controls.right);
keycodes.confirm = key_names_to_codes(controls.confirm);
keycodes.abort = key_names_to_codes(controls.abort);
end

function codes = key_names_to_codes(names)
%KEY_NAMES_TO_CODES 支持 char/string/cellstr 输入。
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
%WAIT_KEY_RELEASE 按键去抖：等待全部键释放。
while KbCheck
    WaitSecs(0.005);
end
end
