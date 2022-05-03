function presentationDisplay = generateBVAMSWhiteDisplay(...
    letterSizeDegs, letterSizePixels, plotCharacteristics)

    % Load the RGB SPDs
    load('BVAMS_White_Guns_At_Max.mat', 'spd');
    wave = 380:770; wave = wave';
    
    ambient = zeros(1,length(wave)); 
    ambient = ambient';
    
    presentationDisplay = generateCustomDisplay(...
           'dotsPerInch', 220, ...
           'spectralPowerDistributionWattsPerSteradianM2NanoMeter', spd, ...
           'wavelengthSupportNanoMeters', wave, ...
           'ambientSPDWattsPerSteradianM2NanoMeter', ambient, ...
           'gammaTable', repmat((linspace(0,1,1024)').^2, [1 3]), ...
           'plotCharacteristics', plotCharacteristics);
    displayGet(presentationDisplay, 'peak luminance')
    
    pixelSizeMeters = displayGet(presentationDisplay, 'meters per dot');
    letterSizeMeters = letterSizePixels*pixelSizeMeters;
    desiredViewingDistance = 0.5*letterSizeMeters/(tand(letterSizeDegs/2));
    presentationDisplay = displaySet(presentationDisplay, 'viewing distance', desiredViewingDistance);
    
end