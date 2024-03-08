function theConeMosaic = generateCustomConeMosaic(integrationTime, ...
    theOI, mosaicSizeDegs, varargin)

    p = inputParser;
    p.addParameter('customMPD', [], @(x)(isempty(x)||isscalar(x)));
    p.addParameter('customConeDensities', [], @(x)(isempty(x)||(isnumeric(x)&&(numel(x)==3))));
    p.parse(varargin{:});
    customMPD = p.Results.customMPD;
    customConeDensities = p.Results.customConeDensities;

    % Get microns/deg from the OI
    optics = oiGet(theOI, 'optics');
    focalLengthMicrons = opticsGet(optics, 'focal length')*1e6;
    micronsPerDegree = focalLengthMicrons*tand(1);
    
    % Generate cone mosaic
    if (~isempty(customMPD))
        fprintf(2,'Applying custom mac pigment density: %f\n', customMPD);
        % Create custom macular pigment
        theMacularPigment = Macular('density', customMPD);

        if (~isempty(customConeDensities))
            fprintf(2,'Applying custom cone densities: %f %f %f\n', customConeDensities(1), customConeDensities(2), customConeDensities(3));
            % Generate cMosaic with custom cone densities
            theConeMosaic = cMosaic(...
                'sizeDegs', mosaicSizeDegs, ...
                'micronsPerDegree', micronsPerDegree, ...
                'integrationTime', integrationTime, ...
                'macular', theMacularPigment, ...
                'coneDensities', customConeDensities);
        else
            % Generate cMosaic with default cone densities
            theConeMosaic = cMosaic(...
                'sizeDegs', mosaicSizeDegs, ...
                'micronsPerDegree', micronsPerDegree, ...
                'integrationTime', integrationTime, ...
                'macular', theMacularPigment);
        end
    else
        % Generate cMosaic with default macular pigment
        if (~isempty(customConeDensities))
            fprintf(2,'Applying custom cone densities: %f %f %f\n', customConeDensities(1), customConeDensities(2), customConeDensities(3));
            % Generate cMosaic with custom cone densities
            theConeMosaic = cMosaic(...
                'sizeDegs', mosaicSizeDegs, ...
                'micronsPerDegree', micronsPerDegree, ...
                'integrationTime', integrationTime, ...
                'coneDensities', customConeDensities);
        else
            % Generate cMosaic with default cone densities
            theConeMosaic = cMosaic(...
                'sizeDegs', mosaicSizeDegs, ...
                'micronsPerDegree', micronsPerDegree, ...
                'integrationTime', integrationTime);
        end
    end
end
