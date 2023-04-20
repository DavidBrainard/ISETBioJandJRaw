function runTask()

    % No waitbar
    ieSessionGet('waitbar');

    % Close all figures
    close all;

    % Parameters    
    params = struct(...
        'spdDataFile', 'BVAMS_White_Guns_At_Max.mat', ...           % Datafile containing the display SPDs
        'psfDataSubDir', 'FullVis_PSFs_10nm_Subject9', ...         % Subdir where the PSF data live
        'psfDataFile', '',...                                       % Datafile containing the PSF data
        'letterSizesNumExamined',  5, ...                           % How many sizes to use for sampling the psychometric curve
        'maxLetterSizeDegs', 0.2, ...                               % The maximum letter size in degrees of visual angle
        'sceneUpSampleFactor', 4, ...                               % Upsample scene, so that the pixel for the smallest scene is < cone aperture
        'mosaicIntegrationTimeSeconds', 500/1000, ...               % Integration time, here 300 msec
        'nTest', 512, ...                                            % Number of trial to use for computing Pcorrect
        'thresholdP', 0.781, ...                                    % Probability correct level for estimating threshold performance
        'visualizedPSFwavelengths', [], ... %380:10:770, ...        % Vector with wavelengths for visualizing the PSF. If set to empty[] there is no visualization.
        'visualizeDisplayCharacteristics', ~true, ...               % Flag, indicating whether to visualize the display characteristics
        'visualizeScene', ~true ...                                 % Flag, indicating whether to visualize one of the scenes
    );

    examinedPSFDataFiles = {...
        'Uniform_FullVis_LCA_zero_TCA_zero.mat' ...
        'Uniform_FullVis_LCA_low_TCA_zero.mat' ...
        'Uniform_FullVis_LCA_high_TCA_zero.mat' ...
        'Uniform_FullVis_LCA_zero_TCA_low.mat' ...
        'Uniform_FullVis_LCA_low_TCA_low.mat' ...
        'Uniform_FullVis_LCA_high_TCA_low.mat' ...
        'Uniform_FullVis_LCA_zero_TCA_high.mat' ...
        'Uniform_FullVis_LCA_low_TCA_high.mat' ...
        'Uniform_FullVis_LCA_high_TCA_high.mat' ...
        };


    theConeMosaic = [];
    for iPSF = 1:1% numel(examinedPSFDataFiles{1})
        tic
        params.psfDataFile = examinedPSFDataFiles{iPSF};
        theConeMosaic = runSimulation(params, theConeMosaic);
        toc
    end
    
end

function theConeMosaic = runSimulation(params, theConeMosaic)

    % Unpack simulation params
    letterSizesNumExamined = params.letterSizesNumExamined;
    maxLetterSizeDegs = params.maxLetterSizeDegs;
    mosaicIntegrationTimeSeconds = params.mosaicIntegrationTimeSeconds;
    nTest = params.nTest;
    thresholdP = params.thresholdP;
    spdDataFile = params.spdDataFile;
    psfDataFile = fullfile(params.psfDataSubDir, params.psfDataFile);
    
    % Generate optics from custom PSFs
    theCustomPSFOptics = generateCustomOptics(psfDataFile);

    % Visualization of the PSF stack
    if (~isempty(params.visualizedPSFwavelengths))
        psfRangeArcMin = 10;
        visualizePSFstack(theCustomPSFOptics, params.visualizedPSFwavelengths, psfRangeArcMin)
    end
    
    if (isempty(theConeMosaic))
        % Generate cone mosaic to use
        mosaicSizeDegs = maxLetterSizeDegs*1.25*[1 1];
        theConeMosaic = generateCustomConeMosaic(...
            mosaicIntegrationTimeSeconds, ...
            theCustomPSFOptics, ...
            mosaicSizeDegs);
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
            'visualizeAllComponents', ~true);

    % Plot the derived psychometric function
    pdfFileName = sprintf('Performance_%s_Reps_%d.pdf', strrep(params.psfDataFile, '.mat', ''), nTest);
    plotDerivedPsychometricFunction(questObj, threshold, fittedPsychometricParams, ...
        thresholdParameters, pdfFileName, 'xRange', [0.02 0.2]);

    pdfFileName = sprintf('Simulation_%s_Reps_%d.pdf', strrep(params.psfDataFile, '.mat', ''), nTest);
    visualizeSimulationResults(questObj, threshold, fittedPsychometricParams, ...
        thresholdParameters, tumblingEsceneEngines, theNeuralEngine, pdfFileName);

    % Export the results
    exportFileName = sprintf('Results_%s_Reps_%d.mat', strrep(params.psfDataFile, '.mat', ''), nTest);
    exportSimulation(questObj, threshold, fittedPsychometricParams, ...
        thresholdParameters, classifierPara, questEnginePara, ...
        tumblingEsceneEngines, theNeuralEngine, classifierEngine, ...
        exportFileName);

end

