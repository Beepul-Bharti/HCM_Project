%% 4 Chamber Heart ROI Detection/Localization

% Inputs
% PatientNumber: String that is the Patient Number/name of the folder: ex '100'
% NOTE: This folder should ONLY containn 4chamber cine 2D + t images

% ImageNumber: Number that identifies which image you want to use: ex if
% patient '100' has 4 images, you can choose any number 1 through 4

% Outputs: 
% ROIIMage: Cropped images around ROI (heart)
function [ROIImage] = LongAxisROI(PatientNumber,ImageNumber)
    % Top Level Folder Directory: PatientNumber
    PatientNumber = string(PatientNumber);
    TopLevelFolder = PatientNumber;
    Directory = dir(PatientNumber);
    Directory(ismember({Directory.name},{'.','..','DICOMDIR'})) = [];

    % ImageNumber = Dicom Image
    PatientFolder = dir(fullfile(TopLevelFolder,Directory(ImageNumber).name));
    PatientFolder(ismember({PatientFolder.name},{'.','..','DICOMDIR'})) = [];

    % Load each frame and store in multidimensional array
    for i = 1:length(PatientFolder)
        info = dicominfo(fullfile(PatientFolder(1).folder,PatientFolder(i).name));
        Instance(i) = info.InstanceNumber;
        Image(:,:,i) = dicomread(info);
    end

    % Rearrange to be from beginning to end w.r.t time
    [~,ind] = sort(Instance);
    Ysort = Image(:,:,ind);

    % Converting Image to double
    Ysort = double(Ysort) + 1;

    %% Perform following operations to each slice
    % Resize to 1 x 1 mm 
    % Zero Center 
    % Pixel Normalization
    % CLAHE

    scale = 1/info.PixelSpacing(1);
    for i = 1:length(PatientFolder)
        % Rescale
        Rescale = imresize(Ysort(:,:,i),scale);
        % ZeroCenter
        ZeroCenter = Rescale - mean(mean(Rescale));
        % Calculate min and max pixel (local slice)
        p_min = min(min(Rescale));
        p_max = max(max(Rescale));
        % Normalize    ROIImage = FinalImage.*Filter;
        SliceNormal = (ZeroCenter-p_min)/(p_max - p_min);
        % CLAHE and store in new 3D array
        FinalImage(:,:,i) = adapthisteq(SliceNormal);
    end
    
    % Display an Example Slice after preprocessing
    figure(1); ax = axes;
    imshow(FinalImage(:,:,1),[])
    title(ax,'Example Slice after Preprocessing')

    % Compute Variance Image (sum of 1 through k harmonic images)
    VarImage = var(FinalImage,0,3);

    % Surface Plot of Variance Image
    [X,Y] = meshgrid(1:1:size(FinalImage,2),1:1:size(FinalImage,1));
    figure(2); ax = axes;
    surf(X,Y,VarImage)
    title(ax,'Variance Image')
    
    % Generate an image that detects edges from the Variance Image
    BW1 = edge(VarImage,'Canny');  
    figure(3); ax = axes;
    imshow(BW1)
    title(ax,'Edges')
    
    % Texture analysis on the Variance Image
    wavelength = 2.^(0:5) * 3;
    orientation = 0:45:135;
    g = gabor(wavelength,orientation);
    gabormag = imgaborfilt(VarImage,g);
    
    for i = 1:length(g)
        sigma = 0.5*g(i).Wavelength;
        gabormag(:,:,i) = imgaussfilt(gabormag(:,:,i),3*sigma); 
    end
    
    % Texture analysis on the Edge Image
    wavelength = 2.^(0:1) * 3;
    orientation = 0:45:135;
    g = gabor(wavelength,orientation);
    gabormag2 = imgaborfilt(single(BW1),g);
    
    for i = 1:length(g)
        sigma = 0.5*g(i).Wavelength;
        gabormag2(:,:,i) = imgaussfilt(gabormag2(:,:,i),3*sigma); 
    end
    
    % Make a feature set that includes texture analysis of both Variance
    % and Edge images
    featureSet = cat(3,gabormag,gabormag2,X,Y);
    SegImage = imsegkmeans(single(featureSet),2,'NormalizeInput',true);

    % Check Bottom left corner pixel value of SegImage
    Val = SegImage(1,size(FinalImage,1),1);
    if Val == 2
        Mask = SegImage == 1;
    else
        Mask = SegImage == 2;
    end
    
    Mask = bwpropfilt(Mask,'perimeter',1);
    
    % Show the mask that comes from k means segmentation
    figure(4); ax = axes;
    imshow(Mask)  
    title(ax,'Mask from K-means Segmentation')
    
   
    % Hough Transform for Circle Detection
    [centers, radii] = imfindcircles(Mask,[40,70],'Sensitivity',0.95);
    
    % Pick the 'best' center and radius
    stats = regionprops(Mask,'Centroid');
    centroid = stats(1).Centroid;
    distance = centers - centroid;
    RelError = vecnorm(distance')/norm(centroid);
    strongcenter = centers(RelError == min(RelError),:);
    strongradius = radii(RelError == min(RelError));
    circlearea = pi*strongradius^2;
    maskarea = sum(sum(Mask));
    ratio = circlearea/maskarea;
    
    if ratio < 1.2 || ratio > 1.3
        strongradius = sqrt((maskarea*1.2)/pi);
    end
    
    % Show resulting circle overlayed over mask
    figure(5); ax = axes;
    imshow(Mask)
    viscircles(ax,centroid, strongradius,'EdgeColor','b')
    title(ax,'Mask and Overlayed Circle')

    %   Make square filter to isolate the heart
    %   The square filter is 10% larger than the circle to ensure the whole
    %   heart is captured
    Filter = zeros(size(FinalImage,1),size(FinalImage,2));
    middle = round(centroid);
    Lside = round(middle(1) - (strongradius*1.20));
    Rside = round(middle(1) + (strongradius*1.20));
    Top = round(middle(2) + (strongradius*1.20));
    Bottom = round(middle(2) - (strongradius*1.20));
    Corners = [Lside,Rside,Top,Bottom];

    if any(Corners > size(FinalImage,1))
        Corners(Corners > size(FinalImage,1)) = size(FinalImage,1);
    end
    if any(Corners < 1)
        Corners(Corners < 1) = 1;
    end

    Filter(Corners(4):Corners(3),Corners(1):Corners(2)) = 1;
    
    figure(6); ax = axes;
    imshow(FinalImage(:,:,1),[])
    rectangle(ax,'Position',[Lside,Bottom,Rside-Lside,Top-Bottom],'FaceColor',[0 .5 .5],'EdgeColor','b',...
        'LineWidth',3)
    title('Image and Overlayed Filter')
    
    % Show Example slice of resulting ROI
    ROIImage = FinalImage.*Filter;
    figure(7); ax = axes;
    imshow(ROIImage(:,:,1),[])
    title('ROI Image')
end