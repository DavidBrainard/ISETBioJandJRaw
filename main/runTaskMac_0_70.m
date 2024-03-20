% This script calculates visual acuity for a set of specified PSFs. 
%
% As configured, it reproduces for Subject 9 the results in Figure X of the
% paper.
%
% To run this script, you need Matlab, some of its toolboxes, and the
% following on your path.
%
%     ISETBioCSFGenerator, branch ChromAbPaper, https://github.com/isetbio/ISETBioCSFGenerator.git
%     isetbio, branch ChromAbPaper, https://github.com/isetbio/isetbio.git
%     mQUESTPlus, https://github.com/brainardlab/mQUESTPlus.git
%     Palamedes Toolbox, https://palamedestoolbox.org, version 1.8.2.
%        [This may work with more recent versions, but we run against 1.8.2.
%        You may need to write to the Palamedes team to get that version.]

function runTask()
    % Clear out
    clear; close all;

    % No waitbar
    ieSessionGet('waitbar');

    % Close all figures
    close all;

    % Make sure figures and results directories exist so that output writes
    % don't fail
    rootPath = ISETBioJandJRootPath;
    if (~exist(fullfile(rootPath,'figures'),'dir'))
        mkdir(fullfile(rootPath,'figures'));
    end
    if (~exist(fullfile(rootPath,'results'),'dir'))
        mkdir(fullfile(rootPath,'results'));
    end

    % Parameters. These control many aspects of what gets done, particular the subject. 
    params = struct(...
        'spdDataFile', 'BVAMS_White_Guns_At_Max.mat', ...           % Datafile containing the display SPDs.  Change to BVAMS_White_Guns_At_Max_HL.mat for high luminance condition.
        'psfDataSubDir', 'FullVis_PSFs_20nm_Subject9', ...          % Subdir where the PSF data live
        'psfDataFile', '',...                                       % Datafile containing the PSF data
        'letterSizesNumExamined',  9, ...                           % How many sizes to use for sampling the psychometric curve (9 used in the paper)
        'maxLetterSizeDegs', 0.2, ...                               % The maximum letter size in degrees of visual angle
        'sceneUpSampleFactor', 4, ...                               % Upsample scene, so that the pixel for the smallest scene is < cone aperture
        'mosaicIntegrationTimeSeconds', 500/1000, ...               % Integration time, here 500 msec
        'nTest', 512, ...                                           % Number of trial to use for computing Pcorrect
        'thresholdP', 0.781, ...                                    % Probability correct level for estimating threshold performance
        'customLensAgeYears', [], ...                               % Lens age in years (valid range: 20-80), or empty to use the default age        
        'customMacularPigmentDensity', 0.7, ...                     % Cstom MPD, or empty to use the default; example, 0.4
        'customConeDensities', [], ...                              % Custom L-M-S ratio or empty to use default; example [0.6 0.3 0.1]
        'customPupilDiameterMM', [], ...                            % Custom pupil diameter in MM or empty to use the value from the psfDataFile
        'visualizedPSFwavelengths', [], ...                         % Vector with wavelengths for visualizing the PSF. If set to empty[] there is no visualization; example 400:20:700
        'visualizeDisplayCharacteristics', ~true, ...               % Flag, indicating whether to visualize the display characteristics
        'visualizeScene', ~true, ...                                % Flag, indicating whether to visualize one of the scenes
        'visualEsOnMosaic', ~true ...                               % Flag, indicating whether to visualize E's against mosaic as function of their size
    );

    % For each PSF file, we also tabulate the amount of LCA in D, and TCA
    % in microns, rounded.
    % 
    % This code as is runs many but not all of the LCA/TCA combinations
    % reported in the paper.  Add in the rest of the PSF data files if you
    % want them all.
    examinedPSFDataFiles = {...
        'Uniform_FullVis_LCA_0_TCA_Hz0_TCA_Vt0.mat'     , 0, 0 ; ...
        'Uniform_FullVis_LCA_1278_TCA_Hz0_TCA_Vt0.mat'  , 1.3, 0 ; ...
        'Uniform_FullVis_LCA_2203_TCA_Hz0_TCA_Vt0.mat'  , 2.2, 0 ; ...
        'Uniform_FullVis_LCA_2665_TCA_Hz0_TCA_Vt0.mat'  , 2.7, 0 ; ...
        'Uniform_FullVis_LCA_3590_TCA_Hz0_TCA_Vt0.mat'  , 3.6, 0 ; ...

        'Uniform_FullVis_LCA_0_TCA_Hz200_TCA_Vt400.mat'    , 0, 0.4 ; ...
        'Uniform_FullVis_LCA_1278_TCA_Hz200_TCA_Vt400.mat' , 1.3, 0.4 ; ...
        'Uniform_FullVis_LCA_2203_TCA_Hz200_TCA_Vt400.mat' , 2.2, 0.4 ; ...
        'Uniform_FullVis_LCA_2665_TCA_Hz200_TCA_Vt400.mat' , 2.7, 0.4 ; ...
        'Uniform_FullVis_LCA_3590_TCA_Hz200_TCA_Vt400.mat' , 3.6, 0.4 ; ...

        'Uniform_FullVis_LCA_0_TCA_Hz790_TCA_Vt1580.mat'    , 0, 1.58 ; ...
        'Uniform_FullVis_LCA_1278_TCA_Hz790_TCA_Vt1580.mat' , 1.3, 1.58 ; ...
        'Uniform_FullVis_LCA_2203_TCA_Hz790_TCA_Vt1580.mat' , 2.2, 1.58 ; ...
        'Uniform_FullVis_LCA_2665_TCA_Hz790_TCA_Vt1580.mat' , 2.7, 1.58 ; ...
        'Uniform_FullVis_LCA_3590_TCA_Hz790_TCA_Vt1580.mat' , 3.6, 1.58 ; ...

        'Uniform_FullVis_LCA_0_TCA_Hz1380_TCA_Vt2760.mat'    , 0, 2.76 ; ...
        'Uniform_FullVis_LCA_1278_TCA_Hz1380_TCA_Vt2760.mat' , 1.3, 2.76 ; ...
        'Uniform_FullVis_LCA_2203_TCA_Hz1380_TCA_Vt2760.mat' , 2.2, 2.76 ; ...
        'Uniform_FullVis_LCA_2665_TCA_Hz1380_TCA_Vt2760.mat' , 2.7, 2.76 ; ...
        'Uniform_FullVis_LCA_3590_TCA_Hz1380_TCA_Vt2760.mat' , 3.6, 2.76 ; ...

        'Uniform_FullVis_LCA_0_TCA_Hz1970_TCA_Vt3940.mat'     , 0, 3.94 ; ...
        'Uniform_FullVis_LCA_1278_TCA_Hz1970_TCA_Vt3940.mat' , 1.3, 3.94 ; ...
        'Uniform_FullVis_LCA_2203_TCA_Hz1970_TCA_Vt3940.mat' , 2.2, 3.94 ; ...
        'Uniform_FullVis_LCA_2665_TCA_Hz1970_TCA_Vt3940.mat' , 2.7, 3.94 ; ...
        'Uniform_FullVis_LCA_3590_TCA_Hz1970_TCA_Vt3940.mat' , 3.6, 3.94 ; ...

        'Uniform_FullVis_LCA_0_TCA_Hz3150_TCA_Vt6300.mat'    , 0, 6.3 ; ...
        'Uniform_FullVis_LCA_1278_TCA_Hz3150_TCA_Vt6300.mat' , 1.3, 6.3 ; ...
        'Uniform_FullVis_LCA_2203_TCA_Hz3150_TCA_Vt6300.mat' , 2.2, 6.3 ; ...
        'Uniform_FullVis_LCA_2665_TCA_Hz3150_TCA_Vt6300.mat' , 2.7, 6.3 ; ...
        'Uniform_FullVis_LCA_3590_TCA_Hz3150_TCA_Vt6300.mat' , 3.6, 6.3 ...
        };

    % Set up summary filename and output dir
    summaryFileName = sprintf('Summary_%s_%dms.mat', strrep(params.psfDataSubDir, '.mat', ''), round(1000*params.mosaicIntegrationTimeSeconds));
    if (~isempty(params.customMacularPigmentDensity))
        summaryFileName = strrep(summaryFileName, '.mat', sprintf('_MPD_%2.2f.mat', params.customMacularPigmentDensity));
    end
    if (~isempty(params.customPupilDiameterMM))
        summaryFileName = strrep(summaryFileName, '.mat', sprintf('_pupilDiamMM_%2.2f.mat', params.customPupilDiameterMM));
    end
    if (~isempty(params.customConeDensities))
        summaryFileName = strrep(summaryFileName, '.mat', sprintf('_cones_%2.2f_%2.2f_%2.2f.mat', params.customConeDensities(1), params.customConeDensities(2), params.customConeDensities(3)));
    end
    if (~isempty(params.customLensAgeYears))
        summaryFileName = strrep(summaryFileName, '.mat', sprintf('_lensAge_%d.mat', params.customLensAgeYears));
    end
    params.outputResultsDir = fullfile(ISETBioJandJRootPath,'results',strrep(summaryFileName, '.mat',''));
    params.outputFiguresDir =  fullfile(ISETBioJandJRootPath,'figures',strrep(summaryFileName, '.mat',''));
    if (~exist(params.outputResultsDir,'dir'))
        mkdir(params.outputResultsDir);
    end
    if (~exist(params.outputFiguresDir,'dir'))
        mkdir(params.outputFiguresDir);
    end

    % Loop over all the specified PSFs.  This loop saves the data out for
    % each PSF, as well as accumulates the threshold for each.
    for iPSF = 1:size(examinedPSFDataFiles,1)
        theConeMosaic = [];
        tempParams = params;
        tempParams.psfDataFile = examinedPSFDataFiles{iPSF,1};
        LCA(iPSF) = examinedPSFDataFiles{iPSF,2};
        TCA(iPSF) = examinedPSFDataFiles{iPSF,3};
        [theConeMosaic{iPSF},threshold(iPSF)] = runSimulation(tempParams, theConeMosaic);
        logMAR(iPSF) = log10(threshold(iPSF)*60/5);
    end

    % Save summary,  This allows examination of the numbers and/or
    % replotting.
    save(fullfile(params.outputResultsDir,summaryFileName),"examinedPSFDataFiles","threshold","logMAR","LCA","TCA","theConeMosaic");
    
    % Make and save a figure of what happened. This is not publication
    % quality, but does match up with the key figure in the paper in tersm
    % of its format. Values may differ from run to run because of
    % differeing random number sequences.
    LCAValues = unique(LCA);
    TCAValues = unique(TCA);
    legendStr = {};
    summaryFig = figure; clf;
    set(gcf,'Position',[100 100 1500 750]);
    subplot(1,2,1); hold on;
    for tt = 1:length(TCAValues)
        theColor(tt,:) = [1-tt/length(TCAValues) tt/length(TCAValues) 0];
        index = find(TCA == TCAValues(tt));
        plot(LCA(index),logMAR(index),'o-','Color',theColor(tt,:),'MarkerFaceColor',theColor(tt,:),'MarkerSize',10,'LineWidth',2);
        legendStr = [legendStr(:)' {['TCA ' num2str(TCAValues(tt))]}];
    end
    ylim([-0.35 0.15]);
    xlabel('LCA (D)');
    ylabel('VA (logMAR)');
    legend(legendStr);
    titleStr = LiteralUnderscore(strrep(summaryFileName,'.mat',''));
    title(titleStr);

    % This panel is the VA difference plot.
    subplot(1,2,2); hold on;
    for tt = 1:length(TCAValues)
        index = find(TCA == TCAValues(tt));
        tempLCA = LCA(index);
        tempLogMAR = logMAR(index);
        index1 = find(tempLCA == 0);
        plot(LCA(index),-(logMAR(index)-tempLogMAR(index1)),'o-','Color',theColor(tt,:),'MarkerFaceColor',theColor(tt,:),'MarkerSize',10,'LineWidth',2);
    end
    ylim([-0.35 0.15]);
    xlabel('LCA (D)');
    ylabel('VA (logMAR)');
    legend(legendStr);
    titleStr = LiteralUnderscore(strrep(summaryFileName,'.mat',''));
    title(titleStr);
    NicePlot.exportFigToPDF(fullfile(params.outputFiguresDir,strrep(summaryFileName,'.mat','.pdf')),summaryFig,300);
end

