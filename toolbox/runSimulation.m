function [theConeMosaic,threshold] = runSimulation(params, theConeMosaic)

    % Unpack simulation params
    letterSizesNumExamined = params.letterSizesNumExamined;
    maxLetterSizeDegs = params.maxLetterSizeDegs;
    mosaicIntegrationTimeSeconds = params.mosaicIntegrationTimeSeconds;
    nTest = params.nTest;
    thresholdP = params.thresholdP;
    spdDataFile = params.spdDataFile;
    psfDataFile = fullfile(params.psfDataSubDir, params.psfDataFile);
    
    % Generate optics from custom PSFs
    theCustomPSFOptics = generateCustomOptics(psfDataFile, params.customPupilDiameterMM, params.customLensAgeYears);

    % Visualization of the PSF stack
    if (~isempty(params.visualizedPSFwavelengths))
        psfRangeArcMin = 10;
        pdfFileName = sprintf('PSFSTack_%s_Reps_%d.pdf', strrep(params.psfDataFile, '.mat', ''), nTest);
        outputFiguresName = fullfile(params.outputFiguresDir,pdfFileName);
        visualizePSFstack(theCustomPSFOptics, params.visualizedPSFwavelengths, psfRangeArcMin, outputFiguresName);
    end
    
    if (isempty(theConeMosaic))
        % Generate cone mosaic to use
        mosaicSizeDegs = maxLetterSizeDegs*1.25*[1 1];
        theConeMosaic = generateCustomConeMosaic(...
            mosaicIntegrationTimeSeconds, ...
            theCustomPSFOptics, ...
            mosaicSizeDegs, ...
            'customMPD', params.customMacularPigmentDensity, ...
            'customConeDensities', params.customConeDensities);
    end

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
    classifierPara = struct('trainFlag', 'none', ...
                            'testFlag', 'random', ...
                            'nTrain', 1, 'nTest', nTest);

    % Tumbling E setup
    orientations = [0 90 180 270];
    
    %% Parameters for threshold estimation/quest engine
    thresholdParameters = struct(...
        'maxParamValue', maxLetterSizeDegs, ...    % The maximum value of the examined param (letter size in degs)
        'logThreshLimitLow', 2.0, ...              % minimum log10(normalized param value)
        'logThreshLimitHigh', 0.0, ...             % maximum log10(normalized param value)
        'logThreshLimitDelta', 0.01, ...
        'slopeRangeLow', 1/20, ...
        'slopeRangeHigh', 500/20, ...
        'slopeDelta', 2/20, ...
        'thresholdCriterion', thresholdP, ...
        'guessRate', 1/numel(orientations), ...
        'lapseRate', [0 0.02]);

    
    % Parameters for Quest
    questEnginePara = struct( ...
        'qpPF',@qpPFWeibullLog, ...
        'minTrial', nTest*letterSizesNumExamined, ...
        'maxTrial', nTest*letterSizesNumExamined, ...
        'numEstimator', 1, ...
        'stopCriterion', 0.05);

    % Generate a customSceneParams struct from the defaultSceneParams
    % so we can set certain scene params of interest
    theSceneEngine = createTumblingEsceneEngine(0);
    customSceneParams = theSceneEngine.sceneComputeFunction();
    customSceneParams.yPixelsNumMargin = 100;
    customSceneParams.xPixelsNumMargin = 100;

    % Change upsample factor if we want smaller pixels
    customSceneParams.upSampleFactor = uint8(params.sceneUpSampleFactor);
       
    % Set the spdDataFile
    customSceneParams.spdDataFile = spdDataFile;
        
    if (params.visualizeDisplayCharacteristics)
        visualizationSceneParams = customSceneParams;
        visualizationSceneParams.plotDisplayCharacteristics = true;
        theSceneEngine.sceneComputeFunction(theSceneEngine,0.3, visualizationSceneParams);
    end
    
    if (params.visualizeScene)
        visualizationSceneParams = customSceneParams;
        visualizationSceneParams.visualizeScene = true;
        theSceneEngine.sceneComputeFunction(theSceneEngine,0.3, visualizationSceneParams);
    end 
    clear 'theSceneEngine';
    
    % Generate scene engines for the tumbling E's (4 orientations)
    tumblingEsceneEngines = cell(1,numel(orientations));
    for iOri = 1:numel(orientations)
       tumblingEsceneEngines{iOri} = createTumblingEsceneEngine(...
           orientations(iOri), ...
           'customSceneParams', customSceneParams);
    end

    % Generate background scene engine.params for the background scene
    sceneParams = tumblingEsceneEngines{1}.sceneComputeFunction();
    backgroundSceneParams = sceneParams;
    backgroundSceneParams.chromaSpecification.foregroundRGB = sceneParams.chromaSpecification.backgroundRGB;
    backgroundSceneEngine = createTumblingEsceneEngine(orientations(1), 'customSceneParams', backgroundSceneParams);

    % Compute psychometric function for the 4AFC paradigm with the 4 E scenes
    [threshold, questObj, psychometricFunction, fittedPsychometricParams] = computeParameterThreshold(...
            tumblingEsceneEngines, theNeuralEngine, classifierEngine, ...
            classifierPara, thresholdParameters, questEnginePara, ...
            'visualizeAllComponents', ~true, ...
            'beVerbose', true);

    % Plot the derived psychometric function and other things.  The lower
    % level routines put this in ISETBioJandJRootPath/figures.
    pdfFileName = sprintf('Performance_%s_Reps_%d.pdf', strrep(params.psfDataFile, '.mat', ''), nTest);
    plotDerivedPsychometricFunction(questObj, threshold, fittedPsychometricParams, ...ISETBio
        thresholdParameters, fullfile(params.outputFiguresDir,pdfFileName), 'xRange', [0.02 0.2]);  
    if (params.visualEsOnMosaic)
        pdfFileName = sprintf('Simulation_%s_Reps_%d.pdf', strrep(params.psfDataFile, '.mat', ''), nTest);
        visualizeSimulationResults(questObj, threshold, fittedPsychometricParams, ...
            thresholdParameters, tumblingEsceneEngines, theNeuralEngine, ...
            fullfile(params.outputFiguresDir,pdfFileName));
    end

    % Export the results
    exportFileName = sprintf('Results_%s_Reps_%d.mat', strrep(params.psfDataFile, '.mat', ''), nTest);
    if (~isempty(params.customMacularPigmentDensity))
        exportFileName = strrep(exportFileName, '.mat', sprintf('_MPD_%2.2f.mat', params.customMacularPigmentDensity));
    end
    if (~isempty(params.customPupilDiameterMM))
        exportFileName = strrep(exportFileName, '.mat', sprintf('_PupilDiamMM_%2.2f.mat', params.customPupilDiameterMM));
    end
    if (~isempty(params.customConeDensities))
        exportFileName = strrep(exportFileName, '.mat', sprintf('_cones_%2.2f_%2.2f_%2.2f.mat', params.customConeDensities(1), params.customConeDensities(2), params.customConeDensities(3)));
    end
    if (~isempty(params.customLensAgeYears))
        exportFileName = strrep(exportFileName, '.mat', sprintf('_lensAge_%d.mat', params.customLensAgeYears));
    end

    fprintf('Saving data to %s\n', fullfile(params.outputResultsDir,exportFileName));
    exportSimulation(questObj, threshold, fittedPsychometricParams, ...
        thresholdParameters, classifierPara, questEnginePara, ...
        tumblingEsceneEngines, theNeuralEngine, classifierEngine, ...
        fullfile(params.outputResultsDir,exportFileName));

    % Append the params struct
    save(fullfile(params.outputResultsDir,exportFileName),'params', '-append');
end

