%% 4 Chamber Heart ROI Detection/Localization

% Inputs
% PatientNumber: Patient Number/name of the folder: ex: 100
% NOTE: This folder should ONLY contain 4chamber cine 2D + t images

% ImageNumber: Number that identifies which image you want to use: ex if
% patient 100 has 4 images, you can choose any number 1 through 4

% Outputs: 
% ROIImage: Cell Array where each entry is a slice cropped around ROI (heart).
% ROIImage is in chronological order
% Corners: Defines the boundaries of the filter for the ROI. 
% Corners = [Lside,Rside,Top,Bottom]
% SortedI: Array of the instances sorted chronologically.

function [ROIImage,Corners,SortedI] = LongAxisROI(PatientNumber,ImageNumber)

    % Top Level Folder Directory: PatientNumber
    PatientNumber = string(PatientNumber);
    Directory = dir(fullfile('/home/beepul/HCM Project/4ChamberCine/',PatientNumber));
    Directory(ismember({Directory.name},{'.','..','DICOMDIR'})) = [];

    % ImageNumber = Dicom Image
    PatientFolder = dir(fullfile(Directory(1).folder,Directory(ImageNumber).name));
    PatientFolder(ismember({PatientFolder.name},{'.','..','DICOMDIR'})) = [];

    % Load each frame and store in multidimensional array
    for i = 1:length(PatientFolder)
        info = dicominfo(fullfile(PatientFolder(1).folder,PatientFolder(i).name));
        Instance(i) = info.InstanceNumber;
        Image(:,:,i) = dicomread(info);
    end

    % Rearrange to be from beginning to end w.r.t time
    [SortedI,ind] = sort(Instance);
    SortedImage = Image(:,:,ind);

    % Converting Image to double
    SortedImage = double(Ysort) + 1;


    % Compute Variance Image (sum of 1 through k harmonic images)
    VarImage = var(SortedImage,0,3);

    % Surface Plot of Variance Image
    numRows = size(VarImage,1);
    numCols = size(VarImage,2);
    [X,Y] = meshgrid(1:numCols,1:numRows); 
    
%     figure(2); ax = axes;
%     surf(X,Y,VarImage)
%     imshow(VarImage,[])
%     title(ax,'Variance Image ')
%     
%     Generate an image that detects edges from the Variance Image
     Edges = edge(VarImage,'Canny');  
     
%     figure(3); ax = axes;
%     imshow(Edges)
%     title(ax,'Edges')
    
    % Texture analysis on the Variance Image
    wavelengthMin = 4/sqrt(2);
    wavelengthMax = hypot(numRows,numCols);
    n = floor(log2(wavelengthMax/wavelengthMin));
    wavelength = 2.^(0:(n-3)) * wavelengthMin;
    orientation = 0:45:135;
    g = gabor(wavelength,orientation);
    gabormag = imgaborfilt(single(VarImage),g);
    
    for i = 1:length(g)
        sigma = 0.5*g(i).Wavelength;
        gabormag(:,:,i) = imgaussfilt(gabormag(:,:,i),3*sigma); 
    end
    
    % montage(gabormag,'Size',[4 4],'DisplayRange',[])
    
    % Texture analysis on the Edge Image
    wavelength = 2.^(0:1) * wavelengthMin;
    g = gabor(wavelength,orientation);
    gabormag2 = imgaborfilt(single(Edges),g);
    
    for i = 1:length(g)
        sigma = 0.5*g(i).Wavelength;
        gabormag2(:,:,i) = imgaussfilt(gabormag2(:,:,i),3*sigma); 
    end
    
    % montage(gabormag2,'Size',[4 2])
    
    % Make a feature set that includes texture analysis of both Variance
    % and Edge images for k-means segmentation
    featureSet = cat(3,gabormag,gabormag2,X,Y);
    SegImage = imsegkmeans(single(featureSet),2,'NormalizeInput',true);
    
    % Check Bottom left corner pixel value of SegImage
    Val = SegImage(1,size(SortedImage,2));
    if Val == 2
        Mask = SegImage == 1;
    else
        Mask = SegImage == 2;
    end
    
    % In case there are more than objects in the mask, select/isolate the
    % one with the largest perimeter
    Mask = bwpropfilt(Mask,'perimeter',1);
    
%     % Show the mask that comes from k means segmentation
%     figure(4); ax = axes;
%     imshow(Mask)  
%     title(ax,'Mask from K-means Segmentation')

    % Hough Transform for Circle Detection
    [centers, radii] = imfindcircles(Mask,[40,90],'Sensitivity',0.95);
    
    % Pick the 'best' radius
    % The best radius is the radius associated with the circle whose center
    % is the closest to the centroid of the object in the mask
    
    stats = regionprops(Mask,'Centroid');
    centroid = stats(1).Centroid;
    distance = centers - centroid;
    RelError = vecnorm(distance')/norm(centroid);
    strongcenter = centers(RelError == min(RelError),:);
    strongradius = radii(RelError == min(RelError));
    circlearea = pi*strongradius^2;
    maskarea = sum(sum(Mask));
    ratio = circlearea/maskarea;
    
    % We want the area of the circle to larger than the object in the mask
    % image to make sure we get the whole heart so if the ratio is less
    % than 1.2 we correct to ensure it is 1.25. Also if the radius is too
    % large we shrink the radius
    if ratio < 1.2 || ratio > 1.3
        strongradius = sqrt((maskarea*1.25)/pi);
    end
    
%     Show resulting circle overlayed over mask
%     NOTE: We could use the 'best' center that comes from imfindcircles
%     but the difference isn't much

%     figure(5); ax = axes;
%     imshow(Mask)
%     viscircles(ax,centroid, strongradius,'EdgeColor','b')
%     title(ax,'Mask and Overlayed Circle')

%     Make square filter to isolate the heart
%     The square filter is 20% larger than the circle to ensure the whole
%     heart is captured

    Filter = zeros(size(SortedImage,1),size(SortedImage,2));
    centroid(1) = centroid(1) + 5;
    middle = round(centroid);
    Lside = round(middle(1) - (strongradius*1.2));
    Rside = round(middle(1) + (strongradius*1.2));
    Top = round(middle(2) - (strongradius*1.2));
    Bottom = round(middle(2) + (strongradius*1.2));
    Corners = [Lside,Rside,Top,Bottom];
     
%     If the filter exceeds the dimensions of the images, this corrects it
    if any(Corners > size(SortedImage,1))
        Corners(Corners > size(SortedImage,1)) = size(SortedImage,1);
    end
    if any(Corners < 1)
        Corners(Corners < 1) = 1;
    end
    
%     Populate the filter to have 1 wherever the heart is located
    Filter(Corners(3):Corners(4),Corners(1):Corners(2)) = 1;
    
%     Show image of the rectangle over the heart

%     figure(6); ax = axes;
%     imshow(FinalImage(:,:,1),[])
%     rectangle(ax,'Position',[Lside,Top,Rside-Lside,Bottom-Top],'FaceColor', ...
%     [0 .5 .5],'EdgeColor','b','LineWidth',3)
%     title('Image and Overlayed Filter')
    
%     Multiply the SortedImage with the Filter to get the ROI
    ROI = SortedImage.*Filter;
    
%     Put each slice into an entry in a cell array
    for i = 1:size(ROI,3)
        ROIImage{i} = ROI(:,:,i);
    end
    
%     figure(7); ax = axes;
%     imshow(ROIImage(:,:,1),[])
%     title('ROI Image')

end