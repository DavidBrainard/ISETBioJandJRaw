% Perform an identification task between the 4 E
%
%
%
%

%% Init
close all
clear

%% Basic parameters
% Cone mosaic integration time
mosaiIntegrationTime = 300/1000;

% How many cone mosaic response instances to compute
nTrials = 1024;

%% Configure the tumbling E scene engines
% 0 deg rotation E
letterRotationDegs = 0;
tumblingEsceneEngine0degs = createTumblingEsceneEngine(letterRotationDegs);

% 90 deg rotation E
letterRotationDegs = 90;
tumblingEsceneEngine90degs = createTumblingEsceneEngine(letterRotationDegs);

% 180 deg rotation E
letterRotationDegs = 180;
tumblingEsceneEngine180degs = createTumblingEsceneEngine(letterRotationDegs);

% 270 deg rotation E
letterRotationDegs = 270;
tumblingEsceneEngine270degs = createTumblingEsceneEngine(letterRotationDegs);

% Configure background scene engine
sceneParams = tumblingEsceneEngine0degs.sceneComputeFunction();
backgroundSceneParams = sceneParams;
backgroundSceneParams.chromaSpecification.foregroundRGB = sceneParams.chromaSpecification.backgroundRGB;
backgroundSceneEngine = createTumblingEsceneEngine(0, 'customSceneParams', backgroundSceneParams);

% Generate tumbling E scenes with size of 0.1 deg
sizeDegs = 0.1;
sceneSequence = tumblingEsceneEngine0degs.compute(sizeDegs);
the0degScene = sceneSequence{1};
sceneSequence = tumblingEsceneEngine90degs.compute(sizeDegs);
the90degScene = sceneSequence{1};
sceneSequence = tumblingEsceneEngine180degs.compute(sizeDegs);
the180degScene = sceneSequence{1};
sceneSequence = tumblingEsceneEngine270degs.compute(sizeDegs);
the270degScene = sceneSequence{1};

% Generate background scene with a size of 0.1 deg
sceneSequence = backgroundSceneEngine.compute(sizeDegs);
theBackgroundScene = sceneSequence{1};


% Generate the custom PSF optics
theOptics = generateCustomOptics();

% Generate a cone mosaic that is 20% larger than the stimulus
mosaicSizeDegs(1) = sceneGet(theBackgroundScene, 'wangular');
mosaicSizeDegs(2) = sceneGet(theBackgroundScene, 'hangular');
theConeMosaic = generateCustomConeMosaic(mosaiIntegrationTime, theOptics, mosaicSizeDegs*1.2);

%% Compute optical images for all scenes
the0degOpticalImage = oiCompute(theOptics, the0degScene);
the90degOpticalImage = oiCompute(theOptics, the90degScene);
the180degOpticalImage = oiCompute(theOptics, the180degScene);
the270degOpticalImage = oiCompute(theOptics, the270degScene);
theBackgroundOpticalImage = oiCompute(theOptics, theBackgroundScene);

%% Compute the cone mosaic responses to all optical images
coneExcitationsNoiseFree = containers.Map();
coneExcitationsNoisyInstances = containers.Map();
[coneExcitationsNoiseFree('0deg'), coneExcitationsNoisyInstances('0deg')] = ...
    theConeMosaic.compute(the0degOpticalImage, 'nTrials', nTrials);

[coneExcitationsNoiseFree('90deg'), coneExcitationsNoisyInstances('90deg')] = ...
    theConeMosaic.compute(the90degOpticalImage, 'nTrials', nTrials);

[coneExcitationsNoiseFree('180deg'), coneExcitationsNoisyInstances('180deg')] = ...
    theConeMosaic.compute(the180degOpticalImage, 'nTrials', nTrials);

[coneExcitationsNoiseFree('270deg'), coneExcitationsNoisyInstances('270deg')] = ...
    theConeMosaic.compute(the270degOpticalImage, 'nTrials', nTrials);

% Compute the cone mosaic response to the background image
[coneExcitationsNoiseFree('null'), coneExcitationsNoisyInstances('null')] = ...
    theConeMosaic.compute(theBackgroundOpticalImage, 'nTrials', nTrials);


%% Transform cone excitations to cone modulations
coneModulationsNoiseFree = containers.Map();
coneModulationsNoisyInstances = containers.Map();
theKeys = keys(coneExcitationsNoiseFree);

for iKey = 1:numel(theKeys)

    theKey = theKeys{iKey};

    coneModulationsNoiseFree(theKey) = excitationsToModulations(...
        coneExcitationsNoiseFree(theKey), coneExcitationsNoiseFree('null'));

    coneModulationsNoisyInstances(theKey) = excitationsToModulations(...
        coneExcitationsNoisyInstances(theKey), coneExcitationsNoiseFree('null'));
end


%% SNR analysis (based on modulations)

theKeys = {'0deg', '90deg', '180deg', '270deg'};
colsNum = numel(theKeys);
rowsNum = numel(theKeys);
subplotPosVectors = NicePlot.getSubPlotPosVectors(...
     'rowsNum', rowsNum+1, ...
     'colsNum', colsNum+1, ...
     'heightMargin',  0.06, ...
     'widthMargin',    0.04, ...
     'leftMargin',     0.01, ...
     'rightMargin',    0.00, ...
     'bottomMargin',   0.05, ...
     'topMargin',      0.03);

hFig = figure();
set(hFig, 'Position', [10 10 1650 980], 'Color', [1 1 1]);
cMap = brewermap(1024, '*RdBu');
for iKey1 = 1:numel(theKeys)
    theKey1 = theKeys{iKey1};
    template = coneModulationsNoiseFree(theKey1);
    ax = subplot('Position', subplotPosVectors(1,iKey1+1).v);
    theConeMosaic.visualize('figureHandle', hFig, 'axesHandle', ax, ...
             'domain', 'degrees', ...
             'domainVisualizationLimits', max(theConeMosaic.sizeDegs)*0.5*[-1 1 -1 1], ...
             'domainVisualizationTicks', struct('x', -0.5:0.1:0.5, 'y', -0.5:0.1:0.5), ...
             'visualizedConeAperture', 'geometricArea', ...
             'crossHairsOnMosaicCenter', true, ...
             'activation', template, ...
             'activationColorMap', cMap, ...
             'activationRange', max(abs(template(:)))*[-1 1], ...
             'backgroundColor', [1 1 1], ...
             'noXLabel', true, ...
             'noYlabel', true, ...
             'crossHairsColor', [0 0 0], ...
             'backgroundColor', [0.75 0.75 0.75], ...
             'fontSize', 16, ...
             'plotTitle', 'cone mosaic' ...
             );
    ax = subplot('Position', subplotPosVectors(iKey1+1,1).v);
    theConeMosaic.visualize('figureHandle', hFig, 'axesHandle', ax, ...
             'domain', 'degrees', ...
             'domainVisualizationLimits', max(theConeMosaic.sizeDegs)*0.5*[-1 1 -1 1], ...
             'domainVisualizationTicks', struct('x', -0.5:0.1:0.5, 'y', -0.5:0.1:0.5), ...
             'visualizedConeAperture', 'geometricArea', ...
             'crossHairsOnMosaicCenter', true, ...
             'activation', template, ...
             'activationColorMap', cMap, ...
             'activationRange', max(abs(template(:)))*[-1 1], ...
             'backgroundColor', [1 1 1], ...
             'noXLabel', true, ...
             'noYlabel', true, ...
             'crossHairsColor', [0 0 0], ...
             'backgroundColor', [0.75 0.75 0.75], ...
             'fontSize', 16, ...
             'plotTitle', 'cone mosaic' ...
             );

    
    signal1Instances = coneModulationsNoisyInstances(theKey1);
    for iKey2 = 1:numel(theKeys)
        ax = subplot('Position', subplotPosVectors(iKey1+1, iKey2+1).v);
        theKey2 = theKeys{iKey2};
        signal2Instances = coneModulationsNoisyInstances(theKey2);
        snrAnalysis(signal1Instances, ...
            signal2Instances, ...
            template, ...
            sprintf('%s', theKey1), ...
            sprintf('%s', theKey2), ax, [0.75 1.25]);
        if (iKey1 < numel(theKeys))
            xlabel('');
        end
    end
end



%% Visualize responses
visualizeResponses = true;
if (visualizeResponses)
    % Visualize the optical image
    visualizeOpticalImage(the0degOpticalImage, ...
        'crossHairsAtOrigin', true, ...
        'displayRadianceMaps', false);
    
    % Visualize the cone mosaic and the cone modulations (noise-free, test stimulus)
    visualizeConeMosaicActivation(theConeMosaic, theOptics, ...
        coneExcitationsNoiseFree('270deg'), coneModulationsNoiseFree('270deg'), 'noise-free');
    
    
    % Visualize the cone mosaic and the cone modulations (noisy, test stimulus)
    visualizeConeMosaicActivation(theConeMosaic, theOptics, ...
        coneExcitationsNoisyInstances('180deg'), coneModulationsNoisyInstances('180deg'), 'noisy instance');
end

