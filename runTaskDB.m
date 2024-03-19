function runTask()

    % No waitbar
    ieSessionGet('waitbar');

    % Close all figures
    close all;

    % Make sure figures and results directories exist so that output writes
    % don't fail
    rootPath = ISETBioJandJRootPath;
    if (~exist(fullfile(rootPath,'figures'),'dir'))
        mkdir(fullfile(rootPath,'figures'));
    end
    if (~exist(fullfile(rootPath,'results'),'dir'))
        mkdir(fullfile(rootPath,'results'));
    end

    % Parameters    
    params = struct(...
        'spdDataFile', 'BVAMS_White_Guns_At_Max.mat', ...           % Datafile containing the display SPDs
        'psfDataSubDir', 'FullVis_PSFs_20nm_Subject9', ...          % Subdir where the PSF data live
        'psfDataFile', '',...                                       % Datafile containing the PSF data
        'letterSizesNumExamined',  5, ...                           % How many sizes to use for sampling the psychometric curve
        'maxLetterSizeDegs', 0.2, ...                               % The maximum letter size in degrees of visual angle
        'sceneUpSampleFactor', 4, ...                               % Upsample scene, so that the pixel for the smallest scene is < cone aperture
        'mosaicIntegrationTimeSeconds', 500/1000, ...               % Integration time, here 500 msec
        'nTest', 512, ...                                           % Number of trial to use for computing Pcorrect
        'thresholdP', 0.781, ...                                    % Probability correct level for estimating threshold performance
        'customMacularPigmentDensity', [], ...                      % Cstom MPD, or empty to use the default; example, 0.4
        'customConeDensities', [], ...                              % Custom L-M-S ratio or empty to use default; example [0.6 0.3 0.1]
        'customPupilDiameterMM', [], ...                            % Custom pupil diameter in MM or empty to use the value from the psfDataFile
        'visualizedPSFwavelengths', [], ...                         % Vector with wavelengths for visualizing the PSF. If set to empty[] there is no visualization; example 400:20:700
        'visualizeDisplayCharacteristics', ~true, ...               % Flag, indicating whether to visualize the display characteristics
        'visualizeScene', ~true, ...                                % Flag, indicating whether to visualize one of the scenes
        'visualEsOnMosaic', ~true ...                               % Flag, indicating whether to visualize E's against mosaic as function of their size
    );

    examinedPSFDataFiles = {...
        'Uniform_FullVis_LCA_0_TCA_Hz0_TCA_Vt0.mat' , 0, 0 ; ...
        'Uniform_FullVis_LCA_2203_TCA_Hz0_TCA_Vt0.mat'  , 2.2, 0 ; ...
        'Uniform_FullVis_LCA_2665_TCA_Hz0_TCA_Vt0.mat'  , 2.7, 0 ; ...
        'Uniform_FullVis_LCA_3590_TCA_Hz0_TCA_Vt0.mat'  , 3.6, 0 ; ...

        'Uniform_FullVis_LCA_0_TCA_Hz200_TCA_Vt400.mat' , 0, 0.4 ; ...
        'Uniform_FullVis_LCA_2203_TCA_Hz200_TCA_Vt400.mat' , 2.2, 0.4 ; ...
        'Uniform_FullVis_LCA_2665_TCA_Hz200_TCA_Vt400.mat' , 2.7, 0.4 ; ...
        'Uniform_FullVis_LCA_3590_TCA_Hz200_TCA_Vt400.mat' , 3.6, 0.4 ; ...

        'Uniform_FullVis_LCA_0_TCA_Hz1380_TCA_Vt2760.mat' , 0, 2.76 ; ...
        'Uniform_FullVis_LCA_2203_TCA_Hz1380_TCA_Vt2760.mat' , 2.2, 2.76 ; ...
        'Uniform_FullVis_LCA_2665_TCA_Hz1380_TCA_Vt2760.mat' , 2.7, 2.76 ; ...
        'Uniform_FullVis_LCA_3590_TCA_Hz1380_TCA_Vt2760.mat' , 3.6, 2.76 ; ...

        'Uniform_FullVis_LCA_0_TCA_Hz3150_TCA_Vt6300.mat' , 0, 6.3 ; ...
        'Uniform_FullVis_LCA_2203_TCA_Hz3150_TCA_Vt6300.mat' , 2.2, 6.3 ; ...
        'Uniform_FullVis_LCA_2665_TCA_Hz3150_TCA_Vt6300.mat' , 2.7, 6.3 ; ...
        'Uniform_FullVis_LCA_3590_TCA_Hz3150_TCA_Vt6300.mat' , 3.6, 6.3 ...
        };


    for iPSF = 1:size(examinedPSFDataFiles,1)
        theConeMosaic = [];
        tempParams = params;
        tempParams.psfDataFile = examinedPSFDataFiles{iPSF,1};
        LCA(iPSF) = examinedPSFDataFiles{iPSF,2};
        TCA(iPSF) = examinedPSFDataFiles{iPSF,3};
        [theConeMosaic{iPSF},threshold(iPSF)] = runSimulation(tempParams, theConeMosaic);
        logMAR(iPSF) = log10(threshold(iPSF)*60/5);
    end
    
end

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
    theCustomPSFOptics = generateCustomOptics(psfDataFile, params.customPupilDiameterMM);

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
    plotDerivedPsychometricFunction(questObj, threshold, fittedPsychometricParams, ...
        thresholdParameters, pdfFileName, 'xRange', [0.02 0.2]);
    if (params.visualEsOnMosaic)
        pdfFileName = sprintf('Simulation_%s_Reps_%d.pdf', strrep(params.psfDataFile, '.mat', ''), nTest);
        visualizeSimulationResults(questObj, threshold, fittedPsychometricParams, ...
            thresholdParameters, tumblingEsceneEngines, theNeuralEngine, pdfFileName);
    end

    % Export the results
    exportFileName = sprintf('Results_%s_Reps_%d.mat', strrep(params.psfDataFile, '.mat', ''), nTest);

    if (~isempty(params.customMacularPigmentDensity))
        exportFileName = strrep(exportFileName, '.mat', sprintf('_customMPD_%2.2f.mat', params.customMacularPigmentDensity));
    end
    if (~isempty(params.customPupilDiameterMM))
        exportFileName = strrep(exportFileName, '.mat', sprintf('_customPupilDiamMM_%2.2f.mat', params.customPupilDiameterMM));
    end
    if (~isempty(params.customConeDensities))
        exportFileName = strrep(exportFileName, '.mat', sprintf('_customConeDensities_%2.2f_%2.2f_%2.2f.mat', params.customConeDensities(1), params.customConeDensities(2), params.customConeDensities(3)));
    end

    fprintf('Saving data to %s\n', fullfile(ISETBioJandJRootPath,'results',exportFileName));
    exportSimulation(questObj, threshold, fittedPsychometricParams, ...
        thresholdParameters, classifierPara, questEnginePara, ...
        tumblingEsceneEngines, theNeuralEngine, classifierEngine, ...
        exportFileName);

    % Append the params struct
    save(fullfile(ISETBioJandJRootPath,'results',exportFileName), 'params', '-append');
end

