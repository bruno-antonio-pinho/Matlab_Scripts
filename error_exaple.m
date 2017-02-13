clear all;
close all;
clc;

url = 'http://172.18.131.248/axis-cgi/mjpg/video.cgi';
cam  = ipcam(url);

img = zeros(1280, 720, 3);
gray = zeros(1280, 720);
while(true)
    
    file_name = strcat(datestr(now,30), '.avi');
    outputVideo = VideoWriter(fullfile('./Videos', file_name));
    outputVideo.FrameRate = 15;
    open(outputVideo);
    for offset = 0:450
        img = snapshot(cam);
        gray = img(:,:, 1); 
        writeVideo(outputVideo, gray);

    end
    close(outputVideo);
    clear outputVideo;
    
end