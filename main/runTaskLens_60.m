% This script calculates visual acuity for a set of specified PSFs. 
%
% As configured, it reproduces for Subject 9 the results in Figure X of the
% paper.
%
% To run this script, you need Matlab, some of its toolboxes, and the
% following on your path.
%
%     ISETBioCSFGenerator, branch ChromAbPaper, https://github.com/isetbio/ISETBioCSFGenerator.git
%     isetbio, branch ChromAbPaper, https://github.com/isetbio/isetbio.git
%     mQUESTPlus, https://github.com/brainardlab/mQUESTPlus.git
%     Palamedes Toolbox, https://palamedestoolbox.org, version 1.8.2.
%        [This may work with more recent versions, but we run against 1.8.2.
%        You may need to write to the Palamedes team to get that version.]

function runTask()
    % Clear out
    clear; close all;

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

    % Parameters. These control many aspects of what gets done, particular the subject. 
    params = struct(...
        'spdDataFile', 'BVAMS_White_Guns_At_Max.mat', ...           % Datafile containing the display SPDs.  Change to BVAMS_White_Guns_At_Max_HL.mat for high luminance condition.
        'psfDataSubDir', 'FullVis_PSFs_20nm_Subject9', ...          % Subdir where the PSF data live
        'psfDataFile', '',...                                       % Datafile containing the PSF data
        'letterSizesNumExamined',  9, ...                           % How many sizes to use for sampling the psychometric curve (9 used in the paper)
        'maxLetterSizeDegs', 0.2, ...                               % The maximum letter size in degrees of visual angle
        'sceneUpSampleFactor', 4, ...                               % Upsample scene, so that the pixel for the smallest scene is < cone aperture
        'mosaicIntegrationTimeSeconds', 500/1000, ...               % Integration time, here 500 msec
        'nTest', 512, ...                                           % Number of trial to use for computing Pcorrect
        'thresholdP', 0.781, ...                                    % Probability correct level for estimating threshold performance
        'customLensAgeYears', 60, ...                               % Lens age in years (valid range: 20-80), or empty to use the default age        
        'customMacularPigmentDensity', [], ...                      % Cstom MPD, or empty to use the default; example, 0.4
        'customConeDensities', [], ...                              % Custom L-M-S ratio or empty to use default; example [0.6 0.3 0.1]
        'customPupilDiameterMM', [], ...                            % Custom pupil diameter in MM or empty to use the value from the psfDataFile
        'visualizedPSFwavelengths', [], ...                         % Vector with wavelengths for visualizing the PSF. If set to empty[] there is no visualization; example 400:20:700
        'visualizeDisplayCharacteristics', ~true, ...               % Flag, indicating whether to visualize the display characteristics
        'visualizeScene', ~true, ...                                % Flag, indicating whether to visualize one of the scenes
        'visualEsOnMosaic', ~true ...                               % Flag, indicating whether to visualize E's against mosaic as function of their size
    );

    % For each PSF file, we also tabulate the amount of LCA in D, and TCA
    % in microns, rounded.
    % 
    % This code as is runs many but not all of the LCA/TCA combinations
    % reported in the paper.  Add in the rest of the PSF data files if you
    % want them all.
    examinedPSFDataFiles = {...
        'Uniform_FullVis_LCA_0_TCA_Hz0_TCA_Vt0.mat'     , 0, 0 ; ...
        'Uniform_FullVis_LCA_1278_TCA_Hz0_TCA_Vt0.mat'  , 1.3, 0 ; ...
        'Uniform_FullVis_LCA_2203_TCA_Hz0_TCA_Vt0.mat'  , 2.2, 0 ; ...
        'Uniform_FullVis_LCA_2665_TCA_Hz0_TCA_Vt0.mat'  , 2.7, 0 ; ...
        'Uniform_FullVis_LCA_3590_TCA_Hz0_TCA_Vt0.mat'  , 3.6, 0 ; ...

        'Uniform_FullVis_LCA_0_TCA_Hz200_TCA_Vt400.mat'    , 0, 0.4 ; ...
        'Uniform_FullVis_LCA_1278_TCA_Hz200_TCA_Vt400.mat' , 1.3, 0.4 ; ...
        'Uniform_FullVis_LCA_2203_TCA_Hz200_TCA_Vt400.mat' , 2.2, 0.4 ; ...
        'Uniform_FullVis_LCA_2665_TCA_Hz200_TCA_Vt400.mat' , 2.7, 0.4 ; ...
        'Uniform_FullVis_LCA_3590_TCA_Hz200_TCA_Vt400.mat' , 3.6, 0.4 ; ...

        'Uniform_FullVis_LCA_0_TCA_Hz790_TCA_Vt1580.mat'    , 0, 1.58 ; ...
        'Uniform_FullVis_LCA_1278_TCA_Hz790_TCA_Vt1580.mat' , 1.3, 1.58 ; ...
        'Uniform_FullVis_LCA_2203_TCA_Hz790_TCA_Vt1580.mat' , 2.2, 1.58 ; ...
        'Uniform_FullVis_LCA_2665_TCA_Hz790_TCA_Vt1580.mat' , 2.7, 1.58 ; ...
        'Uniform_FullVis_LCA_3590_TCA_Hz790_TCA_Vt1580.mat' , 3.6, 1.58 ; ...

        'Uniform_FullVis_LCA_0_TCA_Hz1380_TCA_Vt2760.mat'    , 0, 2.76 ; ...
        'Uniform_FullVis_LCA_1278_TCA_Hz1380_TCA_Vt2760.mat' , 1.3, 2.76 ; ...
        'Uniform_FullVis_LCA_2203_TCA_Hz1380_TCA_Vt2760.mat' , 2.2, 2.76 ; ...
        'Uniform_FullVis_LCA_2665_TCA_Hz1380_TCA_Vt2760.mat' , 2.7, 2.76 ; ...
        'Uniform_FullVis_LCA_3590_TCA_Hz1380_TCA_Vt2760.mat' , 3.6, 2.76 ; ...

        'Uniform_FullVis_LCA_0_TCA_Hz1970_TCA_Vt3940.mat'     , 0, 3.94 ; ...
        'Uniform_FullVis_LCA_1278_TCA_Hz1970_TCA_Vt3940.mat' , 1.3, 3.94 ; ...
        'Uniform_FullVis_LCA_2203_TCA_Hz1970_TCA_Vt3940.mat' , 2.2, 3.94 ; ...
        'Uniform_FullVis_LCA_2665_TCA_Hz1970_TCA_Vt3940.mat' , 2.7, 3.94 ; ...
        'Uniform_FullVis_LCA_3590_TCA_Hz1970_TCA_Vt3940.mat' , 3.6, 3.94 ; ...

        'Uniform_FullVis_LCA_0_TCA_Hz3150_TCA_Vt6300.mat'    , 0, 6.3 ; ...
        'Uniform_FullVis_LCA_1278_TCA_Hz3150_TCA_Vt6300.mat' , 1.3, 6.3 ; ...
        'Uniform_FullVis_LCA_2203_TCA_Hz3150_TCA_Vt6300.mat' , 2.2, 6.3 ; ...
        'Uniform_FullVis_LCA_2665_TCA_Hz3150_TCA_Vt6300.mat' , 2.7, 6.3 ; ...
        'Uniform_FullVis_LCA_3590_TCA_Hz3150_TCA_Vt6300.mat' , 3.6, 6.3 ...
        };

    % Loop over all the specified PSFs.  This loop saves the data out for
    % each PSF, as well as accumulates the threshold for each.
    for iPSF = 1:size(examinedPSFDataFiles,1)
        theConeMosaic = [];
        tempParams = params;
        tempParams.psfDataFile = examinedPSFDataFiles{iPSF,1};
        LCA(iPSF) = examinedPSFDataFiles{iPSF,2};
        TCA(iPSF) = examinedPSFDataFiles{iPSF,3};
        [theConeMosaic{iPSF},threshold(iPSF)] = runSimulation(tempParams, theConeMosaic);
        logMAR(iPSF) = log10(threshold(iPSF)*60/5);
    end

    % Save summary,  This allows examination of the numbers and/or
    % replotting.
    summaryFileName = sprintf('Summary_%s.mat', strrep(params.psfDataSubDir, '.mat', ''));
    if (~isempty(params.customMacularPigmentDensity))
        summaryFileName = strrep(summaryFileName, '.mat', sprintf('_MPD_%2.2f.mat', params.customMacularPigmentDensity));
    end
    if (~isempty(params.customPupilDiameterMM))
        summaryFileName = strrep(summaryFileName, '.mat', sprintf('_pupilDiamMM_%2.2f.mat', params.customPupilDiameterMM));
    end
    if (~isempty(params.customConeDensities))
        summaryFileName = strrep(summaryFileName, '.mat', sprintf('_cones_%2.2f_%2.2f_%2.2f.mat', params.customConeDensities(1), params.customConeDensities(2), params.customConeDensities(3)));
    end
    if (~isempty(params.customLensAgeYears))
        summaryFileName = strrep(summaryFileName, '.mat', sprintf('_lensAge_%d.mat', params.customLensAgeYears));
    end
    save(fullfile(ISETBioJandJRootPath,'results',summaryFileName),"examinedPSFDataFiles","threshold","logMAR","LCA","TCA","theConeMosaic");
    
    % Make and save a figure of what happened. This is not publication
    % quality, but does match up with the key figure in the paper in tersm
    % of its format. Values may differ from run to run because of
    % differeing random number sequences.
    LCAValues = unique(LCA);
    TCAValues = unique(TCA);
    legendStr = {};
    summaryFig = figure; clf;
    set(gcf,'Position',[100 100 1500 750]);
    subplot(1,2,1); hold on;
    for tt = 1:length(TCAValues)
        theColor(tt,:) = [1-tt/length(TCAValues) tt/length(TCAValues) 0];
        index = find(TCA == TCAValues(tt));
        plot(LCA(index),logMAR(index),'o-','Color',theColor(tt,:),'MarkerFaceColor',theColor(tt,:),'MarkerSize',10,'LineWidth',2);
        legendStr = [legendStr(:)' {['TCA ' num2str(TCAValues(tt))]}];
    end
    ylim([-0.35 0.15]);
    xlabel('LCA (D)');
    ylabel('VA (logMAR)');
    legend(legendStr);
    titleStr = LiteralUnderscore(strrep(summaryFileName,'.mat',''));
    title(titleStr);

    % This panel is the VA difference plot.
    subplot(1,2,2); hold on;
    for tt = 1:length(TCAValues)
        index = find(TCA == TCAValues(tt));
        tempLCA = LCA(index);
        tempLogMAR = logMAR(index);
        index1 = find(tempLCA == 0);
        plot(LCA(index),-(logMAR(index)-tempLogMAR(index1)),'o-','Color',theColor(tt,:),'MarkerFaceColor',theColor(tt,:),'MarkerSize',10,'LineWidth',2);
    end
    ylim([-0.35 0.15]);
    xlabel('LCA (D)');
    ylabel('VA (logMAR)');
    legend(legendStr);
    titleStr = LiteralUnderscore(strrep(summaryFileName,'.mat',''));
    title(titleStr);
    NicePlot.exportFigToPDF(strrep(fullfile(ISETBioJandJRootPath,'figures',summaryFileName),'.mat','.pdf'),summaryFig,300);
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
    theCustomPSFOptics = generateCustomOptics(psfDataFile, params.customPupilDiameterMM, params.customLensAgeYears);

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
    plotDerivedPsychometricFunction(questObj, threshold, fittedPsychometricParams, ...ISETBio
        thresholdParameters, pdfFileName, 'xRange', [0.02 0.2]);  
    if (params.visualEsOnMosaic)
        pdfFileName = sprintf('Simulation_%s_Reps_%d.pdf', strrep(params.psfDataFile, '.mat', ''), nTest);
        visualizeSimulationResults(questObj, threshold, fittedPsychometricParams, ...
            thresholdParameters, tumblingEsceneEngines, theNeuralEngine, pdfFileName);
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

    fprintf('Saving data to %s\n', fullfile(ISETBioJandJRootPath,'results',exportFileName));
    exportSimulation(questObj, threshold, fittedPsychometricParams, ...
        thresholdParameters, classifierPara, questEnginePara, ...
        tumblingEsceneEngines, theNeuralEngine, classifierEngine, ...
        fullfile(ISETBioJandJRootPath,'results',exportFileName));

    % Append the params struct
    save(fullfile(ISETBioJandJRootPath,'results',exportFileName), 'params', '-append');
end

