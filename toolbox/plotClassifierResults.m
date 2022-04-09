function plotClassifierResults(trainingData, predictedData)
    hFig = figure(); clf;
    set(hFig, 'Position', [10 10 950 500], 'Color', [1 1 1]);
    minFeature = min([ min(trainingData.features(:)) min(predictedData.features(:)) ]);
    maxFeature = max([ max(trainingData.features(:)) max(predictedData.features(:)) ]);
    
    % The training data
    ax = subplot(1,2,1);
    hold(ax, 'on');
    renderDecisionBoundary(ax,trainingData.decisionBoundary, true); 
    renderFeatures(ax, trainingData.features, trainingData.nominalClassLabels);
    xlabel(ax,'PCA #1 score');
    ylabel(ax,'PCA #2 score');
    title(ax,sprintf('In-sample percent correct: %2.3f', trainingData.pCorrect));
    axis(ax,'square');
    set(ax, 'XLim', [minFeature maxFeature], 'YLim', [minFeature maxFeature], 'FontSize', 12);
    colormap(ax,brewermap(1024, 'RdYlGn'));


    % The predicted data
    ax = subplot(1,2,2);
    hold(ax, 'on');
    renderDecisionBoundary(ax,trainingData.decisionBoundary, false); 
    renderFeatures(ax, predictedData.features, predictedData.nominalClassLabels);
    xlabel(ax,'PCA #1 score');
    ylabel(ax,'PCA #2 score');
    title(ax,sprintf('Out-of-sample percent correct: %2.3f', predictedData.pCorrect));
    axis(ax,'square');
    set(ax, 'XLim', [minFeature maxFeature], 'YLim', [minFeature maxFeature],  'FontSize', 12);
    colormap(ax,brewermap(1024, 'RdYlGn'));
    
end

function renderFeatures(ax, features, nominalLabels)

    idx = find(nominalLabels == 0);
    scatter(ax,features(idx,1), features(idx,2), 64, ...
        'MarkerFaceColor', [0.8 0.8 0.8], ...
        'MarkerEdgeColor', [0.2 0.2 0.2]); 
    hold('on')
    idx = find(nominalLabels == 1);
    scatter(ax,features(idx,1), features(idx,2), 64, ...
        'MarkerFaceColor', [0.4 0.4 0.4], 'MarkerEdgeColor', [0.9 0.9 0.9]);

    legend({'decision boundary', 'nominal class 0', 'nomimal class 1'})
end


function renderDecisionBoundary(ax, decisionBoundary, depictStrength)
    if (~isempty(decisionBoundary))
        N = length(decisionBoundary.x);
        if (depictStrength)
        % Decision boundary as a density plot
            imagesc(ax,decisionBoundary.x,decisionBoundary.y,reshape(decisionBoundary.z,[N N]));
        end
        % The decision boundary as a line
        [C,h] = contour(ax,decisionBoundary.x,decisionBoundary.y,reshape(decisionBoundary.z,[N N]), [0 0]);
        h.LineColor = [0 0 0];
        h.LineWidth = 2.0;
    end
end