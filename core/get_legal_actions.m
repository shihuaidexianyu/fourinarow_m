function legal_actions = get_legal_actions(state)
%GET_LEGAL_ACTIONS 返回所有空格位置，格式为 N×2 矩阵 [row, col]。

[r, c] = find(state.board == 0);
legal_actions = [r, c];
end
