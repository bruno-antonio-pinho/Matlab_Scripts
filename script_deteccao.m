close all
clear all
clc
%profile -memory on;
profile on;
% Leitura da entrada
url = 'http://172.18.131.248/axis-cgi/mjpg/video.cgi'; % endereço para acesso direto a camera.
cam = ipcam(url); % Cria um objeto ipcam.
img_aux = snapshot(cam);
% Height = size(img_aux,1);f
% Width = size(img_aux,2);
%figure(1); imshow(img_aux,[]);
%imcrop(img_aux)
pos = [244.5 497.5 1015 223];
I = imcrop(img_aux, pos);
%figure(1); imshow(I,[]);
Height = size(I,1);
Width = size(I,2);
buffer = uint8(zeros(Height, Width, 50));
border = (zeros(Height, Width)) > 0;
final = uint8(zeros(Height, Width));
background = zeros(Height, Width);
background_frame = background;
clear pontos_rua url user pass img_aux I;
%%

%v = VideoReader('../hou-cam-007.mpg'); % Le o arquivo de video

pontos_rua = [330 69;311 206;305 238;105 237;300 64]; % Pontos da imagem em que se loacliza a estrada. 
%pontos_interesse = [172 114;640 350;640 367;400 367;129 123];  % Pontos da imagem em que se loacliza a via de interesse.

%mask_intersse = uint8(poly2mask(pontos_interesse(:,1),pontos_interesse(:,2),v.Height,v.Width)); % Cria uma mascara para a via de interesse.
mask_rua = uint8(poly2mask(pontos_rua(:,1),pontos_rua(:,2), Height, Width));  % Cria uma mascara para a rua inteira.

% Converte o video para matriz em grayscale
%while hasFrame(v)
%    k = k + 1;
%    video(:,:,k) = imgaussfilt(rgb2gray(readFrame(v)), 0.01); % Converte o frame para grayscale e o submete a um filtro gaussino.
%end

% Criação do plano de fundo inicial

% Para a crição de um plano de fundo inicial são coletados 100 frames.
nFrames = 100;
bg_step = 10;

% Obtem as 100 amostra aplicando a mascara.
%for(k = 1:nFrames)
%    buffer_init(:,:,k) = mask_rua.*  imgaussfilt(rgb2gray(readFrame(v)), 0.01);
%end

% Cria um plano de fundo incial com as amostras obtidas.
for k = 1:bg_step:nFrames
    for(i = k:(k + bg_step))
        tmp = imcrop(snapshot(cam),pos);
        buffer_init(:,:,i) =  imgaussfilt(rgb2gray(tmp), 0.01);
    end
    background_frame = background_frame + double(buffer_init(:,:,k));
end
background = bg_step*background_frame/(nFrames);

clear buffer_init background_frame bg_step k tmp i pontos_rua;
%figure(1); imshow(background,[]);
%% Detecção de carros e atualização do plano de fundo
nFrames = 50;
thr = 20;
se = strel('disk',4);
frame = 0;

while(true)
    
    file_name = strcat(datestr(now,30), '.avi');
    outputVideo = VideoWriter(fullfile('./Videos', file_name));
    outputVideo.FrameRate = 15;
    open(outputVideo);
    offset = 0;
    
    while(offset < 450)
        keyboard;
        for(frame = 1:nFrames)
            buffer(:, :, frame) = imgaussfilt(rgb2gray(imcrop(snapshot(cam),pos)), 0.01); % Adiquire-se o proximo frame na fila.
            
            border = uint8(abs(int16(buffer(:, :, frame)) - int16(background))) > thr; % Com base na formula |F(x,y) - B(x,y)|.
            border = bwareaopen(border, 50); % Remove objetos com menos de 50 px.
            border = imdilate(border, se); % Faz-se uma dilatação no frame atual.
            border = imfill(border, 'holes'); % Prenche os espaços vazios.
            border = imerode(border, se); % Faz-se uma erosão no frame atual.
            border = bwmorph(border, 'remove'); % Cria-se uma imagem contendo apenas o contorno do objetos identificados.
            border = imdilate(border, se); % Faz-se uma dilatação do contorno.
            
            final = buffer(:,:,frame) + uint8(border)*255; % Soma-se o contorno a imagem.
            detected = cat(3, buffer(:,:,frame), final, buffer(:,:,frame)); % Cria-se um video mostrando os
            ... objetos identificados com uma borda no canal verde.
            detected = imcrop(snapshot(cam),pos);
            writeVideo(outputVideo, detected);
            
        end
        
        % Cria-se um novo background com base nas novas 50 amostras obtidas.
        % background = background_creator(buffer, background);
        %figure(1); imshow(background,[]);
        offset = offset + nFrames;
    end
    offset = 0;
    outputVideo.close();
    clear outputVideo;
    
    

end