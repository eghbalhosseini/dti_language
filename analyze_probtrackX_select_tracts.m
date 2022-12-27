% probtrack results folder
clear all 
close all 

probtrack_folder='/Users/eghbalhosseini/MyData/dti_language/probtrackX_results_IFG_top_20-PostTemp_top_20_TO_IFG_top_20-PostTemp_top_20_EX_MFG_top_20';
%probtrack_folder='/Users/eghbalhosseini/MyData/dti_language/probtrackX_results_IFG_top_10-PostTemp_top_10_TO_IFG_top_10-PostTemp_top_10_EX_MFG_top_10';
%probtrack_folder='/Users/eghbalhosseini/MyData/dti_language/probtrackX_results_IFGorb_top_90-AntTemp_top_90_TO_IFGorb_top_90-AntTemp_top_90_EX_MFG_top_90';
analysis_path='/Users/eghbalhosseini/MyData/dti_language/analysis';
% get files both LH and RH 
fdt_files=dir(fullfile(probtrack_folder,'*fdt_network.mat'));
sub_ids=regexp({fdt_files(:).name},'sub\d+','match');
sub_ids=cellfun(@(x) x(1) , sub_ids);
unique_subs=unique(sub_ids);
% pick a random set of 60 subject 

% pick a random set of 60 subject 
rng(1)
% ids=randi(length(unique_subs),1,60);
% train_subs=unique_subs(ids);
train_subs=datasample(unique_subs,60,'Replace',false);

% rng(1)
% ids=randi(length(unique_subs),1,60);
% train_subs=unique_subs(ids);

% get the files for these subjects 
LH_cell={};
RH_cell={};
id_fill=0;
for id_sub=1:length(train_subs)
    sub=train_subs{id_sub};
    overlap=find(strcmp(sub_ids,sub));
    if (length(overlap)==2)
        id_fill=id_fill+1;
    for file_id=overlap
        file_dat=load(fullfile(fdt_files(file_id).folder,fdt_files(file_id).name),'fdt_st');
        file_dat=file_dat.fdt_st;
        switch file_dat.hemi
            case 'LH'
                LH_cell{id_fill,1}=file_dat.fdt_mat;
                LH_cell{id_fill,2}=file_dat.targets;
                LH_cell{id_fill,3}=file_dat.sub_id;
            case 'RH'
                RH_cell{id_fill,1}=file_dat.fdt_mat;
                RH_cell{id_fill,2}=file_dat.targets;
                RH_cell{id_fill,3}=file_dat.sub_id;
        end 
    end
    end 
end 

%% do some checks to make sure everything is properly aligned across subjects
LH_targets=[LH_cell{:,2}];
LH_fdt=[LH_cell(:,1)];
LH_subs=[LH_cell(:,3)];
% check that the labels are the same for the subjects in each row 
arrayfun(@(x) assert(length(unique(LH_targets(x,:)))==1), 1:size(LH_targets,1));

RH_targets=[RH_cell{:,2}];
RH_fdt=[RH_cell(:,1)];
arrayfun(@(x) assert(length(unique(RH_targets(x,:)))==1), 1:size(RH_targets,1));
RH_subs=[RH_cell(:,3)];
assert(all(cellfun(@(x,y) strcmp(x,y), RH_subs,LH_subs)));

%% do some cleanning 
% LH 
% make symmetric by summing up upper and lower halves
temp_fdt=cellfun(@(t) (triu(t)+transpose(tril(t)))/2, LH_fdt,'uni',false); 
temp_fdt=cellfun(@(t_sym) t_sym+transpose(triu(t_sym)), temp_fdt,'uni',false); 
temp_fdt_sum=cellfun(@(t) t./(.5*sum(sum(t))),temp_fdt,'uni',false);
temp_fdt_max=cellfun(@(t) t./(max(max(t))),temp_fdt,'uni',false);
cellfun(@(x) assert(issymmetric(x)),temp_fdt_sum)
cellfun(@(x) assert(issymmetric(x)),temp_fdt_max)
LH_fdt_raw=temp_fdt;
LH_fdt_max=temp_fdt_max;
LH_fdt_sum=temp_fdt_sum;
% RH 
temp_fdt=cellfun(@(t) (triu(t)+transpose(tril(t)))/2, RH_fdt,'uni',false); 
temp_fdt=cellfun(@(t_sym) t_sym+transpose(triu(t_sym)), temp_fdt,'uni',false); 
temp_fdt_sum=cellfun(@(t) t./(.5*sum(sum(t))),temp_fdt,'uni',false);
temp_fdt_max=cellfun(@(t) t./(max(max(t))),temp_fdt,'uni',false);
cellfun(@(x) assert(issymmetric(x)),temp_fdt)
cellfun(@(x) assert(issymmetric(x)),temp_fdt_sum)
cellfun(@(x) assert(issymmetric(x)),temp_fdt_max)
RH_fdt_raw=temp_fdt;
RH_fdt_max=temp_fdt_max;
RH_fdt_sum=temp_fdt_sum;


assert(all(cellfun(@(x,y) strcmp(x,y),LH_subs,train_subs')))
assert(all(cellfun(@(x,y) strcmp(x,y),RH_subs,train_subs')))
%% save it as a structure for future use 
train_dti=struct;
train_dti.train_subs=train_subs;
train_dti.train_LH_targets=LH_targets;
train_dti.train_RH_targets=RH_targets;

train_dti.train_LH_fdt_raw=LH_fdt_raw;
train_dti.train_LH_fdt_max=LH_fdt_max;
train_dti.train_LH_fdt_sum=LH_fdt_sum;

train_dti.train_RH_fdt_raw=RH_fdt_raw;
train_dti.train_RH_fdt_max=RH_fdt_max;
train_dti.train_RH_fdt_sum=RH_fdt_sum;


save(fullfile(probtrack_folder,'train_dti_analysis'),'train_dti');
%% do some checks to see if the data is well formatted 
% plot all the subjects 
y_plot=LH_fdt;
y_plot=cellfun(@(x) reshape(x,[],1),y_plot,'uni',false);
y_plot=cellfun(@(x) x(x~=0),y_plot,'uni',false);
y_plot=cellfun(@log,y_plot,'uni',false);
y_plot_lh=y_plot;
f=figure;
f.Position=[3893 541 1825 1095];
ax=subplot('position',[.1,.1,.8,.35])
hold on 
XJitterWidth=.5;
colors=brewermap(length(y_plot_lh),'Spectral');
arrayfun(@(x) swarmchart(ax,y_plot_lh{x}*0+x,y_plot_lh{x},5,'r','filled','XJitterWidth',XJitterWidth),1:length(y_plot_lh));
ax.YLabel.String='log(weight)';
ax.XLabel.String='subject';
ax.XTick=1:length(y_plot_lh);
ax.XTickLabel=LH_subs
ax.XTickLabelRotation=90;
ax.Title.String='weight distribution - LH';

y_plot=RH_fdt;
y_plot=cellfun(@(x) reshape(x,[],1),y_plot,'uni',false);
y_plot=cellfun(@(x) x(x~=0),y_plot,'uni',false);
y_plot=cellfun(@log,y_plot,'uni',false);
y_plot_rh=y_plot;

ax=subplot('position',[.1,.5,.8,.35])
hold on 
XJitterWidth=.5;
colors=brewermap(length(y_plot_rh),'Spectral');
arrayfun(@(x) swarmchart(ax,y_plot_rh{x}*0+x,y_plot_rh{x},5,'r','filled','XJitterWidth',XJitterWidth),1:length(y_plot_rh));
ax.YLabel.String='log(weight)';
ax.XLabel.String='subject';
ax.XTick=1:length(y_plot_rh);
ax.XTickLabel=[];
ax.XTickLabelRotation=90;
ax.Title.String='weight distribution - RH';

%% plot both of them together 
close all 
ff=figure;
ff.Position=[3893 541 1825 1095];
ff.PaperOrientation='landscape';
ax=subplot('position',[.1,.1,.8,.8]);
hold on;
XJitterWidth=.25;
%colors=brewermap(length(y_plot_lh),'Spectral');
colors=inferno(length(y_plot_lh)+5);
arrayfun(@(x) swarmchart(ax,y_plot_rh{x}*0+x+.2,y_plot_rh{x},15,colors(x,:),'filled','XJitterWidth',XJitterWidth,'markeredgecolor','w','linewidth',.2,'MarkerFaceAlpha',.2,'MarkerEdgeAlpha',.2),1:length(y_plot_rh));
arrayfun(@(x) swarmchart(ax,y_plot_lh{x}*0+x-.2,y_plot_lh{x},15,colors(x,:),'filled','XJitterWidth',XJitterWidth,'markeredgecolor',[.5,.5,.5],'linewidth',.2,'MarkerFaceAlpha',.2,'MarkerEdgeAlpha',.2),1:length(y_plot_lh));
ax.YLabel.String='log(weight)';
ax.XLabel.String='subject';
ax.XTick=1:length(y_plot_lh);
ax.XTickLabel=LH_subs;
ax.XTickLabelRotation=45;
ax.XLim=[0,length(y_plot_lh)+1]
print(ff,'-fillpage','-dpdf','-opengl', strcat(analysis_path,'/','weight_distribution_sample_subjects_lh_vs_rh.pdf'));

%% do plot the region to region fdt 
ff=figure()
ff.Units='Inches';
ff.Position=[55.5139 10.6250 11 8]
ff.PaperOrientation='landscape';
ax=subplot('position',[.2,.12,.85*8/11,.85])
imagesc(LH_fdt{1})
colormap((inferno()))
%grid on;

ax.XTick=[1:size(LH_fdt{1},1)]-0
ax.YTick=ax.XTick;
ax.GridColor=[1,1,1];
ax.GridAlpha=.2;
ax.GridLineStyle='-'
xtick_labels=strrep(LH_targets(:,1),'_', ' ')
xtick_labels=strrep(xtick_labels(:,1),'ROI', '')
ax.XAxis.TickDirection='out'
ax.YAxis.TickDirection='out'
ax.XTickLabel=xtick_labels
ax.XTickLabelRotation=90
ax.FontSize=3;
ax.YTickLabel=xtick_labels

cb=colorbar;
cb.Position = cb.Position + [.05,0,0,0];
cb.FontSize=8;
print(ff,'-fillpage','-dpdf','-painters', strcat(analysis_path,'/','example_LH_fdt.pdf'));
%% compute a correaltion between all LH matrices 
mask=triu(ones(size(LH_fdt{1})),1);
mask(mask==0)=nan;
LH_mask=cellfun(@(x) x.*mask,LH_fdt,'uni',false);
LH_mask=cellfun(@(x) reshape(x,1,[]),LH_mask,'uni',false)
LH_mask_1={};
for kk=1:size(LH_mask,1)
    LH_=LH_mask{kk};
    LH_(isnan(LH_))=[];
    LH_mask_1{kk,1}=LH_;
end 
LH_mask_1=cell2mat(LH_mask_1);
LH_corr=squareform(pdist(LH_mask_1,'correlation'));

ff=figure()
ff.Units='Inches';
ff.Position=[55.5139 10.6250 11 8]
ff.PaperOrientation='landscape';
ax=subplot('position',[.2,.12,.85*8/11,.85])
imagesc(1-LH_corr,[.8,1])
colormap((inferno()))
cb=colorbar;
cb.Position = cb.Position + [.05,0,0,0];
cb.FontSize=8;
print(ff,'-fillpage','-dpdf','-painters', strcat(analysis_path,'/','subject_LH_fdt_correlation.pdf'));
%% hypothesis 1. test difference in left and right connectivity for temporal to frontal connection 
LH_temporal_target=["LH_AntTemp_top_90";"LH_PostTemp_top_90";"LH_AngG_top_90"];
LH_frontal_target=["LH_IFGorb_top_90";"LH_IFG_top_90";"LH_MFG_top_90"];
% 
RH_temporal_target=["RH_AntTemp_top_90";"RH_PostTemp_top_90";"RH_AngG_top_90"];
RH_frontal_target=["RH_IFGorb_top_90";"RH_IFG_top_90";"RH_MFG_top_90"];
% 
[C,~,L_T]=intersect(LH_temporal_target,LH_targets,'stable');
[C,~,L_F]=intersect(LH_frontal_target,LH_targets,'stable');
%t=LH_fdt{1};
source_fdt=cellfun(@(t) t(L_T,:),LH_fdt,'uni',false);
target_fdt=cellfun(@(t) t(:,L_F),source_fdt,'uni',false);
LH_temp_frontal=cell2mat(cellfun(@(x) sum(sum(triu(x))), target_fdt,'uni',false));
% 
[C,~,R_T]=intersect(RH_temporal_target,RH_targets,'stable');
[C,~,R_F]=intersect(RH_frontal_target,RH_targets,'stable');

source_fdt=cellfun(@(t) t(R_T,:),RH_fdt,'uni',false);
target_fdt=cellfun(@(t) t(:,R_F),source_fdt,'uni',false);
RH_temp_frontal=cell2mat(cellfun(@(x) sum(sum(triu(x))), target_fdt,'uni',false));

% 
ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 11 8]
ff.PaperOrientation='landscape';

ax=subplot(1,1,1)
x=LH_temp_frontal;
y=RH_temp_frontal;
[hscatter,hbar,ax,ahist]=scatterDiagHist(x,y);
hscatter.Marker='o'
hscatter.MarkerFaceColor='r'
hscatter.MarkerEdgeColor='k'
hbar.FaceColor='r';
hbar.LineWidth=2;
[h,p]=ttest(x,y,'Tail','right')
ahist.Title.String=titles{h+1}
ahist.Title.Rotation=-45;
ahist.Title.FontSize=15
ahist.Title.Position=[0,max(ahist.YLim),0]
ax.XLabel.String=sprintf('%s \n--> frontal',strrep('LH temporal','_',' '));
ax.YLabel.String=sprintf('%s \n--> frontal',strrep('RH temporal','_',' '));
ax.FontSize=12;
%ylim([min([x;y]),max([x;y])])
%xlim([min([x;y]),max([x;y])])
print(ff,'-fillpage','-dpdf','-painters', strcat(analysis_path,'/','LH_RH_temporal_to_frontal.pdf'));


%% Hypothesis 2. nonlang temporal to lang frontal vs lang temporal to lang frontal 
LH_temp_lang_target=["LH_AntTemp_top_90";"LH_PostTemp_top_90";"LH_AngG_top_90"];
LH_front_lang_target=["LH_IFGorb_top_90";"LH_IFG_top_90";"LH_MFG_top_90"];
LH_PostTemp_nonlang_target=["LH_TPOJ1_ROI";"LH_STSdp_ROI";"LH_STSvp_ROI";"LH_A4_ROI"];
LH_AntTemp_nonlang_target=["LH_STSva_ROI";"LH_STSda_ROI";"LH_TE1a_ROI";"LH_TGd_ROI"];
LH_AngG_nonlang_target=["LH_PGs_ROI";"LH_PGi_ROI";"LH_PFm_ROI";"LH_TPOJ2_ROI"];
titles={'n.s.';'*'};
% post temp comparison 
 [C,~,L_T_Lang]=intersect("LH_PostTemp_top_90",LH_targets(:,1),'stable');
 [C,~,L_F]=intersect(LH_frontal_target,LH_targets(:,1),'stable');
 source_fdt=cellfun(@(t) t(L_T_Lang,:),LH_fdt,'uni',false);
 target_fdt=cellfun(@(t) t(:,L_F),source_fdt,'uni',false);
LH_PostTemp_Frontal=cell2mat(cellfun(@(x) sum(x), target_fdt,'uni',false));

LH_Posttemp_nonLang_frontal=[];
for kk=1:size(LH_PostTemp_nonlang_target)
    nonLang_ROI=LH_PostTemp_nonlang_target(kk);
    [C,~,L_T_nonLang]=intersect(nonLang_ROI,LH_targets(:,1),'stable');
    [C,~,L_F]=intersect(LH_frontal_target,LH_targets(:,1),'stable');
    source_fdt=cellfun(@(t) t(L_T_nonLang,:),LH_fdt,'uni',false);
    target_fdt=cellfun(@(t) t(:,L_F),source_fdt,'uni',false);
    LH_Posttemp_nonLang_frontal=[LH_Posttemp_nonLang_frontal,cell2mat(cellfun(@(x) sum(x), target_fdt,'uni',false))];
end 


ff.Units='Inches';
ff.Position=[55.5139 10.6250 11 8]
ff.PaperOrientation='landscape';

for kk=1:size(LH_PostTemp_nonlang_target)
    ax=subplot(2,2,kk)
    x=LH_PostTemp_Frontal;
    y=LH_Posttemp_nonLang_frontal(:,kk);
    scatter(x,y,25,'filled')
    [hscatter,hbar,ax,ahist]=scatterDiagHist(x,y)
    hscatter.Marker='o'
    hscatter.MarkerFaceColor='r'
    hscatter.MarkerEdgeColor='k'
    hbar.FaceColor='r';
    hbar.LineWidth=2;
    [h,p]=ttest(x,y,'Tail','right')
    ahist.Title.String=titles{h+1}
    ahist.Title.Rotation=-45;
    ahist.Title.FontSize=15
    ahist.Title.Position=[0,max(ahist.YLim),0]
    ax.XLabel.String=sprintf('%s \n--> frontal',strrep('LH_PostTemp_top_90','_',' '));
    ax.YLabel.String=sprintf('%s \n--> frontal',strrep(LH_PostTemp_nonlang_target(kk),'_',' '));
    ax.FontSize=8
    %ylim([min([x;y]),max([x;y])])
    %xlim([min([x;y]),max([x;y])])
end 
print(ff,'-fillpage','-dpdf','-opengl', strcat(analysis_path,'/','lang_postTemp_to_front_vs_nonlang.pdf'));




% ant temp comparison 
 [C,~,L_T_Lang]=intersect("LH_AntTemp_top_90",LH_targets(:,1),'stable');
 [C,~,L_F]=intersect(LH_frontal_target,LH_targets(:,1),'stable');
 source_fdt=cellfun(@(t) t(L_T_Lang,:),LH_fdt,'uni',false);
 target_fdt=cellfun(@(t) t(:,L_F),source_fdt,'uni',false);
LH_AntTemp_Frontal=cell2mat(cellfun(@(x) sum(x), target_fdt,'uni',false));

LH_anttemp_nonLang_frontal=[];
for kk=1:size(LH_AntTemp_nonlang_target)
    nonLang_ROI=LH_AntTemp_nonlang_target(kk);
    [C,~,L_T_nonLang]=intersect(nonLang_ROI,LH_targets(:,1),'stable');
    [C,~,L_F]=intersect(LH_frontal_target,LH_targets(:,1),'stable');
    source_fdt=cellfun(@(t) t(L_T_nonLang,:),LH_fdt,'uni',false);
    target_fdt=cellfun(@(t) t(:,L_F),source_fdt,'uni',false);
    LH_anttemp_nonLang_frontal=[LH_anttemp_nonLang_frontal,cell2mat(cellfun(@(x) sum(x), target_fdt,'uni',false))];
end 


ff.Units='Inches';
ff.Position=[55.5139 10.6250 11 8]
ff.PaperOrientation='landscape';

for kk=1:size(LH_AntTemp_nonlang_target)
    ax=subplot(2,2,kk)
    x=LH_AntTemp_Frontal;
    y=LH_anttemp_nonLang_frontal(:,kk);
    [hscatter,hbar,ax,ahist]=scatterDiagHist(x,y);
    hscatter.Marker='o'
    hscatter.MarkerFaceColor='r'
    hscatter.MarkerEdgeColor='k'
    hbar.FaceColor='r';
    hbar.LineWidth=2;
    ax.XLabel.String=sprintf('%s \n--> frontal',strrep('LH_AntTemp_top_90','_',' '));
    ax.YLabel.String=sprintf('%s \n--> frontal',strrep(LH_AntTemp_nonlang_target(kk),'_',' '));
    ax.FontSize=8;
    
    [h,p]=ttest(x,y,'Tail','right')
    ahist.Title.String=titles{h+1}
    ahist.Title.Rotation=-45;
    ahist.Title.FontSize=15
    ahist.Title.Position=[0,max(ahist.YLim),0]
    %ylim([min([x;y]),max([x;y])])
    %xlim([min([x;y]),max([x;y])])
end 
print(ff,'-fillpage','-dpdf','-opengl', strcat(analysis_path,'/','lang_AntTemp_to_front_vs_nonlang.pdf'));

% 
% AngG comparison 
 [C,~,L_T_Lang]=intersect("LH_AngG_top_90",LH_targets(:,1),'stable');
 [C,~,L_F]=intersect(LH_frontal_target,LH_targets(:,1),'stable');
 source_fdt=cellfun(@(t) t(L_T_Lang,:),LH_fdt,'uni',false);
 target_fdt=cellfun(@(t) t(:,L_F),source_fdt,'uni',false);
LH_AngG_Frontal=cell2mat(cellfun(@(x) sum(x), target_fdt,'uni',false));

LH_AngG_nonLang_frontal=[];
for kk=1:size(LH_AngG_nonlang_target)
    nonLang_ROI=LH_AngG_nonlang_target(kk);
    [C,~,L_T_nonLang]=intersect(nonLang_ROI,LH_targets(:,1),'stable');
    [C,~,L_F]=intersect(LH_frontal_target,LH_targets(:,1),'stable');
    source_fdt=cellfun(@(t) t(L_T_nonLang,:),LH_fdt,'uni',false);
    target_fdt=cellfun(@(t) t(:,L_F),source_fdt,'uni',false);
    LH_AngG_nonLang_frontal=[LH_AngG_nonLang_frontal,cell2mat(cellfun(@(x) sum(x), target_fdt,'uni',false))];
end 


ff.Units='Inches';
ff.Position=[55.5139 10.6250 11 8]
ff.PaperOrientation='landscape';

for kk=1:size(LH_AngG_nonlang_target)
    ax=subplot(2,2,kk)
    x=LH_AngG_Frontal;
    y=LH_AngG_nonLang_frontal(:,kk);
    [hscatter,hbar,ax,ahist]=scatterDiagHist(x,y);
    hscatter.Marker='o'
    hscatter.MarkerFaceColor='r'
    hscatter.MarkerEdgeColor='k'
    hbar.FaceColor='r';
    hbar.LineWidth=2;
    ax.XLabel.String=sprintf('%s \n--> frontal',strrep('LH_AngG_top_90','_',' '));
    ax.YLabel.String=sprintf('%s \n--> frontal',strrep(LH_AngG_nonlang_target(kk),'_',' '));
    ax.FontSize=8;
    
    [h,p]=ttest(x,y,'Tail','right')
    ahist.Title.String=titles{h+1}
    ahist.Title.Rotation=-45;
    ahist.Title.FontSize=15
    ahist.Title.Position=[0,max(ahist.YLim),0]
    %ylim([min([x;y]),max([x;y])])
    %xlim([min([x;y]),max([x;y])])
end 
print(ff,'-fillpage','-dpdf','-opengl', strcat(analysis_path,'/','lang_AngG_to_front_vs_nonlang.pdf'));