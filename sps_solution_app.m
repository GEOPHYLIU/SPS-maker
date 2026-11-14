function app = sps_solution_app()
%SPS_SOLUTION_APP  SPS Solution V8 - Windows 11 style light card interface.
%
%   Standalone .m rebuild of the App Designer app (app1.mlapp). The processing
%   path is unchanged: START calls
%       main_generate_X(sFile, rFile, swathFile, paramFile, logFcn, progFcn)
%   and the helper modules (readParams / readSwathTable / readPoints / ...)
%   are used exactly as before. app1.mlapp is left untouched.
%
%   app = sps_solution_app() returns handles so the window can be scripted:
%       app.figure, app.fields.<name>, app.start(), app.loadParams(),
%       app.loadSwath(), app.loadDefaults(), app.log(msg)

T  = spsTheme();
appDir = fileparts(mfilename('fullpath'));

scr = get(0, 'ScreenSize');
W = min(1200, scr(3) - 60);
H = min(790, scr(4) - 80);

fig = uifigure('Visible', 'off');
fig.Name = 'SPS Solution V8';
fig.Color = T.bg;
fig.Position = [max(20, round((scr(3) - W) / 2)), ...
                max(20, round((scr(4) - H) / 2)), W, H];
logoF = fullfile(appDir, 'Logo2.jpg');
if exist(logoF, 'file')
    try, fig.Icon = logoF; catch, end
end

root = uigridlayout(fig, [3 1]);
root.RowHeight = {64, '1x', 30};
root.ColumnWidth = {'1x'};
root.Padding = [0 0 0 0];
root.RowSpacing = 8;
root.BackgroundColor = T.bg;

% ---------------------------------------------------------------- header ----
head = uigridlayout(root, [1 5]);
head.Layout.Row = 1;
head.ColumnWidth = {150, '1x', 92, 112, 124};
head.Padding = [14 8 14 8];
head.ColumnSpacing = 8;
head.BackgroundColor = T.card;

if exist(logoF, 'file')
    img = uiimage(head);
    img.Layout.Column = 1;
    img.ImageSource = logoF;
    img.ScaleMethod = 'fit';
    try, img.HorizontalAlignment = 'left'; catch, end
end

tstack = uigridlayout(head, [2 1]);
tstack.Layout.Column = 2;
tstack.RowHeight = {30, 18};
tstack.RowSpacing = 0;
tstack.Padding = [0 0 0 0];
tstack.BackgroundColor = T.card;

lbTitle = uilabel(tstack, 'Text', 'SPS Solution', ...
    'FontSize', 18, 'FontWeight', 'bold', 'FontColor', T.text);
lbSub = uilabel(tstack, 'Text', ...
    'SPS / XPS acquisition geometry generator   ·   V8', ...
    'FontSize', 10, 'FontColor', T.mute);

bClear = uibutton(head, 'Text', 'Clear', ...
    'ButtonPushedFcn', @(s,e) onClear());
bClear.Layout.Column = 3;
styleBtn(bClear, 'ghost', 12);

bDef = uibutton(head, 'Text', 'Load defaults', ...
    'ButtonPushedFcn', @(s,e) loadDefaults());
bDef.Layout.Column = 4;
styleBtn(bDef, 'ghost', 12);

bRun = uibutton(head, 'Text', 'START', ...
    'ButtonPushedFcn', @(s,e) runPipeline());
bRun.Layout.Column = 5;
styleBtn(bRun, 'primary', 13);
bRun.FontWeight = 'bold';

% ------------------------------------------------------------------ body ----
body = uigridlayout(root, [2 1]);
body.Layout.Row = 2;
body.RowHeight = {232, '1x'};
body.RowSpacing = 10;
body.Padding = [14 0 14 0];
body.BackgroundColor = T.bg;

top = uigridlayout(body, [1 2]);
top.Layout.Row = 1;
top.ColumnWidth = {598, '1x'};
top.RowHeight = {'1x'};
top.ColumnSpacing = 10;
top.Padding = [0 0 0 0];
top.BackgroundColor = T.bg;

% ---- input files card ------------------------------------------------------
inCard = uigridlayout(top, [7 1]);
inCard.Layout.Row = 1; inCard.Layout.Column = 1;
inCard.RowHeight = {22, 34, 34, 34, 34, '1x', 20};
inCard.Padding = [14 8 14 8];
inCard.RowSpacing = 8;
inCard.ColumnWidth = {'1x'};
inCard.BackgroundColor = T.card;

inCardTitle = uilabel(inCard, 'Text', 'Input files');
inCardTitle.FontSize = 12; inCardTitle.FontWeight = 'bold';
inCardTitle.FontColor = T.text;
inCardTitle.Layout.Row = 1;

rows = {'S File', 'R File', 'Swath File', 'Param File'};
ph   = {'Select SPS source file...', 'Select SPS receiver file...', ...
        'Select swath relation workbook...', 'Select parameter workbook...'};
S = struct();
fNames = {'SFile', 'RFile', 'SwathFile', 'ParamFile'};

for i = 1:4
    rg = uigridlayout(inCard, [1 3]);
    rg.Layout.Row = i + 1;
    rg.ColumnWidth = {92, '1x', 88};
    rg.RowHeight = {'1x'};
    rg.ColumnSpacing = 8;
    rg.Padding = [0 0 0 0];
    rg.BackgroundColor = T.card;

    lb = uilabel(rg, 'Text', rows{i});
    lb.FontSize = 10; lb.FontColor = T.mute;
    lb.FontName = 'Microsoft YaHei UI';
    lb.HorizontalAlignment = 'right';

    ed = uieditfield(rg, 'text');
    ed.Placeholder = ph{i};
    ed.FontSize = 10;
    ed.FontName = 'Microsoft YaHei UI';
    ed.BackgroundColor = T.card;
    ed.Value = '';

    bb = uibutton(rg, 'Text', 'Browse...');
    styleBtn(bb, 'soft', 10);
    switch i
        case 1, bb.ButtonPushedFcn = @(s,e) pickFile(fNames{i}, 'SPS / text data', {'*.txt;*.csv;*.sps;*.dat'}, 'Select S file');
        case 2, bb.ButtonPushedFcn = @(s,e) pickFile(fNames{i}, 'SPS / text data', {'*.txt;*.csv;*.sps;*.dat'}, 'Select R file');
        case 3, bb.ButtonPushedFcn = @(s,e) pickFile(fNames{i}, 'Excel workbook', {'*.xlsx;*.xls'}, 'Select swath relation table');
        case 4, bb.ButtonPushedFcn = @(s,e) pickFile(fNames{i}, 'Excel workbook', {'*.xlsx;*.xls'}, 'Select parameter table');
    end
    S.(fNames{i}) = ed;
    S.([fNames{i} 'Btn']) = bb;
end

hint = uilabel(inCard, 'Text', ...
    'Swath = "Swath" sheet, params = sheet 1; the output path comes from the params workbook.');
hint.Layout.Row = 7;
hint.FontSize = 9; hint.FontColor = T.mute;
hint.FontName = 'Microsoft YaHei UI';

% ---- execution log card ----------------------------------------------------
logCard = uigridlayout(top, [2 1]);
logCard.Layout.Row = 1; logCard.Layout.Column = 2;
logCard.RowHeight = {22, '1x'};
logCard.Padding = [14 8 14 10];
logCard.RowSpacing = 6;
logCard.ColumnWidth = {'1x'};
logCard.BackgroundColor = T.card;

logTitle = uilabel(logCard, 'Text', 'Execution log');
logTitle.FontSize = 12; logTitle.FontWeight = 'bold';
logTitle.FontColor = T.text;
logTitle.Layout.Row = 1;

logBox = uitextarea(logCard);
logBox.Layout.Row = 2;
logBox.Editable = 'off';
logBox.FontName = 'Consolas';
logBox.FontSize = 10;
logBox.FontColor = T.mute;
logBox.BackgroundColor = T.soft2;
logBox.Value = {'Ready.  Select the four input files, then press START.'};

% ---- tables -------------------------------------------------------------------
tblRow = uigridlayout(body, [1 2]);
tblRow.Layout.Row = 2;
tblRow.ColumnWidth = {'1x', '1x'};
tblRow.RowHeight = {'1x'};
tblRow.ColumnSpacing = 10;
tblRow.Padding = [0 0 0 0];
tblRow.BackgroundColor = T.bg;

swCard = uigridlayout(tblRow, [2 1]);
swCard.Layout.Column = 1;
swCard.RowHeight = {22, '1x'};
swCard.Padding = [14 8 14 10];
swCard.RowSpacing = 6;
swCard.ColumnWidth = {'1x'};
swCard.BackgroundColor = T.card;

swTitle = uilabel(swCard, 'Text', 'Swath table   (relation workbook)');
swTitle.FontSize = 12; swTitle.FontWeight = 'bold';
swTitle.FontColor = T.text;
swTitle.Layout.Row = 1;

tSwath = uitable(swCard);
tSwath.Layout.Row = 2;
tSwath.ColumnName = {'Column 1'; 'Column 2'; 'Column 3'; 'Column 4'};
tSwath.RowName = {};
tSwath.FontSize = 10;
tSwath.FontName = 'Microsoft YaHei UI';
tSwath.BackgroundColor = T.card;
try, tSwath.RowStriping = 'on'; catch, end

prCard = uigridlayout(tblRow, [2 1]);
prCard.Layout.Column = 2;
prCard.RowHeight = {22, '1x'};
prCard.Padding = [14 8 14 10];
prCard.RowSpacing = 6;
prCard.ColumnWidth = {'1x'};
prCard.BackgroundColor = T.card;

prTitle = uilabel(prCard, 'Text', 'Parameter table   (params workbook)');
prTitle.FontSize = 12; prTitle.FontWeight = 'bold';
prTitle.FontColor = T.text;
prTitle.Layout.Row = 1;

tParam = uitable(prCard);
tParam.Layout.Row = 2;
tParam.ColumnName = {'Parameter'; 'Value'; 'Column 3'; 'Column 4'};
tParam.RowName = {};
tParam.FontSize = 10;
tParam.FontName = 'Microsoft YaHei UI';
tParam.BackgroundColor = T.card;
try, tParam.RowStriping = 'on'; catch, end

% ----------------------------------------------------------------- footer ----
foot = uigridlayout(root, [1 4]);
foot.Layout.Row = 3;
foot.ColumnWidth = {16, '1x', 84, 300};
foot.Padding = [18 0 18 0];
foot.ColumnSpacing = 8;
foot.BackgroundColor = T.card;

dot = uilabel(foot, 'Text', char(9679));
dot.FontSize = 12;
dot.FontColor = T.accent;
dot.HorizontalAlignment = 'center';

status = uilabel(foot, 'Text', 'Ready');
status.Layout.Column = 2;
status.FontSize = 10; status.FontColor = T.mute;

pct = uilabel(foot, 'Text', '');
pct.Layout.Column = 3;
pct.FontSize = 10; pct.FontColor = T.mute; pct.HorizontalAlignment = 'right';

ver = uilabel(foot, 'Text', 'SPS Solution V8   ·   Windows 11 light theme', ...
    'HorizontalAlignment', 'right');
ver.Layout.Column = 4;
ver.FontSize = 9; ver.FontColor = T.mute;

% state
tStart = tic;
progDlg = [];

setStatus('Ready', T.accent);
loadDefaults(true);

fig.Visible = 'on';

app.figure  = fig;
app.fields  = S;
app.tableSwath = tSwath;
app.tableParam = tParam;
app.logBox  = logBox;
app.start   = @runPipeline;
app.loadParams = @loadParamsTbl;
app.loadSwath  = @loadSwathTbl;
app.loadDefaults = @loadDefaults;
app.log     = @addLog;
app.statusText = @() status.Text;

% =====================================================================
    function styleBtn(b, kind, fs)
        b.FontSize = fs;
        b.FontName = 'Microsoft YaHei UI';
        switch kind
            case 'primary'
                b.BackgroundColor = T.accent;
                b.FontColor = [1 1 1];
                b.FontWeight = 'bold';
            case 'ghost'
                b.BackgroundColor = T.card;
                b.FontColor = T.text;
            otherwise
                b.BackgroundColor = T.soft;
                b.FontColor = T.text;
        end
    end

    function setStatus(txt, col)
        status.Text = txt;
        status.FontColor = col;
        try
            dot.FontColor = col;
        catch
        end
    end

    function addLog(msg)
        if ~ischar(msg)
            msg = char(string(msg));
        end
        lines = logBox.Value;
        if isempty(lines)
            lines = {};
        elseif ischar(lines)
            lines = {lines};
        elseif isstring(lines)
            lines = cellstr(lines);
        end
        if isempty(lines) || numel(lines) == 1
            if isempty(lines) || strncmp(strtrim(lines{1}), 'Ready.', 6)
                lines = {};
            end
        end
        lines{end+1} = msg;
        if numel(lines) > 400
            lines = lines(end-399:end);
        end
        logBox.Value = lines;
        drawnow limitrate;
    end

    function pickFile(fieldName, dlgTitle, filt, promptTitle)
        [f, p] = uigetfile(filt, promptTitle);
        if isequal(f, 0), return; end
        full = fullfile(p, f);
        S.(fieldName).Value = full;
        switch fieldName
            case 'SwathFile'
                loadSwathTbl();
            case 'ParamFile'
                loadParamsTbl();
            otherwise
                setStatus(['Selected ' fieldName ' : ' f], T.accent);
                addLog(['[file] ' fieldName ' = ' full]);
        end
    end

    function loadParamsTbl()
        f = S.ParamFile.Value;
        if isempty(f) || ~isfile(f)
            tParam.Data = {};
            tParam.ColumnName = {};
            return;
        end
        try
            Tt = readtable(f, 'VariableNamingRule', 'preserve');
            tParam.Data = cleanCells(table2cell(Tt));
            tParam.ColumnName = Tt.Properties.VariableNames;
            prTitle.Text = sprintf('Parameter table   (params workbook)   ·   %d rows, %d cols', ...
                size(Tt, 1), size(Tt, 2));
            setStatus(sprintf('Parameters loaded: %d rows', size(Tt, 1)), T.ok);
        catch ME
            tParam.Data = {};
            tParam.ColumnName = {};
            setStatus('Failed to read the params workbook', T.err);
            addLog(['[error] params: ' ME.message]);
            uialert(fig, ['读取参数表失败: ' ME.message], 'Error');
        end
    end

    function loadSwathTbl()
        f = S.SwathFile.Value;
        if isempty(f) || ~isfile(f)
            tSwath.Data = {};
            tSwath.ColumnName = {};
            return;
        end
        try
            try
                Tt = readtable(f, 'Sheet', 'Swath', 'VariableNamingRule', 'preserve');
            catch
                Tt = readtable(f, 'Sheet', 1, 'VariableNamingRule', 'preserve');
            end
            tSwath.Data = cleanCells(table2cell(Tt));
            tSwath.ColumnName = Tt.Properties.VariableNames;
            swTitle.Text = sprintf('Swath table   (relation workbook)   ·   %d rows, %d cols', ...
                size(Tt, 1), size(Tt, 2));
            setStatus(sprintf('Swath table loaded: %d rows', size(Tt, 1)), T.ok);
        catch ME
            tSwath.Data = {};
            tSwath.ColumnName = {};
            setStatus('Failed to read the swath workbook', T.err);
            addLog(['[error] swath: ' ME.message]);
            uialert(fig, ['读取线束表失败: ' ME.message], 'Error');
        end
    end

    function loadDefaults(silent)
        if nargin < 1, silent = false; end
        sw = fullfile(appDir, '关系划分.xlsx');
        pr = fullfile(appDir, 'params.xlsx');
        n = 0;
        if exist(sw, 'file')
            S.SwathFile.Value = sw; loadSwathTbl(); n = n + 1;
        end
        if exist(pr, 'file')
            S.ParamFile.Value = pr; loadParamsTbl(); n = n + 1;
        end
        s1 = fullfile(appDir, 'S1.txt');
        r1 = fullfile(appDir, 'R1.txt');
        if exist(s1, 'file'), S.SFile.Value = s1; n = n + 1; end
        if exist(r1, 'file'), S.RFile.Value = r1; n = n + 1; end
        if n > 0
            if ~silent
                addLog(sprintf('[defaults] %d file(s) pre-filled from the app folder.', n));
            end
            setStatus('Defaults loaded from app folder', T.ok);
        else
            if ~silent
                addLog('[defaults] nothing found in the app folder.');
            end
        end
    end

    function onClear()
        S.SFile.Value = ''; S.RFile.Value = '';
        S.SwathFile.Value = ''; S.ParamFile.Value = '';
        tSwath.Data = {}; tSwath.ColumnName = {'Column 1'; 'Column 2'; 'Column 3'; 'Column 4'};
        tParam.Data = {}; tParam.ColumnName = {'Parameter'; 'Value'; 'Column 3'; 'Column 4'};
        swTitle.Text = 'Swath table   (relation workbook)';
        prTitle.Text = 'Parameter table   (params workbook)';
        logBox.Value = {'Ready.  Select the four input files, then press START.'};
        pct.Text = '';
        setStatus('Cleared', T.accent);
    end

    function setBusy(isBusy)
        bRun.Enable = ~isBusy;
        bClear.Enable = ~isBusy;
        bDef.Enable = ~isBusy;
        fn = fieldnames(S);
        for k = 1:numel(fn)
            if ~isempty(strfind(fn{k}, 'Btn')) %#ok<STREMP>
                S.(fn{k}).Enable = ~isBusy;
            end
        end
        if isBusy
            bRun.Text = 'Running...';
        else
            bRun.Text = 'START';
        end
        drawnow limitrate;
    end

    function runPipeline()
        sFile = char(S.SFile.Value);
        if isempty(sFile) || ~isfile(sFile)
            [f, p] = uigetfile({'*.txt;*.sps;*.csv;*.dat', 'SPS file'}, 'Select S file');
            if isequal(f, 0), return; end
            sFile = fullfile(p, f); S.SFile.Value = sFile;
        end
        rFile = char(S.RFile.Value);
        if isempty(rFile) || ~isfile(rFile)
            [f, p] = uigetfile({'*.txt;*.sps;*.csv;*.dat', 'SPS file'}, 'Select R file');
            if isequal(f, 0), return; end
            rFile = fullfile(p, f); S.RFile.Value = rFile;
        end
        swathFile = char(S.SwathFile.Value);
        if isempty(swathFile) || ~isfile(swathFile)
            d = fullfile(appDir, '关系划分.xlsx');
            if exist(d, 'file')
                swathFile = d; S.SwathFile.Value = d; loadSwathTbl();
            else
                [f, p] = uigetfile({'*.xlsx;*.xls', 'Excel file'}, 'Select swath relation table');
                if isequal(f, 0), return; end
                swathFile = fullfile(p, f); S.SwathFile.Value = swathFile; loadSwathTbl();
            end
        end
        paramFile = char(S.ParamFile.Value);
        if isempty(paramFile) || ~isfile(paramFile)
            d = fullfile(appDir, 'params.xlsx');
            if exist(d, 'file')
                paramFile = d; S.ParamFile.Value = d; loadParamsTbl();
            else
                [f, p] = uigetfile({'*.xlsx;*.xls', 'Excel file'}, 'Select parameter table');
                if isequal(f, 0), return; end
                paramFile = fullfile(p, f); S.ParamFile.Value = paramFile; loadParamsTbl();
            end
        end

        addLog('==== files to process ====');
        addLog(['S     : ' sFile]);
        addLog(['R     : ' rFile]);
        addLog(['Swath : ' swathFile]);
        addLog(['Param : ' paramFile]);

        setBusy(true);
        setStatus('Running...', T.warn);
        tStart = tic;
        try
            progDlg = uiprogressdlg(fig, 'Title', 'SPS Solution', ...
                'Message', 'Reading inputs...', 'Value', 0.02, 'Cancelable', 'off');
        catch
            progDlg = [];
        end
        drawnow;

        try
            logFcn  = @(msg) addLog(msg);
            progFcn = @(frac, msg) updateProgress(frac, msg);
            main_generate_X(sFile, rFile, swathFile, paramFile, logFcn, progFcn);
            addLog(sprintf('【成功】全部生成完毕！  (%.1f s)', toc(tStart)));
            setStatus(sprintf('Done in %.1f s', toc(tStart)), T.ok);
            logOutputFile(paramFile);
        catch ME
            addLog(['【运行报错】: ' ME.message]);
            setStatus('Failed - see the log', T.err);
            for k = 1:min(4, numel(ME.stack))
                addLog(sprintf('   at %s line %d', ME.stack(k).name, ME.stack(k).line));
            end
        end

        if ~isempty(progDlg) && isvalid(progDlg)
            try, close(progDlg); catch, end
        end
        progDlg = [];
        setBusy(false);
        pct.Text = '';
    end

    function logOutputFile(paramFile)
        % report the generated file with its full path
        try
            cfg = readParams(paramFile);
            of = cfg.outputXFile;
            if isempty(of), return; end
            [~, ~, ext] = fileparts(of);
            if isempty(ext), of = [of '.txt']; end
            if isempty(fileparts(of))
                of = fullfile(pwd, of);
            end
            if exist(of, 'file')
                addLog(sprintf('[output] %s   (%.1f KB)', of, dir(of).bytes / 1024));
            else
                addLog(sprintf('[output] %s   (not found)', of));
            end
        catch
        end
    end

    function updateProgress(frac, msg)
        frac = max(0, min(1, frac));
        if ~isempty(progDlg) && isvalid(progDlg)
            progDlg.Value = frac;
            progDlg.Message = msg;
            try, progDlg.ShowPercentage = 'on'; catch, end
        end
        pct.Text = sprintf('%d%%', round(frac * 100));
        drawnow limitrate;
    end
end

% ---------------------------------------------------------------- helpers ----
function C = cleanCells(C)
% blank out missing entries so an empty workbook cell shows as '' not NaN
for i = 1:numel(C)
    v = C{i};
    if isnumeric(v) && isempty(v)
        C{i} = '';
    elseif isnumeric(v) && isscalar(v) && isnan(v)
        C{i} = '';
    elseif ischar(v) && strcmp(strtrim(v), 'NaN')
        C{i} = '';
    elseif isa(v, 'datetime') && ismissing(v)
        C{i} = '';
    elseif isa(v, 'string') && ismissing(v)
        C{i} = '';
    end
end
end

function T = spsTheme()
T.bg    = [0.953 0.957 0.969];
T.card  = [1.000 1.000 1.000];
T.soft  = [0.969 0.973 0.980];
T.soft2 = [0.976 0.980 0.988];
T.text  = [0.114 0.129 0.157];
T.mute  = [0.353 0.388 0.443];
T.accent = [0.000 0.404 0.776];
T.ok    = [0.063 0.486 0.063];
T.warn  = [0.788 0.443 0.114];
T.err   = [0.769 0.169 0.110];
end
