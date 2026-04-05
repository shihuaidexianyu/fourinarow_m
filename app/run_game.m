function run_game()
%RUN_GAME Entry point.

this_file = mfilename('fullpath');
app_dir = fileparts(this_file);
project_root = fileparts(app_dir);
addpath(genpath(project_root));

config = load_config();
main_loop(config);
end
