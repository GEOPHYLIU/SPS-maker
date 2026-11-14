function recvLib = groupRecvByLine(recvPts)
    recvLib = containers.Map();
    lines = unique({recvPts.line});
    for i = 1:numel(lines)
        ln = lines{i};
        mask = strcmp({recvPts.line}, ln);
        recvLib(ln) = sort([recvPts(mask).point]);
    end
end