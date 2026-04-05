function save_trial_log(trial, config)
%SAVE_TRIAL_LOG Save .mat trial log file.

if ~config.logging.enable
    return;
end

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
save_path = fullfile(save_dir, file_name);
save(save_path, 'trial');
end
