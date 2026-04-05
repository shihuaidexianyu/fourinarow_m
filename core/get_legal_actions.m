function legal_actions = get_legal_actions(state)
%GET_LEGAL_ACTIONS Return all empty cells as [row, col].

[r, c] = find(state.board == 0);
legal_actions = [r, c];
end
