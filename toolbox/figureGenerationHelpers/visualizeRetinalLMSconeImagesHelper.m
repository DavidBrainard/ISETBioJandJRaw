function visualizeRetinalLMSconeImagesHelper(opticalImage, ...
             domainVisualizationLimits, ...
             domainVisualizationTicks)

    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
       'rowsNum', 1, ...
       'colsNum', 4, ...
       'heightMargin',  0.0, ...
       'widthMargin',    0.05, ...
       'leftMargin',     0.05, ...
       'rightMargin',    0.00, ...
       'bottomMargin',   0.05, ...
       'topMargin',      0.00);

    hFig = figure(4);
    clf;
    set(hFig, 'Position', [10 10 1650 500], 'Color', [1 1 1]);

    retinalLMSconeImages = oiGet(opticalImage, 'lms');
    retinalLMSconeImages = retinalLMSconeImages/max(retinalLMSconeImages(:));

    % retrieve the spatial support of the scene(in millimeters)
    spatialSupportMM = oiGet(opticalImage, 'spatial support', 'mm');
    
    % Convert spatial support in degrees
    optics = oiGet(opticalImage, 'optics');
    focalLength = opticsGet(optics, 'focal length');
    mmPerDegree = focalLength*tand(1)*1e3;
    spatialSupportDegs = spatialSupportMM/mmPerDegree;
    spatialSupportX = spatialSupportDegs(1,:,1)*60;
    spatialSupportY = spatialSupportDegs(:,1,2)*60;

    for k = size(retinalLMSconeImages,3):-1:1

        ax = subplot('Position', subplotPosVectors(1,4-k).v);

        imagesc(ax, spatialSupportX, spatialSupportY, squeeze(retinalLMSconeImages(:,:,k)));
        set(ax, 'FontSize', 16);
        axis(ax, 'image'); axis 'xy';
        set(ax, 'XTick', domainVisualizationTicks.x*60, 'YTick', domainVisualizationTicks.y*60, ...
                'XTickLabel', sprintf('%2.2f\n', domainVisualizationTicks.x), ...
                'YTickLabel', sprintf('%2.2f\n', domainVisualizationTicks.y));
        set(ax, 'XLim', domainVisualizationLimits(1:2)*60, 'YLim', domainVisualizationLimits(3:4)*60);
        xlabel('space (deg)');
        
        if (k == 1)
            ylabel('space (deg)');
        end
        colormap(ax, gray(1024));
        hC = colorbar(ax, 'south');
        switch k
            case 1
                hC.Label.String = 'retinal L-cone activation';
            case 2
                hC.Label.String = 'retinal M-cone activation';
            case 3
                hC.Label.String = 'retinal S-cone activation';
        end

        drawnow
    end

    projectBaseDir = ISETBioJandJRootPath();
    pdfFile = [fullfile(projectBaseDir, 'figures') filesep 'RetinalLMSconeImages.pdf'];
    NicePlot.exportFigToPDF(pdfFile,hFig, 300);

end

