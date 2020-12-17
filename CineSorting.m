%% Cine Sorting
% Adapting Sevde's code to MATLAB

% Load Image Table
ImageTable = readtable('ImageTable.xls');

%% Cine Images
% Steady-state free precession MRI (SSFP) is a type of gradient echo MRI pulse sequence in which a steady, 
% residual transverse magnetization (Mxy) is maintained between successive cycles. The sequence is noted 
% for its superiority in dynamic/cine assessment of cardiac function.

% Scanning Sequence = 'GR'
CineTable = ImageTable(strcmp(ImageTable.ScanningSequence, 'GR'),:);

% Cardiac Number of Frames > 1
CineTable = CineTable(CineTable.CardiacNumofFrames > 1,:);

% Contrast = 'Missing' or 'No'
Cineindices = strcmp(CineTable.Contrast,'Missing') + strcmp(CineTable.Contrast, 'No');
CineTable = CineTable(logical(Cineindices),:);

% InversionTime = 'Missing' in this case NaN
CineTable = CineTable(isnan(CineTable.InversionTime),:);

% Sequence Name contains "tfi"
CineTable = CineTable(contains(CineTable.SequenceName,'tfi'),:);


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