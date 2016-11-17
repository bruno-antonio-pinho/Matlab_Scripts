close all
clear all
clc

%% Leitura da entrada
url = 'http://172.18.131.248/axis-cgi/mjpg/video.cgi'; % endereço para acesso direto a camera.
user = 'admin'; % Login.
pass = 'admin'; % Senha
cam = ipcam(url, user, pass); % Cria um objeto ipcam.
img_aux = snapshot(cam);
Height = size(img_aux,1);
Width = size(img_aux,2);

% outputVideo = VideoWriter(fullfile('./', 'detected_ip.avi'));
% outputVideo.FrameRate = 15;
% open(outputVideo);

%v = VideoReader('../hou-cam-007.mpg'); % Le o arquivo de video

pontos_rua = [330 69;311 206;305 238;105 237;300 64]; % Pontos da imagem em que se loacliza a estrada. 
%pontos_interesse = [172 114;640 350;640 367;400 367;129 123];  % Pontos da imagem em que se loacliza a via de interesse.

%mask_intersse = uint8(poly2mask(pontos_interesse(:,1),pontos_interesse(:,2),v.Height,v.Width)); % Cria uma mascara para a via de interesse.
mask_rua = uint8(poly2mask(pontos_rua(:,1),pontos_rua(:,2), Height, Width));  % Cria uma mascara para a rua inteira.

clear pontos_rua url user pass img_aux;
%% Converte o video para matriz em grayscale
%while hasFrame(v)
%    k = k + 1;
%    video(:,:,k) = imgaussfilt(rgb2gray(readFrame(v)), 0.01); % Converte o frame para grayscale e o submete a um filtro gaussino.
%end

%% Criação do plano de fundo inicial

% Para a crição de um plano de fundo inicial são coletados 100 frames.
nFrames = 100;
bg_step = 10;

% Obtem as 100 amostra aplicando a mascara.
%for(k = 1:nFrames)
%    buffer_init(:,:,k) = mask_rua.*  imgaussfilt(rgb2gray(readFrame(v)), 0.01);
%end

% Cria um plano de fundo incial com as amostras obtidas.
background_frame = 0.00;
for k = 1:bg_step:nFrames
    for(i = k:(k + bg_step))
        buffer_init(:,:,i) =  imgaussfilt(rgb2gray(snapshot(cam)), 0.01);
    end
    background_frame = background_frame + double(buffer_init(:,:,k));
end
background = bg_step*background_frame/(nFrames);

clear buffer_init background_frame bg_step k;
%% Detecção de carros e atualização do plano de fundo

offset = 0; % Variavel auxiliar para saber apartir de qual frame deve se iniciar.
nFrames = 50;
buffer = uint8(zeros(Height, Width, 50));
border = (zeros(Height, Width)) > 0;
final = uint8(zeros(Height, Width));
thr = 20;
se = strel('disk',4);
frame = 0;

while(offset < 900)

    for(frame = 1:nFrames)
        buffer(:, :, frame) = imgaussfilt(rgb2gray(snapshot(cam)), 0.01); % Adiquire-se o proximo frame na fila.
        
        border = uint8(abs(int16(buffer(:, :, frame)) - int16(background))) > thr; % Com base na formula |F(x,y) - B(x,y)|.
        border = bwareaopen(border, 50); % Remove objetos com menos de 50 px.
        border = imdilate(border, se); % Faz-se uma dilatação no frame atual.
        border = imfill(border, 'holes'); % Prenche os espaços vazios.
        border = imerode(border, se); % Faz-se uma erosão no frame atual.
        border = bwmorph(border, 'remove'); % Cria-se uma imagem contendo apenas o contorno do objetos identificados.
        border = imdilate(border, se); % Faz-se uma dilatação do contorno.
        
        final = buffer(:,:,frame) + uint8(border)*255; % Soma-se o contorno a imagem.
        detected(:, :, :, (offset + frame)) = cat(3, buffer(:,:,frame), final, buffer(:,:,frame)); % Cria-se um video mostrando os 
                ... objetos identificados com uma borda no canal verde.
%        writeVideo(outputVideo, detected);
   
%         if(~hasFrame(v))
%             break;
%         end
        
    end
    
    % Cria-se um novo background com base nas novas 50 amostras obtidas.
    background = background_creator(buffer, background);
    offset = offset + nFrames;
end

% close(outputVideo);

%% Visualiza os carros detectados
implay(detected, 30)