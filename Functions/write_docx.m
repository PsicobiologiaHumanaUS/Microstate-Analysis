function write_docx(outFile, blocks)
% CALLED FROM: write_tables. Builds the minimal set of files of a .docx package in a
% temporary folder, zips it, and renames the zip to .docx.
tmp = tempname;  mkdir(tmp);  mkdir(fullfile(tmp,'_rels'));  mkdir(fullfile(tmp,'word'));
cleanup = onCleanup(@() rmdir(tmp, 's'));   %#ok<NASGU>
q = char(34);
hdr = ['<?xml version=' q '1.0' q ' encoding=' q 'UTF-8' q ' standalone=' q 'yes' q '?>'];
ct = [hdr '<Types xmlns=' q 'http://schemas.openxmlformats.org/package/2006/content-types' q '>' ...
      '<Default Extension=' q 'rels' q ' ContentType=' q 'application/vnd.openxmlformats-package.relationships+xml' q '/>' ...
      '<Default Extension=' q 'xml' q ' ContentType=' q 'application/xml' q '/>' ...
      '<Override PartName=' q '/word/document.xml' q ' ContentType=' q ...
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml' q '/></Types>'];
rels = [hdr '<Relationships xmlns=' q 'http://schemas.openxmlformats.org/package/2006/relationships' q '>' ...
        '<Relationship Id=' q 'rId1' q ' Type=' q ...
        'http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument' q ...
        ' Target=' q 'word/document.xml' q '/></Relationships>'];
body = '';
for i = 1:numel(blocks)
    b = blocks{i};
    switch b.type
        case 'heading', body = [body xml_par(b.text, 30, true, 'left')];     %#ok<AGROW>
        case 'caption', body = [body xml_par(b.text, 22, true, 'left')];     %#ok<AGROW>
        case 'para',    body = [body xml_par(b.text, 19, false, 'left')];    %#ok<AGROW>
        case 'table',   body = [body xml_table(b)];                          %#ok<AGROW>
    end
end
sect = ['<w:sectPr><w:pgSz w:w=' q '16838' q ' w:h=' q '11906' q ' w:orient=' q 'landscape' q '/>' ...
        '<w:pgMar w:top=' q '850' q ' w:right=' q '850' q ' w:bottom=' q '850' q ' w:left=' q '850' q ...
        ' w:header=' q '708' q ' w:footer=' q '708' q ' w:gutter=' q '0' q '/></w:sectPr>'];
doc = [hdr '<w:document xmlns:w=' q 'http://schemas.openxmlformats.org/wordprocessingml/2006/main' q '><w:body>' ...
       body sect '</w:body></w:document>'];
put_file(fullfile(tmp,'[Content_Types].xml'), ct);
put_file(fullfile(tmp,'_rels','.rels'), rels);
put_file(fullfile(tmp,'word','document.xml'), doc);
zipFile = [tempname '.zip'];
try
    zip_java(zipFile, tmp, {'[Content_Types].xml', '_rels/.rels', 'word/document.xml'});
catch
    zip(zipFile, {'[Content_Types].xml', '_rels', 'word'}, tmp);   % fallback if Java is not available
end
if exist(outFile, 'file'), delete(outFile); end
movefile(zipFile, outFile);
end
