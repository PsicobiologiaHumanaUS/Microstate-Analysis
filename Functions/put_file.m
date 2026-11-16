function put_file(f, txt)
fid = fopen(f, 'w');  fprintf(fid, '%s', txt);  fclose(fid);
end
