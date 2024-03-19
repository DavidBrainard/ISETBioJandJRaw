function theOI = generateCustomOptics(psfDataFile, customPupilDiameterMM, customLensAgeYears)

    projectBaseDir = ISETBioJandJRootPath();

    fprintf('Loading custom PSF data from %s\n', fullfile(projectBaseDir,'data',psfDataFile));
    load(fullfile(projectBaseDir,'data',psfDataFile), 'opticsParams', 'thePSFensemble');
    
    % Reshape the PSFs from even-shaped to odd-shaped
    if (rem(numel(opticsParams.spatialSupportArcMin),2) == 0)
          [opticsParams, thePSFensemble] = reshapePSF(opticsParams, thePSFensemble);
    else
          fprintf('No correction needed: odd spatial support');
    end


    if (~isempty(customPupilDiameterMM))
        fprintf(2,'Applying custom pupil diameter: %f\n', customPupilDiameterMM);
        opticsParams.pupilDiameterMM = customPupilDiameterMM;
    end


    % Generate optics from the synthesized PSFs
    theOI = oiFromPSF(thePSFensemble, opticsParams.wavelengthSupport, ...
        opticsParams.spatialSupportArcMin, opticsParams.pupilDiameterMM, ...
        opticsParams.umPerDegree);

    % If we have a custom lens age, update theOI
    if (~isempty(customLensAgeYears))
        % Save the custom lens age in the opticsParams
        opticsParams.customLensAgeYears = customLensAgeYears;

        fprintf(2,'Applying custom lens age: %d\n', customLensAgeYears);

        % Get the optics
        theOptics = oiGet(theOI, 'optics');

        % Get the wavelength support 
        wls = opticsGet(theOptics, 'wave');

        % Compute lens density for the given age
        [~,lensUnitDensity] = LensTransmittance(wls(:),'Human','CIE', customLensAgeYears, opticsParams.pupilDiameterMM);

        % Get the default lens
        theLens = opticsGet(theOptics, 'lens');

        % Get the default lens density
        defaultLensDensity = theLens.get('unitdensity');

        % Update the lens density to the computed value
        theLens.set('unitdensity', lensUnitDensity);

        % Report density change
        customLensDensity = theLens.get('unitdensity');
        idx = find(defaultLensDensity>0);
        fprintf(2,'---> Lens density for %d year-old subject is %2.2f times that of the default subject. \n', ...
            customLensAgeYears, mean(customLensDensity(idx)./defaultLensDensity(idx)));

        % Update the optics with the updated lens
        theOptics = opticsSet(theOptics, 'lens', theLens);

        % Update the oi with the updated optics
        theOI = oiSet(theOI, 'optics', theOptics);
    end
    
    
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