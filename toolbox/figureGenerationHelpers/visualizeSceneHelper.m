function hFig = visualizeSceneHelper(theScene, ...
    thePresentationDisplay, domainVisualizationLimits, ...
    domainVisualizationTicks, varargin)

    p = inputParser;
    p.addParameter('fontSize', 30, @isscalar);
    p.addParameter('noXLabel', false, @islogical);
    p.addParameter('noYLabel', false, @islogical);
    p.addParameter('pdfFileName', '', @ischar);
    p.parse(varargin{:});
    fontSize = p.Results.fontSize;
    noXLabel = p.Results.noXLabel;
    noYLabel = p.Results.noYLabel;
    pdfFileName = p.Results.pdfFileName;

    % Compute the RGB settings for the display
    displayLinearRGBToXYZ = displayGet(thePresentationDisplay, 'rgb2xyz');
    displayXYZToLinearRGB = inv(displayLinearRGBToXYZ);
    
    % Extract the XYZ image representation
    xyzImage = sceneGet(theScene, 'xyz');

    pixelSizeDegs = sceneGet(theScene,'w angular resolution');

    % Linear RGB image
    displayLinearRGBimage = imageLinearTransform(xyzImage, displayXYZToLinearRGB);    
    displaySettingsImage = (ieLUTLinear(displayLinearRGBimage, displayGet(thePresentationDisplay, 'inverse gamma'))) / displayGet(thePresentationDisplay, 'nLevels');

    xPixels = size(xyzImage,2);
    yPixels = size(xyzImage,1);
    x = 1:xPixels;
    y = 1:yPixels;
    x = x-mean(x);
    y = y-mean(y);
    x = x*pixelSizeDegs;
    y = y*pixelSizeDegs;

    hFig = figure();
    set(hFig, 'Position', [10 10 700 700], 'Color', [1 1 1]);
    ax = subplot('Position', [0.17 0.14 0.80 0.80]);
    image(ax,x,y,displaySettingsImage);
    axis(ax, 'image')

    if (~isempty(domainVisualizationLimits))
        set(ax, 'XLim',domainVisualizationLimits(1:2), 'YLim', domainVisualizationLimits(3:4));
    end

    if (~isempty(domainVisualizationTicks))
        set(ax, 'XTick', domainVisualizationTicks.x, ...
                'XTickLabel', sprintf('%.2f\n', domainVisualizationTicks.x), ...
                'YTick', domainVisualizationTicks.y, ...
                'YTickLabel', sprintf('%.2f\n', domainVisualizationTicks.y))
    end

    set(ax, 'FontSize', fontSize);
    if (~noXLabel)   
        xlabel(ax, 'space, x (degs)');
    end
    if (~noYLabel)   
        ylabel(ax, 'space, y (degs)');
    end

    if (~isempty(pdfFileName))
        projectBaseDir = ISETBioJandJRootPath();
        fullPdfFileName = [fullfile(projectBaseDir, 'figures') filesep pdfFileName];
        NicePlot.exportFigToPDF(fullPdfFileName, hFig, 300);
    end

    close(hFig);
end
