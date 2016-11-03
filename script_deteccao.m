close all
clear all
clc

%% Leitura da entrada
v = VideoReader('../sema.mpeg'); % Le o arquivo de video
k = 0;

pontos_rua = [219 104;640 230;640 367;400 367;129 123]; % Pontos da imagem em que se loacliza a estrada. 
pontos_interesse = [172 114;640 350;640 367;400 367;129 123];  % Pontos da imagem em que se loacliza a via de interesse.

mask_intersse = uint8(poly2mask(pontos_interesse(:,1),pontos_interesse(:,2),v.Height,v.Width)); % Cria uma mascara para a via de interesse.
mask_rua = uint8(poly2mask(pontos_rua(:,1),pontos_rua(:,2),v.Height,v.Width));  % Cria uma mascara para a rua inteira.


%% Converte o video para matriz em grayscale
while hasFrame(v)
    k = k + 1;
    video(:,:,k) = imgaussfilt(rgb2gray(readFrame(v)), 0.01); % Converte o frame para grayscale e o submete a um filtro gaussino.
end

%% Criação do plano de fundo inicial

% Para a crição de um plano de fundo inicial são coletados 100 frames.
nFrames = 100;
bg_step = 10;

% Obtem as 100 amostra aplicando a mascara.
for(k = 1:nFrames)
    buffer_init(:,:,k) = mask_rua.*video(:,:, k);
end

% Cria um plano de fundo incial com as amostras obtidas.
background_frame = 0.00;
for k = 1:bg_step:nFrames
    background_frame = background_frame + double(buffer_init(:,:,k));
end
background = bg_step*background_frame/(nFrames);

%% Detecção de carros e atualização do plano de fundo

offset = nFrames ; % Variavel auxiliar para saber apartir de qual frame deve se iniciar.
nFrames = 50;
buffer = uint8(zeros(size(video, 1), size(video, 2), 50));
obj = buffer;
bw = buffer > 0;
border = buffer;
final = buffer;
thr = 20;
se = strel('disk',4);

for(passo = (offset + 1):nFrames:size(video, 3))
    
    for(frame = 1:nFrames)
        buffer(:, :, frame) = mask_rua.*video(:, :, (offset + frame)); % Adiquire-se o proximo frame na fila.
        obj(:, :, frame) = uint8(abs(int16(buffer(:, :, frame)) - int16(background))); % Com base na formula |F(x,y) - B(x,y)|.
        
        bw(:,:,frame) = obj(:,:, frame) > thr;
        bw(:,:,frame) = bwareaopen(bw(:,:,frame), 50); % Remove objetos com menos de 50 px.
        bw(:,:,frame) = imdilate(bw(:,:,frame),se); % Faz-se uma dilatação no frame atual.
        bw(:,:,frame)= imfill(bw(:,:,frame),'holes'); % Prenche os espaços vazios.
        bw(:,:,frame) = imerode(bw(:,:,frame),se); % Faz-se uma erosão no frame atual.
        
        border(:,:,frame) = bwmorph(bw(:,:,frame),'remove'); % Cria-se uma imagem contendo apenas o contorno do objetos identificados.
        border(:,:,frame) = imdilate(border(:,:,frame),se); % Faz-se uma dilatação do contorno.
        
        final(:,:,frame) = buffer(:,:,frame)+uint8(border(:,:,frame))*255; % Soma-se o contorno a imagem.
        detected(:,:,:,((offset - 100) + frame)) = cat(3,buffer(:,:,frame),final(:,:,frame),buffer(:,:,frame)); % Cria-se um video mostrando os 
                ... objetos identificados com uma borda no canal verde.
        
        if((offset + frame) == size(video, 3))
            break;
        end
        
    end
    
    % Cria-se um novo background com base nas novas 50 amostras obtidas.
    background = background_creator(buffer, background);
    offset = offset + nFrames;
end

%% Visualiza os carros detectados
implay(detected)