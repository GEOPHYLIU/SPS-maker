function pts = readPoints(filename, recType, cfg)
    if nargin < 3, cfg = struct(); end

    if strcmpi(recType, 'S')
        fmt = getFieldOrDefault(cfg, 'sFileFormat', '');
    else
        fmt = getFieldOrDefault(cfg, 'rFileFormat', '');
    end
    delim = getFieldOrDefault(cfg, 'csvDelimiter', ',');

    fmt = lower(strtrim(fmt));

    if isempty(fmt)
        [~, ~, ext] = fileparts(filename);
        ext = lower(ext);
        if strcmp(ext, '.csv')
            fmt = 'csv';
        elseif any(strcmp(ext, {'.txt', '.sps', '.dat'}))
            fmt = 'sps';
        else
            try
                pts = readSPSPoints(filename, recType);
                if ~isempty(pts), return; end
            catch
            end
            fmt = 'csv';
        end
    end

    switch fmt
        case 'sps'
            pts = readSPSPoints(filename, recType);
        case 'csv'
            pts = readCSVPoints(filename, recType, delim);
        otherwise
            error('不支持的格式 "%s"（文件 %s，记录类型 %s）', fmt, filename, recType);
    end

    if isempty(pts)
        warning('%s 未读到任何 %s 点', filename, recType);
    end
end

function v = getFieldOrDefault(s, name, default)
    if isfield(s, name) && ~isempty(s.(name))
        v = s.(name);
    else
        v = default;
    end
end