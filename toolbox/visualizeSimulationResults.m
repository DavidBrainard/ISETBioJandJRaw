function visualizeSimulationResults(questObj, threshold, fittedPsychometricParams, ...
    thresholdParameters, tumblingEsceneEngines, theNeuralEngine, pdfFileName)

    % Choose which sizes to display
    fittedPsychometricFunction = questObj.qpPF(questObj.estDomain', fittedPsychometricParams);
    examinedParameterAxis = 10.^(questObj.estDomain)*thresholdParameters.maxParamValue;

    hFig = figure(3); clf;
    
    % Flag indicating whether to visualize the noise-free cone mosaic
    % excitations or noisy instances (generates a video)
    visualizeNoiseFreeMosaicActivation = true;

    if (visualizeNoiseFreeMosaicActivation == false)
        % If we generate a video of noisy response instances, do so for a high-performance value
        % and also increase the mosaic integration time to 2 seconds
        performanceValuesExamined = 0.95;
        theNeuralEngine.neuralPipeline.coneMosaic.integrationTime = 2;

        % Figure setup
        set(hFig, 'Position', [10 10 1500 350], 'Color', [1 1 1]);

        % Video setup
        videoOBJ = VideoWriter('NoisyModulations', 'MPEG-4');
        videoOBJ.FrameRate = 10;
        videoOBJ.Quality = 100;
        videoOBJ.open();
    else
        % Performance levels to examine
        performanceValuesExamined = [0.26 0.5 0.8];
        % Figure setup
        set(hFig, 'Position', [10 10 1500 1000], 'Color', [1 1 1]);
    end

    activationColorMap = brewermap(1024, '*RdBu');

    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
       'rowsNum', numel(performanceValuesExamined), ...
       'colsNum', numel(tumblingEsceneEngines), ...
       'heightMargin',  0.06, ...
       'widthMargin',    0.05, ...
       'leftMargin',     0.07, ...
       'rightMargin',    0.03, ...
       'bottomMargin',   0.05, ...
       'topMargin',      0.05);


    for letterSizeIndex = 1:numel(performanceValuesExamined)
        [~,idx] = min(abs(squeeze(fittedPsychometricFunction(:, 2))-performanceValuesExamined(letterSizeIndex)));
        letterSizeDegs = examinedParameterAxis(idx);
        for letterRotationIndex = 1:numel(tumblingEsceneEngines)
            % Retrieve the sceneEngine
            sceneEngine = tumblingEsceneEngines{letterRotationIndex};

            % Generate a scene engine for the background scene (zero contrast)
            if (letterRotationIndex == 1)
                sceneParams = sceneEngine.sceneComputeFunction();
                backgroundSceneParams = sceneEngine.sceneParams;
                backgroundSceneParams.chromaSpecification.foregroundRGB = sceneParams.chromaSpecification.backgroundRGB;
                backgroundSceneEngine = createTumblingEsceneEngine(0, 'customSceneParams', backgroundSceneParams);
            end

            % Compute the E scene
            theSceneSequence = sceneEngine.compute(letterSizeDegs);
            theTestScene = theSceneSequence{1};

            if (letterRotationIndex == 1)
                % Compute the background scene
                theSceneSequence = backgroundSceneEngine.compute(letterSizeDegs);
                theBackgroundScene = theSceneSequence{1};
            end

            % Compute the optical image of the test scene
            theOI = oiCompute(theTestScene, theNeuralEngine.neuralPipeline.optics);
            
            if (letterRotationIndex == 1)
                % Compute the optical image of the background scene
                theBackgroundOI = oiCompute(theBackgroundScene, theNeuralEngine.neuralPipeline.optics);
            end

            
            % Compute cone mosaic activations to the test scene
            [theNoiseFreeConeMosaicActivation, noisyResponseInstances] = ...
                theNeuralEngine.neuralPipeline.coneMosaic.compute(theOI, 'nTrials', 4);

            if (letterRotationIndex == 1)
                % Compute cone mosaic activations to the background scene
                theNoiseFreeBackgroundConeMosaicActivation = ...
                    theNeuralEngine.neuralPipeline.coneMosaic.compute(theBackgroundOI);
            end

            % Compute noise-free cone modulations
            theNoiseFreeConeMosaicModulation = 100*excitationsToModulations(...
                theNoiseFreeConeMosaicActivation, theNoiseFreeBackgroundConeMosaicActivation);

            % Compute noisy cone modulations
            theNoisyConeMosaicModulations = 100*excitationsToModulations(...
                noisyResponseInstances, theNoiseFreeBackgroundConeMosaicActivation);

            domainVisualizationTicks = struct('x', -0.1:0.1:0.1, 'y', -0.1:0.1:0.1);
            domainVisualizationTicksForThisPlot = domainVisualizationTicks ;
            if (letterSizeIndex<numel(performanceValuesExamined))
                domainVisualizationTicksForThisPlot.x = [];
            end
            if (letterRotationIndex>1)
                domainVisualizationTicksForThisPlot.y = [];
            end

            d = sqrt(sum(theNeuralEngine.neuralPipeline.coneMosaic.coneRFpositionsDegs.^2,2));
            roiConeIndices = find(d<0.1);
            maxModulation = max(abs(theNoiseFreeConeMosaicModulation(roiConeIndices)));

            ax = subplot('Position', subplotPosVectors(letterSizeIndex, letterRotationIndex).v);
            if (visualizeNoiseFreeMosaicActivation)
                theNeuralEngine.neuralPipeline.coneMosaic.visualize(...
                    'figureHandle', hFig', 'axesHandle', ax, ...
                    'activation', theNoiseFreeConeMosaicModulation, ...
                    'activationRange', maxModulation*[-1 1], ...
                    'verticalActivationColorBar', true, ...
                    'activationColorMap', activationColorMap, ...
                    'colorbarTickLabelColor', [0.3 0.3 0.3],...
                    'domain', 'degrees', ...
                    'domainVisualizationLimits', [-0.1 0.1 -0.1 0.1], ...
                    'domainVisualizationTicks', domainVisualizationTicksForThisPlot, ...
                    'crossHairsOnMosaicCenter', true, ...
                    'crossHairsColor',[1 0.2 0.2], ...
                    'noXLabel', (letterSizeIndex<numel(performanceValuesExamined)), ...
                    'noYLabel', (letterRotationIndex>1), ...
                    'plotTitle', sprintf('performance level: %2.2f\n(letter size: %2.3f degs)', ...
                            performanceValuesExamined(letterSizeIndex), letterSizeDegs));
            else
                for iTrial = 1:size(noisyResponseInstances,1)
                
                    theNeuralEngine.neuralPipeline.coneMosaic.visualize(...
                        'figureHandle', hFig', 'axesHandle', ax, ...
                        'activation', theNoisyConeMosaicModulations(iTrial,:,:), ...
                        'activationRange', 2*max(abs(theNoiseFreeConeMosaicModulation(:)))*[-1 1], ...
                        'verticalActivationColorBar', true, ...
                        'activationColorMap', activationColorMap, ...
                        'colorbarTickLabelColor', [0 0 1],...
                        'domain', 'degrees', ...
                        'domainVisualizationLimits', [-0.1 0.1 -0.1 0.1], ...
                        'domainVisualizationTicks', domainVisualizationTicksForThisPlot, ...
                        'crossHairsOnMosaicCenter', true, ...
                        'crossHairsColor', [1 0.2 0.2], ...
                        'noXLabel', (letterSizeIndex<numel(performanceValuesExamined)), ...
                        'noYLabel', (letterRotationIndex>1), ...
                        'plotTitle', sprintf('performance level: %2.2f\n(letter size: %2.3f degs)', ...
                                performanceValuesExamined(letterSizeIndex), letterSizeDegs));
                     drawnow;
                     videoOBJ.writeVideo(getframe(hFig));
                end

            end

%             visualizeScene(theScenes{letterSizeIndex,letterRotationIndex}, ...
%                 'spatialSupportInDegs', true, ...
%                 'crossHairsAtOrigin', true, ...
%                 'displayRadianceMaps', false, ...
%                 'axesHandle', ax, ...
%                 'noTitle', true);
        end
    end

    if (visualizeNoiseFreeMosaicActivation == false)
        videoOBJ.close();
    end

    NicePlot.exportFigToPDF(pdfFileName,hFig, 300);
end
