function testTumblingEsceneEngine()

    % Obtain the default params for the tumblingEscene engine
    defaultParams = sceTumblingEscene();
    
    % Set the plotDisplayCharacteristics field to true to visualize the
    % display SPDs and gamma functions
    customSceneParams = defaultParams;
    customSceneParams.plotDisplayCharacteristics = true;
    
    % Generate sceneEngine for 0 deg rotation E
    letterRotationDegs = 0;
    tumblingEsceneEngine0degs = createTumblingEsceneEngine(letterRotationDegs, 'customSceneParams', customSceneParams);

    % Generate sceneEngine for 90 deg rotation E
    letterRotationDegs = 90;
    tumblingEsceneEngine90degs = createTumblingEsceneEngine(letterRotationDegs);


    % Generate params for the background scene
    sceneParams = tumblingEsceneEngine0degs.sceneComputeFunction();
    backgroundSceneParams = sceneParams;
    backgroundSceneParams.chromaSpecification.foregroundRGB = sceneParams.chromaSpecification.backgroundRGB;
    backgroundSceneEngine = createTumblingEsceneEngine(letterRotationDegs, 'customSceneParams', backgroundSceneParams);

    % Generate scenes with size of 0.1 deg
    sizeDegs = 0.1;
    theSmallEsceneSequence0degs = tumblingEsceneEngine0degs.compute(sizeDegs);
    theSmallEsceneSequence90degs = tumblingEsceneEngine90degs.compute(sizeDegs);
    theSmallBackgroundSceneSequence = backgroundSceneEngine.compute(sizeDegs);

    % Generate scenes with size of 0.3 deg
    sizeDegs = 0.3;
    theLargeEsceneSequence0degs = tumblingEsceneEngine0degs.compute(sizeDegs);
    theLargeEsceneSequence90degs = tumblingEsceneEngine90degs.compute(sizeDegs);
    theLargeBackgroundSceneSequence = backgroundSceneEngine.compute(sizeDegs);

    % Get first frame of the scene sequences
    theSmallEscene0degs = theSmallEsceneSequence0degs{1};
    theSmallEscene90degs = theSmallEsceneSequence90degs{1};
    theSmallBackgroundScene = theSmallBackgroundSceneSequence{1};

    % Get first frame of the scene sequences
    theLargeEscene0degs = theLargeEsceneSequence0degs{1};
    theLargeEscene90degs = theLargeEsceneSequence90degs{1};
    theLargeBackgroundScene = theLargeBackgroundSceneSequence{1};

    hFig = figure(1);
    set(hFig, 'Position', [10 10 1200 940], 'Color', [1 1 1]);
    ax = subplot(2,3,1);
    visualizeScene(theSmallEscene0degs, ...
            'spatialSupportInDegs', true, ...
            'crossHairsAtOrigin', true, ...
            'displayRadianceMaps', false, ...
            'axesHandle', ax);

    ax = subplot(2,3,2);
    visualizeScene(theSmallEscene90degs, ...
            'spatialSupportInDegs', true, ...
            'crossHairsAtOrigin', true, ...
            'displayRadianceMaps', false, ...
            'axesHandle', ax);

    ax = subplot(2,3,3);
    visualizeScene(theSmallBackgroundScene, ...
            'spatialSupportInDegs', true, ...
            'crossHairsAtOrigin', true, ...
            'displayRadianceMaps', false, ...
            'axesHandle', ax);


    ax = subplot(2,3,4);
    visualizeScene(theLargeEscene0degs, ...
            'spatialSupportInDegs', true, ...
            'crossHairsAtOrigin', true, ...
            'displayRadianceMaps', false, ...
            'avoidAutomaticRGBscaling', true, ...
            'axesHandle', ax);

    ax = subplot(2,3,5);
    visualizeScene(theLargeEscene90degs, ...
            'spatialSupportInDegs', true, ...
            'crossHairsAtOrigin', true, ...
            'displayRadianceMaps', false, ...
            'avoidAutomaticRGBscaling', true, ...
            'axesHandle', ax);

    ax = subplot(2,3,6);
    visualizeScene(theLargeBackgroundScene, ...
            'spatialSupportInDegs', true, ...
            'crossHairsAtOrigin', true, ...
            'displayRadianceMaps', false, ...
            'avoidAutomaticRGBscaling', true, ...
            'axesHandle', ax);

end
