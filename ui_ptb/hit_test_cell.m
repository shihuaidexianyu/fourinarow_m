function cell_rc = hit_test_cell(layout, mouse_x, mouse_y)
%HIT_TEST_CELL Return [row, col] if mouse is inside a board cell.

cell_rc = [];
rows = size(layout.cell_rects, 1);
cols = size(layout.cell_rects, 2);

for r = 1:rows
    for c = 1:cols
        rect = squeeze(layout.cell_rects(r, c, :))';
        if inside_rect(mouse_x, mouse_y, rect)
            cell_rc = [r, c];
            return;
        end
    end
end
end

function tf = inside_rect(x, y, rect)
tf = x >= rect(1) && x <= rect(3) && y >= rect(2) && y <= rect(4);
end
