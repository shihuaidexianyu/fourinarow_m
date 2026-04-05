function send_marker_stub(event_code, event_name, timestamp, payload)
%SEND_MARKER_STUB Default marker callback (console + no-op).

if nargin < 4
    payload = struct();
end

if ~isstruct(payload)
    payload = struct('value', payload);
end

fprintf('[MARKER] code=%d name=%s time=%.6f payload=%s\n', ...
    event_code, event_name, timestamp, jsonencode(payload));
end
