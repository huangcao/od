function [P1, P2, f, pp, base] = readCalibData(cab_file)
fid = fopen(cab_file, 'r');
fseek(fid, 3, 'bof');
P1 = fscanf(fid,'%g', 12);
P1 = reshape(P1,[4 3])';
fseek(fid, 4, 'cof');
P2 = fscanf(fid, '%g', 12);
P2 = reshape(P2,[4 3])';
f = P1(1,1);
M1 = P1(1:3,1:3);
pp = M1*M1(3,:)'; % principal point
base = -P2(1,4)/P2(1,1);

fclose(fid);
end