function theOI = generateCustomOptics(psfDataFile)

    fprintf('Loading custom PSF data from %s\n', psfDataFile);
    load(psfDataFile, 'opticsParams', 'thePSFensemble');
    
    % Reshape the PSFs from even-shaped to odd-shaped
    if (rem(numel(opticsParams.spatialSupportArcMin),2) == 0)
          [opticsParams, thePSFensemble] = reshapePSF(opticsParams, thePSFensemble);
    else
          fprintf('No correction needed: odd spatial support');
    end

    % Generate optics from the synthesized PSFs
    theOI = oiFromPSF(thePSFensemble, opticsParams.wavelengthSupport, ...
        opticsParams.spatialSupportArcMin, opticsParams.pupilDiameterMM, opticsParams.umPerDegree);
end



% Reshape PSFs from even-shape to odd-shape 
function [opticsParams, thePSFensemble] = reshapePSF(opticsParams, thePSFensemble)

  nOdd = numel(opticsParams.spatialSupportArcMin)+1;
  theOddSpatialSupportArcMin = linspace(...
      opticsParams.spatialSupportArcMin(1), ...
      opticsParams.spatialSupportArcMin(end), ...
      nOdd);

  % Ensure the spatial support is zero at the center
  centerPos = floor(numel(theOddSpatialSupportArcMin)/2)+1;
  assert(abs(theOddSpatialSupportArcMin(centerPos))< 100*eps, 'support at zero > 100 * eps')
  theOddSpatialSupportArcMin(centerPos) = 0;


  nWaves = numel(opticsParams.wavelengthSupport);
  theOddSizedPSFensemble = zeros(nOdd, nOdd, nWaves);

  [Xeven,Yeven] = meshgrid(opticsParams.spatialSupportArcMin);
  [Xodd,Yodd] = meshgrid(theOddSpatialSupportArcMin);

  for iWave = 1:nWaves
      tmp = interp2( ...
          Xeven, ...
          Yeven, ...
          squeeze(thePSFensemble(:,:,iWave)), ...
          Xodd, ...
          Yodd, ...
          'linear');
       theOddSizedPSFensemble(:,:,iWave) = tmp;
  end

  thePSFensemble = theOddSizedPSFensemble;
  opticsParams.spatialSupportArcMin = theOddSpatialSupportArcMin; 
end