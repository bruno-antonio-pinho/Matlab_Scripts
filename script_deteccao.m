%% Limpa o Matlab.
close all
clear all
clc

%% Inicialização de variaveis e alocação de memória para todas as matrize.

profile on;

% Leitura da entrada
url = 'http://172.18.131.248/axis-cgi/mjpg/video.cgi'; % endereço para acesso direto a camera.
cam = ipcam(url); % Cria um objeto ipcam.
img_aux = snapshot(cam);

% Corta a area de interesse da imagem.
% imcrop(img_aux) 
pos = [244.5 497.5 1015 223];
I = imcrop(img_aux, pos);

% Pega o tamanho da imagem da área de interesse e aloca memória do sistema.
% para as matrizes.
Height = size(I,1);
Width = size(I,2);
buffer_init = uint8(zeros(Height, Width, 3, 100));
buffer = uint8(zeros(Height, Width, 50));
border = (zeros(Height, Width)) > 0;
final = uint8(zeros(Height, Width));
detected = uint8(zeros(Height, Width, 3));
background = zeros(Height, Width);
background_frame = background;

% Cria as maskara para isolar a área da estrada.
pontos_rua = [330 69;311 206;305 238;105 237;300 64]; % Pontos da imagem em que se loacliza a estrada. 
%pontos_interesse = [172 114;640 350;640 367;400 367;129 123];  % Pontos da imagem em que se loacliza a via de interesse.

%mask_intersse = uint8(poly2mask(pontos_interesse(:,1),pontos_interesse(:,2),v.Height,v.Width)); % Cria uma mascara para a via de interesse.
mask_rua = uint8(poly2mask(pontos_rua(:,1),pontos_rua(:,2), Height, Width));  % Cria uma mascara para a rua inteira.

img_aux = uint8(zeros(Height, Width, 3, 100));
I = uint8(zeros(Height, Width, 3));;

clear pontos_rua url user pass;

%% Criação do plano de fundo inicial

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
        img_aux = snapshot(cam);
        I = imcrop(img_aux, pos);
        buffer_init(:,:,i) = rgb2gray(I);
    end
    background_frame = background_frame + double(buffer_init(:,:,k));
end
background = bg_step*background_frame/(nFrames);

clear buffer_init background_frame bg_step k i;
%figure(1); imshow(background,[]);
%% Detecção de carros e atualização do plano de fundo

nFrames = 50;
thr = 20;
se = strel('disk',4);
frame = 0;

while(true)
    
    offset = 0; % Inicia o offset
    
    file_name = strcat(datestr(now,30), '.avi'); % Pega a data e o horario 
    ... atual como uma string e concatena com .avi para criar o nome do arquivo.
    outputVideo = VideoWriter(fullfile('./Videos', file_name));
    outputVideo.FrameRate = 15; % Configura o video de sida para o mesmo framerate da camera.
    open(outputVideo);
    
    while(offset < 450) % Limita os videos a 450 frames ou 30 segundos.
        
        for(frame = 1:nFrames)
            img_aux = snapshot(cam);
            I = imcrop(img_aux, pos);
            buffer(:, :, frame) = rgb2gray(I); % Adiquire-se o proximo frame na fila.
            
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
            writeVideo(outputVideo, detected); % Grava a imagem processada no video.
            
        end
        
        % Cria-se um novo background com base nas novas 50 amostras obtidas.
        background = background_creator(buffer, background);
        offset = offset + nFrames;
    end
    
    close(outputVideo); % Fecha o arquivo de video, se o mesmo não for 
    ... fechado o arquivo é corrompido e sua leitura é impossibilitada.
    %clear outputVideo;
    
    

end