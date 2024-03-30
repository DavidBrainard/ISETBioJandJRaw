% Visualize the PSF stack
function visualizePSFstack(theOI, sampledWavelengths, psfRangeArcMin, pdfFilename)

    % Don't save the figure out unless the filename is passed.
    if (nargin < 4 || isempty(pdfFilename))
        pdfFilename = [];
    end
  
    colsNum = 7;
    rowsNum = 3;
    
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
        'rowsNum', rowsNum, ...
        'colsNum', colsNum, ...
        'heightMargin',  0.08, ...
        'widthMargin',    0.02, ...
        'leftMargin',     0.03, ...
        'rightMargin',    0.00, ...
        'bottomMargin',   0.04, ...
        'topMargin',      0.01);
    
    wavelengthSupport = oiGet(theOI, 'wave');
    pageNo = 0;
    for k = 1:numel(sampledWavelengths)
    
        kk = mod(k-1,21)+1;
        if (kk-1 == 0)
            hFig = figure(); clf;
            set(hFig,  'Color', [1 1 1], 'Position', [10 10 1800 900]);
        end
    
        [~,wIndex] = min(abs(wavelengthSupport-sampledWavelengths(k)));
        targetWavelength = wavelengthSupport(wIndex);
    
        row = floor((kk-1)/colsNum)+1;
        col = mod(kk-1,colsNum)+1;
        ax = subplot('Position', subplotPosVectors(row,col).v);
        visualizePSF(theOI, targetWavelength, psfRangeArcMin, ...
            'contourLevels', 0.1:0.1:0.9, ...
            'axesHandle', ax, ...
            'figureTitle', sprintf('%2.0f nm', targetWavelength), ...
            'fontSize', 14);

        if ((kk-1 == 20) || (k == numel(sampledWavelengths)))
            drawnow;
            pageNo = pageNo + 1;

            % Check on pdfFiledir because we should never save files in
            % random places.  If it isn't passed, don't save it.
            if (~isempty(pdfFilename))
                NicePlot.exportFigToPDF(pdfFilename , hFig, 300);
            end
        end
    end
    
end