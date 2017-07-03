function [ background ] = background_refresh( frame, background_frame)
thr =40;
area_min = 1000;
pixel_sample_density = ones(size(background_frame,1), size(background_frame,2));
background = background_frame;
se = strel('disk',4);

diff_frame = abs(double(background) - double(frame));
diff_BW = imdilate(im2bw(uint8(diff_frame),.21),se); %Level .1 nã se adaptava corretamente a luminosidade.
diff_BW = imfill(diff_BW,'holes');
diff_BW = imerode(diff_BW,se);
diff_BW = bwareaopen(diff_BW, area_min);
diff_BW = bwmorph(diff_BW, 'remove');
centroids = regionprops(diff_BW,'Centroid','Area', 'BoundingBox');

%LP_I = medfilt2(background, [10 10]);
LP_I = background;
borda = 'Sobel';
edge_background = edge(LP_I, borda);
%LP_I = medfilt2(frame, [10 10]);
LP_I = frame;
edge_frame = edge(LP_I, borda);

peso = zeros(4,size(centroids,1));
image = zeros(size(diff_BW,1), size(diff_BW,2));

for counter = 1:size(centroids,1)
    pos(:) = int16(centroids(counter).BoundingBox);
    area = centroids(counter).Area;
    if((pos(2)+pos(4)) < size(diff_BW, 1))
        dy = pos(2):(pos(2)+pos(4));
    else
        dy = pos(2): size(diff_BW, 1);
    end
    if((pos(1)+pos(3)) < size(diff_BW, 2))
        dx = pos(1):(pos(1)+pos(3));
    else
        dx = pos(1): size(diff_BW,2);
    end
    %Object = zeros(size(dy,1), size(dx,1));
    Object = diff_BW(dy, dx);
    Object = xor (bwareaopen(Object, area), bwareaopen(Object, area+1));
    %Object = bwareaopen(Object, area);
    img_edge_background =imdilate(Object,strel('disk',2)) .* edge_background(dy, dx);
    % peso1 -> numero de pixel de borda na regiao do background
    % peso2 -> numero de pixel de borda na regiao do frame atual
    % peso3 -> percentagem de mudança em relação ao BG
    
    peso(1,counter) = sum(img_edge_background(:));
    img_edge_frame =imdilate(Object,strel('disk',2)) .* edge_frame(dy, dx);
    peso(2,counter) = sum(img_edge_frame(:));
    peso(3,counter) = (peso(1,counter)-peso(2,counter))/peso(1,counter)*100;
    %peso(4,counter) = area;
    Object = imfill(Object, 'holes');
    %        if(((peso(1, counter) <= 150) && (peso(2,counter) <= 150)) || ...
    %                (((peso(3,counter) > 0)) &&((peso(3,counter) < thr))) || ...
    %                (((peso(3,counter) < 0)) && ((peso(3,counter) > -thr))))
    if((peso(1, counter) <= 150) && (peso(2,counter) <= 150))
        % objeto com diferença temporal com numero de pixel de borda  < 150 no
        % BG e no frame atual (FA)
        Object = Object * 0;
    else
        if ((peso(3,counter) < thr))
            %objeto do BG nao esta mais no FA  (SAIU)
            nomoving_count = nomoving_count + 1;
            Object = Object * const_peso * bk_downsample;
        else
            % objeto ou tem pouca percentagem de variação ou esta no FA mas nao estava no BG (ENTROU)
            Object = Object *0;
            
        end
    end
    image(dy, dx) = image(dy, dx) + Object;
end
clear diff_frame;

diff_frameBW = const_peso * bk_downsample - image;

pixel_sample_density = pixel_sample_density + diff_frameBW;
nonmoving = double(frame).*diff_frameBW;

background = background + nonmoving;
background = background./pixel_sample_density;

clear nonmoving pixel_sample_density diff_frame diff_BW  se;

end