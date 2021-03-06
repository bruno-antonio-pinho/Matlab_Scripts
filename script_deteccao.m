%% Limpa o Matlab.
close all
clear all
clc
v_time = 3600;
fps = 15;
%% Inicialização de variaveis e alocação de memória para todas as matrize.

%profile on;
key = 0;
prompt = 'Selecione o modo desejado: \n 0 - Camera ip.\n 1 - Arquivo de video. \n 2 - Webcam. \n';
while(true)
    key = input(prompt);
    %key = 1;
    if(key == 0)
        % Leitura da entrada
        url = 'http://172.18.116.31/axis-cgi/mjpg/video.cgi'; % endereço para acesso direto a camera.
        %user = 'odilson';
        %pass = 'pr0j3t0';
        user = 'admin';
        pass = 'admin';
        cam = ipcam(url, user, pass); % Cria um objeto ipcam.
        img_aux = snapshot(cam);
        break;
    elseif(key == 1)
        %file = input('Digite ocaminho para o arquivo de video:\n', 's')
        file = 'Videos\mini_teste.avi';
        v = VideoReader(file);
        fps = v.FrameRate;
        img_aux = readFrame(v);
        break;
    
    elseif(key == 2)
        cam = webcam(1); % Cria um objeto ipcam.
        img_aux = snapshot(cam);
        break;
    else
        display('Op��o invalida.')
        
    end
end
% timer1 = zeros(1, 6);
% while true
%     timer1 = clock;
%     if ((timer1(4) >= 17) && (timer1(5) >= 20))
%         break;
%     end
% end


%%
tudo = true;
blob_size = 2300;
video_size = fps*v_time; %10s de dura��o a 15fps;
% Corta a area de interesse da imagem.
%imcrop(img_aux)
pos = [3.5 217.5 1277 548];
if ~tudo
    I = imcrop(img_aux, pos);
else
    I = img_aux;
end
%imshow(I)
%roipoly(I)
% Pega o tamanho da imagem da área de interesse e aloca memória do sistema.
% para as matrizes.
Height = size(I,1);
Width = size(I,2);
frame_ini = 100;
buffer_init = uint8(zeros(Height, Width, frame_ini));
buffer = uint8(zeros(Height, Width, 50));
gray = uint8(zeros(Height, Width));
border = (zeros(Height, Width)) > 0;
final = uint8(zeros(Height, Width));
detected = uint8(zeros(Height, Width, 3));
background = zeros(Height, Width);
background_frame = background;

% Cria as maskara para isolar a área da estrada.
pontos_rua =[3.75 208.25;1082.25 545.75;1278.75 545.75;1278.75 301.25;158.25 26.75]; % Pontos da imagem em que se loacliza a estrada.
%pontos_interesse = [172 114;640 350;640 367;400 367;129 123];  % Pontos da imagem em que se loacliza a via de interesse.

%mask_intersse = uint8(poly2mask(pontos_interesse(:,1),pontos_interesse(:,2),v.Height,v.Width)); % Cria uma mascara para a via de interesse.
mask_rua = uint8(poly2mask(pontos_rua(:,1),pontos_rua(:,2), Height, Width));  % Cria uma mascara para a rua inteira.

img_aux = uint8(zeros(Height, Width, 3, 100));
I = uint8(zeros(Height, Width, 3));

clear pontos_rua url user pass;

%% Criação do plano de fundo inicial

% Para a cri��o de um plano de fundo inicial s�o coletados 100 frames.
bg_step = 30;
nFrames = bg_step*3+1;
buffer_init(Height,Width,nFrames) = uint8(0);

tstart = 0;
buff_time = zeros(1,100);
% Obtem as 100 amostra aplicando a mascara.
%for(k = 1:nFrames)
%    buffer_init(:,:,k) = mask_rua.*  imgaussfilt(rgb2gray(readFrame(v)), 0.01);
%end

% % Cria um plano de fundo incial com as amostras obtidas.
% for k = 1:bg_step:nFrames
%     for(f = k:(k + bg_step))
%         if(key == 1)
%             img_aux = readFrame(v);
%         else
%             tstart = tic;
%             img_aux = snapshot(cam);
%         end
%         
%         if ~tudo
%             I = imcrop(img_aux, pos);
%         else
%             I = img_aux;
%         end
%         buffer_init(:,:,f) = rgb2gray(I);%.*mask_rua
%         %buff_time(i) = toc(tstart);
%     end
%     background_frame = background_frame + double(buffer_init(:,:,k));
% end
% background = bg_step*background_frame/(nFrames);

if(key == 1)
    img_aux = readFrame(v);
else
    img_aux = snapshot(cam);
end

background = double(rgb2gray(img_aux));
for pos = 1:frame_ini
    if(key == 1)
        img_aux = readFrame(v);
    else
        img_aux = snapshot(cam);
    end
   buffer_init(:,:, pos) = rgb2gray(img_aux);
end
background = background_creator(buffer_init, background);

clear buffer_init background_frame bg_step k i;
%figure(1); imshow(background,[]);
%% Detecção de carros e atualização do plano de fundo

nFrames = 50;
thr = 20;
se = strel('disk',4);
frame = 0;    
buff_time = zeros(1,v_time*fps);

%interrupt = 0;
%timer0 = timer('TimerFcn', 'stat=false; interrupt = 1','StartDelay';10);
while(true)

    offset = 0; % Inicia o offset
    file_name = strcat(datestr(now,30), '.avi'); % Pega a data e o horario
    ... atual como uma string e concatena com .avi para criar o nome do arquivo.
    outputVideo = VideoWriter(fullfile('./Videos', file_name));
    outputVideo.FrameRate = fps; % Configura o video de sida para o mesmo framerate da camera.
    open(outputVideo);
    
    temporizador = 0;
    tstart = tic;
    fim_video = false;
    while(offset < video_size) % Limita os videos a 450 frames ou 30 segundos.
        
        for(frame = 1:nFrames)
            if(key == 1)
                if(hasFrame(v))
                    img_aux = readFrame(v);
                else
                    fim_video = true;
                    break;
                end
            else
                img_aux = snapshot(cam);
            end
            
            if ~tudo
                I = imcrop(img_aux, pos);
            else
                I = img_aux;
            end
            gray = rgb2gray(I);
            buffer(:, :, frame) = gray;%.*mask_rua; % Adiquire-se o proximo frame na fila.
            
            border = uint8(abs(int16(buffer(:, :, frame)) - int16(background))) > thr; % Com base na formula |F(x,y) - B(x,y)|.
            border = bwareaopen(border, blob_size); % Remove objetos com menos de 50 px.
            border = imdilate(border, se); % Faz-se uma dilatação no frame atual.
            border = imfill(border, 'holes'); % Prenche os espaços vazios.
            border = imerode(border, se); % Faz-se uma erosão no frame atual.
            border = bwmorph(border, 'remove'); % Cria-se uma imagem contendo apenas o contorno do objetos identificados.
            border = imdilate(border, se); % Faz-se uma dilatação do contorno.
            
            final = buffer(:,:,frame) + uint8(border)*255; % Soma-se o contorno a imagem.
            detected = cat(3, gray, final, gray); % Cria-se um video mostrando os
            ... objetos identificados com uma borda no canal verde.
            %background = background_refresh(gray, background);    
        %writeVideo(outputVideo, gray); % Grava a imagem processada no video.
        writeVideo(outputVideo, detected); % Grava a imagem processada no video.
        
        if(key == 0)
            t_final = toc(tstart);
            while t_final < 0.1
                t_final = toc(tstart);
            end
            interrupt = 0;
            temporizador = temporizador + 0.20;
        end
        
        end
        
        % Cria-se um novo background com base nas novas 50 amostras obtidas.
        background = background_creator(buffer, background);
        offset = offset + nFrames;
        clear functions;
        if(fim_video)
            break;
        end
    end
    
    close(outputVideo); % Fecha o arquivo de video, se o mesmo não for
    ... fechado o arquivo é corrompido e sua leitura é impossibilitada.
        %clear outputVideo;
    %fprintf('O arquivo %s foi gravado em disco com sucesso. \n', file_name);
    if(fim_video)
        break;
    end
    
end