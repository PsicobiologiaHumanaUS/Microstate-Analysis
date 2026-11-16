function tt = table_to_txt(b)
% CALLED FROM: write_txt_tables. Converts one table block to tab-separated text.
tab = char(9);  nl = char(10);
nc = size(b.body, 2);  hdr = repmat({''}, 1, nc);
for k = 1:numel(b.header)                         % merge the header levels into one line
    H = b.header{k};  col = 1;
    for j = 1:size(H,1)
        sp = H{j,2};  th = txt_clean(H{j,1});
        for c = col:col+sp-1
            if ~isempty(th)
                if isempty(hdr{c}), hdr{c} = th; else, hdr{c} = [hdr{c} ' - ' th]; end
            end
        end
        col = col + sp;
    end
end
tt = [strjoin(hdr, tab) nl];
for r = 1:size(b.body, 1)
    row = cell(1, nc);
    for c = 1:nc, row{c} = txt_clean(b.body{r,c}); end
    tt = [tt strjoin(row, tab) nl];               %#ok<AGROW>
end
end
