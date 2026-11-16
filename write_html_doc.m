function write_html_doc(f, blocks)
% Fallback writer: HTML that Word opens as a document.
h = '<html><head><meta charset="utf-8"><style>table{border-collapse:collapse;font-size:9pt}td,th{border:1px solid #808080;padding:2px 4px;text-align:center}</style></head><body>';
for i = 1:numel(blocks)
    b = blocks{i};
    switch b.type
        case 'heading', h = [h '<h2>' xesc(b.text) '</h2>']; %#ok<AGROW>
        case 'caption', h = [h '<p><b>' xesc(b.text) '</b></p>']; %#ok<AGROW>
        case 'para',    h = [h '<p style="font-size:9pt">' xesc(b.text) '</p>']; %#ok<AGROW>
        case 'table'
            h = [h '<table>']; %#ok<AGROW>
            for k = 1:numel(b.header)
                H = b.header{k};  h = [h '<tr>']; %#ok<AGROW>
                for j = 1:size(H,1)
                    h = [h sprintf('<th colspan="%d" bgcolor="#D9D9D9">%s</th>', H{j,2}, xesc(H{j,1}))]; %#ok<AGROW>
                end
                h = [h '</tr>']; %#ok<AGROW>
            end
            for r = 1:size(b.body,1)
                h = [h '<tr>']; %#ok<AGROW>
                for c = 1:size(b.body,2)
                    t = xesc(b.body{r,c});
                    if ismember(r, b.boldRows), t = ['<b>' t '</b>']; end
                    h = [h '<td>' t '</td>']; %#ok<AGROW>
                end
                h = [h '</tr>']; %#ok<AGROW>
            end
            h = [h '</table>']; %#ok<AGROW>
    end
end
put_file(f, [h '</body></html>']);
end
