function [action, meta] = random_agent_play(obs, player_config, ~)
%RANDOM_AGENT_PLAY Uniform random from legal actions.

if nargin < 2
    player_config = struct();
end
legal = obs.legal_actions;
if isempty(legal)
    action = [];
    meta = struct('reason', 'no_legal_action');
    return;
end

idx = randi(size(legal, 1));
action.row = legal(idx, 1);
action.col = legal(idx, 2);
meta = struct('type', 'random', 'candidate_count', size(legal, 1));

if isfield(player_config, 'type')
    meta.agent_type = player_config.type;
end
end
