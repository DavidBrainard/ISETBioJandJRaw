function generateFigures()

% Parameters    
params = struct(...
    'spdDataFile', 'BVAMS_White_Guns_At_Max.mat', ...           % Datafile containing the display SPDs
    'psfDataFile', '',...                                       % Datafile containing the PSF data
    'letterSizesNumExamined',  8, ...                           % How many sizes to use for sampling the psychometric curve
    'maxLetterSizeDegs', 0.4, ...                               % The maximum letter size in degrees of visual angle
    'sceneUpSampleFactor', 4, ...                               % Upsample scene, so that the pixel for the smallest scene is < cone aperture
    'mosaicIntegrationTimeSeconds', 500/1000, ...               % Integration time, here 300 msec
    'nTest', 128, ...                                            % Number of trial to use for computing Pcorrect
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

examinedPSFDataFiles = {...
    'Uniform_FullVis_LCA_low_TCA_high.mat' ...
    };

psfDataSubDir = 'FullVis_PSFs_10nm_Subject9';

for iOptics = 1:numel(examinedPSFDataFiles)
    examinedPSFDataFile = fullfile(psfDataSubDir, examinedPSFDataFiles{iOptics});

    if (1==2)
        resultsDataFileName = sprintf('Results_%s_Reps_%d.mat', strrep(examinedPSFDataFile, '.mat', ''), params.nTest);
        load(resultsDataFileName, ...
                'fittedPsychometricParams','questObj', 'thresholdParameters', 'threshold');
        
        pdfFileName = sprintf('Performance_%s_Reps_%d.pdf', strrep(examinedPSFDataFile, '.mat', ''), params.nTest);
            
        plotDerivedPsychometricFunction(questObj, threshold, fittedPsychometricParams, ...
                thresholdParameters, pdfFileName, 'xRange', [0.02 0.2]);
        continue;
    end

    % Generate optics from custom PSFs
    theCustomPSFOptics = generateCustomOptics(examinedPSFDataFile);

    domainVisualizationLimits = 0.3*0.5*[-1 1 -1 1];
    domainVisualizationTicks = struct('x', -0.2:0.1:0.2, 'y', -0.2:0.1:0.2);



    targetWavelengths = [450 550 650];
    visualizePSFsAtWavelengths(theCustomPSFOptics, ...
        targetWavelengths, domainVisualizationLimits, domainVisualizationTicks);

    

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
    
    
    tumblingEsceneEngine = createTumblingEsceneEngine(0, ...
           'customSceneParams', customSceneParams);

    % Generate background scene engine.params for the background scene
    sceneParams = tumblingEsceneEngine.sceneComputeFunction();
    backgroundSceneParams = sceneParams;
    backgroundSceneParams.chromaSpecification.foregroundRGB = sceneParams.chromaSpecification.backgroundRGB;
    backgroundSceneEngine = createTumblingEsceneEngine(0, 'customSceneParams', backgroundSceneParams);

    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
           'rowsNum', 2, ...
           'colsNum', 3, ...
           'heightMargin',  0.08, ...
           'widthMargin',    0.04, ...
           'leftMargin',     0.03, ...
           'rightMargin',    0.00, ...
           'bottomMargin',   0.06, ...
           'topMargin',      0.02);

    desiredSizeDegs = 0.1;

    
    for iOri = 1:4

        orientationDegs = (iOri-1)*90;

        % Set sceneParams
        theSceneEngine = createTumblingEsceneEngine(0);
        customSceneParams = theSceneEngine.sceneComputeFunction();
        customSceneParams.letterRotationDegs = orientationDegs;
        customSceneParams.yPixelsNumMargin = 100;
        customSceneParams.xPixelsNumMargin = 100;

        % Change upsample factor if we want smaller pixels
        customSceneParams.upSampleFactor = uint8(params.sceneUpSampleFactor);
       
        % Set the spdDataFile
        customSceneParams.spdDataFile = params.spdDataFile; 
    
        tumblingEsceneEngine = createTumblingEsceneEngine(0, ...
               'customSceneParams', customSceneParams);


        pdfFileName = sprintf('%s_%2.2fDegs_OrientationDegs_%d.pdf', strrep(strrep(examinedPSFDataFile, 'Uniform_FullVis_', ''), '.mat', ''), desiredSizeDegs, orientationDegs);
    
        visualizationSceneParams = customSceneParams;
        visualizationSceneParams.chromaSpecification.foregroundRGB = sceneParams.chromaSpecification.backgroundRGB;
        dataOut = backgroundSceneEngine.sceneComputeFunction(backgroundSceneEngine,desiredSizeDegs, visualizationSceneParams);
        theBackgroundScene = dataOut.sceneSequence{1};
        thebackgroundOI = oiCompute(theBackgroundScene, theNeuralEngine.neuralPipeline.optics);
        visualizationSceneParams = customSceneParams;
      
        dataOut = tumblingEsceneEngine.sceneComputeFunction(tumblingEsceneEngine,desiredSizeDegs, visualizationSceneParams);

        theTestScene = dataOut.sceneSequence{1};
        theOI = oiCompute(theTestScene, theNeuralEngine.neuralPipeline.optics);
    
        if (iOri == 1)
        visualizeRetinalImagesAtWavelengths(theOI, ...
             targetWavelengths, ...
             domainVisualizationLimits, domainVisualizationTicks);

        visualizeRetinalLMSconeImages(theOI, ...
             domainVisualizationLimits, ...
             domainVisualizationTicks);
        end

        [theNoiseFreeConeMosaicTestActivation, theNoisyActivations] = ...
                    theNeuralEngine.neuralPipeline.coneMosaic.compute(theOI, 'nTrials', 4);
    

        theNoiseFreeConeMosaicBackgroundActivation = ...
                    theNeuralEngine.neuralPipeline.coneMosaic.compute(thebackgroundOI, 'nTrials', 1);
    
        theConeMosaicModulation{iOri} = 100*(theNoiseFreeConeMosaicTestActivation - theNoiseFreeConeMosaicBackgroundActivation)./theNoiseFreeConeMosaicBackgroundActivation;
        theNoisyConeMosaicModulations{iOri} = 100*(bsxfun(@times,bsxfun(@minus,theNoisyActivations, theNoiseFreeConeMosaicBackgroundActivation),1./theNoiseFreeConeMosaicBackgroundActivation));
    

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
            'activation', theConeMosaicModulation{iOri}, ...
            'activationRange', 20*[-1 1], ...
            'verticalActivationColorBar', true, ...
            'domainVisualizationLimits', domainVisualizationLimits, ...
            'domainVisualizationTicks', domainVisualizationTicks, ...
            'noYLabel', true, ...
            'plotTitle', sprintf('cone modulation (max: %2.1f%%)',max(abs(theConeMosaicModulation{iOri}(:)))), ...
            'fontSize', 18, ...
            'backgroundColor', [0 0 0]);
        xtickangle(ax, 0);
        ytickangle(ax, 0);
        
        ax = subplot('Position', subplotPosVectors(2,1).v);
        theNeuralEngine.neuralPipeline.coneMosaic.visualize(...
            'figureHandle', hFig, ...
            'axesHandle', ax, ...
            'domain', 'degrees', ...
            'activation', theNoisyConeMosaicModulations{iOri}, ...
            'activationRange', 20*[-1 1], ...
            'verticalActivationColorBar', true, ...
            'domainVisualizationLimits', domainVisualizationLimits, ...
            'domainVisualizationTicks', domainVisualizationTicks, ...
            'noYLabel', true, ...
            'plotTitle', sprintf('cone modulation (max: %2.1f%%)',max(abs(theConeMosaicModulation{iOri}(:)))), ...
            'fontSize', 18, ...
            'backgroundColor', [0 0 0]);
        xtickangle(ax, 0);
        ytickangle(ax, 0);


        %NicePlot.exportFigToPDF(pdfFileName, hFig, 300);
    end

    visualizeConeMosaicActivations(theNeuralEngine.neuralPipeline.coneMosaic, ...
        theConeMosaicModulation, theNoisyConeMosaicModulations, ...
         domainVisualizationLimits, ...
         domainVisualizationTicks)

end
end

function visualizeConeMosaicActivations(theConeMosaic, ...
        theConeMosaicModulation, theNoisyConeMosaicModulations, ...
         domainVisualizationLimits, ...
         domainVisualizationTicks)

     domainVisualizationTicks.y = [-0.1 0 0.1];
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
       'rowsNum', 1, ...
       'colsNum', 4, ...
       'heightMargin',  0.0, ...
       'widthMargin',    0.05, ...
       'leftMargin',     0.05, ...
       'rightMargin',    0.00, ...
       'bottomMargin',   0.05, ...
       'topMargin',      0.00);

    hFig = figure(4);
    clf;
    set(hFig, 'Position', [10 10 1650 500], 'Color', [1 1 1]);


    for iOri = 1:4
        ax = subplot('Position', subplotPosVectors(1,iOri).v);
        theConeMosaic.visualize(...
            'figureHandle', hFig, ...
            'axesHandle', ax, ...
            'domain', 'degrees', ...
            'activation', theConeMosaicModulation{iOri}, ...
            'activationRange', 20*[-1 1], ...
            'verticalActivationColorBarInside', true, ...
            'domainVisualizationLimits', domainVisualizationLimits, ...
            'domainVisualizationTicks', domainVisualizationTicks, ...
            'noYLabel', (iOri>1), ...
            'plotTitle', sprintf('cone modulation (max: %2.1f%%)',max(abs(theConeMosaicModulation{iOri}(:)))), ...
            'fontSize', 16, ...
            'backgroundColor', [0 0 0]);
        xtickangle(ax, 0);
        ytickangle(ax, 0);
    end

    projectBaseDir = strrep(ISETbioJandJRootPath(), 'toolbox', '');
    pdfFile = [fullfile(projectBaseDir, 'figures') filesep 'MeanConeMosaicActivations.pdf'];
    NicePlot.exportFigToPDF(pdfFile,hFig, 300);


    hFig = figure(5);
    clf;
    set(hFig, 'Position', [10 10 1650 500], 'Color', [1 1 1]);

    for iInstance = 1:4
        ax = subplot('Position', subplotPosVectors(1,iInstance).v);
        theConeMosaic.visualize(...
            'figureHandle', hFig, ...
            'axesHandle', ax, ...
            'domain', 'degrees', ...
            'activation', squeeze(theNoisyConeMosaicModulations{1}(iInstance,:,:)), ...
            'activationRange', 20*[-1 1], ...
            'verticalActivationColorBarInside', true, ...
            'domainVisualizationLimits', domainVisualizationLimits, ...
            'domainVisualizationTicks', domainVisualizationTicks, ...
            'noYLabel', (iOri>1), ...
            'plotTitle', sprintf('noisy cone mosaic activation\n(instance %d)', iInstance),...
            'fontSize', 16, ...
            'backgroundColor', [0 0 0]);
        xtickangle(ax, 0);
        ytickangle(ax, 0);
    end

    projectBaseDir = strrep(ISETbioJandJRootPath(), 'toolbox', '');
    pdfFile = [fullfile(projectBaseDir, 'figures') filesep 'NoisyConeMosaicActivations.pdf'];
    NicePlot.exportFigToPDF(pdfFile,hFig, 300);


    hFig = figure(6);
    clf;
    set(hFig, 'Position', [10 10 1650 500], 'Color', [1 1 1]);

    ax = subplot('Position', subplotPosVectors(1,4).v);
    theConeMosaic.visualize(...
            'figureHandle', hFig, ...
            'axesHandle', ax, ...
            'domain', 'degrees', ...
            'domainVisualizationLimits', domainVisualizationLimits, ...
            'domainVisualizationTicks', domainVisualizationTicks, ...
            'plotTitle', 'cone mosaic',...
            'fontSize', 16, ...
            'backgroundColor', [0 0 0]);

    wave = theConeMosaic.wave;
    photopigment = theConeMosaic.pigment;

    ax = subplot('Position', subplotPosVectors(1,1).v);
    plot(ax, wave, photopigment.quantalEfficiency(:,3), 'bo-', ...
        'MarkerSize', 12, 'MarkerFaceColor', [0.5 0.5 1], 'LineWidth', 1.5);
    xlabel(ax, 'wavelength (nm)');
    ylabel(ax, 'quantal efficiency');
    axis(ax, 'square'); grid(ax, 'on');
    set(ax, 'YLim', [0 0.5], 'YTick', 0:0.1:0.5, 'FontSize', 16)
    title(ax, 'S-cone');

    ax = subplot('Position', subplotPosVectors(1,2).v);
    plot(ax, wave, photopigment.quantalEfficiency(:,2), 'go-', ...
        'MarkerSize', 12, 'MarkerFaceColor', [0.5 1 0.5], 'MarkerEdgeColor', [0.5 0 0], 'LineWidth', 1.5);
    xlabel(ax, 'wavelength (nm)');
    axis(ax, 'square'); grid(ax, 'on');
    set(ax, 'YLim', [0 0.5], 'YTick', 0:0.1:0.5, 'FontSize', 16)
    title(ax, 'M-cone');

    ax = subplot('Position', subplotPosVectors(1,3).v);
    plot(ax, wave, photopigment.quantalEfficiency(:,1), 'ro-', ...
        'MarkerSize', 12, 'MarkerFaceColor', [1 0.5 0.5],  'LineWidth', 1.5);
    xlabel(ax, 'wavelength (nm)');
    axis(ax, 'square'); grid(ax, 'on');
    set(ax, 'YLim', [0 0.5], 'YTick', 0:0.1:0.5, 'FontSize', 16)
    title(ax, 'L-cone');

    projectBaseDir = strrep(ISETbioJandJRootPath(), 'toolbox', '');
    pdfFile = [fullfile(projectBaseDir, 'figures') filesep 'ConeMosaic.pdf'];
    NicePlot.exportFigToPDF(pdfFile,hFig, 300);

end


function visualizeRetinalLMSconeImages(opticalImage, ...
             domainVisualizationLimits, ...
             domainVisualizationTicks)

    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
       'rowsNum', 1, ...
       'colsNum', 4, ...
       'heightMargin',  0.0, ...
       'widthMargin',    0.05, ...
       'leftMargin',     0.05, ...
       'rightMargin',    0.00, ...
       'bottomMargin',   0.05, ...
       'topMargin',      0.00);

    hFig = figure(3);
    clf;
    set(hFig, 'Position', [10 10 1650 500], 'Color', [1 1 1]);

    retinalLMSconeImages = oiGet(opticalImage, 'lms');
    retinalLMSconeImages = retinalLMSconeImages/max(retinalLMSconeImages(:));

    % retrieve the spatial support of the scene(in millimeters)
    spatialSupportMM = oiGet(opticalImage, 'spatial support', 'mm');
    
    % Convert spatial support in degrees
    optics = oiGet(opticalImage, 'optics');
    focalLength = opticsGet(optics, 'focal length');
    mmPerDegree = focalLength*tand(1)*1e3;
    spatialSupportDegs = spatialSupportMM/mmPerDegree;
    spatialSupportX = spatialSupportDegs(1,:,1)*60;
    spatialSupportY = spatialSupportDegs(:,1,2)*60;

    for k = size(retinalLMSconeImages,3):-1:1

        ax = subplot('Position', subplotPosVectors(1,4-k).v);

        imagesc(ax, spatialSupportX, spatialSupportY, squeeze(retinalLMSconeImages(:,:,k)));
        set(ax, 'FontSize', 16);
        axis(ax, 'image'); axis 'xy';
        set(ax, 'XTick', domainVisualizationTicks.x*60, 'YTick', domainVisualizationTicks.y*60, ...
                'XTickLabel', sprintf('%2.2f\n', domainVisualizationTicks.x), ...
                'YTickLabel', sprintf('%2.2f\n', domainVisualizationTicks.y));
        set(ax, 'XLim', domainVisualizationLimits(1:2)*60, 'YLim', domainVisualizationLimits(3:4)*60);
        xlabel('space (deg)');
        
        if (k == 1)
            ylabel('space (deg)');
        end
        colormap(ax, gray(1024));
        hC = colorbar(ax, 'south');
        switch k
            case 1
                hC.Label.String = 'retinal L-cone activation';
            case 2
                hC.Label.String = 'retinal M-cone activation';
            case 3
                hC.Label.String = 'retinal S-cone activation';
        end

        drawnow
    end

    projectBaseDir = strrep(ISETbioJandJRootPath(), 'toolbox', '');
    pdfFile = [fullfile(projectBaseDir, 'figures') filesep 'RetinalLMSconeImages.pdf'];
    NicePlot.exportFigToPDF(pdfFile,hFig, 300);

end

function visualizeRetinalImagesAtWavelengths(opticalImage, ...
             targetWavelengths, ...
             domainVisualizationLimits, ...
             domainVisualizationTicks)

    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
       'rowsNum', 1, ...
       'colsNum', 4, ...
       'heightMargin',  0.0, ...
       'widthMargin',    0.05, ...
       'leftMargin',     0.05, ...
       'rightMargin',    0.00, ...
       'bottomMargin',   0.05, ...
       'topMargin',      0.00);

    wavelengthSupport = oiGet(opticalImage, 'wave');
    hFig = figure(3);
    clf;
    set(hFig, 'Position', [10 10 1650 500], 'Color', [1 1 1]);

    retinalImagePhotonRate = oiGet(opticalImage, 'photons');

    % retrieve the spatial support of the scene(in millimeters)
    spatialSupportMM = oiGet(opticalImage, 'spatial support', 'mm');
    
    % Convert spatial support in degrees
    optics = oiGet(opticalImage, 'optics');
    focalLength = opticsGet(optics, 'focal length');
    mmPerDegree = focalLength*tand(1)*1e3;
    spatialSupportDegs = spatialSupportMM/mmPerDegree;
    spatialSupportX = spatialSupportDegs(1,:,1)*60;
    spatialSupportY = spatialSupportDegs(:,1,2)*60;

    for k = 1:numel(targetWavelengths)
        [~,wIndex] = min(abs(wavelengthSupport-targetWavelengths(k)));
        targetWavelength = wavelengthSupport(wIndex);
    
        ax = subplot('Position', subplotPosVectors(1,k).v);
        imagesc(ax, spatialSupportX, spatialSupportY, squeeze(retinalImagePhotonRate(:,:,wIndex)));
        set(ax, 'FontSize', 16);
        axis(ax, 'image'); axis 'xy';
        set(ax, 'XTick', domainVisualizationTicks.x*60, 'YTick', domainVisualizationTicks.y*60, ...
                'XTickLabel', sprintf('%2.2f\n', domainVisualizationTicks.x), ...
                'YTickLabel', sprintf('%2.2f\n', domainVisualizationTicks.y));
        set(ax, 'XLim', domainVisualizationLimits(1:2)*60, 'YLim', domainVisualizationLimits(3:4)*60);
        xlabel('space (deg)');
        
        if (k == 1)
            ylabel('space (deg)');
        end
        colormap(ax, gray(1024));
        hC = colorbar(ax, 'south');
        hC.Label.String = sprintf('retinal irradiance (photons/m^2/sec)');

        title(ax, sprintf('%d nm', targetWavelength));
        drawnow
    end

    projectBaseDir = strrep(ISETbioJandJRootPath(), 'toolbox', '');
    pdfFile = [fullfile(projectBaseDir, 'figures') filesep 'RetinalImages.pdf'];
    NicePlot.exportFigToPDF(pdfFile,hFig, 300);

end


function visualizePSFsAtWavelengths(theCustomPSFOptics, ...
        targetWavelengths, domainVisualizationLimits, domainVisualizationTicks)

    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
       'rowsNum', 1, ...
       'colsNum', 4, ...
       'heightMargin',  0.0, ...
       'widthMargin',    0.05, ...
       'leftMargin',     0.05, ...
       'rightMargin',    0.00, ...
       'bottomMargin',   0.05, ...
       'topMargin',      0.00);

    wavelengthSupport = oiGet(theCustomPSFOptics, 'wave');
    hFig = figure(2);
    clf;
    set(hFig, 'Position', [10 10 1650 500], 'Color', [1 1 1]);

    
    for k = 1:numel(targetWavelengths)
        [~,wIndex] = min(abs(wavelengthSupport-targetWavelengths(k)));
        targetWavelength = wavelengthSupport(wIndex);
    
        psfRangeArcMin = max(domainVisualizationLimits)*60*0.5;
        ax = subplot('Position', subplotPosVectors(1,k).v);
        visualizePSF(theCustomPSFOptics, targetWavelength, psfRangeArcMin, ...
            'contourLevels', 0.1:0.1:0.9, ...
            'axesHandle', ax, ...
            'figureTitle', sprintf('%2.0f nm', targetWavelength), ...
            'fontSize', 16);
        set(ax, 'XTick', domainVisualizationTicks.x*60, 'YTick', domainVisualizationTicks.y*60, ...
                'XTickLabel', sprintf('%2.2f\n', domainVisualizationTicks.x), ...
                'YTickLabel', sprintf('%2.2f\n', domainVisualizationTicks.y));
        set(ax, 'XLim', domainVisualizationLimits(1:2)*60, 'YLim', domainVisualizationLimits(3:4)*60);
        xlabel('space (deg)');
        if (k == 1)
            ylabel('space (deg)');
        end
        drawnow
    end

    projectBaseDir = strrep(ISETbioJandJRootPath(), 'toolbox', '');
    pdfFile = [fullfile(projectBaseDir, 'figures') filesep 'PSFs.pdf'];
    NicePlot.exportFigToPDF(pdfFile,hFig, 300);
end
