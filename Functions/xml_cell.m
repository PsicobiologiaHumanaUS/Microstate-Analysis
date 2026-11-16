function x = xml_cell(txt, w, span, bold, fill, jc, sz)
q = char(34);
sp = '';  if span > 1, sp = ['<w:gridSpan w:val=' q sprintf('%d', span) q '/>']; end
sh = '';  if ~isempty(fill), sh = ['<w:shd w:val=' q 'clear' q ' w:color=' q 'auto' q ' w:fill=' q fill q '/>']; end
x = ['<w:tc><w:tcPr><w:tcW w:w=' q sprintf('%d', w) q ' w:type=' q 'dxa' q '/>' sp sh '</w:tcPr>' ...
     '<w:p><w:pPr><w:spacing w:before=' q '20' q ' w:after=' q '20' q '/><w:jc w:val=' q jc q '/></w:pPr>' ...
     xml_run(txt, sz, bold) '</w:p></w:tc>'];
end
