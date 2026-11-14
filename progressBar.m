function progressBar(cur, total, prefix, tStart)
    % 命令行单行进度：prefix [=====>    ] 45.2% (cur/total) 已用 12.3s
    if nargin < 3 || isempty(prefix), prefix = '进度'; end
    if nargin < 4 || isempty(tStart), tStart = tic; end

    pct = cur / max(total, 1) * 100;
    nBar = 30;
    nFill = round(nBar * cur / max(total, 1));
    bar = [repmat('=', 1, nFill), repmat(' ', 1, nBar - nFill)];
    if nFill > 0, bar(min(nFill, nBar)) = '>'; end

    elapsed = toc(tStart);
    fprintf('\r%s [%s] %5.1f%% (%d/%d) 已用 %.1fs', ...
        prefix, bar, pct, cur, total, elapsed);
    if cur >= total
        fprintf('\n');
    end
end