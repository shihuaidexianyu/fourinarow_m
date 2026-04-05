function emit_marker(config, event_name, timestamp, payload)
%EMIT_MARKER Unified marker emit function.

if ~config.marker.enable
    return;
end

if ~isfield(config, 'events') || ~isa(config.events, 'containers.Map')
    error('MarkerError:EventMapMissing', 'config.events is missing or invalid.');
end

if ~isKey(config.events, event_name)
    error('MarkerError:UnknownEvent', 'Unknown marker event: %s', event_name);
end

event_code = config.events(event_name);

try
    config.marker.callback(event_code, event_name, timestamp, payload);
catch ME
    warning('MarkerWarning:CallbackFailed', ...
        'Marker callback failed for %s: %s', event_name, ME.message);
end
end
