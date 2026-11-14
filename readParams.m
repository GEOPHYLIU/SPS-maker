function cfg = readParams(paramFile)
    % 使用 readcell 读取原始数据，避免类型被强制转换
    try
        T = readcell(paramFile, 'Sheet', 1);
    catch
        error('读取 params 表格失败，请确认文件路径正确且格式无误。');
    end

    cfg = struct();
    
    % 从第 2 行开始遍历
    for i = 2:size(T, 1)
        keyCell = T{i, 1};
        val = T{i, 2};
        
        % 1. 安全获取参数名 (Parameter)
        key = '';
        try
            if ischar(keyCell)
                key = strtrim(keyCell);
            elseif isstring(keyCell) && isscalar(keyCell)
                key = strtrim(char(keyCell));
            end
        catch
            continue; % 如果解析失败直接跳过
        end
        
        if isempty(key), continue; end
        
        % 2. 安全获取参数值 (Value)
        switch key
            case {'recvLineStep','d','halfApertureSmall','halfApertureLarge', ...
                  'P_offset','pointCode','chInc','gapHalfWidth','splitOnGap'}
                % 数值参数
                if isnumeric(val) && isscalar(val) && ~isnan(val)
                    cfg.(key) = double(val);
                elseif ischar(val) || (isstring(val) && isscalar(val))
                    numVal = str2double(val);
                    if ~isnan(numVal), cfg.(key) = numVal; end
                end

            case {'xHeaderTemplate','outputXFile','sFileFormat','rFileFormat','csvDelimiter'}
                % 字符串参数（彻底解决 NaN 问题）
                if ismissing(val)
                    s = '';
                elseif isnumeric(val) && isscalar(val) && isnan(val)
                    s = '';
                else
                    try
                        if ischar(val)
                            s = strtrim(val);
                        elseif isstring(val) && isscalar(val)
                            s = strtrim(char(val));
                        else
                            s = strtrim(char(string(val)));
                        end
                    catch
                        s = '';
                    end
                end
                cfg.(key) = s;

            case 'halfAperture'
                if isnumeric(val) && isscalar(val) && ~isnan(val)
                    cfg.halfApertureSmall = double(val);
                    cfg.halfApertureLarge = double(val);
                end
        end
    end

    % 3. 默认值兜底
    defaults = struct('recvLineStep',16,'d',2, ...
                      'halfApertureSmall',320,'halfApertureLarge',320, ...
                      'P_offset',1,'pointCode',1,'chInc',1, ...
                      'gapHalfWidth',0,'splitOnGap',0, ...
                      'xHeaderTemplate','','outputXFile','output', ...
                      'sFileFormat','','rFileFormat','','csvDelimiter',',');

    fn = fieldnames(defaults);
    for i = 1:numel(fn)
        v = [];
        if isfield(cfg, fn{i}), v = cfg.(fn{i}); end
        isEmpty = isempty(v) || (isnumeric(v) && any(isnan(v))) || ...
                  (ischar(v) && isempty(strtrim(v)));
        if isEmpty
            cfg.(fn{i}) = defaults.(fn{i});
        end
    end

    % 4. 其他处理
    if strcmpi(cfg.csvDelimiter, 'tab')
        cfg.csvDelimiter = sprintf('\t');
    end

    if cfg.splitOnGap && cfg.gapHalfWidth <= 0
        warning('splitOnGap=1 但 gapHalfWidth<=0，挖空无效');
    end
end