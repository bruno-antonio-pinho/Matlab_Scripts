clear all;
close all;
clc;

image = uint8(magic(1920));

while(true)
    
    file_name = strcat(datestr(now,30), '.avi');
    outputVideo = VideoWriter(fullfile('./Videos', file_name));
    outputVideo.FrameRate = 15;
    open(outputVideo);
    for offset = 0:450
        writeVideo(outputVideo, image);
    end
    outputVideo.close();
    clear outputVideo;
    
end