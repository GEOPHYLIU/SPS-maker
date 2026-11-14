function pts = readCSVPoints(filename, recType, delimiter)
    if nargin < 3 || isempty(delimiter), delimiter = ','; end

    fid = fopen(filename, 'r');
    if fid < 0, error('无法打开 %s', filename); end

    headerLine = fgetl(fid);
    if isempty(headerLine)
        fclose(fid);
        error('%s 为空或缺少表头', filename);
    end

    headers = strtrim(strsplit(headerLine, delimiter));
    if ~isempty(headers) && startsWith(headers{1}, char(65279))
        headers{1} = strtrim(extractAfter(headers{1}, 1));
    end

    idx = @(name) find(strcmpi(headers, name), 1);
    iLine  = idx('Line');
    iPoint = idx('Point');
    iX     = idx('X');
    iY     = idx('Y');
    iElev  = idx('Elev');

    if any(cellfun(@isempty, {iLine, iPoint}))
        fclose(fid);
        error('%s 表头缺少 Line 或 Point 列', filename);
    end

    pts = struct('line',{},'point',{},'x',{},'y',{},'elev',{});
    lineNum = 1;
    while ~feof(fid)
        lineNum = lineNum + 1;
        line = fgetl(fid);
        if isempty(line) || all(isspace(line)), continue; end
        fields = strsplit(line, delimiter);
        if numel(fields) < max([iLine, iPoint])
            warning('%s 第 %d 行列数不足，跳过', filename, lineNum);
            continue;
        end

        p.line  = strtrim(fields{iLine});
        p.point = str2double(strtrim(fields{iPoint}));
        p.x     = safeNum(fields, iX);
        p.y     = safeNum(fields, iY);
        p.elev  = safeNum(fields, iElev);

        if isnan(p.point) || isempty(p.line)
            warning('%s 第 %d 行 Line/Point 无效，跳过', filename, lineNum);
            continue;
        end
        pts(end+1) = p; %#ok<AGROW>
    end
    fclose(fid);
end

function v = safeNum(fields, i)
    if i >= 1 && i <= numel(fields) && ~isempty(strtrim(fields{i}))
        v = str2double(strtrim(fields{i}));
    else
        v = NaN;
    end
end