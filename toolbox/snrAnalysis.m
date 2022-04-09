function snrAnalysis(stim1NoisyInstances, stim2NoisyInstances, template, ...
    signal1Name, signal2Name, ax, signalRange)

    % Compute reponses pooled by optimal template
    template = squeeze(template);
    n2 = (norm(template))^2;
    
    nTrials = size(stim1NoisyInstances,1);
    for i = 1:nTrials
        signal1(i) = dot(squeeze(stim1NoisyInstances(i,:,:)), template)/n2;
        signal2(i) = dot(squeeze(stim2NoisyInstances(i,:,:)), template)/n2;
    end
    
    d = (mean(signal1)-mean(signal2))/(0.5*std(signal1,1)+0.5*std(signal2,1));

    % Plot the distribution of signals
    minAll = min([min(signal1(:)) min(signal2(:))]);
    maxAll = max([max(signal1(:)) max(signal2(:))]);
    edges = linspace(minAll, maxAll, 32);
    h1 = histcounts(signal1,edges);
    h2 = histcounts(signal2,edges);
    
    bar(ax,edges(1:end-1),h1,1, 'FaceColor', [0.4 1 1]);
    hold(ax,'on');
    bar(ax,edges(1:end-1),h2,0.5, 'FaceColor', [0.95 0.2 0.4]);
    legend(ax,{signal1Name, signal2Name})
    set(ax, 'FontSize', 14);
    xlabel(ax,'dot(s, templ.)/norm(templ.)^2');
    set(ax, 'XLim', signalRange, 'YLim', [0 200], 'YTick', 0:50:200)
    grid(ax, 'on');
    box(ax, 'off');
    title(ax,sprintf('d'' = %2.3f', d));
end

