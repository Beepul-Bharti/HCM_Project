%% Cine Sorting
% Adapting Sevde's code to MATLAB

% Load Image Tables
ImageTable = readtable('ImageTable.xls');
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

% Contrast = 'Missing' or 'No'
Cineindices = strcmp(CineTable.Contrast,'Missing') + strcmp(CineTable.Contrast, 'No');
CineindiceswPath = strcmp(CineTablewPath.Contrast,'Missing') + strcmp(CineTablewPath.Contrast, 'No');
CineTable = CineTable(logical(Cineindices),:);
CineTablewPath = CineTablewPath(logical(CineindiceswPath),:);

% InversionTime = 'Missing' in this case NaN
CineTable = CineTable(isnan(CineTable.InversionTime),:);
CineTablewPath = CineTablewPath(isnan(CineTablewPath.InversionTime),:);

% Sequence Name contains "tfi"
CineTable = CineTable(contains(CineTable.SequenceName,'tfi'),:);
CineTablewPath = CineTablewPath(contains(CineTablewPath.SequenceName,'tfi'),:);


% Copy Cine Images to Separate Folder
% Copying and moving LGE Series into Separate Folder
CineOnly = unique(CineTable.PatientNumber);

% Make Specific Folder for 4 chamber views only
mkdir('Cine', '4Chamber');

parfor i = 1:length(CineOnly)
    name = CineOnly{i};
    newpath = fullfile('/home/beepul/HCM Project/Cine',name);
    newpath2 = fullfile('/home/beepul/HCM Project/Cine/4Chamber',name);
    temparray = CineTablewPath(strcmp(CineTablewPath.PatientNumber,name),2:end);
    for k = 1:size(temparray,1)
        [path,seriesname] = fileparts(temparray{k,1}{1});
        if strcmp(temparray.Orientation{k},'HzLong')
            copyfile(temparray{k,1}{1},fullfile(newpath2,seriesname))
        else
            copyfile(temparray{k,1}{1},fullfile(newpath,seriesname));
        end
    end
end 

%% Perfusion Images
PerfTable = ImageTable(strcmp(ImageTable.ScanningSequence, 'GR'),:);

% Cardiac Number of Frames > 1
PerfTable = PerfTable(PerfTable.CardiacNumofFrames > 1,:);

% Contrast is Present
PerfIndices = strcmp(PerfTable.Contrast,'Missing') + strcmp(PerfTable.Contrast, 'No');
PerfIndices = abs(PerfIndices - 1);
PerfTable = PerfTable(logical(PerfIndices),:);

% InversionTime = 'Missing' in this case NaN
PerfTable = PerfTable(isnan(PerfTable.InversionTime),:);

% Sequence Name contains "tfi"
PerfTable = PerfTable(contains(PerfTable.SequenceName,'tfi'),:);

% Make Excel Table
writetable(PerfTable,'FinalPerfTable.xls')

%% Counts
% Patients with Cine
CineCount = unique(CineTable.PatientNumber);
fprintf('There are %d Patients with Cine',size(CineCount,1));

% Patients with Perfusion
PerfCount = unique(PerfTable.PatientNumber);
fprintf('There are %d Patients with Perfusion',size(PerfCount,1));