function s = txt_clean(s)
% CALLED FROM: write_txt_tables, table_to_txt. Plain-text version of the table tokens.
s = strrep(s, '{alpha}', 'alpha');  s = strrep(s, '{Delta}', 'Delta');
s = strrep(s, '{ge}', '>=');        s = strrep(s, '{le}', '<=');   s = strrep(s, '{sq}', '^2');
s = strrep(s, char(9), ' ');        s = strrep(s, char(10), ' ');
end
