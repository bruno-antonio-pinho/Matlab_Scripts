function [outputVideo] = recorder( imSeq, frameRate, path )

outputVideo = VideoWriter(fullfile('./', path));
outputVideo.FrameRate = frameRate;
open(outputVideo);

len = size(imSeq);


switch(length(len))
    case 3
        for i = 1:len(3)
            writeVideo(outputVideo, imSeq(:,:,i))
        end
        
    case 4
        for i = 1:len(4)
            writeVideo(outputVideo, imSeq(:,:,:,i))
        end
end

close(outputVideo);

end

