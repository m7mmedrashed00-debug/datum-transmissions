function h = c0v2_sha256(fn)
%C0V2_SHA256  SHA-256 of a file, lowercase hex. P0-2: cache keys and manifests.
md = java.security.MessageDigest.getInstance('SHA-256');
fid = fopen(fn,'r'); assert(fid>0, 'cannot open %s', fn);
b = fread(fid, inf, '*uint8'); fclose(fid);
md.reset(); d = typecast(md.digest(b),'uint8');
h = lower(reshape(dec2hex(d)',1,[]));
end
