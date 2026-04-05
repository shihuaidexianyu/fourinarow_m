function [action, meta] = human_mouse_player_play(obs, player_config, runtime_context)
%HUMAN_MOUSE_PLAYER_PLAY 人类鼠标输入适配器。
%   采用"完整点击"逻辑：按下与释放必须在同一格内才算有效点击。
%   返回值：
%     action  - 合法动作 struct(.row,.col)，非法或中止时为 []
%     meta    - 辅助信息：.aborted=true 表示 ESC 中止，
%               .is_illegal=true 表示点击了已占用格子

ui = runtime_context.ui;
layout = runtime_context.layout;
action = [];
meta = struct('aborted', false, 'is_illegal', false);

while true
    % 检测 ESC 退出
    [~, ~, keyCode] = KbCheck;
    if keyCode(KbName('ESCAPE'))
        meta.aborted = true;
        return;
    end

    % 检测鼠标按下
    [mx, my, buttons] = GetMouse(ui.win);
    if buttons(1)
        down_cell = hit_test_cell(layout, mx, my);  % 按下时所在格子

        % 等待鼠标释放
        while any(buttons)
            [mx2, my2, buttons] = GetMouse(ui.win);
            WaitSecs(0.005);
        end

        up_cell = hit_test_cell(layout, mx2, my2);   % 释放时所在格子

        % 按下与释放在同一格内 → 有效点击
        if ~isempty(down_cell) && ~isempty(up_cell) && all(down_cell == up_cell)
            row = down_cell(1);
            col = down_cell(2);
            if obs.board(row, col) == 0
                % 合法落子
                action.row = row;
                action.col = col;
                return;
            else
                % 非法点击（已占用格）→ 返回给 main_loop 处理
                meta.is_illegal = true;
                meta.illegal_row = row;
                meta.illegal_col = col;
                meta.illegal_time = GetSecs();
                return;
            end
        end
        % 按下与释放不在同一格 → 忽略，不产生动作
    end

    WaitSecs(0.005);
end
end
