
function [ background ] = background_finder( video )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

bk_downsample = 30;
vidHeight = size(video, 1);
vidWidth = size(video, 2);
nFrames = size(video, 3);

%% First-iteration background frame
background_frame = 0.00;
for k = 1:bk_downsample:nFrames
    background_frame = background_frame + double(video(:,:,k));
end

background_frame = bk_downsample*background_frame/(nFrames);

%% Second-iteration background frame
%This section re-calculates the background frame while attempting to
%minimize the effect of moving objects in the calculation

background_frame2 = 0.00;
pixel_sample_density = 0.00;
diff_frame = 0.00;
bk_downsample = 50;
se = strel('disk',4);

for k = 1:bk_downsample:nFrames
    diff_frame = abs(double(video(:,:,k)) - background_frame);
    diff_BW = imdilate(im2bw(uint8(diff_frame),.1),se);
    diff_BW = imfill(diff_BW,'holes');
    diff_BW = imerode(diff_BW,se);
    diff_frame = 1 - diff_BW;
    pixel_sample_density = pixel_sample_density + diff_frame;
    nonmoving = double(video(:,:,k)).*diff_frame;
    background_frame2 = background_frame2 + nonmoving;
end

background = background_frame2./pixel_sample_density;


end

