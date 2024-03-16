function generateFigurePanels2()

    % Parameters    
    params = struct(...
        'spdDataFile', 'BVAMS_White_Guns_At_Max.mat', ...           % Datafile containing the display SPDs
        'psfDataFile', '',...                                       % Datafile containing the PSF data
        'letterSizesNumExamined',  8, ...                           % How many sizes to use for sampling the psychometric curve
        'maxLetterSizeDegs', 0.4, ...                               % The maximum letter size in degrees of visual angle
        'sceneUpSampleFactor', 4, ...                               % Upsample scene, so that the pixel for the smallest scene is < cone aperture
        'mosaicIntegrationTimeSeconds', 500/1000, ...               % Integration time, here 300 msec
        'nTest', 128, ...                                           % Number of trial to use for computing Pcorrect
        'thresholdP', 0.781, ...                                    % Probability correct level for estimating threshold performance
        'visualizedPSFwavelengths', [], ... %380:10:770, ...        % Vector with wavelengths for visualizing the PSF. If set to empty[] there is no visualization.
        'visualizeDisplayCharacteristics', ~true, ...               % Flag, indicating whether to visualize the display characteristics
        'visualizeScene', ~true ...                                 % Flag, indicating whether to visualize one of the scenes
    );

    modulations = 0; % 0 = excitations, 1 = modulations
    psfDataSubDir = 'FullVis_PSFs_20nm_Subject9';
    examinedPSFDataFile = fullfile(psfDataSubDir, 'Uniform_FullVis_LCA_2203_TCA_Hz1380_TCA_Vt2760.mat');

    % Generate optics from custom PSFs
    theCustomPSFOptics = generateCustomOptics(examinedPSFDataFile);

    % Generate cone mosaic to use
    mosaicSizeDegs = params.maxLetterSizeDegs*1.25*[1 1];
    theConeMosaic = generateCustomConeMosaic(...
            params.mosaicIntegrationTimeSeconds, ...
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

    desiredSizeDegs = 0.1;
    %desiredSizeDegs = 0.043;
    eOrientationsDegs = [0 90 180 270];

    domainVisualizationLimits = [-0.15 0.15 -0.15 0.15];
    domainVisualizationTicks =  struct('x', -1:0.1:1, 'y', -1:0.1:1);

    visualizedWavelengths = [400 560 700];
    nNoisyResponseInstances = 4;

    for iOri = 1:numel(eOrientationsDegs)

        % Set sceneParams
        theSceneEngine = createTumblingEsceneEngine(0);
        customSceneParams = theSceneEngine.sceneComputeFunction();
        customSceneParams.letterRotationDegs = eOrientationsDegs(iOri);
        customSceneParams.yPixelsNumMargin = 100;
        customSceneParams.xPixelsNumMargin = 100;

        % Change upsample factor if we want smaller pixels
        customSceneParams.upSampleFactor = uint8(params.sceneUpSampleFactor);
       
        % Set the spdDataFile
        customSceneParams.spdDataFile = params.spdDataFile; 
    
        if (iOri == 1)
            % Generate background scene
            backgroundSceneParams = customSceneParams;
            backgroundSceneParams.chromaSpecification.foregroundRGB = backgroundSceneParams.chromaSpecification.backgroundRGB;
            backgroundSceneEngine = createTumblingEsceneEngine(0, ...
               'customSceneParams', backgroundSceneParams);
            dataOut = backgroundSceneEngine.sceneComputeFunction(backgroundSceneEngine,desiredSizeDegs, backgroundSceneParams);
            theBackgroundScene = dataOut.sceneSequence{1};
            theBackgroundRetinalOpticalImage = oiCompute(theBackgroundScene, theNeuralEngine.neuralPipeline.optics);
            theNoiseFreeConeMosaicBackgroundActivation = ...
                    theNeuralEngine.neuralPipeline.coneMosaic.compute(theBackgroundRetinalOpticalImage);
        end
        
        % Excitations to modulations
        eToM = @(e) bsxfun(@times, bsxfun(@minus,e,theNoiseFreeConeMosaicBackgroundActivation), 1./theNoiseFreeConeMosaicBackgroundActivation);

        
        % Generate stimulus scene
        tumblingEsceneEngine = createTumblingEsceneEngine(0, ...
               'customSceneParams', customSceneParams);
        dataOut = tumblingEsceneEngine.sceneComputeFunction(tumblingEsceneEngine,desiredSizeDegs, customSceneParams);
        theTestScene = dataOut.sceneSequence{1};
        thePresentationDisplay = dataOut.presentationDisplay;
        theTestStimulusRetinalOpticalImage = oiCompute(theTestScene, theNeuralEngine.neuralPipeline.optics);
        [theNoiseFreeConeMosaicTestActivation, theNoisyConeMosaicTestActivations] = ...
                    theNeuralEngine.neuralPipeline.coneMosaic.compute(theTestStimulusRetinalOpticalImage, 'nTrials', nNoisyResponseInstances);
    
        % Excitations to modulations
        if modulations == 1
            theNoiseFreeConeMosaicTestModulation = eToM(theNoiseFreeConeMosaicTestActivation);
            theNoisyConeMosaicTestModulations = eToM(theNoisyConeMosaicTestActivations);
        else
            theNoiseFreeConeMosaicTestModulation = theNoiseFreeConeMosaicTestActivation./max(abs(theNoiseFreeConeMosaicTestActivation(:)));
            theNoisyConeMosaicTestModulations = theNoisyConeMosaicTestActivations./max(abs(theNoisyConeMosaicTestActivations(:)));
        end


        % Generate and export test scene figure
        visualizeSceneHelper(theTestScene, thePresentationDisplay, ...
            domainVisualizationLimits, domainVisualizationTicks, ...
            'noXLabel', false, ...
            'noYLabel', false, ...
            'pdfFileName', sprintf('TumblingEscene_%dDegs.pdf', eOrientationsDegs(iOri)));

        if (iOri == 1)
            % Generate and export background scene figure
            visualizeSceneHelper(theBackgroundScene, thePresentationDisplay, ...
                domainVisualizationLimits, domainVisualizationTicks, ...
                'noXLabel', false, ...
                'noYLabel', false, ...
                'pdfFileName', 'BackgroundScene.pdf');
        end

        % Generate the retinal optical images
        for iWave = 1:numel(visualizedWavelengths)
            visualizeRetinalImageHelper(theTestStimulusRetinalOpticalImage, ...
                visualizedWavelengths(iWave), ...
                domainVisualizationLimits, domainVisualizationTicks, ...
                'retinalIrradianceRange', [], ...
                'colorLUT', brewermap(1024, '*greys'), ...
                'displayColorBar', true, ...
                'colorBarLocation', 'south', ...
                'plotTitle', sprintf('%d nm', visualizedWavelengths(iWave)),...
                'noXLabel', false, ...
                'noYLabel', false, ...
                'pdfFileName', sprintf('RetinalImage_%dnm_%dDegs.pdf', visualizedWavelengths(iWave), eOrientationsDegs(iOri)));
        end % iWave

        if modulations == 1
            activationRange = max(abs(theNoiseFreeConeMosaicTestModulation(:)))*[-1 1];
        else
            %activationRange = [min(theNoiseFreeConeMosaicTestModulation(:)) max(theNoiseFreeConeMosaicTestModulation(:))];
            activationRange = max(abs(theNoiseFreeConeMosaicTestModulation(:)))*[0 1];
        end
        visualizeConeMosaicHelper(theNeuralEngine.neuralPipeline.coneMosaic, ...
            domainVisualizationLimits, domainVisualizationTicks, ...
            'activation', theNoiseFreeConeMosaicTestModulation, ...
            'activationRange', activationRange, ...
            'colorLUT', brewermap(1024, '*greys'), ...
            'displayColorBar', ~true, ...
            'colorBarLocation', 'south', ...
            'noXLabel', false, ...
            'noYLabel', false, ...
            'pdfFileName', sprintf('NoiseFreeConeModulations_%dDegs.pdf', eOrientationsDegs(iOri)));
    

        for iTrial = 1:nNoisyResponseInstances
            visualizeConeMosaicHelper(theNeuralEngine.neuralPipeline.coneMosaic, ...
                domainVisualizationLimits, domainVisualizationTicks, ...
                'activation', theNoisyConeMosaicTestModulations(iTrial,:,:), ...
                'activationRange', activationRange, ...
                'colorLUT', brewermap(1024, '*greys'), ...
                'plotTitle', sprintf('instance #%d', iTrial),...
                'displayColorBar', ~true, ...
                'colorBarLocation', 'south', ...
                'noXLabel', false, ...
                'noYLabel', false, ...
                'pdfFileName', sprintf('NoisyConeModulations_Instance%d_%dDegs.pdf', iTrial, eOrientationsDegs(iOri)));
        end

    end % iOri

end

