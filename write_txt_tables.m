function write_txt_tables(baseFile, blocks)
% CALLED FROM: write_tables. Writes <base>.txt (everything) and <base>_Table1.txt, _Table2.txt ...
% Tables are tab-separated with ONE header line (the header levels are joined with " - ").
[pth, nm] = fileparts(baseFile);
nl = char(10);  allTxt = '';  tfiles = {};  t = 0;
for i = 1:numel(blocks)
    b = blocks{i};
    switch b.type
        case 'heading', allTxt = [allTxt txt_clean(b.text) nl nl];                  %#ok<AGROW>
        case 'caption', cap = txt_clean(b.text);  allTxt = [allTxt cap nl];         %#ok<AGROW>
        case 'para'
            allTxt = [allTxt txt_clean(b.text) nl nl];                              %#ok<AGROW>
            if t > 0, tfiles{t} = [tfiles{t} nl txt_clean(b.text) nl]; end          %#ok<AGROW>
        case 'table'
            t = t + 1;  tt = table_to_txt(b);
            allTxt = [allTxt tt nl];                                                %#ok<AGROW>
            tfiles{t} = [cap nl tt];                                                %#ok<AGROW>
    end
end
put_file([baseFile '.txt'], allTxt);
for k = 1:numel(tfiles)
    put_file(fullfile(pth, sprintf('%s_Table%d.txt', nm, k)), tfiles{k});
end
fprintf('Text tables written: %s.txt and %d files %s_Table*.txt\n', baseFile, numel(tfiles), fullfile(pth, nm));
end
