function x = xml_par(txt, sz, bold, jc)
q = char(34);
kn = '';  if bold, kn = '<w:keepNext/>'; end          % captions/headings stay with the next block
x = ['<w:p><w:pPr>' kn '<w:spacing w:before=' q '120' q ' w:after=' q '120' q '/><w:jc w:val=' q jc q '/></w:pPr>' ...
     xml_run(txt, sz, bold) '</w:p>'];
end
