function headerLines = readHeaderLines(templateFile)
    if nargin < 1 || isempty(templateFile) || ~isfile(templateFile)
        headerLines = { ...
            'H00 SPS format version num.     SPS 2.1;', ...
            'H01 Description of survey area  ,;', ...
            'H02 Date of survey              N/A,N/A;', ...
            'H26 Date file written           N/A;' ...
        };
        return;
    end
    fid = fopen(templateFile, 'r');
    headerLines = {};
    while ~feof(fid)
        line = fgetl(fid);
        if isempty(line) || line(1) ~= 'H'
            break;
        end
        headerLines{end+1} = line; %#ok<AGROW>
    end
    fclose(fid);
end