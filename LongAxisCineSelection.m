%% Analyzing LongAxis Cine Images

% Directory of all 4 Chamber Cine Images
% Each Object in the Directory is an 2D + t Cine Image
LongAxisDir = dir('4ChamberCine/*/*');
LongAxisDir(ismember({LongAxisDir.name},{'.','..','DICOMDIR'})) = [];

% Tabulating relevant information for each Image
ImagePath = cell(length(LongAxisDir),1);
PatientID = cell(length(LongAxisDir),1);
SortedInstance = cell(length(LongAxisDir),1);
Range = cell(length(LongAxisDir),1);
CardiacNumImages = cell(length(LongAxisDir),1);
NumofFrames = cell(length(LongAxisDir),1);

% Retrieving the following pieces of information
% File path of each image, CardiacNumberOfFrames, and instance number 
% for each slice
parfor i = 1:length(LongAxisDir)
    ImagePath{i} = fullfile(LongAxisDir(i).folder,LongAxisDir(i).name);
    ImageDir = dir(ImagePath{i});
    ImageDir(ismember({ImageDir.name},{'.','..','DICOMDIR'})) = [];
    Instance = [];
    for k = 1:length(ImageDir)
        dinfo = dicominfo(fullfile(ImageDir(1).folder,ImageDir(k).name));
        Instance(k) = dinfo.InstanceNumber;
    end
    [~,ID] = fileparts(LongAxisDir(i).folder);
    PatientID{i} = ID;
    SortedInstance{i} = sort(Instance);
    CardiacNumImages{i} = dinfo.CardiacNumberOfImages;
end

% Sorting the Instance Number and calculate number of frames and range of
% frames for each image
for i = 1:length(LongAxisDir)
    Object = SortedInstance{i};
    Range{i} = range(Object);
    NumofFrames{i} = length(Object);
end

%% Original Array of All Patients
CineMetrics = [ImagePath,PatientID,CardiacNumImages,NumofFrames,Range,SortedInstance];

% Original Total Number of Patients
OriginalTotal = length(unique(PatientID));
fprintf('There are %d total Patients with 2D + t Long Axis Cine Images \n', OriginalTotal);

%% Looking at Patients wth CardiacNumberOfImages = 30writetable(Final4ChamberCine, 'Final4ChamberCine.xls')
Array30 = CineMetrics(cell2mat(CardiacNumImages) == 30,:);

RawTable30 = cell2table(Array30);

Headers = {'ImagePath','PatientNumber','CardiacNumofImages','NumOfFrames','Range','SortedInstance'};

% Adding headers to table
RawTable30.Properties.VariableNames = Headers;

% Total Patients: CardiacNumberOfImages = 30
RawName30 = unique(RawTable30.PatientNumber);

% Mean Range and Number of Frames
figure(1)
histogram(RawTable30.NumOfFrames)
MeanFrame30 = mean(RawTable30.NumOfFrames);
title('NumOfFrames for C = 30')
ylabel('Count')
xlabel('Number of Frames')

figure(2)
histogram(RawTable30.Range)
MeanRange50 = mean(RawTable30.Range);
title('Range for C = 30')
ylabel('Count')
xlabel('Range')

% There are some outliers: Some patient has NumOfFrames > 30 (Not Possible)
% Remove them
Delete = RawTable30.NumOfFrames ~= 30;
Table30 = RawTable30;
Table30(Delete,:) = [];

% Updated Name30 and Total 30 with removed Patient(s)
Name30 = unique(Table30.PatientNumber);
Total30 = length(unique(Name30)); 

figure(3)
histogram(Table30.NumOfFrames)
title('NumOfFrames for C = 30')
ylabel('Count')
xlabel('Number of Frames')

figure(4)
histogram(Table30.Range)
MeanRange50 = mean(Table30.Range);
title('Range for C = 30')
ylabel('Count')
xlabel('Range')

% Final Table of Eligible Patients with CNum = 30
EligibleImages30 = Table30;

%% Selecting the best image for each patient
% Criteria (In Order)
% 1) Pick the image with more frames

EligiblePatients30 = unique(EligibleImages30.PatientNumber);
BestImage30 = array2table(zeros(length(EligiblePatients30),size(EligibleImages30,2)));
Headers = {'ImagePath','PatientNumber','CardiacNumofImages','NumOfFrames','Range','SortedInstance'};
BestImage30.Properties.VariableNames = Headers;
BestImage30.ImagePath = cell(length(EligiblePatients30),1);
BestImage30.PatientNumber = cell(length(EligiblePatients30),1);
BestImage30.SortedInstance = cell(length(EligiblePatients30),1);

for i = 1:length(EligiblePatients30)
    Array = EligibleImages30(strcmp(EligibleImages30.PatientNumber,EligiblePatients30{i}),:);
    PossibleImage = Array(Array.NumOfFrames == max(Array.NumOfFrames) ,:);
    if size(PossibleImage,1) == 1
        BestImage30(i,:) = PossibleImage;
    else
        BestImage30(i,:) = PossibleImage(1,:);
    end
end


%% Looking at Patients with CardiacNumberOfImages = 50
Array50 = CineMetrics(cell2mat(CardiacNumImages) == 50,:);

RawTable50 = cell2table(Array50);

Headers = {'ImagePath','PatientNumber','CardiacNumofImages','NumOfFrames','Range','SortedInstance'};

% Adding header
RawTable50.Properties.VariableNames = Headers;

% Total Patients: CardiacNumberOfImages = 50
RawName50 = unique(RawTable50.PatientNumber);

% Mean Range and Number of Frames
figure(5)
histogram(RawTable50.NumOfFrames)
MeanFrame50 = mean(RawTable50.NumOfFrames);
title('NumOfFrames for C = 50')
ylabel('Count')
xlabel('Number of Frames')

figure(6)
histogram(RawTable50.Range)
MeanRange50 = mean(RawTable50.Range);
title('Range for C = 50')
ylabel('Count')
xlabel('Range')

% Some Patients have Range > 49: Remove them
Delete = RawTable50.NumOfFrames ~= 50;
Table50 = RawTable50;
Table50(Delete,:) = [];

% Updated Name50 and Total50 with removed Patient(s)
Name50 = unique(Table50.PatientNumber);
Total50 = length(unique(Name50)); 

figure(7)
histogram(Table50.NumOfFrames)
title('NumOfFrames for C = 50')
ylabel('Count')
xlabel('Number of Frames')

figure(8)
histogram(Table50.Range)
MeanRange50 = mean(Table50.Range);
title('Range for C = 50')
ylabel('Count')
xlabel('Range')

% Final Table of Eligible Patients with CNum = 50
EligibleImages50 = Table50;

%% Selecting the best image for each patient
% Criteria (In Order)
% 1) Pick the image with more frames

EligiblePatients50 = unique(EligibleImages50.PatientNumber);
BestImage50 = array2table(zeros(length(EligiblePatients50),size(EligibleImages50,2)));
Headers = {'ImagePath','PatientNumber','CardiacNumofImages','NumOfFrames','Range','SortedInstance'};
BestImage50.Properties.VariableNames = Headers;
BestImage50.ImagePath = cell(length(EligiblePatients50),1);
BestImage50.PatientNumber = cell(length(EligiblePatients50),1);
BestImage50.SortedInstance = cell(length(EligiblePatients50),1);

for i = 1:length(EligiblePatients50)
    Array = EligibleImages50(strcmp(EligibleImages50.PatientNumber,EligiblePatients50{i}),:);
    PossibleImage = Array(Array.NumOfFrames == max(Array.NumOfFrames) ,:);
    if size(PossibleImage,1) == 1
        BestImage50(i,:) = PossibleImage;
    else
        BestImage50(i,:) = PossibleImage(1,:);
    end
end

%% Combining C = 30 and C = 50
TotalPatients30 = length(unique(BestImage30.PatientNumber));
TotalPatients50 = length(unique(BestImage50.PatientNumber));

% Accounting for Repeats
Loc = ismember(BestImage30.PatientNumber,BestImage50.PatientNumber);
Loc2 = ismember(BestImage50.PatientNumber,BestImage30.PatientNumber);

% Total Eligible Patients
FinalTotal = TotalPatients30 + TotalPatients50 - sum(Loc);

%% Final Table: "Best" Image for each Patient
OverLap = BestImage50;
OverLap(Loc2,:) = [];
Final4ChamberCine = [BestImage30(:,:);OverLap(:,:)];
writetable(Final4ChamberCine, 'Final4ChamberCine.xls')

%% Copy Best Images into Separate Folder
% Only Need to Run this Once

mkdir('Best4ChamberCine')
parfor i = 1:size(Final4ChamberCine,1)
    FolderName = Final4ChamberCine.PatientNumber{i};
    newpath = fullfile('/home/beepul/HCM-Project/Best4ChamberCine',FolderName);
    [~,seriesname] = fileparts(Final4ChamberCine.ImagePath{i})
    copyfile(Final4ChamberCine.ImagePath{i},fullfile(newpath,seriesname));
end 