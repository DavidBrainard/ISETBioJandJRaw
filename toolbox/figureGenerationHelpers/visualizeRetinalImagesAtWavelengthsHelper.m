function visualizeRetinalImagesAtWavelengthsHelper(opticalImage, ...
             targetWavelengths, ...
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

    wavelengthSupport = oiGet(opticalImage, 'wave');
    hFig = figure(3);
    clf;
    set(hFig, 'Position', [10 10 1650 500], 'Color', [1 1 1]);

    retinalImagePhotonRate = oiGet(opticalImage, 'photons');

    % retrieve the spatial support of the scene(in millimeters)
    spatialSupportMM = oiGet(opticalImage, 'spatial support', 'mm');
    
    % Convert spatial support in degrees
    optics = oiGet(opticalImage, 'optics');
    focalLength = opticsGet(optics, 'focal length');
    mmPerDegree = focalLength*tand(1)*1e3;
    spatialSupportDegs = spatialSupportMM/mmPerDegree;
    spatialSupportX = spatialSupportDegs(1,:,1)*60;
    spatialSupportY = spatialSupportDegs(:,1,2)*60;

    for k = 1:numel(targetWavelengths)
        [~,wIndex] = min(abs(wavelengthSupport-targetWavelengths(k)));
        targetWavelength = wavelengthSupport(wIndex);
    
        ax = subplot('Position', subplotPosVectors(1,k).v);
        imagesc(ax, spatialSupportX, spatialSupportY, squeeze(retinalImagePhotonRate(:,:,wIndex)));
        set(ax, 'FontSize', 16);
        axis(ax, 'image'); axis 'xy';
        set(ax, 'XTick', domainVisualizationTicks.x*60, 'YTick', domainVisualizationTicks.y*60, ...
                'XTickLabel', sprintf('%2.1f\n', domainVisualizationTicks.x), ...
                'YTickLabel', sprintf('%2.1f\n', domainVisualizationTicks.y));
        set(ax, 'XLim', domainVisualizationLimits(1:2)*60, 'YLim', domainVisualizationLimits(3:4)*60);
        xlabel('space (deg)');
        
        if (k == 1)
            ylabel('space (deg)');
        end
        colormap(ax, gray(1024));
        hC = colorbar(ax, 'south');
        hC.Label.String = sprintf('retinal irradiance (photons/m^2/sec)');

        title(ax, sprintf('%d nm', targetWavelength));
        drawnow
    end

    projectBaseDir = ISETBioJandJRootPath();
    pdfFile = [fullfile(projectBaseDir, 'figures') filesep 'RetinalImages.pdf'];
    NicePlot.exportFigToPDF(pdfFile,hFig, 300);

end


