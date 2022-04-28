% The tublingEsceneEngine.compute(Esize) compute function
function dataOut = sceTumblingEscene(sceneEngineOBJ, testEsizeDegs, sceneParams)
    % Check input arguments. If called with zero input arguments, just return the default params struct
    if (nargin == 0)
        dataOut = generateDefaultParams();
        return;
    end

    % Validate params
    assert(sceneParams.letterHeightPixels == 20, 'letterHeight must be 20 pixels');
    assert(sceneParams.letterWidthPixels == 18, 'letterWidth must be 18 pixels');
    assert(ismember(sceneParams.letterRotationDegs, [0 90 180 270]), 'letterRotationDegs must be in 0, 90, 180, or 270');

    % Generate the display on which the tumbing E scenes are presented
    presentationDisplay = generateBVAMSWhiteDisplay(...
        testEsizeDegs, sceneParams.letterHeightPixels, sceneParams.plotDisplayCharacteristics);

    % Generate the E scene with 0 deg rotation
    theTestScene = generateTumblingEscene(...
        presentationDisplay, 'E', sceneParams, ...
        'visualizeScene', sceneParams.visualizeScene);

    % Assemble dataOut struct - required fields
    dataOut.sceneSequence{1} = theTestScene;
    dataOut.temporalSupport(1) = 0;
    dataOut.statusReport = 'done';
end


function theScene = generateTumblingEscene(...
    presentationDisplay, theChar, sceneParams, varargin)

    % Parse optional input
    p = inputParser;
    p.addParameter('visualizeScene', false, @islogical);
    p.parse(varargin{:});
    visualizeScene = p.Results.visualizeScene;

    textSceneParams = struct(...
        'textString', theChar, ...                              % Text to display
        'textRotation', sceneParams.letterRotationDegs, ...                     % Rotation (0,90,180,270 only)
        'rowsNum', sceneParams.letterHeightPixels + sceneParams.yPixelsNumMargin*2, ... % Pixels along the vertical (y) dimension
        'colsNum', sceneParams.letterWidthPixels + sceneParams.xPixelsNumMargin*2, ...  % Pixels along the horizontal (x) dimension
        'targetRow', sceneParams.yPixelsNumMargin, ...                      % Y-pixel offset 
        'targetCol', sceneParams.xPixelsNumMargin, ...                      % X-pixel offset 
        'upSampleFactor', sceneParams.upSampleFactor, ...                         % Upsample the scene to increase the retinal image resolution
        'chromaSpecification', sceneParams.chromaSpecification ...          % Background and stimulus chromaticity
    );
    
    % Generate stimulus scene
    theScene = rotatedTextSceneRealizedOnDisplay(presentationDisplay, ...
        textSceneParams, visualizeScene);
end


function p = generateDefaultParams()

    p = struct(...
        'letterRotationDegs', 0, ...            % Letter rotation (0,90,180,270 only)
        'letterHeightPixels', 20, ...           % Letter height in pixels - must be 20
        'letterWidthPixels', 18, ...            % Letter width in pixels - must be 18
        'yPixelsNumMargin', 10, ...             % Y-margin
        'xPixelsNumMargin', 15, ...             % X-margin
        'upSampleFactor', uint8(3), ...         % Upsampling for better centering
        'chromaSpecification', struct(...
                'type', 'RGBsettings', ...
                'backgroundRGB', [0.5 0.5 0.5], ...   
                'foregroundRGB',  [0.4 0.4 0.4]), ...
        'visualizeScene', false, ...                % Whether to visualize the generated scene
        'plotDisplayCharacteristics', false ...     % Whether to visualize the display characteristics
       );
end