function codes = resolve_key_names_to_codes(names)
%RESOLVE_KEY_NAMES_TO_CODES 将键名配置解析为 PTB keycode 数组。
%   支持 char/string/cellstr 输入。
%   仅按配置中提供的键名直接解析，便于实验现场定向调试。

if ischar(names) || isstring(names)
    names = {char(names)};
end

codes = [];
for i = 1:numel(names)
    name_i = char(names{i});
    try
        code_i = KbName(name_i);
    catch
        code_i = [];
    end

    if isempty(code_i) || any(isnan(code_i))
        error('ConfigError:InvalidKeyName', ...
            'Invalid key name in config.controls: %s', name_i);
    end

    codes = [codes, code_i(:)']; %#ok<AGROW>
end

codes = unique(codes);
end
