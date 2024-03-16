%% Plot individual psychometric function output
%
% By: Derek Nankivil, 4/18/2023
%
%
%% Initialize

save_rendered = 0;
EXT = 'mat';
datpath_ini = 'Z:\ISETBioJandJ-main\results';
[datfilename,datpath] = uigetfile([datpath_ini '\*.' EXT],'Select the data file');
longname = [datpath datfilename];
load(longname);

%[data] = F_Load_Data_Table('Z:\ISETBioJandJ-main\results','EXT','mat');

params = struct(...
        'spdDataFile', 'BVAMS_White_Guns_At_Max.mat', ...           % Datafile containing the display SPDs
        'psfDataSubDir', 'FullVis_PSFs', ...                        % Subdir where the PSF data live
        'psfDataFile', '',...                                       % Datafile containing the PSF data
        'letterSizesNumExamined',  5, ...                           % How many sizes to use for sampling the psychometric curve
        'maxLetterSizeDegs', 0.2, ...                               % The maximum letter size in degrees of visual angle
        'sceneUpSampleFactor', 4, ...                               % Upsample scene, so that the pixel for the smallest scene is < cone aperture
        'mosaicIntegrationTimeSeconds', 500/1000, ...               % Integration time, here 300 msec
        'nTest', 512, ...                                           % Number of trial to use for computing Pcorrect
        'thresholdP', 0.781, ...                                    % Probability correct level for estimating threshold performance
        'visualizedPSFwavelengths', 380:20:770, ...                 % Vector with wavelengths for visualizing the PSF. If set to empty[] there is no visualization.
        'visualizeDisplayCharacteristics', ~true, ...               % Flag, indicating whether to visualize the display characteristics
        'visualizeScene', ~true ...                                 % Flag, indicating whether to visualize one of the scenes
    );

% Unpack simulation params
letterSizesNumExamined = params.letterSizesNumExamined;
maxLetterSizeDegs = params.maxLetterSizeDegs;
mosaicIntegrationTimeSeconds = params.mosaicIntegrationTimeSeconds;
nTest = params.nTest;
thresholdP = params.thresholdP;
spdDataFile = params.spdDataFile;
psfDataFile = fullfile(params.psfDataSubDir, params.psfDataFile);

% Unpack simulation results
% questObj = data.questObj;
% threshold = data.threshold;
% fittedPsychometricParams = data.threshold;
% thresholdParameters = data.thresholdParameters;

%% Plot data

%pdfFileName = sprintf('Performance_%s_Reps_%d.pdf', strrep(params.psfDataFile, '.mat', ''), nTest);
pdfFileName = strrep(datpath,datpath_ini,'');
pdfFileName = strrep(pdfFileName,'\','');
pdfFileName = [pdfFileName '_' strrep(datfilename,EXT,'') 'pdf'];
plotDerivedPsychometricFunction(questObj, threshold, fittedPsychometricParams, ...
    thresholdParameters, pdfFileName, 'xRange', [0.02 0.2]);

if save_rendered
    imgFileName = strrep(pdfFileName,'.pdf','.png');
    saveas(gcf,imgFileName);
end