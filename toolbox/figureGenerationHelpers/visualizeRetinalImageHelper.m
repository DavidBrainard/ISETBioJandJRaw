function visualizeRetinalImageHelper(theOpticalImage, visualizedWavelength, ...
                domainVisualizationLimits, domainVisualizationTicks, varargin)
            
    p = inputParser;
    p.addParameter('retinalIrradianceRange', [], @(x)(isempty(x)||(numel(x)==2)));
    p.addParameter('colorLUT', brewermap(1024, 'greys')), @(x)((size(x,2) == 3));
    p.addParameter('displayColorBar', true, @islogical);
    p.addParameter('colorBarLocation', 'south', @ischar);
    p.addParameter('plotTitle', '', @ischar);
    p.addParameter('fontSize', 30, @isscalar);
    p.addParameter('noXLabel', false, @islogical);
    p.addParameter('noYLabel', false, @islogical);
    p.addParameter('pdfFileName', '', @ischar);
    p.parse(varargin{:});

    retinalIrradianceRange = p.Results.retinalIrradianceRange;
    colorLUT = p.Results.colorLUT;
    displayColorBar = p.Results.displayColorBar;
    colorBarLocation = p.Results.colorBarLocation;
    plotTitle = p.Results.plotTitle;
    fontSize = p.Results.fontSize;
    noXLabel = p.Results.noXLabel;
    noYLabel = p.Results.noYLabel;
    pdfFileName = p.Results.pdfFileName;


    wavelengthSupport = oiGet(theOpticalImage, 'wave');
    retinalImagePhotonRate = oiGet(theOpticalImage, 'photons');

    % retrieve the spatial support of the scene(in millimeters)
    spatialSupportMM = oiGet(theOpticalImage, 'spatial support', 'mm');
    
    % Convert spatial support in degrees
    optics = oiGet(theOpticalImage, 'optics');
    focalLength = opticsGet(optics, 'focal length');
    mmPerDegree = focalLength*tand(1)*1e3;
    spatialSupportDegs = spatialSupportMM/mmPerDegree;
    spatialSupportX = spatialSupportDegs(1,:,1);
    spatialSupportY = spatialSupportDegs(:,1,2);

    [~,wIndex] = min(abs(wavelengthSupport-visualizedWavelength));
    
    hFig = figure();
    set(hFig, 'Position', [10 10 700 700], 'Color', [1 1 1]);
    ax = subplot('Position', [0.17 0.14 0.80 0.80]);
    imagesc(ax, spatialSupportX, spatialSupportY, squeeze(retinalImagePhotonRate(:,:,wIndex)));
    axis(ax, 'image')

    if (~isempty(domainVisualizationLimits))
        set(ax, 'XLim',domainVisualizationLimits(1:2), 'YLim', domainVisualizationLimits(3:4));
    end

    if (~isempty(domainVisualizationTicks))
        set(ax, 'XTick', domainVisualizationTicks.x, ...
                'XTickLabel', sprintf('%.1f\n', domainVisualizationTicks.x), ...
                'YTick', domainVisualizationTicks.y, ...
                'YTickLabel', sprintf('%.1f\n', domainVisualizationTicks.y))
    end

    if (~isempty(retinalIrradianceRange))
        set(ax, 'CLim', retinalIrradianceRange)
    end

    set(ax, 'FontSize', fontSize);
    if (~noXLabel)   
        xlabel(ax, 'space, x (degs)');
    end
    if (~noYLabel)   
        ylabel(ax, 'space, y (degs)');
    end

    if (isempty(colorLUT))
        colormap(ax, gray(1024));
    else
        colormap(ax, colorLUT)
    end

    if (displayColorBar)
        hC = colorbar(ax, colorBarLocation);
        hC.Label.String = sprintf('retinal irradiance (photons/m^2/sec)');
    end

    if (~isempty(plotTitle))
        title(ax, plotTitle)
    end

    if (~isempty(pdfFileName))
        projectBaseDir = ISETBioJandJRootPath();
        fullPdfFileName = [fullfile(projectBaseDir, 'figures') filesep pdfFileName];
        NicePlot.exportFigToPDF(fullPdfFileName, hFig, 300);
    end

    close(hFig);
end

