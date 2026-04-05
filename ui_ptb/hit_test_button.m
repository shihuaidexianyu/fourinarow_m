function button_id = hit_test_button(layout, mouse_x, mouse_y, screen_name)
%HIT_TEST_BUTTON 检测鼠标是否在某个按钮内。
%   命中返回按钮 id 字符串，否则返回空字符串。

button_id = '';

switch screen_name
    case 'start'
        if inside_rect(mouse_x, mouse_y, layout.start_button)
            button_id = 'start_game';
        end

    case 'result'
        names = fieldnames(layout.result_buttons);
        for i = 1:numel(names)
            name = names{i};
            rect = layout.result_buttons.(name);
            if inside_rect(mouse_x, mouse_y, rect)
                button_id = name;
                return;
            end
        end

    otherwise
        button_id = '';
end
end

function tf = inside_rect(x, y, rect)
tf = x >= rect(1) && x <= rect(3) && y >= rect(2) && y <= rect(4);
end
