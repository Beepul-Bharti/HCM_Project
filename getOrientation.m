%% Get Orientation function
function [Orientation] = getOrientation(v1,v2)

    % Modify v1
    v1(v1 < 0) = 0;
    v1(v1 > 0.45) = 1;
    v1 = round(v1);
    
    % Check/modify v2
    rv2 = round(v2);
    if isequal(v1', [1,0,0]) && rv2(1) == 0 && abs(rv2(2)) == 1
        Orientation = 'HzLong';
    elseif isequal(v1', [1,1,0])
        Orientation = 'ShortAxis';
    else 
        Orientation = 'Other';
    end
end
%     
%     % Modify v2
%    
%     v2(v2 > 0.707) = 1;
%     if v2(3) < -0.707 
%         v2(3) = round(v2(3));
%     else
%         v2(3) = 0;
%     end
%     v2(1) = 0;
%     v2 = round(v2);
%     n = abs(cross(v1,v2));
%     
%     Orientation = ["VLong","Coronal","HzLong"];
%     if sum(n) == 1
%         Orientation = convertStringsToChars(Orientation(n == 1));
%     else
%         Orientation = 'ShortAxis';
%     end