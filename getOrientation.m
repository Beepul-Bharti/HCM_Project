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
    if sum(n) == 1;
        Orientation = convertStringsToChars(Orientation(n == 1));
    else
        Orientation = 'ShortAxis';
    end
end
%     % Identity Matrix for Unit Vectors
%     Identity = eye(3);
%     if any(abs(v1) > 0.705)
%         v = Identity(:,(find(abs(v1) > 0.705)));
%         if size(v,2) > 1
%             v1 = v1;
%         else
%             v1 = v;
%         end
%     else 
%         v1 = v1;
%     end
%     if any(abs(v2) > 0.705)
%         v = Identity(:,(find(abs(v2) > 0.705)));
%         if size(v,2) > 1
%             v2 = v2;
%         else
%             v2 = v;
%         end
%     else 
%         v2 = v2;
%     end
%     n = abs(cross(v1,v2));
%     Ovectors = [1,0,0;0,1,0;0,0,1;1,1,0;1,0,1;0,1,1];
%     Orientation = ["Sagittal","Coronal","Transverse","Oblique","Oblique","Oblique"];
%     for i = 1:length(Ovectors)
%         D(i) = norm(n-(Ovectors(i,:))');
%     end
%     Orientation = convertStringsToChars(Orientation(find(D == min(D))));
% end