function [ background ] = background_creator( video, background_frame )

nFrames = size(video, 3);
pixel_sample_density = 0.00;
background = 0.00;
bk_downsample = 5;
se = strel('disk',4);

for k = 1:bk_downsample:nFrames
    diff_frame = abs(double(video(:,:,k)) - background_frame);
    diff_BW = imdilate(im2bw(uint8(diff_frame),.1),se);
    diff_BW = imfill(diff_BW,'holes');
    diff_BW = imerode(diff_BW,se);
    diff_frame = 1 - diff_BW;
    pixel_sample_density = pixel_sample_density + diff_frame;
    nonmoving = double(video(:,:,k)).*diff_frame;
    background = background + nonmoving;
end

background = background./pixel_sample_density;


end