function main_generate_X(sFile, rFile, swathFile, paramFile, logFcn, progFcn)
% 主入口：读四个输入文件，生成 SPS 2.1 格式 X 关系文件
% 支持根据 params 自动输出 TXT 定宽格式 或 CSV 逗号分隔格式

    if nargin < 4
        error('需要 4 个输入：S 文件、R 文件、线束表、参数表');
    end
    if nargin < 5 || isempty(logFcn)
        logFcn = @(msg) fprintf('%s\n', msg);
    end
    if nargin < 6 || isempty(progFcn)
        progFcn = @(frac, msg) [];
    end

    tAll = tic;

    % 1. 读取参数
    cfg = readParams(paramFile);
    logFcn(sprintf('参数: recvLineStep=%d, d=%d, small=%d, large=%d, P_offset=%d, gap=%d', ...
        cfg.recvLineStep, cfg.d, cfg.halfApertureSmall, ...
        cfg.halfApertureLarge, cfg.P_offset, cfg.gapHalfWidth));
        
    % ================= 关键修改：自动补全后缀 =================
    [~, ~, ext] = fileparts(cfg.outputXFile);
    
    % 如果 Excel 里没填后缀（比如只填了 newsps），自动帮它补上 .txt
    % 如果你想默认生成 CSV，只需把下面的 '.txt' 改成 '.csv' 即可
    if isempty(ext)
        cfg.outputXFile = [cfg.outputXFile, '.txt']; 
    end
    
    % 重新获取后缀，判断输出格式
    [~, ~, ext] = fileparts(cfg.outputXFile);
    isCSV = strcmpi(ext, '.csv');
    
    if isCSV
        logFcn(sprintf('目标输出文件: %s (CSV 模式，逗号分隔)', cfg.outputXFile));
    else
        logFcn(sprintf('目标输出文件: %s (TXT 模式，80列定宽)', cfg.outputXFile));
    end
    % ==========================================================

    % 2. 读取线束表、S/R 文件
    swaths = readSwathTable(swathFile);
    logFcn(sprintf('线束表: %d 个 Swath', numel(swaths)));

    logFcn(sprintf('读取 S 文件: %s ...', sFile));
    shots = readPoints(sFile, 'S', cfg);
    logFcn(sprintf('读取 R 文件: %s ...', rFile));
    recvPts = readPoints(rFile, 'R', cfg);
    recvLib = groupRecvByLine(recvPts);
    logFcn(sprintf('S: %d 炮; R: %d 检波点; 检波线: %d', ...
        numel(shots), numel(recvPts), recvLib.Count));

    headerLines = readHeaderLines(cfg.xHeaderTemplate);

    % 统计总炮数（用于进度条计算）
    totalShots = 0;
    for s = 1:numel(swaths)
        sw = swaths(s);
        for i = 1:numel(shots)
            sl = str2double(shots(i).line);
            if shots(i).point >= sw.firstShot && shots(i).point <= sw.lastShot && ...
               sl >= sw.firstShotLine && sl <= sw.lastShotLine
                totalShots = totalShots + 1;
            end
        end
    end

    recNum = 0;
    doneShots = 0;
    totalWrittenRecs = 0;

    % 3. 提前打开文件，边生成边写 (彻底解决内存溢出与卡死)
    fid = fopen(cfg.outputXFile, 'w');
    if fid < 0
        error('无法创建输出文件 %s，请检查路径或权限！', cfg.outputXFile);
    end
    
    % 写入头文件
    for i = 1:numel(headerLines)
        if isCSV
            fprintf(fid, '"%s"\n', headerLines{i}); % CSV 下加引号防串列
        else
            fprintf(fid, '%s\n', headerLines{i});
        end
    end

    % 4. 逐 Swath 生成并写入
    for s = 1:numel(swaths)
        sw = swaths(s);
        if ~isnan(sw.fixedLineMin)
            modeStr = sprintf('fixedRange [%d, %d]', sw.fixedLineMin, sw.fixedLineMax);
        else
            modeStr = sprintf('interval (recvLineStep=%d)', cfg.recvLineStep);
        end
        logFcn(sprintf('[%d/%d] %s: %s', s, numel(swaths), sw.name, modeStr));

        nSwShots = 0;
        for i = 1:numel(shots)
            sl = str2double(shots(i).line);
            if shots(i).point >= sw.firstShot && shots(i).point <= sw.lastShot && ...
               sl >= sw.firstShotLine && sl <= sw.lastShotLine
                nSwShots = nSwShots + 1;
            end
        end

        % 计算当前 Swath 的关系记录
        [xRecs, recNum] = generateXForSwath(sw, shots, recvLib, cfg, recNum, ...
            nSwShots, doneShots, totalShots, progFcn);

        doneShots = doneShots + nSwShots;
        nRecs = numel(xRecs);

        if nRecs == 0
            logFcn('  → 0 条');
        else
            logFcn(sprintf('  → %d 条, 记录号 %d-%d', ...
                nRecs, xRecs(1).recordNum, xRecs(end).recordNum));
                
            % 【核心优化】立刻把当前 Swath 的数据格式化并写入
            outLines = strings(nRecs, 1);
            for k = 1:nRecs
                r = xRecs(k);
                
                if isCSV
                    % --- CSV 模式：用逗号分隔各个字段 ---
                    outLines(k) = sprintf('X, %d, %s, %d, 1, %d, %d, %s, %d, %d, 1', ...
                        r.recordNum, num2str(r.shotLine), r.shotPoint, r.firstCh, r.lastCh, ...
                        num2str(r.recvLine), r.firstRecv, r.lastRecv);
                else
                    % --- TXT 模式：按 123.txt 列位（80 列） ---
lineStr = [ ...
    'X', ...                                        % 列1
    sprintf('%6d', 0), ...                          % 列2–7 磁带盘号（固定0，或 cfg 里的值）
    sprintf('%8d', r.recordNum), ...                % 列8–15 记录号
    '1', ...                                        % 列16 记录增量
    '1', ...                                        % 列17 索引（仪器代码/固定1）
    sprintf('%10d', str2double(r.shotLine)), ...    % 列18–27 炮线号
    sprintf('%10d', r.shotPoint), ...               % 列28–37 炮点号
    sprintf('%1s', r.pointCode), ...                % 列38 炮点索引
    sprintf('%5d', r.firstCh), ...                  % 列39–43 首通道
    sprintf('%5d', r.lastCh), ...                   % 列44–48 末通道
    sprintf('%1d', r.chInc1), ...                   % 列49 通道增量
    sprintf('%10d', str2double(r.recvLine)), ...    % 列50–59 检波线号
    sprintf('%10d', r.firstRecv), ...               % 列60–69 首检波点
    sprintf('%10d', r.lastRecv), ...                % 列70–79 末检波点
    sprintf('%1s', r.pointCode) ...                 % 列80 检波点索引
];

if length(lineStr) ~= 80
    error('第 %d 条 X 记录长度 %d，不是 80 列（记录号 %d）', ...
        k, length(lineStr), r.recordNum);
end
outLines(k) = string(lineStr);
                    
                    
           
                    
                   
                end
            end
            % 一次性写入当前 Swath 的数据
            fprintf(fid, '%s\n', outLines);
            totalWrittenRecs = totalWrittenRecs + nRecs;
        end
        % 清空当前 Swath 数组，避免撑爆内存
        clear xRecs outLines; 
    end

    % 5. 关闭文件
    fclose(fid);

    totalSec = toc(tAll);
    logFcn(sprintf('完成: 共 %d 条记录, 末号 %d, 输出 %s', ...
        totalWrittenRecs, recNum, cfg.outputXFile));
    logFcn(sprintf('总运行时间: %.2f s (%.2f min)', totalSec, totalSec/60));
end