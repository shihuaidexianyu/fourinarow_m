function save_trial_log(trial, config)
%SAVE_TRIAL_LOG Save .mat trial log file.

if ~config.logging.enable
    return;
end

save_dir = config.logging.save_dir;
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

ts = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss_SSS'));
file_name = sprintf('trial_%s_%s.mat', ts, trial.game_id);
save_path = fullfile(save_dir, file_name);
save(save_path, 'trial');
end
