function exportSimulation(questObj, threshold, fittedPsychometricParams, ...
    thresholdParameters, classifierPara, questEnginePara, ...
    tumblingEsceneEngines, theNeuralEngine, classifierEngine)
        
    dataToSave = questdlg('Which data to save?', ...
	    'Data export', ...
	    'Everything (multi-GB file)','Results only', 'Nothing', 'Results only');
    
    % Handle response
    switch (dataToSave)
        case 'Everything (multi-GB file)'
            exportedData = 'everything';
        case 'Results only'
            exportedData = 'results';
        otherwise
            fprintf('Simulation results not saved.\n');
            return;
    end

    dataFileName = 'TumblingESimulationResults.mat';
    [file, path] = uiputfile('*.mat', 'Simulation results export', dataFileName);

    if (isequal(file,0) || (isequal(path,0)))
        fprintf('Simulation results not saved.\n');
    else
        dataFileName  = fullfile(path,file);
        if (strcmp(exportedData, 'everything'))
            save(dataFileName, 'questObj','threshold','fittedPsychometricParams',...
                'thresholdParameters', 'classifierPara', 'questEnginePara', ...
                'tumblingEsceneEngines', 'theNeuralEngine', 'classifierEngine', '-v7.3');
            fprintf('Full simulation saved in %s.\n', dataFileName);
        else
            save(dataFileName, 'questObj','threshold','fittedPsychometricParams',...
                'thresholdParameters', '-v7.3');
            fprintf('Simulation results saved in %s.\n', dataFileName);
        end
    end
end
