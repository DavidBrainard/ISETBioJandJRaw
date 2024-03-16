%% PlotSummaryFrom_runTask2
%
% By: Derek Nankivil, 4/3/2023
%
%
%% Initialize

Subj_Num = 18;
%SubDir = ['FullVis_PSFs_Subject' num2str(Subj_Num)];
SubDir = ['FullVis_PSFs_Subject' '18'];
DataPath = 'Z:\ISETBioJandJ-main\results\White_Stimulus_160cpdpm2_20pctContrast';
save_rendered = 1;
[fileList,~]=F_walkFolders1([DataPath '\' SubDir],'.mat');
[w,~] = size(fileList);
progressbar('Get Data');

%% Calculations
for n = 1:w
    frac1 = n/w;
    progressbar(frac1) % Update progress bar
    load(fileList(n,1:end),'threshold');
    VA(n,1) = log10(threshold*60/5); % VA (logMAR)
    LCA_str = extractBetween(fileList(n,1:end),'LCA_','_TCA');
    LCA(n,1) = str2double(LCA_str)/1000;
    TCA_Hz_str = extractBetween(fileList(n,1:end),'TCA_Hz','_TCA');
    TCA_Hz(n,1) = str2double(TCA_Hz_str);
    TCA_Vt_str = extractBetween(fileList(n,1:end),'TCA_Vt','_Reps');
    TCA_Vt(n,1) = str2double(TCA_Vt_str);
end

TCA_vals = unique(TCA_Vt);
for n = 1:length(TCA_vals)
    [row, ~] = find(TCA_Vt == TCA_vals(n));
    VA_sub(:,n) = VA(row,1);
    LCA_sub(:,n) = LCA(row,1);
end

for n = 1:length(TCA_vals)
    VA_change(n,:) = VA_sub(1,:) - VA_sub(n,:);
end

%% Plotting
ax_title_font = 28;
ax_tick_font = 24;
sup_title_font = 30;
[ line_style,point_style,color_spec ] = F_line_specifier4(width(LCA_sub));
figure('units','normalized','OuterPosition',[0.01 0.05 0.95 0.75])
subplot(1,2,1)
hold on
for n = 1:width(LCA_sub)
    plot(LCA_sub(:,n),VA_sub(:,n),'-o','LineWidth',2,'Color',color_spec{n},...
        'MarkerSize',8,'MarkerFaceColor',color_spec{n});
    leg_label{n} = [num2str(TCA_vals(n)/1000)];
end
xlim([-0.25 3.75]);
ylim([-0.7 -0.1]);
yticks([-0.7:0.1:-0.1]);
xlabel('LCA (D)', 'FontSize',ax_title_font);
ylabel('Visual Acuity (logMAR)','FontSize',ax_title_font);
set(gca,'FontSize',ax_tick_font);
leg = legend(leg_label,'Location','SouthEast','FontSize',12);
title(leg,'TCA (arcmin)');
hold off

subplot(1,2,2)
hold on
for n = 1:width(LCA_sub)
    plot(LCA_sub(:,n),VA_change(:,n),'-o','LineWidth',2,'Color',color_spec{n},...
        'MarkerSize',8,'MarkerFaceColor',color_spec{n});
    leg_label{n} = [num2str(TCA_vals(n)/1000)];
end
xlim([-0.25 3.75]);
ylim([-0.3 0.05]);
yticks([-0.3:0.05:0.05]);
xlabel('LCA (D)', 'FontSize',ax_title_font);
ylabel('Change in Visual Acuity (logMAR)','FontSize',ax_title_font);
set(gca,'FontSize',ax_tick_font);
plot([-0.25 3.75],[0 0], 'k', 'LineWidth',0.5);
hold off

supheader = ['Subject ' num2str(Subj_Num)];
sgtitle(supheader, 'FontSize', sup_title_font, 'Interpreter', 'none');

if save_rendered
    saveas(gcf,fullfile(DataPath, [SubDir '_CA_Results']),'png');
end