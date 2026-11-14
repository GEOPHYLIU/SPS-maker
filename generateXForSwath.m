function [xRecs, recNum] = generateXForSwath(swath, shots, recvLib, cfg, recNum, ...
        nSwShots, doneShots, totalShots, progFcn)
% 生成单个 Swath 的 X 记录
% 可选参数：
%   nSwShots   本 Swath 炮数（仅用于判定"本段结束必刷"，可为 NaN）
%   doneShots  之前已完成炮数
%   totalShots 全局总炮数（NaN 表示不显示进度）
%   progFcn    @(frac, msg) 进度回调；frac∈[0,1]

    if nargin < 6, nSwShots   = NaN; end
    if nargin < 7, doneShots  = 0;   end
    if nargin < 8, totalShots = NaN; end
    if nargin < 9 || isempty(progFcn), progFcn = @(f,m) []; end

    lines = buildReceiverLineList(swath, recvLib, cfg);
    nLines = numel(lines);

    % ---- 预分配 xRecs ----
    maxLines = max(nLines, 1);
    cap = nSwShots * maxLines * 2;
    if isnan(cap) || cap < 1024
        cap = 1024;
    end
    xRecs = repmat(struct('recordNum',0,'shotLine','','shotPoint',0, ...
        'pointCode','','firstCh',0,'lastCh',0,'chInc1',0, ...
        'recvLine','','firstRecv',0,'lastRecv',0,'chInc2',0), cap, 1);
    nRec = 0;

    lastTick = tic;
    processedInSwath = 0;

    for i = 1:numel(shots)
        sh = shots(i);
        shotLineNum = str2double(sh.line);

        if sh.point < swath.firstShot || sh.point > swath.lastShot
            continue;
        end
        if shotLineNum < swath.firstShotLine || shotLineNum > swath.lastShotLine
            continue;
        end

        processedInSwath = processedInSwath + 1;

        if ~isnan(totalShots) && totalShots > 0
            if toc(lastTick) > 2.0 || processedInSwath == nSwShots
                frac = (doneShots + processedInSwath) / totalShots;
                progFcn(frac, sprintf('生成 %s（%d/%d）', ...
                    swath.name, doneShots + processedInSwath, totalShots));
                lastTick = tic;
            end
        end
        recNum = recNum + 1;
        P = shotLineNum + cfg.P_offset;   % P_offset = 0 时 P = 炮线号
        chCursor = 1;

        useGap = cfg.splitOnGap && cfg.gapHalfWidth > 0;

        for k = 1:nLines
            lineNo = lines{k};
            if ~isKey(recvLib, lineNo)
                continue;
            end
            pts = recvLib(lineNo);

            % ---- 取道范围：挖空时把 gap 加进 halfAperture，总道数不变 ----
            if useGap
                pLo = P - (cfg.halfApertureSmall + cfg.gapHalfWidth - 0.5) * cfg.d;
                pHi = P + (cfg.halfApertureLarge + cfg.gapHalfWidth - 0.5) * cfg.d;
            else
                pLo = P - (cfg.halfApertureSmall - 0.5) * cfg.d;
                pHi = P + (cfg.halfApertureLarge - 0.5) * cfg.d;
            end
            inRange = pts >= pLo & pts <= pHi;

            if useGap
                gLo = P - cfg.gapHalfWidth * cfg.d - 0.5 * cfg.d;
                gHi = P + cfg.gapHalfWidth * cfg.d + 0.5 * cfg.d;
                inGap = pts > gLo & pts < gHi;
                keep = inRange & ~inGap;
                segMask = { keep & (pts <= gLo), keep & (pts >= gHi) };
            else
                keep = inRange;
                segMask = { keep };
            end

            for s = 1:numel(segMask)
                mask = segMask{s};
                if ~any(mask)
                    continue;
                end
                segPts = pts(mask);
                nCh = numel(segPts);

                r.recordNum = recNum;
                r.shotLine  = sh.line;
                r.shotPoint = sh.point;
                r.pointCode = sprintf('%d', cfg.pointCode);
                r.firstCh   = chCursor;
                r.chInc1    = cfg.chInc;
                r.lastCh    = chCursor + nCh - 1;
                r.recvLine  = lineNo;
                r.firstRecv = segPts(1);
                r.lastRecv  = segPts(end);
                r.chInc2    = cfg.chInc;

                nRec = nRec + 1;
                if nRec > numel(xRecs)
                    xRecs = [xRecs; repmat(xRecs(1), cap, 1)]; %#ok<AGROW>
                end
                xRecs(nRec) = r;

                chCursor = chCursor + nCh;
            end
        end
    end

    xRecs = xRecs(1:nRec);
end

function lines = buildReceiverLineList(swath, recvLib, cfg)
    useFixed = ~isnan(swath.fixedLineMin) && ~isnan(swath.fixedLineMax);
    if useFixed
        allKeys = recvLib.keys;
        allNums = cellfun(@str2double, allKeys);
        selNums = sort(allNums(allNums >= swath.fixedLineMin & allNums <= swath.fixedLineMax));
        lines = arrayfun(@(x) sprintf('%d', x), selNums, 'UniformOutput', false);
    else
        nLines = round((swath.lastRecvLine - swath.firstRecvLine) / cfg.recvLineStep) + 1;
        lines = cell(1, nLines);
        for k = 1:nLines
            lines{k} = sprintf('%d', swath.firstRecvLine + (k-1)*cfg.recvLineStep);
        end
    end
end