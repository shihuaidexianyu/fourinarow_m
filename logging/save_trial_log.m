function save_trial_log(trial, config)
%SAVE_TRIAL_LOG 将单局日志保存为 .mat 文件。
%   文件名格式：trial_<exp>_tXXX_<时间戳>_<game_id>.mat

if ~config.logging.enable
    return;
end

% 确保保存目录存在
save_dir = config.logging.save_dir;
if ~isfolder(save_dir)
    if isfield(config, 'runtime') && isfield(config.runtime, 'project_root') && ~isfolder(save_dir)
        if ~contains(save_dir, ':') && ~startsWith(save_dir, filesep)
            save_dir = fullfile(config.runtime.project_root, save_dir);
        end
    end

    [ok, msg] = mkdir(save_dir);
    if ~ok
        error('LoggingError:CreateDirFailed', ...
            'Failed to create log directory: %s (%s)', save_dir, msg);
    end
end

ts = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss_SSS'));
file_name = sprintf('trial_%s_%s.mat', ts, trial.game_id);

if isfield(trial, 'experiment_id') && ~isempty(trial.experiment_id)
    exp_short = regexprep(trial.experiment_id, '[^A-Za-z0-9]', '');
    exp_short = lower(exp_short);
    if strlength(string(exp_short)) > 12
        exp_short = extractBefore(string(exp_short), 13);
        exp_short = char(exp_short);
    end

    if isfield(trial, 'trial_index') && ~isempty(trial.trial_index)
        file_name = sprintf('trial_%s_t%03d_%s_%s.mat', exp_short, trial.trial_index, ts, trial.game_id);
    else
        file_name = sprintf('trial_%s_%s_%s.mat', exp_short, ts, trial.game_id);
    end
end

save_path = fullfile(save_dir, file_name);
save(save_path, 'trial');
end
