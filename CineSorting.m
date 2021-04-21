%% Cine Sorting
% Finds Cine images from all the images using table created in
% DicomAnalysis.m
% Adapting Sevde's code to MATLAB

% Load Image Tables
ImageTable = readtable('ImageTable.xls');

% Image Table w/ Path has the file paths to each image
ImageTablewPath = readtable('ImageTableWithPaths.xls');

%% Cine Images
% Steady-state free precession MRI (SSFP) is a type of gradient echo MRI pulse sequence in which a steady, 
% residual transverse magnetization (Mxy) is maintained between successive cycles. The sequence is noted 
% for its superiority in dynamic/cine assessment of cardiac function.

% Scanning Sequence = 'GR'
CineTable = ImageTable(strcmp(ImageTable.ScanningSequence, 'GR'),:);
CineTablewPath = ImageTablewPath(strcmp(ImageTablewPath.ScanningSequence, 'GR'),:);

% Cardiac Number of Frames > 1
CineTable = CineTable(CineTable.CardiacNumofFrames > 1,:);
CineTablewPath = CineTablewPath(CineTablewPath.CardiacNumofFrames > 1,:);

%% Run this block if you want to EXCLUDE contrast
% Contrast = 'Missing' or 'No'
Cineindices = strcmp(CineTable.Contrast,'Missing') + strcmp(CineTable.Contrast, 'No');
CineindiceswPath = strcmp(CineTablewPath.Contrast,'Missing') + strcmp(CineTablewPath.Contrast, 'No');
CineTable = CineTable(logical(Cineindices),:);
CineTablewPath = CineTablewPath(logical(CineindiceswPath),:);

%%
% InversionTime = 'Missing' in this case NaN
CineTable = CineTable(isnan(CineTable.InversionTime),:);
CineTablewPath = CineTablewPath(isnan(CineTablewPath.InversionTime),:);

% Sequence Name contains "tfi"
CineTable = CineTable(contains(CineTable.SequenceName,'tfi'),:);
CineTablewPath = CineTablewPath(contains(CineTablewPath.SequenceName,'tfi'),:);

% Write Table
% Change name depending on if you including contrast or not
writetable(CineTable, 'CineTable_Contrast.xls')
writetable(CineTablewPath,'CineTablewPaths_Contrast.xls')

% Copy Cine Images to Separate Folder
CineOnly = unique(CineTable.PatientNumber);


%% Only Need to run this one time

% Change folder names depending on if you chose to include contrast images
% or not

% Make Specific Folder for 4 chamber views only (Example: this includes contrast)
mkdir('ShortAxisCine_contrast_included')
mkdir('4ChamberCine_contrast_included')
mkdir('RemainingCine_contrast_included')

% Copy different cine images into their respective new folders
parfor i = 1:length(CineOnly)
    name = CineOnly{i};
    newpath = fullfile('/home/beepul/HCM-Project/RemainingCine_contrast_included',name);
    newpath2 = fullfile('/home/beepul/HCM-Project/4ChamberCine_contrast_included',name);
    newpath3 = fullfile('/home/beepul/HCM-Project/ShortAxisCine_contrast_included',name);
    temparray = CineTablewPath(strcmp(CineTablewPath.PatientNumber,name),:);
    for k = 1:size(temparray,1)
        [path,seriesname] = fileparts(temparray.ImagePath{k});
        if strcmp(temparray.Orientation{k},'HzLong')
            copyfile(temparray.ImagePath{k},fullfile(newpath2,seriesname))
        elseif strcmp(temparray.Orientation{k},'ShortAxis')
            copyfile(temparray.ImagePath{k},fullfile(newpath3,seriesname))
        else
            copyfile(temparray.ImagePath{k},fullfile(newpath,seriesname));
        end
    end
end 