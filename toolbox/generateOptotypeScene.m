function [theScene, theBackgroundScene] = generateOptotypeScene(...
    presentationDisplay, theChar, theOrientation, varargin)

    % Parse optional input
    p = inputParser;
    p.addParameter('visualizeScene', false, @islogical);
    p.parse(varargin{:});
    visualizeScene = p.Results.visualizeScene;

    chromaSpecificationType = 'RGBsettings';
    chromaSpecification = struct(...
                'type', chromaSpecificationType, ...
                'backgroundRGB', [0.5 0.5 0.5], ...
                'foregroundRGB',  [0.4 0.4 0.4]);
      
    letterHeightPixels = 20;
    letterWidthPixels = 18;
    yPixelsNumMargin = 10;
    xPixelsNumMargin = 15;

    textSceneParams = struct(...
        'textString', theChar, ...                              % Text to display
        'textRotation', theOrientation, ...                     % Rotation (0,90,180,270 only)
        'rowsNum', letterHeightPixels + yPixelsNumMargin*2, ... % Pixels along the vertical (y) dimension
        'colsNum', letterWidthPixels + xPixelsNumMargin*2, ...  % Pixels along the horizontal (x) dimension
        'targetRow', yPixelsNumMargin, ...                      % Y-pixel offset 
        'targetCol', xPixelsNumMargin, ...                      % X-pixel offset 
        'upSampleFactor', uint8(3), ...                         % Upsample the scene to increase the retinal image resolution
        'chromaSpecification', chromaSpecification ...          % Background and stimulus chromaticity
    );


    
    % Generate stimulus scene
    theScene = rotatedTextSceneRealizedOnDisplay(presentationDisplay, ...
        textSceneParams, visualizeScene);

    % Generate the background scene: zero contrast chroma specificiation
    chromaSpecification.foregroundRGB = chromaSpecification.backgroundRGB;
    textSceneParams.chromaSpecification = chromaSpecification;
    theBackgroundScene = rotatedTextSceneRealizedOnDisplay(presentationDisplay, ...
        textSceneParams, false);
end
