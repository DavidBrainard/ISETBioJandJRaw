% Perform a detection task between E and no E
%
%
%

%% Init
close all
clear
addpath(genpath(pwd))

%% Basic parameters
% Stimulus size & rotation
letterRotationDegs = 0;
letterSizePixels = 20;
scaleFactor = 1;
letterSizeDegs = 0.132*scaleFactor;

% Cone mosaic integration time
mosaiIntegrationTime = 30/1000;

% How many cone mosaic response instances to compute
nTrials = 1024;

%% Generate simulation components

% Generate the presentation display with a viewing distance such that
% each character, which is letterSizePixels tall, has the desired angular size: letterSizeDegs
plotCharacteristics = ~true;
thePresentationDisplay = generateBVAMSWhiteDisplay(...
    letterSizeDegs, letterSizePixels, plotCharacteristics);

% Generate the E scene with 0 deg rotation
[theTestScene, theBackgroundScene] = generateOptotypeScene(...
    thePresentationDisplay, 'E', letterRotationDegs, ...
    'visualizeScene', true);

% Generate the custom PSF optics
theOptics = generateCustomOptics();

% Generate a mosaic appropriate for the stimulus
theConeMosaic = generateCustomConeMosaic(mosaiIntegrationTime, ...
    theOptics, theBackgroundScene);

%% Compute
% Compute the optical image for the test scene
theTestOpticalImage = oiCompute(theOptics, theTestScene);

% Compute the optical image for the background scene
theBackgroundOpticalImage = oiCompute(theOptics, theBackgroundScene);

% Compute the cone mosaic response to the test image
[coneExcitationsTestNoiseFree, coneExcitationsTestNoisyInstances] = ...
    theConeMosaic.compute(theTestOpticalImage, 'nTrials', nTrials);

% Compute the cone mosaic response to the background image
[coneExcitationsBackgroundNoiseFree, coneExcitationsBackgroundNoisyInstances] = ...
    theConeMosaic.compute(theBackgroundOpticalImage, 'nTrials', nTrials);


%% Transform cone excitations to cone modulations
coneModulationsTestNoiseFree = excitationsToModulations(...
    coneExcitationsTestNoiseFree, coneExcitationsBackgroundNoiseFree);
coneModulationsTestNoisyInstances = excitationsToModulations(...
    coneExcitationsTestNoisyInstances, coneExcitationsBackgroundNoiseFree);
coneModulationsBackgroundNoisyInstances = excitationsToModulations(...
    coneExcitationsBackgroundNoisyInstances, coneExcitationsBackgroundNoiseFree);


%% Conduct template-based SNR analysis
hFig = figure();
set(hFig, 'Position', [10 10 1000 350], 'Color', [1 1 1]);
ax = subplot(1,2,1);
template = coneExcitationsTestNoiseFree;
snrAnalysis(coneExcitationsTestNoisyInstances, ...
            coneExcitationsBackgroundNoisyInstances, ...
            template, 'excitations (E)', 'null', ax, [0.9 1.1]);

ax = subplot(1,2,2);
template = coneModulationsTestNoiseFree;
snrAnalysis(coneModulationsTestNoisyInstances, ...
            coneModulationsBackgroundNoisyInstances, ...
            template, 'modulations (E)', 'null', ax, [-2 2]);


%% Estimate detection performance using a binary SVM classifier
% Partition the data to in-sample for training the SVM
% and out-of-sample for assessing performance
inSampleNullResponses = coneExcitationsBackgroundNoisyInstances(1:nTrials/2,:,:);
inSampleTestResponses = coneExcitationsTestNoisyInstances(1:nTrials/2,:,:);

outOfSampleNullResponses = coneExcitationsBackgroundNoisyInstances(nTrials/2+1:end,:,:);
outOfSampleTestResponses = coneExcitationsTestNoisyInstances(nTrials/2+1:end,:,:);


%% Set-up the classifier
% User-supplied computeFunction for the @responseClassifierEngine
classifierComputeFunction = @rcePcaSVMTAFC;
    
% User-supplied struct with params appropriate for the @responseClassifierEngine computeFunction
customClassifierParams = struct(...
        'PCAComponentsNum', 2, ...          % number of PCs used for feature set dimensionality reduction
        'crossValidationFoldsNum', 10, ...  % employ a 10-fold cross-validated linear 
        'kernelFunction', 'linear', ...     % linear
        'classifierType', 'svm' ...         % binary SVM classifier
        );

% Instantiate our responseClassifierEngine
theClassifierEngine = responseClassifierEngine(classifierComputeFunction, customClassifierParams);
   

% Train the binary classifier on the above NULL/TEST response set
trainingData = theClassifierEngine.compute('train',...
        inSampleNullResponses, ...
        inSampleTestResponses);

% Assess performance on the out-of-sample responses
% Run the classifier on the new response instances
predictedData = theClassifierEngine.compute('predict',...
        outOfSampleNullResponses, ...
        outOfSampleTestResponses);

plotClassifierResults(trainingData, predictedData);

%% Visualize
% Visualize the PSF stack
%sampledWavelengths = 375:25:700;
%psfRangeArcMin = 10;
%visualizePSFstack(theOptics, sampledWavelengths, psfRangeArcMin)

% Visualize the optical image
visualizeOpticalImage(theTestOpticalImage, ...
    'crossHairsAtOrigin', true, ...
    'displayRadianceMaps', false);

% Visualize the cone mosaic and the cone modulations (noise-free, test stimulus)
visualizeConeMosaicActivation(theConeMosaic, theOptics, ...
    coneExcitationsTestNoiseFree, coneModulationsTestNoiseFree, 'noise-free');


% Visualize the cone mosaic and the cone modulations (noisy, test stimulus)
visualizeConeMosaicActivation(theConeMosaic, theOptics, ...
    coneExcitationsTestNoisyInstances, coneModulationsTestNoisyInstances, 'noisy instance');

