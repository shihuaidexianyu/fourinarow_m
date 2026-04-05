function send_marker_stub(event_code, event_name, timestamp, payload)
%SEND_MARKER_STUB 默认 marker 回调（仅控制台打印）。
%   实际 EEG/MEG 环境下替换 config.marker.callback 为硬件发送函数。

if nargin < 4
    payload = struct();
end

if ~isstruct(payload)
    payload = struct('value', payload);
end

fprintf('[MARKER] code=%d name=%s time=%.6f payload=%s\n', ...
    event_code, event_name, timestamp, jsonencode(payload));
end
