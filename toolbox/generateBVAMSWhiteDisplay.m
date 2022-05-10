function presentationDisplay = generateBVAMSWhiteDisplay(...
    letterSizeDegs, letterSizePixels, spdDataFile, plotCharacteristics)

    % Load the RGB SPDs
    fprintf('Loading SPDs from %s\n', spdDataFile);
    load(spdDataFile, 'spd');
    
    spectralSupport(1) = 380;
    spectralSupport(2) = 1;
    spectralSupport(3) = 770;
    fprintf('Assuming spectral support with min %dnm, step: %dnm, max: %dnm \n',...
        spectralSupport(1), spectralSupport(2), spectralSupport(3));
    
    wave = spectralSupport(1):spectralSupport(2):spectralSupport(3); 
    wave = wave';
    
    if (size(spd,1) ~= size(wave,1))
        size(spd)
        size(wave)
        error('Inconsistent SPD and spectral support dimensionalities');
    end
    
    ambient = zeros(1,length(wave)); 
    ambient = ambient';
    
    presentationDisplay = generateCustomDisplay(...
           'dotsPerInch', 220, ...
           'spectralPowerDistributionWattsPerSteradianM2NanoMeter', spd, ...
           'wavelengthSupportNanoMeters', wave, ...
           'ambientSPDWattsPerSteradianM2NanoMeter', ambient, ...
           'gammaTable', repmat((linspace(0,1,1024)').^2, [1 3]), ...
           'plotCharacteristics', plotCharacteristics);
    
    
    pixelSizeMeters = displayGet(presentationDisplay, 'meters per dot');
    letterSizeMeters = letterSizePixels*pixelSizeMeters;
    desiredViewingDistance = 0.5*letterSizeMeters/(tand(letterSizeDegs/2));
    presentationDisplay = displaySet(presentationDisplay, 'viewing distance', desiredViewingDistance);
    
end