function write_tables(baseFile, blocks, writeDocx)
% CALLED FROM: the end of the table-building section.
% 1) ALWAYS writes tab-separated text files (open them in Word or Excel: Insert > Table >
%    Convert Text to Table, or paste into Excel): one combined file and one file per table.
% 2) If writeDocx is true, also tries to build a Word file (.docx); if that fails, an
%    HTML-based .doc is written instead. The .txt tables are never lost.
try
    write_txt_tables(baseFile, blocks);
catch ME
    warning('Could not write the .txt tables: %s', ME.message);
end
if writeDocx
    try
        write_docx([baseFile '.docx'], blocks);
        fprintf('Word file written: %s.docx\n', baseFile);
    catch ME
        warning('Could not build the .docx (%s). Writing an HTML-based .doc instead.', ME.message);
        try
            write_html_doc([baseFile '.doc'], blocks);
            fprintf('Word-readable file written: %s.doc\n', baseFile);
        catch ME2
            warning('Could not write the .doc either: %s', ME2.message);
        end
    end
end
end
