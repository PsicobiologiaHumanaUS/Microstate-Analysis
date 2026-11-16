function zip_java(zipFile, rootDir, rels)
% CALLED FROM: write_docx. Builds the zip with Java (always present in desktop MATLAB), which
% handles file names such as [Content_Types].xml and .rels reliably.
fos = java.io.FileOutputStream(zipFile);
zos = java.util.zip.ZipOutputStream(fos);
for i = 1:numel(rels)
    fid = fopen(fullfile(rootDir, rels{i}), 'r');
    data = fread(fid, inf, '*uint8');  fclose(fid);
    zos.putNextEntry(java.util.zip.ZipEntry(strrep(rels{i}, '\', '/')));
    zos.write(typecast(data, 'int8'), 0, numel(data));
    zos.closeEntry();
end
zos.close();  fos.close();
end
