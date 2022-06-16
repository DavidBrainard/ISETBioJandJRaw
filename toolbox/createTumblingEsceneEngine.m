function tumblingEsceneEngine = createTumblingEsceneEngine(orientation, varargin)

    % Parse
    p = inputParser;
    p.addParameter('customSceneParams', [], @(x)(isempty(x)||(isstruct(x))));
    p.parse(varargin{:});
    customSceneParams = p.Results.customSceneParams;

    % Handle to the compute function which will compute a new scene
    % which varies in the size of 'E' letter (the variable for which 
    % we assess performance)
    sceneComputeFunction = @sceTumblingEscene;

    if (isempty(customSceneParams))
        % Retrieve the default params for the tumbingE scene
        sceneParams = sceneComputeFunction();
    else
        sceneParams = customSceneParams;
    end


    % Change the orientation to the passed orientation
    sceneParams.letterRotationDegs = orientation;

    % Instantiate a tumblingEsceneEngine
    tumblingEsceneEngine = sceneEngine(sceneComputeFunction, sceneParams);
end
