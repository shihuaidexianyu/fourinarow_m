function send_marker(event_code, event_name, timestamp, ~, marker_cfg)
%SEND_MARKER 通过并口发送 EEG marker。
%   按 test.m 的硬件流程发码：outp(address, code) -> 短脉冲 -> outp(address, 0)。
%
%   输入参数：
%   - event_code: 事件码（ 1~255）
%   - event_name: 事件名（用于告警/调试输出）
%   - timestamp : 事件时间戳（用于回退日志输出）
%   - marker_cfg: 可选配置结构体
%       * parallel_port_address: 并口地址（十六进制字符串，如 '0FF8'）
%       * pulse_width_sec      : 脉冲宽度（秒）
%
%   约束：
%   - 事件码应为 1~255 的整数（0 保留给复位）
%   - 默认并口地址使用 0x0FF8（可由 marker_cfg.parallel_port_address 覆盖）
%   - 默认脉冲宽度 0.004s（可由 marker_cfg.pulse_width_sec 覆盖）

event_code = round(double(event_code));
% 声明静态变量
persistent io_ready address pulse_width_sec
if isempty(io_ready)
    % 首次调用时初始化：读取配置并尝试初始化 I/O。
    % 使用 persistent 避免每次发码重复初始化硬件接口。
    address = hex2dec('0FF8');
    pulse_width_sec = 0.004;

    if isstruct(marker_cfg)
        if isfield(marker_cfg, 'parallel_port_address') && ~isempty(marker_cfg.parallel_port_address)
            address = hex2dec(char(marker_cfg.parallel_port_address));
        end
        if isfield(marker_cfg, 'pulse_width_sec') && ~isempty(marker_cfg.pulse_width_sec)
            pulse_width_sec = double(marker_cfg.pulse_width_sec);
        end
    end

    try
        % 初始化入口
        config_io;
        io_ready = true;
    catch ME
        warning('MarkerWarning:IOUnavailable', ...
            'Marker I/O init failed (%s). Falling back to console print.', ME.message);
        io_ready = false;
    end
end

if ~io_ready
    % 硬件不可用时降级为控制台输出，避免主实验流程中断。
    fprintf('[MARKER:FALLBACK] code=%d name=%s time=%.6f\n', event_code, event_name, timestamp);
    return;
end

% 发送流程：写入事件码 -> 保持脉冲宽度 -> 拉低到 0（复位）
outp(address, event_code);
WaitSecs(pulse_width_sec);
outp(address, 0);

end
