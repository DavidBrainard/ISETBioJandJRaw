
% No waitbar
ieSessionGet('waitbar');

clear all;
close all;

% Tumbling E setup
orientations = [0 90 180 270];
maxLetterSizeDegs = 0.4;

% Generate optics from custom PSFs
theCustomPSFOptics = generateCustomOptics();

% Generate cone mosaic to use
mosaicSizeDegs = maxLetterSizeDegs*1.25*[1 1];
mosaicIntegrationTime = 300/1000;
theConeMosaic = generateCustomConeMosaic(...
    mosaicIntegrationTime, ...
    theCustomPSFOptics, ...
    mosaicSizeDegs);

%% Create neural response engine
%
% This calculations isomerizations in a patch of cone mosaic with Poisson
% noise, and includes optical blur.
neuralResponsEngineComputeFunction = @nrePhotopigmentExcitationsCmosaicSingleShot;
neuralParams = neuralResponsEngineComputeFunction();

% Instantiate the neural engine with the default params
theNeuralEngine = neuralResponseEngine(neuralResponsEngineComputeFunction, neuralParams);

% Update the neural pipeline with custom cone mosaic and custom PSF - based optics
theNeuralEngine.customNeuralPipeline(struct(...
          'coneMosaic', theConeMosaic, ...
          'optics', theCustomPSFOptics));

% Poisson n-way AFC
classifierEngine = responseClassifierEngineNWay(@rcePoissonNWay_OneStimPerTrial);

% Parameters associated with use of the Poisson classifier.
nTest = 512;
classifierPara = struct('trainFlag', 'none', ...
                        'testFlag', 'random', ...
                        'nTrain', 1, 'nTest', nTest);


%% Parameters for threshold estimation/quest engine
thresholdParameters = struct(...
    'maxParamValue', maxLetterSizeDegs, ...    % The maximum value of the examined param (letter size in degs)
    'logThreshLimitLow', 2.0, ...              % minimum log10(normalized param value)
    'logThreshLimitHigh', 0.0, ...             % maximum log10(normalized param value)
    'logThreshLimitDelta', 0.01, ...
    'slopeRangeLow', 1/20, ...
    'slopeRangeHigh', 500/20, ...
    'slopeDelta', 2/20, ...
    'thresholdCriterion', 0.60, ...
    'guessRate', 1/numel(orientations), ...
    'lapseRate', [0 0.02]);

% Measure the psychometric function for this many levels
letterSizesNumExamined = 8;

% Parameters for Quest
questEnginePara = struct( ...
    'qpPF',@qpPFWeibullLog, ...
    'minTrial', nTest*letterSizesNumExamined, ...
    'maxTrial', nTest*letterSizesNumExamined, ...
    'numEstimator', 1, ...
    'stopCriterion', 0.05);

% Generate scene engines for the tumbling E's (4 orientations)
tumblingEsceneEngines = cell(1,numel(orientations));
for iOri = 1:numel(orientations)
   tumblingEsceneEngines{iOri} = createTumblingEsceneEngine(orientations(iOri));
end

% Generate background scene engine.params for the background scene
sceneParams = tumblingEsceneEngines{1}.sceneComputeFunction();
backgroundSceneParams = sceneParams;
backgroundSceneParams.chromaSpecification.foregroundRGB = sceneParams.chromaSpecification.backgroundRGB;
backgroundSceneEngine = createTumblingEsceneEngine(orientations(1), 'customSceneParams', backgroundSceneParams);

% Compute psychometric function
[threshold, questObj, psychometricFunction, fittedPsychometricParams] = computeParameterThreshold(...
        tumblingEsceneEngines, theNeuralEngine, classifierEngine, ...
        classifierPara, thresholdParameters, questEnginePara, ...
        'visualizeAllComponents', true);

% Plot the derived psychometric function
plotDerivedPsychometricFunction(questObj, threshold, fittedPsychometricParams, thresholdParameters);

visualizeSimulationResults(questObj, threshold, fittedPsychometricParams, ...
    thresholdParameters, tumblingEsceneEngines, theNeuralEngine);

% Export the results
exportSimulation(questObj, threshold, fittedPsychometricParams, ...
    thresholdParameters, classifierPara, questEnginePara, ...
    tumblingEsceneEngines, theNeuralEngine, classifierEngine);
