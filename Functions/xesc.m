function s = xesc(s)
% Escapes XML characters and converts the tokens {alpha}, {Delta}, {ge}, ... to
% numeric character references (keeps this script pure ASCII).
s = strrep(s, '&', '&amp;');  s = strrep(s, '<', '&lt;');  s = strrep(s, '>', '&gt;');
s = strrep(s, '{alpha}', '&#945;');  s = strrep(s, '{Delta}', '&#916;');
s = strrep(s, '{ge}', '&#8805;');    s = strrep(s, '{le}', '&#8804;');
s = strrep(s, '{sq}', '&#178;');
end
