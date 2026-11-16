function x = xml_run(txt, sz, bold)
q = char(34);
b = '';  if bold, b = '<w:b/>'; end
x = ['<w:r><w:rPr><w:rFonts w:ascii=' q 'Calibri' q ' w:hAnsi=' q 'Calibri' q '/>' b ...
     '<w:sz w:val=' q sprintf('%d', sz) q '/></w:rPr><w:t xml:space=' q 'preserve' q '>' xesc(txt) '</w:t></w:r>'];
end
