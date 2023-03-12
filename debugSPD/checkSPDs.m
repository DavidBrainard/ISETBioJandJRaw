function checkSPDs()

    % Generate testimage (linearRGB)
    linearRGBimage = generateTestPattern();
    
    % Default display
    AppleDisplay = displayCreate();
    
    % BVAMS display
    testEsizeDegs = 0.2; nPixelRows = 10; plotDisplayCharacteristics = false;
    spdDataFile = 'BVAMS_White_Guns_At_Max.mat';
    ambientSPDDataFile = 'BVAMS_White_Background.mat';
    BVAMSWhiteDisplay = generatePresentationDisplay(testEsizeDegs, nPixelRows, spdDataFile, ambientSPDDataFile, plotDisplayCharacteristics);
    
    % Generate scene rendered on Apple display
    theScene1 = generateSceneFromLinearRGBimage(linearRGBimage, AppleDisplay);
    
    % Generate scene rendered on BVAMSWhite display
    theScene2 = generateSceneFromLinearRGBimage(linearRGBimage, BVAMSWhiteDisplay);
    
    % Display the scenes
    figure(1); clf;
    subplot(3,3,1)
    plotStimulus(linearRGBimage, 'linearRGB');
    
    subplot(3,3,2);
    plotStimulus(theScene1, 'Apple display');
    
    subplot(3,3,3);
    plotStimulus(theScene2, 'BVAMSWhite display');
    
    % Plot the SPDs
    subplot(3,3,5);
    plotSPDs(AppleDisplay)

    subplot(3,3,6);
    plotSPDs(BVAMSWhiteDisplay);
    
    subplot(3,3,8);
    plotCIEcoords(AppleDisplay);
    
    subplot(3,3,9);
    plotCIEcoords(BVAMSWhiteDisplay);
end

function linearRGBimage = generateTestPattern()
    nPixelRows = 5;
    mPixelCols = 5;
    nChannels = 3;
    linearRGBimage = 0.5 + zeros(nPixelRows,mPixelCols,nChannels);

    % Red corner
    linearRGBimage(1,1,1) = 1;
    linearRGBimage(1,1,2) = 0;
    linearRGBimage(1,1,3) = 0;
    
    % Green corner
    linearRGBimage(1,mPixelCols,1) = 0;
    linearRGBimage(1,mPixelCols,2) = 1;
    linearRGBimage(1,mPixelCols,3) = 0;
    
    % Blue corner
    linearRGBimage(nPixelRows,mPixelCols,1) = 0;
    linearRGBimage(nPixelRows,mPixelCols,2) = 0;
    linearRGBimage(nPixelRows,mPixelCols,3) = 1;
    
    % White corner
    linearRGBimage(nPixelRows,1,1) = 1;
    linearRGBimage(nPixelRows,1,2) = 1;
    linearRGBimage(nPixelRows,1,3) = 1;
    
    % Black pixel
    linearRGBimage(2,2,1:nChannels) = 0.0;
end
    
function plotStimulus(theScene, displayName)
    if (isstruct(theScene))
        image(lrgb2srgb(sceneGet(theScene, 'rgbimage')))
    else
        image(lrgb2srgb(theScene));
    end
    set(gca, 'XTick', [], 'YTick', [], 'FontSize', 16);
    axis 'image'
    title(displayName);
end
    
    
function plotSPDs(presentationDisplay)
    wave = displayGet(presentationDisplay, 'wave');
    spds = displayGet(presentationDisplay, 'spd');
    plot(wave, spds(:,1)*1e3, 'r.-', 'LineWidth', 1.5);
    hold on;
    plot(wave, spds(:,2)*1e3, 'g.-', 'LineWidth', 1.5);
    plot(wave, spds(:,3)*1e3, 'b.-', 'LineWidth', 1.5);
    axis 'square';
    set(gca, 'XTick', 400:100:800, 'XLim', [350 800], 'FontSize', 16);
    ylabel('milliWatts/sr/m^2/nm')
end
    
function plotCIEcoords(presentationDisplay)
    rgb2xyzMap = displayGet(presentationDisplay, 'rgb2xyz');
    xyzRgun = imageLinearTransform([1 0 0], rgb2xyzMap);
    xyzGgun = imageLinearTransform([0 1 0], rgb2xyzMap);
    xyzBgun = imageLinearTransform([0 0 1], rgb2xyzMap);
    xyzAgun = imageLinearTransform([1 1 1], rgb2xyzMap);
    
    xRgun = xyzRgun(1)/sum(xyzRgun);
    yRgun = xyzRgun(2)/sum(xyzRgun);
    xGgun = xyzGgun(1)/sum(xyzGgun);
    yGgun = xyzGgun(2)/sum(xyzGgun);
    xBgun = xyzBgun(1)/sum(xyzBgun);
    yBgun = xyzBgun(2)/sum(xyzBgun);
    xAgun = xyzAgun(1)/sum(xyzAgun);
    yAgun = xyzAgun(2)/sum(xyzAgun);
    
    xTicks = [0.1 xAgun 0.6 0.9];
    yTicks = [0.1 yAgun 0.6 0.9];
    
    % Render the CIE diagram
    renderCIEdiagramBackground()
    
    plot([xRgun xGgun xBgun xRgun], [yRgun yGgun yBgun yRgun], 'k-', 'LineWidth', 1.0);
    hold on;
    
    plot(xRgun, yRgun, 'rs', 'MarkerSize', 12, 'MarkerFaceColor', [1 0.5 0.5]);
    plot(xGgun, yGgun, 'gs', 'MarkerSize', 12, 'MarkerFaceColor', [0.5 1 0.5]);
    plot(xBgun, yBgun, 'bs', 'MarkerSize', 12, 'MarkerFaceColor', [0.5 0.5 1]);
    plot(xAgun, yAgun, 'ks', 'MarkerSize', 12, 'MarkerFaceColor', [0.5 0.5 0.5]);
    
    set(gca, 'XLim', [0 0.9], 'YLim', [0 0.9], 'XTick', xTicks,  'XTickLabel', sprintf('%1.2f\n', xTicks));
    set(gca, 'YTick', yTicks, 'YTickLabel', sprintf('%1.2f\n', yTicks));
    axis 'square'
    axis 'xy'
    set(gca, 'FontSize', 16);
    grid on
end

function theScene = generateSceneFromLinearRGBimage(linearRGBimage, presentationDisplay)
    % Extract inverse gamma table 
    inverseGammaTable = displayGet(presentationDisplay, 'inverse gamma')/displayGet(presentationDisplay, 'nlevels');

    % Gamma un-correct linear RGB values (primaries) through the display's
    % gamma table to get RGB settings values, so that when they are passed
    % through the display's gamma table we get back the desired linear RGB values
    gammaUncorrectedRGBimage = ieLUTLinear(linearRGBimage, inverseGammaTable);
    
    theScene = sceneFromFile(gammaUncorrectedRGBimage,'rgb', [], presentationDisplay);
end

function renderCIEdiagramBackground()
    % Method to render the shoehorse CIE color background
    wave = 420:5:700;
    XYZcolorMatchingFunctions = ieReadSpectra('XYZ', wave);
    xOutline = XYZcolorMatchingFunctions(:,1)./sum(XYZcolorMatchingFunctions,2);
    yOutline = XYZcolorMatchingFunctions(:,2)./sum(XYZcolorMatchingFunctions,2);
    xOutline(end+1) = xOutline(1);
    yOutline(end+1) = yOutline(1);

    N = 500;
    x = (0:(N-1))/N;
    [X,Y] = meshgrid(x);
    [iCol, iRow] = meshgrid(1:N);
    iCol = iCol(:); iRow = iRow(:);
    X = X(:); Y = Y(:);
    [in,on] = inpolygon(X(:),Y(:),xOutline,yOutline);
    idx = find(in==true);
    backgroundLuminance = 90;
    lum = zeros(numel(idx),1) + backgroundLuminance/683;
    XYZ = xyYToXYZ([X(idx) Y(idx) lum]');
    c = xyz2rgb(XYZ');
    c(c<0) = 0;
    c(c>1) = 1;

    backgroundImage = zeros(N,N,3)+1;
    for ix = 1:numel(idx)
        if (in(idx(ix))) || (on(idx(ix)))
           theColor = c(ix,:);
           backgroundImage(iRow(idx(ix)),iCol(idx(ix)),:) = theColor;
        end
    end
    x = (0:(N-1))/N;
    image(x,x,backgroundImage);
    hold on
    plot([0 0 0.9 0.9 0], [0 0.9 0.9 0 0], 'k-');
    plot(xOutline,yOutline,'ko-', 'MarkerFaceColor', 'k');
    indices = [1 10 14:2:35 37 57];
    for k = 1:numel(indices)
        wI = indices(k);
        text(xOutline(wI)+0.01, yOutline(wI)+0.02, sprintf('%2.0f',wave(wI)));
    end
    set(gca, 'XLim', [0 0.9], 'YLim', [0 0.9], 'XTick', 0:0.1:1, 'YTick', 0:0.1:1, 'FontSize', 16);
end