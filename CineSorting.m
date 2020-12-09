%% Cine Sorting
% Adapting Sevde's code in R

% Load Image Table
ImageTable = readtable('ImageTable.xls');

%% Currently used criteria for cine images
% Check Possible Contrast Values
ContrastOptions = unique(ImageTable.Contrast);

% Contrast = 'Missing' or 'No'
indices = strcmp(ImageTable.Contrast,'Missing') + strcmp(ImageTable.Contrast, 'No');
CineTable = ImageTable(logical(indices),:);

% InversionTime = 'Missing' in this case NaN
CineTable = CineTable(isnan(CineTable.InversionTime),:);

% Scanning Sequence = 'GR'
CineTable = CineTable(strcmp(CineTable.ScanningSequence, 'GR'),:);

% Sequence Name begins contains "tfi"
CineTable = CineTable(contains(CineTable.SequenceName,'tfi'),:);

%% Looking at the size of these images
% Seems to be two distinct populations
% The 100-200 is most likely the Short-Axis 3D + t cine
figure(1)
histogram(CineTable.NumberOfSlice_Frames)

% Patients with Cine
PatientCount = unique(CineTable.PatientNumber);
fprintf('There are %d Patients with Cine',size(PatientCount,1));