function theConeMosaic = generateCustomConeMosaic(integrationTime, theOI, mosaicSizeDegs)

    % Get microns/deg from the OI
    optics = oiGet(theOI, 'optics');
    focalLengthMicrons = opticsGet(optics, 'focal length')*1e6;
    micronsPerDegree = focalLengthMicrons*tand(1);
    
    % Generate cone mosaic
    theConeMosaic = cMosaic(...
        'sizeDegs', mosaicSizeDegs, ...
        'micronsPerDegree', micronsPerDegree, ...
        'integrationTime', integrationTime);
end
