function x = xml_table(tb)
q = char(34);
B = tb.body;  nc = size(B, 2);
total = 15138;  fw = tb.firstW;
if nc == 1, w = total; else, w = [fw, repmat(floor((total - fw)/(nc-1)), 1, nc-1)]; end
bd = '';
for nm = {'top','left','bottom','right','insideH','insideV'}
    bd = [bd '<w:' nm{1} ' w:val=' q 'single' q ' w:sz=' q '4' q ' w:space=' q '0' q ' w:color=' q '808080' q '/>']; %#ok<AGROW>
end
x = ['<w:tbl><w:tblPr><w:tblW w:w=' q sprintf('%d', sum(w)) q ' w:type=' q 'dxa' q '/><w:jc w:val=' q 'center' q '/>' ...
     '<w:tblBorders>' bd '</w:tblBorders><w:tblLayout w:type=' q 'fixed' q '/></w:tblPr><w:tblGrid>'];
for c = 1:nc, x = [x '<w:gridCol w:w=' q sprintf('%d', w(c)) q '/>']; end %#ok<AGROW>
x = [x '</w:tblGrid>'];
for k = 1:numel(tb.header)                         % header rows (repeat on every page)
    H = tb.header{k};  col = 1;
    x = [x '<w:tr><w:trPr><w:tblHeader/></w:trPr>']; %#ok<AGROW>
    for j = 1:size(H,1)
        sp = H{j,2};
        x = [x xml_cell(H{j,1}, sum(w(col:col+sp-1)), sp, true, 'D9D9D9', 'center', 17)]; %#ok<AGROW>
        col = col + sp;
    end
    x = [x '</w:tr>']; %#ok<AGROW>
end
for i = 1:size(B,1)                                % body rows
    isb = ismember(i, tb.boldRows);
    fill = '';  if isb, fill = 'F2F2F2'; end
    x = [x '<w:tr>']; %#ok<AGROW>
    for c = 1:nc
        jc = 'center';  if c == 1, jc = 'left'; end
        x = [x xml_cell(B{i,c}, w(c), 1, isb, fill, jc, 17)]; %#ok<AGROW>
    end
    x = [x '</w:tr>']; %#ok<AGROW>
end
x = [x '</w:tbl>'];
end
