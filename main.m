cc
%% camera parameter
fileindex = '000104';
[P1, P2, f, pp, base] = readCalibData(['E:\picture_database\data_stereo_flow\training\calib\',fileindex,'.txt']);
theta = 0;
img_left = ReadImage(['E:\picture_database\data_stereo_flow\training\image_0\',fileindex,'_11.png']);
img_right = ReadImage(['E:\picture_database\data_stereo_flow\training\image_1\',fileindex,'_11.png']);

img_left = im2uint8(img_left);
img_right = im2uint8(img_right);
img = img_left;
% imshowpair(img_left, img_right, 'ColorChannels', 'red-cyan');
%% stereo disparity extraction

disp_range = 96;
d_origin = computeDisparity(img_left, img_right, disp_range, 1);
d_origin(d_origin<0) = 0;
% figure,imshow(d_origin,[])
%% show disparity
tic
thr = 5;
d = d_origin;
d1 = RowFilter(double(d));
d = d_origin - d1;
d(d <= thr) = 0;
[row, col] = find(d > thr);
A = find(d > thr);

W_img = zeros(4, length(row));
W_img(1,:) = col;
W_img(2,:) = row;
W_img(3,:) = d_origin(A);
W_img(4,:) = ones(1, length(row));
X_world = compute3DPoints(W_img, f, pp, base, theta);
X = X_world(1,:);
Y = X_world(2,:);
Z = X_world(3,:);

%%
H_img = zeros(size(d));
W_img = zeros(size(d));
L_img = zeros(size(d));
W_img(A) = X;
L_img(A) = Y;
H_img(A) = Z - min(Z);
mark = H_img > 4;
H_img(H_img > 4) = 0;
N = H_img;
P = false(size(d));
P(mark) = true;
%%
figure
ex = 50;
for i = size(d,1)-ex-1: -5: ex+1
    for j = ex+1: 5: size(d,2)-ex-1
        if N(i,j) == 0
            continue;
        end
        x0 = [W_img(i,j), L_img(i,j), H_img(i,j)];
        for m = -1:-9:-ex
            for n = -abs(m):round(log(abs(m))):abs(m)
                if d_origin(i+m,j+n) == 0
                    continue;
                end
                if abs(d_origin(i+m,j+n) - d_origin(i,j)) <= 1
                    x2 = [W_img(i+m,j+n), L_img(i+m,j+n), H_img(i+m,j+n)];
                    if x2(3) - x0(3) > 0.3 && x2(3) - x0(3) < 1
                        angle = asind(abs(x2(3) - x0(3))/norm(x2-x0));
                        
                        if angle > 40
                            img_left(i+m,j+n) = 0;
                            N(i+m,j+n) = 0;
                            P(i+m,j+n) = true;
                            k2 = -1;
                            for k1 = k2:-k2
                                if d_origin(i+m+k1,j+n+k2) == 0
                                    continue;
                                end
                                while(abs(d_origin(i+m+k1,j+n+k2) - d_origin(i+m,j+n)) < 1)
                                    if i+m+k1 > 0 && i+m+k1 <= size(d,1)...
                                            && j+n+k2 > 0 && j+n+k2 < size(d,2)...
                                            && H_img(i+m+k1,j+n+k2) > H_img(i+m,j+n)
                                        img_left(i+m+k1,j+n+k2) = 0;
                                        N(i++m+k1,j+n+k2) = 0;
                                        P(i++m+k1,j+n+k2) = true;
                                        for k3 = -7: 7
                                            for k4 = -abs(k3): abs(k3)
                                                if i+m+k1+k3 > 0 && i+m+k1+k3 <= size(d,1)...
                                                        && j+n+k2+k4 > 0 && j+n+k2+k4 < size(d,2)...
                                                        && (abs(d_origin(i+m+k1+k3,j+n+k2+k4) - d_origin(i+m,j+n)) < 1)
                                                    img_left(i+m+k1+k3,j+n+k2+k4) = 0;
                                                    N(i+m+k1+k3,j+n+k2+k4) = 0;
                                                    P(i+m+k1+k3,j+n+k2+k4) = true;
                                                end
                                            end
                                        end
                                    end
                                    k2 = k2-1;
                                end
                            end
                        end
                    end
                end
            end
        end
    end
%     imshow(img_left)
%     drawnow
end
toc
% P = P | logical(d1);
R = img;
G = img;
B = img;
R(P) = 255;
R(logical(d1)) = 0;
% G(P) = 0;
% G(logical(d1)) = 0;
B(logical(d1)) = 255;
img = cat(3,R,G,B);
imshow(img)