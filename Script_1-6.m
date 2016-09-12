close all
clear all
clc

I = imread('pout.tif'); % Lê o conteudo da imagen e armazena os valores na matriz I.
imshow(I) % Mostra a imagem armazenada em I.
whos I % Mostra as informações de I.

figure % Cria uma nova figura.
imhist(I) % Mostra a distribuição dos valores de intensidade dos pixeis armazenados em I.

I2 = histeq(I); % Distribui os valore de intensidade em todo .
figure % Cria uma nova figura.
imshow(I2) % Mostra a distribuição dos valores de intensidade dos pixeis armazenados em I2.

imwrite (I2, 'pout2.png'); % Grava a Imagen armazenad em I2 em disco.
imfinfo('pout2.png')