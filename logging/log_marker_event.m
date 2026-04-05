function trial = log_marker_event(trial, event_code, event_name, timestamp, payload)
%LOG_MARKER_EVENT Append one marker event.

entry.event_code = event_code;
entry.event_name = event_name;
entry.timestamp = timestamp;
entry.payload = payload;

if isempty(trial.marker_events)
    trial.marker_events = entry;
else
    trial.marker_events(end + 1) = entry;
end
end
