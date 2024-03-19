function visualizeConeMosaicHelper(theConeMosaic, ...
    domainVisualizationLimits, domainVisualizationTicks, varargin)

    p = inputParser;
    p.addParameter('activation', [], @isnumeric);
    p.addParameter('activationRange', [], @(x)(isempty(x)||(numel(x)==2)));
    p.addParameter('colorLUT', brewermap(1024, '*greys')), @(x)((size(x,2) == 3));
    p.addParameter('displayColorBar', true, @islogical);
    p.addParameter('colorBarLocation', 'south', @ischar);
    p.addParameter('plotTitle', '', @ischar);
    p.addParameter('fontSize', 30, @isscalar);
    p.addParameter('noXLabel', false, @islogical);
    p.addParameter('noYLabel', false, @islogical);
    p.addParameter('pdfFileName', '', @ischar);
    p.parse(varargin{:});

    activation = p.Results.activation;
    activationRange = p.Results.activationRange;
    colorLUT = p.Results.colorLUT;
    displayColorBar = p.Results.displayColorBar;
    colorBarLocation = p.Results.colorBarLocation;
    plotTitle = p.Results.plotTitle;
    fontSize = p.Results.fontSize;
    noXLabel = p.Results.noXLabel;
    noYLabel = p.Results.noYLabel;
    pdfFileName = p.Results.pdfFileName;

    hFig = figure();
    set(hFig, 'Position', [10 10 700 700], 'Color', [1 1 1]);
    ax = subplot('Position', [0.17 0.14 0.80 0.80]);

    if (isempty(activationRange))
        activationRange = max(abs(activation(:)))*[-1 1];
    end


    theConeMosaic.visualize(...
            'figureHandle', hFig, ...
            'axesHandle', ax, ...
            'domain', 'degrees', ...
            'activation', activation, ...
            'activationRange', activationRange, ...
            'visualizeCones', false, ...
            'activationColorMap', colorLUT, ...
            'verticalActivationColorBarInside', displayColorBar, ...
            'domainVisualizationLimits', domainVisualizationLimits, ...
            'domainVisualizationTicks', domainVisualizationTicks, ...
            'noYLabel', noYLabel, ...
            'noXLabel', noXLabel, ...
            'plotTitle', sprintf('cone modulation (max: %2.3f)', max(abs(activation(:)))), ...
            'fontSize', fontSize, ...
            'plotTitleFontSize', fontSize-4, ...
            'backgroundColor', [0 0 0]);
     xtickangle(ax, 0);
     ytickangle(ax, 0);

    if (displayColorBar)
        hC = colorbar(ax, colorBarLocation);
        hC.Label.String = sprintf('cone excitations');
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
