function [BlockTypes, blocklist] = sortblocks(BlockSpec)

numconds = length(BlockSpec);
foundblocks = cat(2, BlockSpec{:});
blocklist = unique(foundblocks);
if ~any(blocklist),
    blocklist = [1];
end
numblocks = length(blocklist);

for cnum = 1:numconds, %entering a cond-in-block of zero indicates the condition appears in all blocks.
    if any(~BlockSpec{cnum}),
        BlockSpec{cnum} = blocklist(blocklist > 0);
    end
end

BlockTypes = cell(numblocks, 1);
for bnum = 1:numblocks,
    clist = [];
    thisblock = blocklist(bnum);
    for cnum = 1:numconds,
        clist(cnum) = any(BlockSpec{cnum} == thisblock);
    end
    BlockTypes{thisblock} = find(clist);
end
