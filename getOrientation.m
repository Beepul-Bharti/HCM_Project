%% Get Orientation function
function [Orientation] = getOrientation(v1,v2)
    % Modify v1
    v1(v1 < 0) = 0;
    v1 = round(v1);
    
    % Modify v2
    v2(v2 > 0.707) = 1;
    if v2(3) < 0 
        v2(3) = round(v2(3));
    else
        v2(3) = 0;
    end
    v2(1) = 0;
    v2 = round(v2);
    n = abs(cross(v1,v2));
    
    Orientation = ["VLong","Coronal","HzLong"];
    if sum(n) == 1
        Orientation = convertStringsToChars(Orientation(n == 1));
    else
        Orientation = 'ShortAxis';
    end
end