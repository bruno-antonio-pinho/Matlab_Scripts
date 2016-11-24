clear all;
close all;
clc;

url = 'http://admin:admin@172.18.131.248/cgi-bin/snapshot.cgi?1';
user = 'admin';
pass = 'admin';
img_file = 'image_cam.jpg';

img = zeros(1280, 720, 3);
gray = zeros(1280, 720);
while(true)
    
    file_name = strcat(datestr(now,30), '.avi');
    outputVideo = VideoWriter(fullfile('./Videos', file_name));
    outputVideo.FrameRate = 15;
    open(outputVideo);
    for offset = 0:450
        urlwrite(url,img_file,'Authentication','Basic','Username', user ,'Password', pass);
        img = imread(img_file);
        gray = img(:,:, 1); 
        writeVideo(outputVideo, gray);
        delete(img_file);
    end
    close(outputVideo);
    clear outputVideo img;
    
end