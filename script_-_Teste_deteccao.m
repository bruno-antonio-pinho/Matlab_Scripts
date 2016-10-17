close all
clear all
clc

v = VideoReader('sema.mpeg');
k = 0;

c = [213 640 640 400 129];
r = [48 129 367 367 129];
mask = uint8(poly2mask(c,r,v.Height,v.Width));

while hasFrame(v)
    k = k + 1;
    vcolor(:,:,:,k) = (readFrame(v)); % Frame em RGB.
    video(:,:,k) = mask.*imgaussfilt(rgb2gray(vcolor(:,:,:,k)), 0.01); % Frame em GrayScale.
end
 
% Para testes iniciais assumiremos o frame 60 como Background.
background = mask.*video(:,:,60);

for k = 1:size(video, 3)
    obj(:, :, k) = abs((video(:, :, k)) - background); % Com base na formula |F(x,y) - B(x,y)|.
end

%%
% imshow(video(:,:,60))
% h = impoly(gca, [213 48;640 129;640 367;400 367;129 123]);
% implay(video)

%%
frame = 380;
im_filt = imgaussfilt(obj(:,:, frame), 0.04); % Utiliza

figure(1)

subplot(2,2,1)
imshow(obj(:,:, frame)) % objetos.

subplot(2,2,2)
imshow(edge(obj(:,:, frame))) % mostra os limiares.

im = im2bw(obj(:,:, frame), 0.04);

im = bwmorph(im,'open'); % Procedimento fechamento.
im = bwmorph(im,'close'); % Procedimento abertura.
im = bwareaopen(im, 50); % Remove objetos com menos de 20 px.

figure(1)
subplot(2,2,3)
imshow(im)

subplot(2,2,4)
imshow(uint8(cat(3, im, im,im)).*vcolor(:, :,:, frame) + uint8(1- cat(3, im, im,im)).* ...
    cat(3, video(:,:,frame), video(:,:,frame), video(:,:,frame))) % Mostra os objetos detectados em cores.
