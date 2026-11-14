function pts = readSPSPoints(filename, recType)
    fid = fopen(filename, 'r');
    if fid < 0
        error('无法打开 %s', filename);
    end
    pts = struct('line',{},'point',{},'x',{},'y',{},'elev',{});
    while ~feof(fid)
        line = fgetl(fid);
        if isempty(line) || line(1) ~= recType
            continue;
        end
        if numel(line) < 71
            line = [line, repmat(' ', 1, 71-numel(line))];
        end
        p.line  = strtrim(line(2:11));
        p.point = str2double(strtrim(line(12:21)));
        p.x     = str2double(strtrim(line(47:55)));
        p.y     = str2double(strtrim(line(56:65)));
        p.elev  = str2double(strtrim(line(66:71)));
        pts(end+1) = p; %#ok<AGROW>
    end
    fclose(fid);
end