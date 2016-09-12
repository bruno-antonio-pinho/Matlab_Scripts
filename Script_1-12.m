close all
clear all
clc

I = imread('rice.png');
imshow(I)

background = imopen(I,strel('disk',15)); % Cria discos de tamanho 15 
                                         % apartir da matriz I e armazena
                                         % na matriz background.
                                         
figure
surf(double(background(1:8:end,1:8:end))),zlim([0 255]);
set(gca,'ydir','reverse');

I2 = I - background;
imshow(I2)

I3 = imadjust(I2); % Aumenta o contraste de I2.
imshow(I3);

level = graythresh(I3); % Caucula automaticamente o limiar para converter de grayscale para binario.
bw = im2bw(I3,level); % Converte de gryscale para binario.
bw = bwareaopen(bw, 50); % Remove o ruido de fundo.
imshow(bw)

cc = bwconncomp(bw, 4) % encontra o numero de objetos na imagem usando adjacencia-4.
cc.NumObjects

% Visualiza o grão com a label 50.
grain = false(size(bw));
grain(cc.PixelIdxList{50}) = true;
imshow(grain);

labeled = labelmatrix(cc);
RGB_label = label2rgb(labeled, @spring, 'c', 'shuffle');
imshow(RGB_label)


graindata = regionprops(cc, 'basic') % Calcula a área de todos o grães
graindata(50).Area % Mostra a área do grão com label 50.
grain_areas = [graindata.Area];

% Acha o gão com a menor área.
[min_area, idx] = min(grain_areas)
grain = false(size(bw));
grain(cc.PixelIdxList{idx}) = true;
imshow(grain);

% Cria um histograma com a area dos grães.
nbins = 20;
figure, hist(grain_areas, nbins)
title('Histogram of Rice Grain Area');
