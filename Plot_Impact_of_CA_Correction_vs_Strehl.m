%% Plot impact of CA correction vs monochromatic strehl
%
% By: Derek Nankivil, 5/23/2023

%% Initialize
TCA_dis = 'zero';   % Set to zero for monochromatic (baseline)
LCA_dis = TCA_dis;
VA_best_fname = 'Uniform_FullVis_LCA_2203_TCA_Hz0_TCA_Vt0_Reps_512.mat';   % Suggest: Monochromatic VA
VA_fname = 'Uniform_FullVis_LCA_2203_TCA_Hz200_TCA_Vt400_Reps_512.mat';     % Select value of LCA and TCA correction here
save_rendered = 1;

%% Get list of wavefront files
datpath = 'E:\Manuscripts\Chromatic Aberration\WaveAberrationsForDereksModel\';
fileList_WF = dir(fullfile(datpath, '*.csv'));

%% Get list of VA results directories
pathstr = 'Z:\ISETBioJandJ-main\results\White_Stimulus_4cpdpm2_20pctContrast';
[fileList_VA,folderList_VA]=F_walkFolders1(pathstr,'.mat');
folderList_VA = folderList_VA(2:end,:); % Eliminate results folder

%% Main - strehl
if exist('Monochromatic_Strehl.mat', 'file') == 2
    disp('loading existing monochromatic strehl file');
    load('Monochromatic_Strehl.mat');
else
    strehl = zeros(1,length(fileList_WF));     % Initialize
    for n = 1:length(fileList_WF)
        datfilename = fileList_WF(n).name;     % Select one wavefront file among the list
        [mtf_return, mtf_x_at_6cpd, mtf_x_area, mtf_y_at_6cpd, mtf_y_area] = F_Role_of_ChromaticAberration(datfilename,datpath,'TCA_dis',TCA_dis,'LCA_dis',LCA_dis,'save_each_psf',1);
        strehl(n) = mtf_return.strehl;
    end
end

%% Main - VA results
[rows, cols] = size(folderList_VA);
VA = zeros(1,rows); % Initialize
VA_best = VA;
VA_change = VA;
progressbar('Loading VA Data');
for n = 1:rows
    frac = n/rows;
    progressbar(frac);
    load([folderList_VA(n,1:end) '\' VA_fname]);
    VA(n) = log10(threshold*60/5);              % VA (logMAR)
    load([folderList_VA(n,1:end) '\' VA_best_fname]);
    VA_best(n) = log10(threshold*60/5);
    VA_change(n) = VA_best(n) - VA(n);
end
% Pre (ocular)
LCA_str = extractBetween(VA_fname,'LCA_','_TCA');
LCA_eye = str2double(LCA_str)/1000;
TCA_Vt_str = extractBetween(VA_fname,'TCA_Vt','_Reps');
TCA_Vt_eye = str2double(TCA_Vt_str)/1000;
% Post (with correction)
LCA_str = extractBetween(VA_best_fname,'LCA_','_TCA');
LCA_post = str2double(LCA_str)/1000;
TCA_Vt_str = extractBetween(VA_best_fname,'TCA_Vt','_Reps');
TCA_Vt_post = str2double(TCA_Vt_str)/1000;

%% Plot results
ax_title_font = 28;
ax_tick_font = 24;
[ line_style,point_style,color_spec ] = F_line_specifier4(2);
figure('units','normalized','OuterPosition',[0.01 0.05 0.45 0.75])
plot(strehl,VA_change,'o','LineWidth',2,'Color',color_spec{2},...
    'MarkerSize',8,'MarkerFaceColor',color_spec{2});
hold on
% Linear fit
    P = polyfit(strehl,VA_change,1);
    x_fit = linspace((min(strehl)-0.05),(max(strehl)+0.05),500);
    y_fit = polyval(P,x_fit);
    plot(x_fit,y_fit,'LineWidth',2,'Color',color_spec{2});
xlim([0 0.5]);
xlabel('Monochromatic Strehl Ratio', 'FontSize',ax_title_font);
ylabel('Change in Visual Acuity (logMAR)','FontSize',ax_title_font);
set(gca,'FontSize',ax_tick_font);
title(   ['LCA_{pre} = '  num2str(LCA_eye,2)  ' D, TCA_{pre} = '  num2str(TCA_Vt_eye)  ' arcmin'],'Interpreter', 'tex','FontWeight','normal');
subtitle(['LCA_{post} = ' num2str(LCA_post,2) ' D, TCA_{post} = ' num2str(TCA_Vt_post) ' arcmin'],'Interpreter', 'tex');
ylim([-0.2 0.05]);
plot([0 0.5],[0 0],'k');
if P(2) > 0
    text(0.65,0.95,['y = ' num2str(P(1),2) 'x + ' num2str(abs(P(2)),2)],'Units','Normalized','FontSize',18);
else
    text(0.65,0.95,['y = ' num2str(P(1),2) 'x - ' num2str(abs(P(2)),2)],'Units','Normalized','FontSize',18);
end
hold off

%% Save plot
if save_rendered
    saveas(gcf,fullfile(pathstr, ['Impact_of_CA_Correction_vs_Strehl']),'png');
end
