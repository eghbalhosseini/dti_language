clear all ;
close all; 
analysis_path='/Users/eghbalhosseini/MyData/dti_language/analysis';
addpath('/Users/eghbalhosseini/MyCodes/export_fig/');
%% analyze LH Temporal to LH Frontal based on sum  
%probtrack_folder='/Users/eghbalhosseini/MyData/dti_language/probtrackX_group_results_AntTemp_top_20-IFGorb_top_20-IFG_top_20-MFG_top_20_TO_AntTemp_top_20-IFGorb_top_20-IFG_top_20-MFG_top_20_EX_PostTemp_top_20-AngG_top_20/';
%probtrack_folder='/Users/eghbalhosseini/MyData/dti_language/probtrackX_group_results_PostTemp_top_20-IFGorb_top_20-IFG_top_20-MFG_top_20_TO_PostTemp_top_20-IFGorb_top_20-IFG_top_20-MFG_top_20_EX_AntTemp_top_20-AngG_top_20/';
%probtrack_folder='/Users/eghbalhosseini/MyData/dti_language/probtrackX_group_results_AntTemp_top_20-IFGorb_top_20-IFG_top_20-MFG_top_20_TO_AntTemp_top_20-IFGorb_top_20-IFG_top_20-MFG_top_20/';
%probtrack_folder='/Users/eghbalhosseini/MyData/dti_language/probtrackX_group_results_PostTemp_top_20-IFGorb_top_20-IFG_top_20-MFG_top_20_TO_PostTemp_top_20-IFGorb_top_20-IFG_top_20-MFG_top_20/';

probtrack_folers={'/Users/eghbalhosseini/MyData/dti_language/probtrackX_group_results_AntTemp_top_20-IFGorb_top_20-IFG_top_20-MFG_top_20_TO_AntTemp_top_20-IFGorb_top_20-IFG_top_20-MFG_top_20_EX_PostTemp_top_20-AngG_top_20/';
    '/Users/eghbalhosseini/MyData/dti_language/probtrackX_group_results_PostTemp_top_20-IFGorb_top_20-IFG_top_20-MFG_top_20_TO_PostTemp_top_20-IFGorb_top_20-IFG_top_20-MFG_top_20_EX_AntTemp_top_20-AngG_top_20/';
    '/Users/eghbalhosseini/MyData/dti_language/probtrackX_group_results_AntTemp_top_20-IFGorb_top_20-IFG_top_20-MFG_top_20_TO_AntTemp_top_20-IFGorb_top_20-IFG_top_20-MFG_top_20/';
    '/Users/eghbalhosseini/MyData/dti_language/probtrackX_group_results_PostTemp_top_20-IFGorb_top_20-IFG_top_20-MFG_top_20_TO_PostTemp_top_20-IFGorb_top_20-IFG_top_20-MFG_top_20/'};


titles={'AntTemp to IFGorb, IFG, and MFG; excluding PostTemp and AngG';
    'PostTemp to IFGorb, IFG, and MFG; excluding AntTemp and AngG';
    'AntTemp to IFGorb, IFG, and MFG';
    'PostTemp to IFGorb, IFG, and MFG'};

tracula_dpaths='/Users/eghbalhosseini/MyData/dti_language/tracula_dpath/';
trac_paths={'lh.unc_AS_avg33_mni_bbr','lh.slft_PP_avg33_mni_bbr','lh.slfp_PP_avg33_mni_bbr','lh.ilf_AS_avg33_mni_bbr','lh.cst_AS_avg33_mni_bbr','lh.ccg_PP_avg33_mni_bbr','lh.cab_PP_avg33_mni_bbr'};
%
trac_names={'Uncinate fasciculus','Superior longitudinal fasciculus (temporal)','Superior longitudinal fasciculus (paretial)','Inferior longitudinal fasciculus','Cortico spinal','cingulate gyrus','Cingulum - angular bundle.'};
%% 
%
index=1;
probtrack_folder= probtrack_folers{index};
fig_title=titles{index};

train_dti=load(fullfile('/Users/eghbalhosseini/MyData/dti_language/probtrackX_results/','train_dti_analysis'));
train_dti=train_dti.train_dti;
subs=train_dti.train_subs;
all_subs=dir(probtrack_folder);
pattern = 'sub\d{3}';
extractedPatterns = cellfun(@(filename) regexp(filename, pattern, 'match', 'once'), ...
                            {all_subs.name}, 'UniformOutput', false);
extractedPatterns = extractedPatterns(~cellfun('isempty', extractedPatterns));
extractedPatterns=unique(extractedPatterns);

subs=subs(cell2mat(cellfun(@(x) any(ismember(extractedPatterns,x)),subs,'UniformOutput',false)));

bad_sub={'sub007';'sub072';'sub106';'sub124';'sub126';'sub135';'sub136';'sub138';'sub148';'sub159';'sub163';'sub171';'sub172';'sub190';'sub195';'sub199';'sub202';'sub206';'sub210';'sub234';'sub254';'sub298';'sub311';'sub540';'sub541'; 'sub721'};
subs=sort(subs(~cell2mat(cellfun(@(x) any(ismember(bad_sub,x)),subs,'UniformOutput',false)))');
%
threshold=0;
sub_vox_count=[];
for sub_id=1:size(subs,1)
    probtrac_nii_file=sprintf("%s/%s_LH_fdt_paths.nii.gz",probtrack_folder,subs{sub_id});
    probrac_nii_data = double(niftiread(probtrac_nii_file));
    [rows_p, cols_p, pages_p] = ind2sub(size(probrac_nii_data),find(probrac_nii_data~=0));
    filtered_values = probrac_nii_data(sub2ind(size(probrac_nii_data), rows_p, cols_p, pages_p));
    assert(all(filtered_values>0))
    filtered_probrac_vector = reshape(filtered_values, 1, []);
    path_by_trac={};
    for k=1:size(trac_paths,2)
        trac_path=trac_paths{k};
        dpath_nii_file=sprintf("%s/%s/dpath/%s/path.pd.nii.gz",tracula_dpaths,subs{sub_id},trac_path);
        tracula_nii_data = double(niftiread(dpath_nii_file));
        
        tracula_vector=tracula_nii_data(:);
        tracula_vector_nonzero=tracula_vector(tracula_vector~=0);
        threshold=prctile(tracula_vector_nonzero,50);
        
        % create a mask 
        index_tracula_nii_data=tracula_nii_data>threshold;
        % multiply the mask by probtrac
        A=index_tracula_nii_data.*probrac_nii_data;
        %[rows_t, cols_t, pages_t] = ind2sub(size(A),find(tracula_nii_data~=threshold));
        %filtered_values = tracula_nii_data(sub2ind(size(tracula_nii_data), rows_t, cols_t, pages_t));
        %filtered_row_vector = reshape(filtered_values, 1, []);
        filtered_A_values = A(sub2ind(size(A), rows_p, cols_p, pages_p));
        filtered_A_row_vector = reshape(filtered_A_values, 1, []);
        path_by_trac=[path_by_trac;filtered_A_row_vector];
    end 
    vox_count=cell2mat(cellfun(@(x) sum(x==filtered_probrac_vector)/length(x)*100, path_by_trac,'UniformOutput',false));
    sub_vox_count=[sub_vox_count,vox_count];
end

%% 
f=figure('Units', 'centimeters', 'Position', [0, 0, 21, 29.7]); % A4 size: 21x29.7 cm
% Calculate means and standard deviations
means = mean(sub_vox_count, 2);         % Mean of each row (Subject)
stdDevs = std(sub_vox_count, 0, 2);     % Standard deviation of each row

% Define number of subjects
numSubjects = size(sub_vox_count, 1);

% Define colors using a colormap (e.g., parula)
cmap = parula(numSubjects);

% Create a figure with optimized size
figure('Position', [100, 100, 800, 600]);
factor=21/29.7 ;
ax1=axes('position',[.3,.4,.3,.6*factor]);
% Create a bar graph with customized colors
b = bar(means, 'FaceColor', 'flat', 'EdgeColor', 'k');
for k = 1:numSubjects
    b.CData(k,:) = cmap(3,:);
end
hold on;

% Plot error bars with enhanced visibility
errorbar(1:numSubjects, means, stdDevs/sqrt(size(sub_vox_count,2)), ...
    'k', 'LineStyle', 'none', 'LineWidth', 1.5, 'CapSize', 10, 'Marker', 'none');

% Customize the axes
ylabel({'Mean and Standard Deviation of','Percentages for Each Subject'}, 'FontSize',12, 'FontWeight', 'normal');
title(sprintf('%s\n', fig_title), ...
    'FontSize', 14, 'FontWeight', 'bold');

% Customize the x-axis labels
xticks(1:numSubjects);
xticklabels(arrayfun(@(x) trac_names{x}, 1:numSubjects, 'UniformOutput', false));
xtickangle(45); % Rotate labels by 45 degrees for better readability

% Set y-axis limits
ylim([0, 40]);

% Add grid lines for better readability


% Set font size for axes ticks
set(gca, 'FontSize', 12, 'FontWeight', 'bold');

% Optional: Add data labels on top of each bar
for k = 1:numSubjects
    text(k, means(k) + stdDevs(k)/sqrt(size(sub_vox_count,2)) + 1, ...
        sprintf('%.1f', means(k)), ...
        'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');
end

hold off;

% Optional: Add a colorbar if colors represent specific information
% colorbar;

%export_fig(sprintf('/Users/eghbalhosseini/MyData/dti_language/tracula/probtrac_by_tracula_%s_nsub_%d.pdf',fig_title,sub_id), '-pdf', '-transparent');