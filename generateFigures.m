function generateFigures()

% Parameters    
params = struct(...
    'spdDataFile', 'BVAMS_White_Guns_At_Max.mat', ...           % Datafile containing the display SPDs
    'psfDataFile', '',...                                       % Datafile containing the PSF data
    'letterSizesNumExamined',  8, ...                           % How many sizes to use for sampling the psychometric curve
    'maxLetterSizeDegs', 0.4, ...                               % The maximum letter size in degrees of visual angle
    'sceneUpSampleFactor', 4, ...                               % Upsample scene, so that the pixel for the smallest scene is < cone aperture
    'mosaicIntegrationTimeSeconds', 500/1000, ...               % Integration time, here 300 msec
    'nTest', 2, ...                                            % Number of trial to use for computing Pcorrect
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

for iOptics = 1:numel(examinedPSFDataFiles)
    examinedPSFDataFile = examinedPSFDataFiles{iOptics};

    % Generate optics from custom PSFs
    theCustomPSFOptics = generateCustomOptics(examinedPSFDataFile);

    % Generate cone mosaic to use
    if (iOptics == 1)
        mosaicSizeDegs = params.maxLetterSizeDegs*1.25*[1 1];
        theConeMosaic = generateCustomConeMosaic(...
            params.mosaicIntegrationTimeSeconds, ...
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


    % Generate a customSceneParams struct from the defaultSceneParams
    % so we can set certain scene params of interest
    theSceneEngine = createTumblingEsceneEngine(0);
    customSceneParams = theSceneEngine.sceneComputeFunction();
    customSceneParams.yPixelsNumMargin = 100;
    customSceneParams.xPixelsNumMargin = 100;

    % Change upsample factor if we want smaller pixels
    customSceneParams.upSampleFactor = uint8(params.sceneUpSampleFactor);
       
    % Set the spdDataFile
    customSceneParams.spdDataFile = params.spdDataFile;
        
    orientationDegs = 0;
    tumblingEsceneEngine = createTumblingEsceneEngine(...
           orientationDegs, ...
           'customSceneParams', customSceneParams);

    % Generate background scene engine.params for the background scene
    sceneParams = tumblingEsceneEngine.sceneComputeFunction();
    backgroundSceneParams = sceneParams;
    backgroundSceneParams.chromaSpecification.foregroundRGB = sceneParams.chromaSpecification.backgroundRGB;
    backgroundSceneEngine = createTumblingEsceneEngine(orientationDegs, 'customSceneParams', backgroundSceneParams);

    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
           'rowsNum', 2, ...
           'colsNum', 3, ...
           'heightMargin',  0.08, ...
           'widthMargin',    0.04, ...
           'leftMargin',     0.03, ...
           'rightMargin',    0.00, ...
           'bottomMargin',   0.06, ...
           'topMargin',      0.02);

    sizesDegs = [0.06 0.08 0.1 0.2 0.35];
    for iSize = 1:numel(sizesDegs)
        desiredSizeDegs = sizesDegs(iSize);
        pdfFileName = sprintf('%s_%2.2fDegs.pdf', strrep(strrep(examinedPSFDataFile, 'Uniform_FullVis_', ''), '.mat', ''), desiredSizeDegs);
    
        visualizationSceneParams = customSceneParams;
        visualizationSceneParams.chromaSpecification.foregroundRGB = sceneParams.chromaSpecification.backgroundRGB;
        dataOut = backgroundSceneEngine.sceneComputeFunction(backgroundSceneEngine,desiredSizeDegs, visualizationSceneParams);
        theBackgroundScene = dataOut.sceneSequence{1};
        thebackgroundOI = oiCompute(theBackgroundScene, theNeuralEngine.neuralPipeline.optics);
        visualizationSceneParams = customSceneParams;
        dataOut = tumblingEsceneEngine.sceneComputeFunction(tumblingEsceneEngine,desiredSizeDegs, visualizationSceneParams);

        theTestScene = dataOut.sceneSequence{1};
        theOI = oiCompute(theTestScene, theNeuralEngine.neuralPipeline.optics);
    
        theNoiseFreeConeMosaicTestActivation = ...
                    theNeuralEngine.neuralPipeline.coneMosaic.compute(theOI, 'nTrials', 1);
    
        theNoiseFreeConeMosaicBackgroundActivation = ...
                    theNeuralEngine.neuralPipeline.coneMosaic.compute(thebackgroundOI, 'nTrials', 1);
    
        theConeMosaicModulation = 100*(theNoiseFreeConeMosaicTestActivation - theNoiseFreeConeMosaicBackgroundActivation)./theNoiseFreeConeMosaicBackgroundActivation;
        

        spatialSupportDegs = oiGet(theOI, 'spatial support', 'microns') / theNeuralEngine.neuralPipeline.coneMosaic.micronsPerDegree;
        spatialSupportX = squeeze(spatialSupportDegs(1,:,1));
        spatialSupportY = squeeze(spatialSupportDegs(:,1,2));
        % illuminance = (683 * binwidth) * irradianceE * vLambda
        theRetinalIlluminanceLux = oiGet(theOI, 'illuminance');
        theLMS = oiGet(theOI, 'lms');
        LconeRange = [min(min(theLMS(:,:,1))) max(max(theLMS(:,:,1)))];
        MconeRange = [min(min(theLMS(:,:,2))) max(max(theLMS(:,:,2)))];
        SconeRange = [min(min(theLMS(:,:,3))) max(max(theLMS(:,:,3)))];
    
        retinalIlluminanceRange = [min(theRetinalIlluminanceLux(:)) max(theRetinalIlluminanceLux(:))];

        domainVisualizationLimits = 0.3*0.5*[-1 1 -1 1];
        domainVisualizationTicks = struct('x', -0.2:0.1:0.2, 'y', -0.2:0.1:0.2);
        hFig = figure(1);
        clf;
        set(hFig, 'Position', [10 10 1650 960], 'Color', [1 1 1]);
    
        ax = subplot('Position', subplotPosVectors(1,1).v);
        imagesc(ax,spatialSupportX, spatialSupportY, squeeze(theLMS(:,:,3)));
        colormap(gray(1024));
        colorbar
        axis(ax, 'image');
        set(ax, 'XLim', domainVisualizationLimits(1:2), 'YLim', domainVisualizationLimits(3:4), ...
            'XTick', domainVisualizationTicks.x, 'YTick', domainVisualizationTicks.y, ...
            'CLim', SconeRange, 'fontSize', 18);
        grid(ax, 'on');
        title('S-cone activation');
        ylabel(ax, 'space (degrees)');
        xtickangle(ax, 0);
        ytickangle(ax, 0);

        ax = subplot('Position', subplotPosVectors(1,2).v);
        imagesc(ax,spatialSupportX, spatialSupportY, squeeze(theLMS(:,:,2)));
        colormap(gray(1024));
        colorbar
        axis(ax, 'image');
        set(ax, 'XLim', domainVisualizationLimits(1:2), 'YLim', domainVisualizationLimits(3:4), ...
            'XTick', domainVisualizationTicks.x, 'YTick', domainVisualizationTicks.y, 'YTickLabel', {}, ...
            'CLim', MconeRange, 'fontSize', 18);
        grid(ax, 'on');
        title('M-cone activation');
        xtickangle(ax, 0);
        ytickangle(ax, 0);

        ax = subplot('Position', subplotPosVectors(1,3).v);
        imagesc(ax,spatialSupportX, spatialSupportY, squeeze(theLMS(:,:,1)));
        colormap(gray(1024));
        colorbar
        axis(ax, 'image');
        set(ax, 'XLim', domainVisualizationLimits(1:2), 'YLim', domainVisualizationLimits(3:4), ...
            'XTick', domainVisualizationTicks.x, 'YTick', domainVisualizationTicks.y, 'YTickLabel', {}, ...
            'CLim', LconeRange, 'fontSize', 18);
        grid(ax, 'on');
        title('L-cone activation');
        xtickangle(ax, 0);
        ytickangle(ax, 0);



        ax = subplot('Position', subplotPosVectors(2,1).v);
        imagesc(ax,spatialSupportX, spatialSupportY, theRetinalIlluminanceLux);
        colormap(gray(1024));
        c = colorbar();
        c.Label.String = '(Lux)';
        axis(ax, 'image');
        set(ax, 'XLim', domainVisualizationLimits(1:2), 'YLim', domainVisualizationLimits(3:4), ...
            'XTick', domainVisualizationTicks.x, 'YTick', domainVisualizationTicks.y, ...
            'CLim', retinalIlluminanceRange, 'fontSize', 18);
        grid(ax, 'on');
        xlabel(ax, 'space (degrees)');
        ylabel(ax, 'space (degrees)');
        title(sprintf('retinal illuminance (%2.2f degs)', desiredSizeDegs));
        xtickangle(ax, 0);
        ytickangle(ax, 0);

        domainVisualizationTicks.y = [];
        ax = subplot('Position', subplotPosVectors(2,2).v);
        theNeuralEngine.neuralPipeline.coneMosaic.visualize(...
            'figureHandle', hFig, ...
            'axesHandle', ax, ...
            'domain', 'degrees', ...
            'verticalActivationColorBar', true, ...
            'domainVisualizationLimits', domainVisualizationLimits, ...
            'domainVisualizationTicks', domainVisualizationTicks, ...
            'noYLabel', true, ...
            'fontSize', 18, ...
            'backgroundColor', [0 0 0]);
        xtickangle(ax, 0);
        ytickangle(ax, 0);

        ax = subplot('Position', subplotPosVectors(2,3).v);
        theNeuralEngine.neuralPipeline.coneMosaic.visualize(...
            'figureHandle', hFig, ...
            'axesHandle', ax, ...
            'domain', 'degrees', ...
            'activation', theConeMosaicModulation, ...
            'activationRange', 20*[-1 1], ...
            'verticalActivationColorBar', true, ...
            'domainVisualizationLimits', domainVisualizationLimits, ...
            'domainVisualizationTicks', domainVisualizationTicks, ...
            'noYLabel', true, ...
            'plotTitle', sprintf('cone modulation (max: %2.1f%%)',max(abs(theConeMosaicModulation(:)))), ...
            'fontSize', 18, ...
            'backgroundColor', [0 0 0]);
        xtickangle(ax, 0);
        ytickangle(ax, 0);
        
        NicePlot.exportFigToPDF(pdfFileName, hFig, 300);
    end

end
end

