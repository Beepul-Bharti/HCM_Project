%% Sorting and Organizing Dicom Images
% Files Organization:
% Patient => Date => Series => Images

% Initialization steps:
clc;        % Clear the command window.
workspace;  % Make sure the workspace panel is showing.
format long g;
format compact;

% Define a starting folder.
% This is where you will put your path
% This folder should contain folders of each patient
start_path = fullfile('/home/beepul/HCM-Project/DicomImages');

% Ask user to confirm the folder, or change it.
uiwait(msgbox('Pick a starting folder on the next window that will come up.'));
topLevelFolder = uigetdir(start_path);
if topLevelFolder == 0
    return;
end
fprintf('The top level folder is "%s".\n', topLevelFolder);

%% Patients Directory: 813 Patients
% Each entry is a patient
PatientsDir = dir(topLevelFolder);
PatientsDir(ismember({PatientsDir.name},{'.','..','DICOMDIR'})) = [];

% 813 Patients with 813 subfolders
filePattern = strcat(topLevelFolder,'/*/*');
subfolders = dir(filePattern);
subfolders(~[subfolders.isdir])= []; %Remove all non directories.
subfolders(ismember({subfolders.name},{'.','..'})) = [];

%% Access Each Series
% Each series has 1 to many slices/frames 
filePattern2 = strcat(topLevelFolder,'/*/*/*');
allseries = dir(filePattern2);
allseries(~[allseries.isdir])= []; %Remove all non directories.
allseries(ismember({allseries.name},{'.','..'})) = [];

% Print how many series there are
fprintf('There are %d total series \n', length(allseries))
% 27447 total series/images

%% Access files in each series 
% Each file is a dicom file (slice/frame) that comes from a series (image)
filePattern3 = strcat(topLevelFolder,'/*/*/*/*');
allfiles = dir(filePattern3);
allfiles(ismember({allfiles.name},{'.','..'})) = [];
fprintf('There are %d total slices/frames/dicom files \n', length(allfiles));

%% Classify View, Type and Retrieve Other Tags of Each Series/Image
PatientPath = cell(length(allseries),1);
SeriesPath = cell(length(allseries),1);
seriessize = cell(length(allseries),1);
Name = cell(length(allseries),1);
Number = cell(length(allseries),1);
Category = cell(length(allseries),1);
p = 1;
k = 2;

% Figuring out which series is an image and which is not
% This will only select MRI images (removes reports and other images)
parfor i = 1:length(allseries)
    seriesdir = dir(fullfile(allseries(i).folder,allseries(i).name));
    [patpath,date] = fileparts(allseries(i).folder);
    PatientPath{i} = patpath;
    seriesdir(ismember({seriesdir.name},{'.','..'})) = [];
    seriessize{i} = length(seriesdir);
    SeriesPath{i} = seriesdir(1).folder;
    
    % Get Dicom Metadata
    info = dicominfo(seriesdir(p).name,'UseDictionaryVR',true);
        
    % Patient Name/Number
    Name{i} = info.PatientName.FamilyName;
        
    % Series Number
    Number{i} = info.SeriesNumber;
    
    try
        % The image orientation tag will tell us if its an image or not.
        o = info.ImageOrientationPatient;
        v = info.Modality
        if strcmp(v, 'MR')
            Category{i} = 'MRI_Image';
        else
            Category{i} = 'Not MRI'
        end
    catch
        Category{i} = 'N/A';
    end
end

% This was a file that really was not an image so I specifically removed it
% '/home/beepul/HCM Project/DicomImages/377/Mar 7, 2016/[501] MR  -- (1 instances)'

% Array that shows if a series is an image or not
SeriesArray = [PatientPath,SeriesPath,Name,Category,Number,seriessize];

% Array for just MRI Images
% Subset of SeriesArray which are MR
ImageArray = SeriesArray(strcmp(Category,'MRI_Image'),:);

% Removing these image (Series 501 for Patients 377 and 377_1] bc unclear what it is
ImageArray(strcmp(ImageArray(:,3),'377') & cell2mat(ImageArray(:,5)) == 501,:) = [];
ImageArray(strcmp(ImageArray(:,3),'377_1') & cell2mat(ImageArray(:,5)) == 501,:) = [];

%% Relevant Dicom Tags

% Sequence Attributes 
ScanSequence = cell(length(ImageArray),1);
SequenceVar = cell(length(ImageArray),1);

% Image Attributes
PixelColumn = cell(length(ImageArray),1);
PixelRow = cell(length(ImageArray),1);

% Common Time Attributes
EchoTime = cell(length(ImageArray),1);
RepTime = cell(length(ImageArray),1);

% Image Specific Time Attributes (Inversion Time) (OPTIONAL)
ITime = cell(length(ImageArray),1);
CNumFrames = cell(length(ImageArray),1);

% Other Relevant Attributes (OPTIONAL)
Contrast = cell(length(ImageArray),1);
FlipAngle = cell(length(ImageArray),1);
SequenceName = cell(length(ImageArray),1);

% Calculating Orientation
Orientation = cell(length(ImageArray),1);


%% DO NOT RUN THIS PART OF THE CODE
%%% Histogram Orientation
% Tabulating all relevant DICOM tags for every image
parfor i  = 1:length(ImageArray)
    imagedir = dir(ImageArray{i,2});
    imagedir(ismember({imagedir.name},{'.','..'})) = [];
    
    % Get dicom metadata
    info = dicominfo(imagedir(p).name,'UseDictionaryVR',true);
    
    % Orientation
    v = info.ImageOrientationPatient;
    v1_1(i) = v(1);
    v1_2(i) = v(2);
    v1_3(i) = v(3);
    v2_1(i) = v(4);
    v2_2(i) = v(5);
    v2_3(i) = v(6);
end

figure(1)
histogram(v1_1)
title('v1_1')

figure(2)
histogram(v1_2)
title('v1_2')

figure(3)
histogram(v1_3)
title('v1_3')

figure(4)
histogram(v2_1)
title('v2_1')

figure(5)
histogram(v2_2)
title('v2_2')

figure(6)
histogram(v2_3)
title('v2_3')

%% Run this part

parfor i  = 1:length(ImageArray)
    imagedir = dir(ImageArray{i,2});
    imagedir(ismember({imagedir.name},{'.','..'})) = [];
    
    % Get dicom metadata
    info = dicominfo(imagedir(p).name,'UseDictionaryVR',true);
    
    % Orientation
    v = info.ImageOrientationPatient;
    Orientation{i} = getOrientation(v(1:3),v(4:6));

    % Pixel Spacing
    Spacing = info.PixelSpacing;
    PixelRow{i} = Spacing(1);
    PixelColumn{i} = Spacing(2);

    % Repetition and Echo Times
    EchoTime{i} = info.EchoTime;
    RepTime{i} = info.RepetitionTime;

    % Sequence Variant
    SequenceVar{i} = info.SequenceVariant;

    % Scan Sequence
    ScanSequence{i} = info.ScanningSequence;
    
    % Dicom Tags that are optional
    try
        SequenceName{i} = info.SequenceName;
    catch
        SequenceName{i} = 'Missing' ;  
    end
    
    try
        Contrast{i} = info.ContrastBolusAgent ;
    catch
        Contrast{i} = 'Missing';
    end
    
    try
        FlipAngle{i} = info.FlipAngle;
    catch
        FlipAngle{i} = 'Missing';
    end
    
    try
        ITime{i} = info.InversionTime;
    catch
        ITime{i} = 'Missing';
    end
    
    try
        CNumFrames{i} = info.CardiacNumberOfImages;
    catch
        CNumFrames{i} = 'Missing';
    end
end

% Array with details of each series
ImageArrayNoPath = ImageArray(:,3:end);

% Including File Paths
FinalImageArraywPath = [ImageArray,ScanSequence,SequenceVar,SequenceName,PixelRow,PixelColumn,...
    FlipAngle,EchoTime,RepTime,ITime,CNumFrames,Contrast,Orientation];

% No File paths
FinalImageArray = [ImageArrayNoPath,ScanSequence,SequenceVar,SequenceName,PixelRow,PixelColumn,...
    FlipAngle,EchoTime,RepTime,ITime,CNumFrames,Contrast,Orientation];

% Create Table
ImageTablewPath = cell2table(FinalImageArraywPath);
ImageTable = cell2table(FinalImageArray);

Headers = {'PatientNumber' 'Image' 'SeriesNumber' 'Number of Slice/Frames' 'ScanningSequence' 'SequenceVariant'...
    'SequenceName' 'PixelRowSpace' 'PixelColumnSpace' 'FlipAngle' 'EchoTime' 'RepetitionTime' 'InversionTime'...
    'CardiacNumofFrames' 'Contrast' 'Orientation'};
HeaderswPaths = {'PatientPath' 'ImagePath' 'PatientNumber' 'Image' 'SeriesNumber' 'Number of Slice/Frames' 'ScanningSequence' 'SequenceVariant'...
    'SequenceName' 'PixelRowSpace' 'PixelColumnSpace' 'FlipAngle' 'EchoTime' 'RepetitionTime' 'InversionTime'...
    'CardiacNumofFrames' 'Contrast' 'Orientation'};
    
% Adding header
ImageTablewPath.Properties.VariableNames = HeaderswPaths;
ImageTable.Properties.VariableNames = Headers;

% Creating Excel Tables
writetable(ImageTablewPath, 'ImageTableWithPaths.xls')
writetable(ImageTable,'ImageTable.xls')