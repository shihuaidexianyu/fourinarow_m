function save_trial_log(trial, config)
%SAVE_TRIAL_LOG 将单局日志保存为 .mat 文件。
%   文件名格式：trial_<exp>_tXXX.mat

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

timestamp_str = char(datetime('now', 'Format', 'yyMMddHHmmss'));
file_name = sprintf('trial_%s.mat', timestamp_str);

if isfield(trial, 'experiment_id') && ~isempty(trial.experiment_id)
    experiment_id_short = regexprep(trial.experiment_id, '[^A-Za-z0-9]', '');
    experiment_id_short = lower(experiment_id_short);
    if strlength(string(experiment_id_short)) > 12
        experiment_id_short = extractBefore(string(experiment_id_short), 13);
        experiment_id_short = char(experiment_id_short);
    end

    if isfield(trial, 'trial_index') && ~isempty(trial.trial_index)
        file_name = sprintf('trial_%s_t%03d.mat', experiment_id_short, trial.trial_index);
    else
        file_name = sprintf('trial_%s.mat', experiment_id_short);
    end
end

save_path = fullfile(save_dir, file_name);
save(save_path, 'trial');
end
