close all
clear all
clc

%%
v = VideoReader('../sema.mpeg');
k = 0;

pontos_rua = [219 104;640 230;640 367;400 367;129 123];
pontos_interesse = [172 114;640 350;640 367;400 367;129 123];

mask_intersse = uint8(poly2mask(pontos_interesse(:,1),pontos_interesse(:,2),v.Height,v.Width));
mask_rua = uint8(poly2mask(pontos_rua(:,1),pontos_rua(:,2),v.Height,v.Width));


%% Converte o video para matrizes 
while hasFrame(v)
    k = k + 1;
    vcolor(:,:,:,k) = (readFrame(v)); % Frame em RGB.
    video(:,:,k) = mask_rua.*imgaussfilt(rgb2gray(vcolor(:,:,:,k)), 0.01); % Frame em GrayScale.
end

%%

% Para testes iniciais assumiremos o frame 60 como Background.
background = mask_rua.*uint8(background_finder(video));

for k = 1:size(video, 3)
    obj(:, :, k) = uint8(abs(int16(video(:, :, k)) - int16(background))); % Com base na formula |F(x,y) - B(x,y)|.
end

%% Area de testes
imshow(video(:,:,60))
%h = impoly(gca, [172 114;640 350;640 367;400 367;129 123]);
%h1 = impoly(gca, [219 104;640 230;640 367;400 367;129 123]);
% implay(video)


%%

%bw = zeros(size(video,1), size(video,2), size(video,3));
%border = zeros(size(video,1), size(video,2), size(video,3));
%final = zeros(size(video,1), size(video,2), size(video,3));
detected = vcolor;

for(frame = 1:size(video,3))
    
    thr = 20;
    bw(:,:,frame) = obj(:,:, frame) > thr;
    bw(:,:,frame) = bwareaopen(bw(:,:,frame), 50); % Remove objetos com menos de 50 px.
    se = strel('disk',4);
    bw(:,:,frame) = imdilate(bw(:,:,frame),se);
    bw(:,:,frame)= imfill(bw(:,:,frame),'holes');
    bw(:,:,frame) = imerode(bw(:,:,frame),se);
    
    border(:,:,frame) = bwmorph(bw(:,:,frame),'remove');
    border(:,:,frame) = imdilate(border(:,:,frame),se);
    
    final(:,:,frame) = video(:,:,frame)+uint8(border(:,:,frame))*255;
    detected(:,:,:,frame) = cat(3,video(:,:,frame),final(:,:,frame),video(:,:,frame));
end

%% Plot dos resultados
figure(1)
subplot(1, 4, 1)
imshow(video(:,:,380));
impoly(gca,pontos_rua);
subplot(1, 4, 2)
imshow(obj(:,:,380));
subplot(1, 4, 3)
imshow(bw(:,:,380));
subplot(1, 4, 4)
imshow(detected(:,:,:,380));

%%
implay(video)
implay(obj)
implay(detected)

