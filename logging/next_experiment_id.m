function experiment_id = next_experiment_id(save_dir)
%NEXT_EXPERIMENT_ID 生成递增的数字实验序号（字符串）。
%   扫描日志目录中已保存文件名，提取 trial_<exp_id>_tXXX_*.mat 的 exp_id，
%   返回 max(exp_id)+1，固定为 6 位数字（如 '000123'）。

if nargin < 1 || isempty(save_dir)
    save_dir = 'logs';
end

max_id = 0;
if isfolder(save_dir)
    files = dir(fullfile(save_dir, 'trial_*_t*_*.mat'));
    for i = 1:numel(files)
        token = regexp(files(i).name, '^trial_(\d+)_t\d{3}_', 'tokens', 'once');
        if isempty(token)
            continue;
        end

        id_num = str2double(token{1});
        if ~isnan(id_num)
            max_id = max(max_id, id_num);
        end
    end
end

experiment_id = sprintf('%06d', max_id + 1);
end
