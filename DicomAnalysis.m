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
start_path = fullfile('/home/beepul/HCM Project/DicomImages');

% Ask user to confirm the folder, or change it.
uiwait(msgbox('Pick a starting folder on the next window that will come up.'));
topLevelFolder = uigetdir(start_path);
if topLevelFolder == 0
    return;
end
fprintf('The top level folder is "%s".\n', topLevelFolder);

%% Patients Directory: 812 Patients
% Each entry is a patient
PatientsDir = dir(topLevelFolder);
PatientsDir(ismember({PatientsDir.name},{'.','..','DICOMDIR'})) = [];


% 812 Patients with 812 subfolders
filePattern = strcat(topLevelFolder,'/*/*');
subfolders = dir(filePattern);
subfolders(~[subfolders.isdir])= []; %Remove all non directories.
subfolders(ismember({subfolders.name},{'.','..'})) = [];

%% Access Each Series
% Each series has 1 to many images 
filePattern2 = strcat(topLevelFolder,'/*/*/*');
allseries = dir(filePattern2);
allseries(~[allseries.isdir])= []; %Remove all non directories.
allseries(ismember({allseries.name},{'.','..'})) = [];

% Print how many series there are
fprintf('There are %d total series \n', length(allseries))

%% Access files in each series 
% Each file is a dicom file (slice/frame) that comes from a series (image)
filePattern3 = strcat(topLevelFolder,'/*/*/*/*');
allfiles = dir(filePattern3);
allfiles(ismember({allfiles.name},{'.','..'})) = [];
fprintf('There are %d total images \n', length(allfiles));

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

% Removing this image bc unclear what it is
ImageArray(strcmp(ImageArray(:,2),'/home/beepul/HCM Project/DicomImages/377/Mar 7, 2016/[501] MR  -- (1 instances)'),:) = [];

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
    v = info.ImageOrientationPatient
    Orientation{i} = getOrientation(v(1:3),v(4:6));
    
    % Scanning Sequence
    SequenceClass = info.ScanningSequence;
    ScanSequence{i} = SequenceClass;
    
    % Sequence Variant
    SequenceVar{i} = info.SequenceVariant;
    
    % Pixel Spacing
    Spacing = info.PixelSpacing;
    PixelRow{i} = Spacing(1);
    PixelColumn{i} = Spacing(2);
    
    % Repetition and Echo Times
    EchoTime{i} = info.EchoTime;
    RepTime{i} = info.RepetitionTime;
    
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
        ITime{i} = info.InversionTime
    catch
        ITime{i} = 'Missing'
    end
    
    try
        CNumFrames{i} = info.CardiacNumberOfImages
    catch
        CNumFrames{i} = 'Missing'
    end
end

% Array with details of each series
% Creating Excel file
ImageArrayNoPath = ImageArray(:,3:end);
FinalImageArray = [ImageArrayNoPath,ScanSequence,SequenceVar,SequenceName,PixelRow,PixelColumn,...
    FlipAngle,EchoTime,RepTime,ITime,CNumFrames,Contrast,Orientation];
ImageTable = cell2table(FinalImageArray);
Headers = {'Patient Number' 'Image' 'SeriesNumber' 'Number of Slice/Frames' 'ScanningSequence' 'SequenceVariant'...
    'SequenceName' 'PixelRowSpace' 'PixelColumnSpace' 'FlipAngle' 'EchoTime' 'RepetitionTime' 'InversionTime'...
    'CardiacNumofFrames' 'Contrast' 'Orientation'};
ImageTable.Properties.VariableNames = Headers;
writetable(ImageTable,'ImageTable.xls')

% Looking at overall distribution of number of slices/frames in images
ImageSize = ImageTable(:,4);
ImageSize = table2array(ImageSize);
figure(1)
histogram(ImageSize)
xlabel('Number of Slices/Frames')
ylabel('Count')

% Checking number of slices/frames for images with CardiacNumberOfFrames
% Creating histogram for Inversion Time
% Inversion Time
ITimeChar = cellfun(@(x) num2str(x), ITime, 'UniformOutput',false);
indices = strcmp(ITimeChar, 'Missing');
indices = (indices == 0);
NumberofIR = sum(indices);
IValues = ITimeChar(indices);
IValues = str2double(IValues);
figure(1)
histogram(IValues)
ylabel('Number of Images')
xlabel('IR Time')
MeanITime = round(mean(IValues),2);

% Scan Sequence
IRScanOnly = contains(ScanSequence,'IR');
NumberofScanIR = sum(IRScanOnly);

% Contrast
ContrastOnly = (strcmp(Contrast,'Missing')==0);
NumberofContrast = sum(ContrastOnly);

% Summary of IR TIme, IR Scan Sequence, and Contrast
fprintf('%d Images have an inversion recovery time \n', NumberofIR)
fprintf('%.2f is the mean IR time \n', MeanITime)
fprintf('%d Images have "IR" in ScanSequence \n', NumberofScanIR)
fprintf('%d Images have Contrast \n', NumberofContrast)


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

%% Making Subfolders
LGESeries = ImageTable(strcmp(ImageTable(:,6),'LGE'),:);
LGEOnly = unique(LGESeries(:,2));

% Copying and moving LGE Series into Separate Folder
parfor i = 1:length(LGEOnly)
    name = LGEOnly{i};
    mkdir('LGEMRI', name);
    newpath = fullfile('/home/beepul/HCM Project/LGEMRI',name);
    temparray = LGESeries(strcmp(LGESeries(:,2),name),3);
    for k = 1:length(temparray)
        [path,seriesname] = fileparts(temparray{k});
        copyfile(temparray{k},fullfile(newpath,seriesname));
    end
end 


% Looking more closely at Short Axis (Oblique)
for i = 1:length(NumberUnique)
    [folder,name] = fileparts(NumberUnique{i});
    PatID(i) = {name};
    indices = find(strcmp(ImageTable(:,2),name));
    temparray = ImageTable(indices,3:7);
    indices = find(strcmp(temparray(:,5),'MRI_Oblique'));
    if isempty(indicefigure(1)
histogram(cell2mat(Max));s) == 0;
        Size{i} = temparray(indices,3);
        Max{i} = max(cell2mat(Size{i}));
    else 
        Size{i} = 0;
        Max{i} = 0;
    end
end

% Size lists the lengths of all SA_MRI series for a patient
% Max is the longest series
SA_Descrip = [PatID,Size',Max'];

% Removes all patients who dont have short axis
Maxnum = nonzeros(cell2mat(Max));
figure(1)
histogram(Maxnum)

% Some relevant numbers
fprintf('%d Patients have only 1 frame \n', sum(Maxnum==1))
fprintf('%d Patients have only 2 frames \n', sum(Maxnum==2))
fprintf('%d Patients have only 3 frames \n', sum(Maxnum==3))
fprintf('%d Patients have greater than or equal to 5 frames \n', sum(Maxnum >= 4))

SASeries = ImageTable(strcmp(ImageTable(:,7),'MRI_Oblique'),:);
SAOnly = unique(SASeries(:,2));

% Copying and moving SA MRI into specific folder
parfor i = 1:length(SAOnly)
    name = SAOnly{i};
    mkdir('PatientShortAxisMRI', name);
    newpath = fullfile('/home/beepul/HCM Project/PatientShortAxisMRI',name);
    temparray = SASeries(strcmp(SASeries(:,2),name),3);
    for k = 1:length(temparray)
        [path,seriesname] = fileparts(temparray{k});
        copyfile(temparray{k},fullfile(newpath,seriesname));
    end
end 

%% Labeling and Sorting the Cine Views 
CineSeries = ImageTable(strcmp(ImageTable(:,6),'Cine'),:);
CineOnly = unique(CineSeries(:,2));

% Checking Views of Cine 
ID = cell(length(CineOnly),1);
CineSA = zeros(length(CineOnly),1);
CineHZL = zeros(length(CineOnly),1);
CineVL = zeros(length(CineOnly),1);
CineCor = zeros(length(CineOnly),1);

parfor i = 1:length(CineOnly)
    name = CineOnly{i};
    ID{i} = name;
    indices = find(strcmp(ImageTable(:,2),name));
    temparray = ImageTable(indices,3:7);
    if isempty(find(strcmp(temparray,'Cine_Oblique'))) == 1
        CineSA(i) = 0;
    else
        CineSA(i) = 1;
    end
    if isempty(find(strcmp(temparray,'Cine_Transverse'))) == 1
        CineHZL(i) = 0;
    else
        CineHZL(i) = 1;
    end
    if isempty(find(strcmp(temparray,'Cine_Sagittal'))) == 1
        CineVL(i) = 0;
    else
        CineVL(i) = 1;
    end
    if isempty(find(strcmp(temparray,'Cine_Coronal'))) == 1
        CineCor(i) = 0;
    else
        CineCor(i) = 1;
    end
end
CineDescrip = table(ID,CineSA,CineHZL,CineVL,CineCor);

fprintf('%d Patients have Short Axis Cine \n', sum(CineSA))
fprintf('%d Patients have HZ Long Cine \n', sum(CineHZL))
fprintf('%d Patients have V Long Cine \n', sum(CineVL))
fprintf('%d Patients have Coronal Cine \n', sum(CineCor))

%% Axial Cine

% Make Axial Folder
mkdir('Cine', 'Axial')

AxCinePatients = CineDescrip.ID(CineDescrip.CineHZL == 1);

parfor i = 1:length(AxCinePatients)
    ID = AxCinePatients{i};
    mkdir('/home/beepul/HCM Project/Cine/Axial', ID);
    newpath = fullfile('/home/beepul/HCM Project/Cine/Axial',ID)
    patIndices = CineSeries(strcmp(CineSeries(:,2),ID),:);
    Axial = patIndices(strcmp(patIndices(:,4),'Transverse'),:);
    for k = 1:size(Axial,1)
        [path,seriesname] = fileparts(Axial{k,3});
        copyfile(Axial{k,3},fullfile(newpath,seriesname));
    end
end

% Max Number of Frames
AxCine = CineSeries(strcmp(CineSeries(:,7),'Cine_Transverse'),:);
AxMaxFrames = zeros(length(AxCinePatients),1);

for i = 1:length(AxCinePatients)
    indices = find(strcmp(AxCine(:,2),AxCinePatients(i)));
    temparray = AxCine(indices,5);
    AxMaxFrames(i) = max(cell2mat(temparray));
end

AxCineCount = [AxCinePatients,num2cell(AxMaxFrames)];

%% Short Axis Cine

% % Make SA Folder
mkdir('Cine', 'SA')

SACinePatients = CineDescrip.ID(CineDescrip.CineSA == 1);

parfor i = 1:length(SACinePatients)
    ID = SACinePatients{i};
    mkdir('/home/beepul/HCM Project/Cine/SA', ID);
    newpath = fullfile('/home/beepul/HCM Project/Cine/SA',ID)
    patIndices = CineSeries(strcmp(CineSeries(:,2),ID),:);
    SA = patIndices(strcmp(patIndices(:,4),'Oblique'),:);
    for k = 1:size(SA,1)
        [path,seriesname] = fileparts(SA{k,3});
        copyfile(SA{k,3},fullfile(newpath,seriesname));
    end
end

% Max Number of Frames
SACine = CineSeries(strcmp(CineSeries(:,7),'Cine_Oblique'),:);
SAMaxFrames = zeros(length(SACinePatients),1);

for i = 1:length(SACinePatients)
    indices = find(strcmp(SACine(:,2),SACinePatients(i)));
    temparray = SACine(indices,5);
    SAMaxFrames(i) = max(cell2mat(temparray));
end

SACineCount = [SACinePatients,num2cell(SAMaxFrames)]

%% Checking SA Cine count...
p = 0;
for i = 1:length(PatID)
    ind = strcmp(PatID(i),ImageTable(:,2));
    counts = cell2mat(ImageTable(ind,5));
    if any(counts > 100)
        p = p + 1;
    else
        p = p;
    end
end
