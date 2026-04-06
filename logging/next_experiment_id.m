function experiment_id = next_experiment_id(~)
%NEXT_EXPERIMENT_ID 生成一次 run_game 使用的实验 ID（字符串）。
%   简单策略：直接使用当前时间戳（毫秒精度）。
%   保留 save_dir 参数仅为兼容既有调用。

experiment_id = char(datetime('now', 'Format', 'yyMMddHHmmssSSS'));
end
