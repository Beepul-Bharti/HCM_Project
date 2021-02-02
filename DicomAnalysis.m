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
start_path = fullfile('/home/beepul/HCM Project/DicomImages');

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
        o = info.ImageOrientationPatient
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

% Removing this image (Series 51 for Patient 501] bc unclear what it is
ImageArray(strcmp(ImageArray(:,2),'/home/beepul/HCM Project/NEWDicomImages/377/Mar 7, 2016/[501] MR  -- (1 instances)'),:) = [];

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

% Tabulating all relevant DICOM tags for every image
parfor i  = 1:length(ImageArray)
    imagedir = dir(ImageArray{i,2});
    imagedir(ismember({imagedir.name},{'.','..'})) = [];
    
    % Get dicom metadata
    info = dicominfo(imagedir(p).name,'UseDictionaryVR',true);
    
    % Orientation
    try
        v = info.ImageOrientationPatient;
        Orientation{i} = getOrientation(v(1:3),v(4:6));
    catch
        Orientation{i} = 'Missing'
    end
    
    % Pixel Spacing
    try
        Spacing = info.PixelSpacing;
        PixelRow{i} = Spacing(1);
        PixelColumn{i} = Spacing(2);
    catch
        PixelRow{i} = 'Missing';
        PixelColumn{i} = 'Missing';
    end
    
    % Repetition and Echo Times
    try
        EchoTime{i} = info.EchoTime;
        RepTime{i} = info.RepetitionTime;
    catch
        EchoTime{i} = 'Missing'
        RepTime{i} = 'Missing'
    end
    
    % Sequence Variant
    try
         SequenceVar{i} = info.SequenceVariant;
    catch
         SequenceVar{i} = 'Missing'
    end
    
    % Scan Sequence
    try
        SequenceClass = info.ScanningSequence;
        ScanSequence{i} = SequenceClass;
    catch 
        ScanSequence{i} = 'Missing';
    end
    
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

% Remove Entries that do not have a Scan Sequence
ImageArray(strcmp(ScanSequence,'Missing'),:) = [];

% Create Table
ImageTablewPath = cell2table(FinalImageArraywPath);
ImageTable = cell2table(FinalImageArray);

Headers = {'Patient Number' 'Image' 'SeriesNumber' 'Number of Slice/Frames' 'ScanningSequence' 'SequenceVariant'...
    'SequenceName' 'PixelRowSpace' 'PixelColumnSpace' 'FlipAngle' 'EchoTime' 'RepetitionTime' 'InversionTime'...
    'CardiacNumofFrames' 'Contrast' 'Orientation'};
HeaderswPaths = {'PatientPath' 'ImagePath' 'Patient Number' 'Image' 'SeriesNumber' 'Number of Slice/Frames' 'ScanningSequence' 'SequenceVariant'...
    'SequenceName' 'PixelRowSpace' 'PixelColumnSpace' 'FlipAngle' 'EchoTime' 'RepetitionTime' 'InversionTime'...
    'CardiacNumofFrames' 'Contrast' 'Orientation'};
    
% Adding header
ImageTablewPath.Properties.VariableNames = HeaderswPaths;
ImageTable.Properties.VariableNames = Headers;

% Creating Excel Tables
writetable(ImageTablewPath, 'ImageTableWithPaths.xls')
writetable(ImageTable,'ImageTable.xls')


%% Table compiling patient data
uniqueID = unique(Name);
PatID = cell(length(uniqueID),1);
LGEVLong = zeros(length(uniqueID),1);
LGEHzLong = zeros(length(uniqueID),1);
LGECoronal = zeros(length(uniqueID),1);
LGEShortAxis = zeros(length(uniqueID),1);
CineVLong = zeros(length(uniqueID),1);
CineHzLong = zeros(length(uniqueID),1);
CineCoronal = zeros(length(uniqueID),1);
CineShortAxis = zeros(length(uniqueID),1);

% Table to describe each patients data
for i = 1:length(PatID)
    ID = uniqueID{i};
    PatID{i} = ID;
    indices = find(strcmp(ImageArray(:,1),ID));
    temparray = ImageArray(indices,6);
    if isempty(find(strcmp(temparray,'LGE_VLong'))) == 1 
        LGEVLong(i) = 0;
    else
        LGEVLong(i) = 1;
    end
    if isempty(find(strcmp(temparray,'LGE_HzLong'))) == 1
        LGEHzLong(i) = 0;
    else
        LGEHzLong(i) = 1;
    end
    if isempty(find(strcmp(temparray,'LGE_Coronal'))) == 1
        LGECoronal(i) = 0;
    else
        LGECoronal(i) = 1;
    end
    if isempty(find(strcmp(temparray,'LGE_ShortAxis'))) == 1
        LGEShortAxis(i) = 0;
    else
        LGEShortAxis(i) = 1;
    end        
    if isempty(find(strcmp(temparray,'Cine_VLong'))) == 1
        CineVLong(i) = 0;
    else
        CineVLong(i) = 1;
    end
    if isempty(find(strcmp(temparray,'Cine_HzLong'))) == 1
        CineHzLong(i) = 0;
    else
        CineHzLong(i) = 1;
    end
    if isempty(find(strcmp(temparray,'Cine_Coronal'))) == 1
        CineCoronal(i) = 0;
    else
        CineCoronal(i) = 1;
    end
    if isempty(find(strcmp(temparray,'Cine_ShortAxis'))) == 1
        CineShortAxis(i) = 0;
    else
        CineShortAxis(i) = 1;
    end 
end

% Final Table Summarizing Patients and their image types
PatientTable = table(PatID,LGEVLong,LGEHzLong,LGECoronal,LGEShortAxis,CineVLong,CineHzLong,CineCoronal,CineShortAxis);
writetable(PatientTable,'PatientTable.xls')


%% IGNORE FOR RIGHT NOW
% Patients that have ShortAxis MRI and Short Axis Cine
SA = PatImageSummary(PatImageSummary.LGEShortAxis == 1,:);
SA = PatImageSummary.LGEShortAxis
HZ = PatImageSummary(PatImageSummary.LGEHzLong == 1,:);
HZ = PatImageSummary.LGEHzLong
SA_Cine = SA(SA.CineShortAxis ==1,:);
both = size(SA_Cine);

% Summary
fprintf('%d Patients have Short Axis MRI \n', sum(LGEShortAxis))
fprintf('%d Patients have Hz Long MRI \n', sum(LGEHzLong))
fprintf('%d Patients have Vertical Long MRI \n', sum(LGEVLong))
fprintf('%d Patients have Coronal MRI \n', sum(LGECoronal))
fprintf('%d Patients have Short Axis Cine \n', sum(CineShortAxis))
fprintf('%d Patients have Hz Long Cine \n', sum(CineHzLong))
fprintf('%d Patients have Vertical Long Cine \n', sum(CineVLong))
fprintf('%d Patients have Coronal Cine \n', sum(CineCoronal))
fprintf('%d Patients have both Short Axis Cine and MRI', both(1))
