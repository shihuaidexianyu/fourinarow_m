# Matlab + Psychtoolbox 四子棋技术规格 v1

## 1. 文档目的

本文档用于定义一个基于 **Matlab + Psychtoolbox（PTB）** 实现的四子棋程序的完整技术规格。该程序面向“**人类玩家 vs agent**”的对局场景，采用 **4×9 自由落点棋盘**，以 **PTB 图形界面** 作为人类输入与刺激呈现方式，并在关键事件发生时提供统一的 **EEG/MEG marker 打标接口**。

本文档的目标是冻结第一版实现所需的核心需求、模块边界、接口定义、运行流程、显示规则、日志规范与异常处理策略，以确保后续开发具有一致的实现依据。

---

## 2. 项目范围

### 2.1 第一版包含内容

第一版程序包含以下能力：

1. 4×9 棋盘的自由落点四子棋对局。
2. 人类玩家与 agent 的单局对战。
3. PTB 全屏图形界面显示。
4. 鼠标点击输入。
5. 可配置先手与双方执子颜色。
6. 局内胜负判定与结果展示。
7. EEG/MEG marker 接口回调。
8. 基本实验级日志记录。
9. 基于视觉角度的棋盘尺寸计算。
10. 非法点击提示与 ESC 退出确认。

### 2.2 第一版不包含内容

第一版不包含以下能力：

1. 联网对战。
2. 本地双人对战。
3. 声音反馈。
4. 悔棋。
5. 悬停预览与 hover 高亮。
6. 自适应缩放棋盘以容纳任意屏幕。
7. 多局 block 设计与复杂实验流程管理。
8. 高级 agent，仅实现最简单的随机 agent 基线。

---

## 3. 总体设计原则

本项目采用严格分层设计，分为以下层次：

1. **Game Engine 层**：纯逻辑层，不依赖 PTB，不依赖输入设备，不依赖 EEG/MEG 设备。
2. **Player 层**：统一动作生成接口，human 与 agent 都通过相同语义的 player 机制输出动作。
3. **UI/PTB 层**：负责图形绘制、按钮、鼠标交互、屏幕刷新与视觉参数计算。
4. **Marker 层**：负责事件名到事件码的映射，以及 EEG/MEG marker 发出。
5. **Logging 层**：负责行为数据、配置、屏幕参数、结果与中止状态的记录。
6. **App/State Machine 层**：负责驱动程序状态机，组织初始化、开局、对局、结算、退出。

设计原则如下：

* 核心规则必须与显示彻底解耦。
* 所有动作必须通过统一的 action 结构表示。
* 所有刺激关键时间点必须以 `Screen('Flip')` 返回的时间作为视觉呈现基准。
* 所有行为关键时间点必须显式区分 response 与 stimulus。
* 第一版优先保证结构稳定、日志完备、时序清晰，而非功能复杂度。

---

## 4. 游戏规则定义

## 4.1 棋盘规格

* 棋盘大小固定为 **4 行 × 9 列**。
* 棋盘内部采用二维数组表示，尺寸为 `4 x 9`。

## 4.2 落子规则

* 本游戏采用 **自由落点** 规则。
* 玩家每回合可在任意一个空格中落子。
* 不采用重力下落机制。

## 4.3 先手规则

* 先手为可配置项。
* 第一版中，先手配置通过代码硬编码。
* 可选值为：

  * black
  * white

## 4.4 棋子颜色与玩家身份

* 棋盘状态编码为：

  * `0 = empty`
  * `1 = black`
  * `2 = white`

* 人类与 agent 的执子方均为可配置项。

* 第一版中，该配置通过代码硬编码。

## 4.5 胜利条件

满足以下任一条件时，当前落子方立即获胜：

* 横向连续长度 ≥ 4
* 纵向连续长度 ≥ 4
* 主对角线连续长度 ≥ 4
* 副对角线连续长度 ≥ 4

判胜规则采用“**至少四连**”而非“恰好四连”。若一次落子同时形成多条连线，仍视为立即胜利，无需额外区分。

## 4.6 平局条件

若棋盘已满且没有任何一方获胜，则判定为平局。

## 4.7 判定顺序

在一次合法落子后，判定顺序固定为：

1. 检查当前落子方是否获胜。
2. 若未获胜，则检查棋盘是否已满。
3. 若棋盘已满且无人胜，则判平局。
4. 否则进入下一回合。

---

## 5. 内部数据表示

## 5.1 坐标系统

棋盘坐标采用 Matlab 直觉形式：

* `board(row, col)`
* `row = 1` 表示最上面一行
* `col = 1` 表示最左边一列

所有逻辑层、显示层、日志层均使用此统一坐标系，不允许使用倒置坐标或屏幕坐标直接作为逻辑坐标。

## 5.2 棋盘状态结构

建议使用如下 state 结构体：

```matlab
state.board           % 4x9 double/int matrix
state.current_player  % 1 or 2
state.first_player    % 1 or 2
state.move_count      % 已完成合法落子数
state.last_action     % struct or []
state.game_over       % logical
state.result          % 'ongoing' | 'black_win' | 'white_win' | 'draw' | 'aborted'
state.winning_cells   % Nx2 matrix, 每行为 [row, col]
state.winning_line    % struct, 记录高亮线起终点逻辑坐标
```

## 5.3 动作结构

动作采用统一的最简结构：

```matlab
action.row
action.col
```

约束如下：

* `row` 必须为 `1..4` 的整数。
* `col` 必须为 `1..9` 的整数。
* 动作必须指向一个空格，否则为非法动作。

## 5.4 观察量结构

传给 player 的 observation 至少包含：

```matlab
obs.board
obs.current_player
obs.legal_actions
obs.last_action
obs.move_count
obs.game_over
```

建议 `obs.legal_actions` 使用 `N x 2` 矩阵，每行为 `[row, col]`。

---

## 6. 配置系统

第一版采用**硬编码配置结构体**的方式，不提供图形化配置界面。

建议定义统一 `config` 结构体，至少包含以下字段：

```matlab
config.game.rows = 4;
config.game.cols = 9;
config.game.connect_n = 4;
config.game.first_player = 1;         % 1 black, 2 white
config.game.human_player = 1;         % 1 or 2
config.game.agent_player = 2;         % 1 or 2

config.display.cell_deg = 2.0;
config.display.piece_ratio = 0.85;
config.display.viewing_distance_cm = 60;
config.display.use_manual_screen_size = false;
config.display.manual_screen_width_cm = [];
config.display.manual_screen_height_cm = [];
config.display.screen_index = max(Screen('Screens')); % 第一版默认主屏可另行设置为主屏编号策略
config.display.fullscreen = true;

config.ui.illegal_message_duration_sec = 0.8;
config.ui.title_text = '四子棋';
config.ui.instruction_text = '请点击开始按钮进入对局。';
config.ui.show_config_summary = true;

config.marker.enable = true;
config.marker.enable_illegal_click_marker = true;
config.marker.callback = @send_marker_stub;

config.agent.type = 'random';
config.agent.move_delay_sec = 0.0;

config.logging.enable = true;
config.logging.save_dir = 'logs';
config.logging.version = 'v1';
```

说明如下：

1. 第一版允许实验者手动覆盖屏幕物理尺寸。
2. 观察距离固定为硬编码参数。
3. 非法提示时长为硬编码配置项。
4. marker 是否启用、非法点击是否打 marker 都为配置项。
5. 第一版 agent 仅实现 `random`。

---

## 7. 显示与视觉角度规格

## 7.1 屏幕参数来源

程序启动后，显示层需要获取以下屏幕信息：

* 屏幕分辨率（像素）
* 屏幕物理宽度（cm）
* 屏幕物理高度（cm）

默认从 PTB / 系统接口读取。若配置中 `use_manual_screen_size = true`，则使用人工覆盖值。

## 7.2 视觉角度到像素的转换

单个格子边长固定为 **2.0° 视角**。

物理尺寸计算公式为：

[
cell_size_{cm} = 2 \cdot distance_{cm} \cdot \tan\left(\frac{\theta}{2}\right)
]

其中：

* `distance_cm` 为观看距离
* `theta` 为格子边长视角，单位为度

像素尺寸通过屏幕像素密度换算：

[
px_per_cm_x = \frac{screen_width_px}{screen_width_{cm}}
]

[
px_per_cm_y = \frac{screen_height_px}{screen_height_{cm}}
]

为避免形变，建议在第一版中使用统一的标量像素密度，例如：

[
px_per_cm = \min(px_per_cm_x,; px_per_cm_y)
]

则：

[
cell_size_{px} = round(cell_size_{cm} \cdot px_per_cm)
]

## 7.3 棋子尺寸

棋子直径固定为格子边长的 **0.85**：

[
piece_diameter_{px} = round(0.85 \cdot cell_size_{px})
]

## 7.4 布局规则

界面布局要求如下：

* 全屏显示
* 默认使用主屏
* 棋盘水平居中
* 棋盘垂直居中
* 标题位于棋盘上方
* 状态提示文字位于棋盘下方
* 开始页与结果页按钮垂直排布，整体居中

## 7.5 安全显示范围检查

程序必须在初始化阶段检查理论棋盘尺寸是否能在当前屏幕中安全显示。安全显示范围除棋盘外，还应预留：

* 标题区域
* 状态文字区域
* 按钮区域或结果文字区域
* 基本边距

若超出允许范围，则程序必须中止，并输出详细报错信息。

## 7.6 报错信息要求

当棋盘理论尺寸无法在当前屏幕条件下显示时，报错信息必须包含：

* 当前屏幕分辨率
* 当前物理宽高
* 当前观察距离
* 当前设定的格子视角大小
* 计算得到的棋盘像素尺寸
* 最大可显示区域尺寸
* 修改建议，例如减小 `cell_deg` 或调整距离

程序不得自动缩放棋盘替代报错。

---

## 8. 视觉样式规范

第一版可采用以下默认样式，后续允许调整：

* 背景色：中性灰
* 棋盘网格线：深灰或黑色
* 黑子：黑色实心圆
* 白子：白色实心圆，建议带深色描边
* 胜利高亮边框：高对比颜色
* 胜利中心连线：高对比颜色
* 状态文字：高对比可读颜色
* 按钮：矩形按钮，带边框与标签文本

第一版不使用悬停效果。

---

## 9. 人类输入规范

## 9.1 输入方式

* 输入设备：鼠标
* 人类通过点击格子完成落子

## 9.2 格子命中规则

每个格子对应一个完整的可点击矩形区域。点击格子内任意位置均视为选中该格子。

## 9.3 有效点击定义

采用“完整点击”逻辑：

仅当以下条件同时成立时，才算一次有效点击尝试：

1. 鼠标按下时位于某格内部
2. 鼠标释放时仍位于同一格内部

否则不产生动作。

## 9.4 棋盘外点击

点击棋盘外区域时：

* 不报错
* 不落子
* 不改变当前玩家
* 不写入非法动作提示

## 9.5 非法点击

若点击已被占用的格子，则视为非法点击：

* 屏幕显示提示文字“非法动作，请重试”
* 当前玩家不变
* 棋盘状态不变
* 非法提示显示时长由配置项控制
* 提示期间允许继续点击
* 是否发送 marker 由配置项控制

---

## 10. Agent 规范

## 10.1 第一版 agent 类型

第一版仅实现最简单的 **随机 agent**：

* 在 `obs.legal_actions` 中均匀随机选择一个合法动作。

## 10.2 执子方

* agent 的执子方为可配置项
* human 与 agent 的颜色分配可任意组合，但必须互补

## 10.3 动作延迟

第一版中 agent **立即落子**，不人为引入额外延迟。

## 10.4 统一 player 职责

所有 player 均只负责根据 observation 生成动作。
因此：

* human player 是 PTB 鼠标输入适配器
* random agent 是合法动作采样器

player 不直接修改棋盘，不直接判断胜负，不直接绘图。

---

## 11. 程序状态机

程序状态机定义如下：

## 11.1 初始化阶段

职责：

1. 加载配置
2. 打开 PTB 窗口
3. 获取屏幕参数
4. 计算视觉尺寸
5. 进行可显示性检查
6. 初始化颜色、字体、按钮布局、日志对象、marker 映射表等资源

输出：

* 成功进入等待开局状态
* 或因显示条件不满足而报错退出

## 11.2 等待开局状态

界面包含：

* 游戏标题
* 实验提示语
* 开始按钮
* 可选的配置摘要

允许操作：

* 点击“开始”按钮进入正式对局
* 按 ESC 弹出退出确认

进入对局时应发送状态进入类 marker。

## 11.3 对局中状态

职责：

1. 渲染当前棋盘与棋子
2. 等待轮到一方行动
3. 若轮到 human，则等待鼠标输入
4. 若轮到 agent，则调用 agent player
5. 提交动作给 game engine
6. 判定胜负或平局
7. 记录 response / stimulus marker
8. 写入日志
9. 若未结束，则进入下一手

## 11.4 结果显示状态

界面包含：

* 结果文字：黑胜 / 白胜 / 平局
* 胜利高亮边框
* 胜利中心连线
* 三个垂直排布按钮：

  * 再来一局
  * 返回开始界面
  * 退出程序

允许操作：

* 点击对应按钮执行状态跳转
* 按 ESC 弹出退出确认

## 11.5 退出 / 清理状态

职责：

1. 保存当前日志
2. 关闭 PTB 窗口
3. 恢复鼠标与键盘相关状态
4. 释放资源
5. 正常退出程序

## 11.6 ESC 退出规则

在任意允许退出的状态中按 ESC 时：

1. 弹出确认界面或确认对话逻辑
2. 若用户确认，则记录中止事件
3. 设置结果为 `aborted`
4. 进入退出 / 清理状态

---

## 12. 核心逻辑模块定义

建议核心逻辑模块提供以下函数。

## 12.1 初始化

```matlab
state = init_game(config)
```

职责：

* 初始化棋盘为空
* 设定当前玩家与先手
* 初始化 move_count、last_action、game_over、result 等字段

## 12.2 获取合法动作

```matlab
legal_actions = get_legal_actions(state)
```

输出所有空格位置，格式为 `N x 2` 矩阵。

## 12.3 检查动作合法性

```matlab
is_valid = is_valid_action(state, action)
```

判断 action 是否满足：

* 行列范围合法
* 目标格为空
* 游戏尚未结束

## 12.4 应用动作

```matlab
[next_state, apply_info] = apply_action(state, action)
```

职责：

1. 写入当前玩家棋子
2. 更新 `last_action`
3. 更新 `move_count`
4. 检查胜利
5. 检查平局
6. 若未结束则切换当前玩家

`apply_info` 建议至少包含：

```matlab
apply_info.is_win
apply_info.is_draw
apply_info.result
apply_info.winning_cells
apply_info.winning_line
```

## 12.5 胜利检测

```matlab
[is_win, winning_cells, winning_line] = check_winner(state, action)
```

输入当前状态与刚完成的动作，仅围绕新落子位置检查四个方向。

若连续长度大于 4，`winning_cells` 应包含整段连续棋子坐标。

## 12.6 平局检测

```matlab
is_draw = check_draw(state)
```

若棋盘已满且游戏未胜，则返回真。

---

## 13. Player 接口定义

建议统一 player 调用形式如下：

```matlab
[action, meta] = player_play(obs, player_config, runtime_context)
```

说明：

* `obs`：观察量
* `player_config`：该 player 的配置
* `runtime_context`：可选上下文，如 PTB 句柄、布局信息、输入设备状态等

返回：

* `action`：动作结构
* `meta`：调试与计时辅助信息

对于第一版，至少实现：

1. `human_mouse_player_play`
2. `random_agent_play`

若要进一步简化，也可由 App 层直接分别调 human 与 agent 的具体函数，但必须保证对外语义统一：都返回 `action`。

---

## 14. PTB 显示模块定义

建议 UI/PTB 层提供以下模块。

## 14.1 打开窗口

```matlab
ui = open_window_and_init_ui(config)
```

职责：

* 打开 PTB 窗口
* 记录屏幕分辨率
* 设置字体、颜色、优先级等
* 初始化 UI 资源结构

## 14.2 计算布局

```matlab
layout = compute_visual_layout(ui, config)
```

职责：

* 完成视觉角度换算
* 计算棋盘矩形
* 计算每个格子的屏幕矩形
* 计算标题区、状态区、按钮区位置
* 完成安全显示检查

## 14.3 绘制开始界面

```matlab
draw_start_screen(ui, layout, config)
```

内容：

* 标题
* 实验提示语
* 开始按钮
* 配置摘要（建议）

## 14.4 绘制对局界面

```matlab
draw_game_screen(ui, layout, state, transient_ui)
```

内容：

* 棋盘网格
* 已有棋子
* 状态提示文字
* 非法提示（若存在）
* 不绘制 hover

## 14.5 绘制结果界面

```matlab
draw_result_screen(ui, layout, state, result_ui)
```

内容：

* 结果文字
* 胜利高亮边框
* 胜利中心连线
* 三个按钮

## 14.6 格子命中检测

```matlab
cell = hit_test_cell(layout, mouse_x, mouse_y)
```

若命中则返回 `[row, col]`，否则返回空。

## 14.7 按钮命中检测

```matlab
button_id = hit_test_button(layout, mouse_x, mouse_y, screen_name)
```

用于开始页与结果页按钮判定。

---

## 15. 计时规范

## 15.1 反应时定义

每一步反应时从“**棋盘完成上一手刷新后**”开始计时，到“**当前合法动作被接受**”为止。

该定义同时适用于：

* human 反应时
* agent 反应时

## 15.2 刺激刷新时间

每次与实验相关的视觉更新都应通过 `Screen('Flip')` 获取真实刺激呈现时间戳，并用于 stimulus marker 与日志记录。

## 15.3 两类关键时点

每一步动作至少区分两个时点：

1. **response 时间**

   * 合法动作被系统接受的时间
   * 对 human 来说，是完成合法点击并通过逻辑验证的时间
   * 对 agent 来说，是 agent 返回动作并通过逻辑验证的时间

2. **stimulus 时间**

   * 新棋盘画面通过 `Screen('Flip')` 真正显示到屏幕上的时间

---

## 16. EEG / MEG Marker 规范

## 16.1 Marker 接口

统一接口固定为：

```matlab
send_marker(event_code, event_name, timestamp, payload);
```

参数说明：

* `event_code`：整数事件码
* `event_name`：字符串事件名
* `timestamp`：当前事件时间
* `payload`：结构体，包含辅助信息

第一版中，marker 层应支持 callback 方式。若没有真实设备，可使用空实现或日志实现。

## 16.2 事件分类

事件名必须区分事件类型。建议分为以下三大类：

1. **状态类事件**
2. **行为响应类事件**
3. **视觉呈现类事件**

## 16.3 推荐事件命名

### 状态类

* `session_enter_game`
* `game_start`
* `game_abort_esc`
* `game_end_black_win`
* `game_end_white_win`
* `game_end_draw`

### 行为响应类

* `response_human_move`
* `response_agent_move`
* `response_illegal_click`

### 视觉呈现类

* `stimulus_human_move_shown`
* `stimulus_agent_move_shown`
* `stimulus_result_shown`

## 16.4 推荐事件码映射

建议使用固定编号段：

* `101 = session_enter_game`

* `102 = game_start`

* `103 = game_abort_esc`

* `201 = response_human_move`

* `202 = response_illegal_click`

* `301 = response_agent_move`

* `401 = stimulus_human_move_shown`

* `402 = stimulus_agent_move_shown`

* `403 = stimulus_result_shown`

* `501 = game_end_black_win`

* `502 = game_end_white_win`

* `503 = game_end_draw`

## 16.5 Marker 发送时机

### 进入正式对局时

* 发送 `session_enter_game`
* 发送 `game_start`

### human 合法落子

* response 时发送 `response_human_move`
* 该步棋盘刷新后发送 `stimulus_human_move_shown`

### agent 合法落子

* response 时发送 `response_agent_move`
* 该步棋盘刷新后发送 `stimulus_agent_move_shown`

### 非法点击

* 若配置允许，则在非法点击被识别时发送 `response_illegal_click`

### 游戏结束

* 逻辑结束时发送对应结果事件：

  * `game_end_black_win`
  * `game_end_white_win`
  * `game_end_draw`
* 结果页面刷新后发送 `stimulus_result_shown`

### ESC 中止

* 确认退出时发送 `game_abort_esc`

## 16.6 Payload 规范

推荐至少包含：

```matlab
payload.player
payload.row
payload.col
payload.move_count
payload.is_illegal
payload.result
payload.rt
```

不同事件按需填写。例如：

* 合法落子：`player, row, col, move_count, rt`
* 非法点击：`player, row, col, move_count, is_illegal=true`
* 游戏结果：`result, move_count`
* 开始事件：可附带配置摘要 ID

---

## 17. 日志规范

## 17.1 日志目标

日志必须足以支持以下用途：

1. 还原整局动作序列
2. 分析每步反应时
3. 对齐 EEG/MEG marker
4. 检查非法点击与中止情况
5. 复现实验参数与显示条件

## 17.2 每局最低记录项

第一版必须记录：

* 开局时间
* 动作序列
* 最终结果
* 每步反应时
* 非法点击次数
* 屏幕参数
* 距离参数
* 配置快照

建议额外记录：

* 程序版本号
* 每局唯一 ID

## 17.3 动作级日志字段建议

每一步合法动作建议记录：

```matlab
trial.moves(k).player
trial.moves(k).row
trial.moves(k).col
trial.moves(k).rt
trial.moves(k).response_time
trial.moves(k).stimulus_time
trial.moves(k).move_count
trial.moves(k).board_after
```

非法点击建议记录：

```matlab
trial.illegal_clicks(m).player
trial.illegal_clicks(m).row
trial.illegal_clicks(m).col
trial.illegal_clicks(m).time
trial.illegal_clicks(m).move_count
```

## 17.4 局级日志字段建议

```matlab
trial.game_id
trial.start_datetime
trial.end_datetime
trial.result
trial.aborted
trial.first_player
trial.human_player
trial.agent_player
trial.screen_info
trial.viewing_distance_cm
trial.config_snapshot
trial.marker_events
trial.moves
trial.illegal_click_count
```

## 17.5 存储格式

第一版建议优先保存为 `.mat` 文件，必要时可同时导出简化版 `.csv` 或 `.json`。

---

## 18. 胜利高亮规范

若产生胜利结果，结果页与最终棋盘显示时必须执行如下高亮：

1. 对胜利连线上的所有连续棋子添加高亮边框。
2. 若连续长度大于 4，则整段连续棋子都高亮。
3. 在整段连线中心绘制一条高亮线。

这两种高亮方式必须同时存在：

* 棋子边框高亮
* 连线中心高亮

---

## 19. 开始页与结果页规范

## 19.1 开始页

开始页必须包含：

* 游戏标题
* 实验提示语
* 开始按钮

建议包含：

* 配置摘要，例如：

  * 棋盘大小
  * 自由落点
  * human 颜色
  * agent 颜色
  * 先手颜色

按钮布局采用**垂直排布**。

## 19.2 结果页

结果页必须包含：

* 结果文字
* 胜利高亮（若有）
* 三个按钮，垂直排布：

  1. 再来一局
  2. 返回开始界面
  3. 退出程序

---

## 20. 异常与错误处理

## 20.1 显示参数异常

若视觉参数导致棋盘无法显示，程序应：

1. 停止继续运行
2. 输出详细报错信息
3. 不进入开始页

## 20.2 非法动作异常

对于 human：

* 占用格点击视为非法动作
* 给出提示但不终止程序

对于 agent：

* 第一版 random agent 理论上不应输出非法动作
* 若出现非法动作，应视为程序错误并中止，便于调试

## 20.3 ESC 中止

用户在允许状态下按 ESC：

1. 弹出确认
2. 若确认，则记录中止
3. 保存日志
4. 退出程序

## 20.4 PTB 运行失败

若 PTB 窗口创建失败、屏幕读取失败或 `Flip` 失败，程序应尽量：

1. 写出错误信息
2. 执行 `sca` 与资源清理
3. 避免 Matlab 会话残留异常显示状态

---

## 21. 推荐模块目录

建议项目目录结构如下：

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
```

---

## 22. 运行流程概述

建议主流程如下：

1. 读取配置
2. 打开 PTB 窗口并初始化 UI
3. 计算视觉布局并检查可显示性
4. 进入开始页
5. 用户点击“开始”
6. 发送开始类 marker
7. 初始化 state 与 log
8. 进入对局循环
9. 每回合：

   * 刷新棋盘并记录上一刺激完成时刻
   * 根据当前玩家调用 human 或 agent
   * 记录 response 时间与 RT
   * 发送 response marker
   * 应用动作
   * 刷新棋盘
   * 记录 stimulus 时间
   * 发送 stimulus marker
   * 写入日志
   * 判断是否结束
10. 若结束：

* 发送 game_end marker
* 绘制结果页
* 发送 stimulus_result_shown

11. 结果页等待按钮选择
12. 根据按钮决定重开、返回开始页或退出
13. 最终保存日志并清理 PTB

---

## 23. 测试要求

第一版开发完成后，至少应完成以下测试。

## 23.1 核心逻辑测试

1. 空棋盘初始化正确
2. 合法动作数量正确
3. 落子后棋盘状态正确更新
4. 横向胜利检测正确
5. 纵向胜利检测正确
6. 主对角线胜利检测正确
7. 副对角线胜利检测正确
8. 长度大于 4 的连线能正确返回整段 winning_cells
9. 棋盘满且无人胜时正确判平
10. 非法动作能被正确拒绝

## 23.2 UI 交互测试

1. 开始按钮点击有效
2. 结果页按钮点击有效
3. 完整点击规则正确实现
4. 棋盘外点击被忽略
5. 占用格点击提示非法
6. ESC 退出确认逻辑正确

## 23.3 视觉尺寸测试

1. 默认屏幕参数读取正常
2. 手动覆盖物理尺寸正常
3. 格子视角换算正确
4. 超尺寸条件能触发详细报错

## 23.4 Marker 测试

1. 所有启用的事件都能正确映射事件码
2. response marker 与 stimulus marker 时序正确区分
3. 非法点击 marker 能按配置启停
4. 结果 marker 能正确区分 black_win / white_win / draw / abort

## 23.5 日志测试

1. 每局能生成日志文件
2. 动作序列可重建整局棋盘
3. RT 记录存在且非负
4. 屏幕参数与配置快照被正确保存
5. 中止局能正确记录为 aborted