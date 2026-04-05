# Four-in-a-Row (Matlab + Psychtoolbox) v1

本项目按照 `prompt.md` 的技术规格实现了一个 v1 版本的 **4×9 自由落点四子棋**（human vs random agent）框架，包含：

- 分层目录结构（app/core/players/ui_ptb/markers/logging/utils）
- 核心规则引擎（落子、合法性、胜负/平局）
- PTB 基础 UI（开始页、对局页、结果页、按钮和格子命中）
- marker 映射与统一发射接口
- 实验日志结构与 `.mat` 保存
- 核心逻辑测试脚本

## 开发机版本

- **OS**：Windows 11
- **MATLAB**：`24.2.0.2712019 (R2024b)`（64-bit）
- **Psychtoolbox**：`3.0.19`（Build date: `Jul 31 2024`）
- **GPU / OpenGL Renderer**：NVIDIA GeForce RTX 4060 Laptop GPU（OpenGL 4.6）

## 目录结构

```text
project_root/
  app/
    run_game.m
    main_loop.m
    load_config.m

  core/
    init_game.m
    get_legal_actions.m
    is_valid_action.m
    apply_action.m
    check_winner.m
    check_draw.m

  players/
    human_mouse_player_play.m
    random_agent_play.m

  ui_ptb/
    open_window_and_init_ui.m
    compute_visual_layout.m
    draw_start_screen.m
    draw_game_screen.m
    draw_result_screen.m
    draw_board.m
    draw_pieces.m
    draw_buttons.m
    hit_test_cell.m
    hit_test_button.m
    confirm_exit_dialog.m

  markers/
    send_marker_stub.m
    marker_name_to_code.m
    emit_marker.m

  logging/
    init_trial_log.m
    log_move.m
    log_illegal_click.m
    log_marker_event.m
    finalize_trial_log.m
    save_trial_log.m

  utils/
    deg2cm.m
    cm2px.m
    assert_display_fits.m

  tests/
    test_core.m
    run_all_tests.m
```

## 运行方式

1. 安装 MATLAB（R2021a+）与 Psychtoolbox（3.0.19+）。
2. 在 Matlab 将工作目录切到项目根目录。
3. 执行：`app/run_game`。

## 测试方式

在 Matlab 中执行：`tests/run_all_tests`。

目前测试覆盖以 `core` 逻辑为主，包含：

- 初始化与合法动作数量
- 横/纵/主对角/副对角胜利检测
- 大于 4 连的整段返回
- 平局判定
- 非法动作拒绝

## 注意事项

- 第一版 agent 为 `random`。
- 现在支持可替换 agent：在 `app/load_config.m` 中设置 `config.agent.player_fn` 即可。
  - 例如：`config.agent.player_fn = @random_agent_play;`
  - 也可填函数名字符串：`config.agent.player_fn = 'random_agent_play';`
- 若屏幕物理尺寸读取异常，可在 `app/load_config.m` 中将 `use_manual_screen_size` 设为 `true` 并填写手动尺寸。
- marker 默认使用 `send_marker_stub`（控制台打印）；实际 EEG/MEG 环境可替换 `config.marker.callback`。
