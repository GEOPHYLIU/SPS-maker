function swaths = readSwathTable(swathFile)
    try
        T = readtable(swathFile, 'Sheet', 'Swath', 'VariableNamingRule', 'preserve');
    catch
        T = readtable(swathFile, 'Sheet', 1, 'VariableNamingRule', 'preserve');
    end
    vars = T.Properties.VariableNames;
    idx = @(name) find(strcmpi(strtrim(vars), name), 1);

    iName = idx('Swath');
    iFS   = idx('First Shot');
    iLS   = idx('Last Shot');
    iFSL  = idx('First Shot Line');
    iLSL  = idx('Last Shot Line');
    iFRL  = idx('First Receiver Line');
    iLRL  = idx('Last Receiver Line');
    iFLMin = idx('Fixed Line Min');   % 可选列
    iFLMax = idx('Fixed Line Max');   % 可选列

    if any(cellfun(@isempty, {iName,iFS,iLS,iFSL,iLSL,iFRL,iLRL}))
        error('线束表列名不完整，需要：Swath, First Shot, Last Shot, First Shot Line, Last Shot Line, First Receiver Line, Last Receiver Line');
    end

    swaths = struct('name',{},'firstShot',{},'lastShot',{}, ...
                    'firstShotLine',{},'lastShotLine',{}, ...
                    'firstRecvLine',{},'lastRecvLine',{}, ...
                    'fixedLineMin',{},'fixedLineMax',{});

    for i = 1:height(T)
        s.name          = char(T{i,iName});
        s.firstShot     = double(T{i,iFS});
        s.lastShot      = double(T{i,iLS});
        s.firstShotLine = double(T{i,iFSL});
        s.lastShotLine  = double(T{i,iLSL});
        s.firstRecvLine = double(T{i,iFRL});
        s.lastRecvLine  = double(T{i,iLRL});

        % 可选：Fixed Line Min/Max（留空或 NaN 表示走原有 interval 逻辑）
        hasMin = ~isempty(iFLMin) && ~isnan(T{i,iFLMin});
        hasMax = ~isempty(iFLMax) && ~isnan(T{i,iFLMax});
        if hasMin && hasMax
            s.fixedLineMin = double(T{i,iFLMin});
            s.fixedLineMax = double(T{i,iFLMax});
            if s.fixedLineMin > s.fixedLineMax
                error('Swath "%s" 的 Fixed Line Min(%g) > Max(%g)', ...
                      s.name, s.fixedLineMin, s.fixedLineMax);
            end
        elseif hasMin ~= hasMax
            error('Swath "%s" 的 Fixed Line Min/Max 必须同时填写或同时留空', s.name);
        else
            s.fixedLineMin = NaN;
            s.fixedLineMax = NaN;
        end

        swaths(end+1) = s; %#ok<AGROW>
    end
end