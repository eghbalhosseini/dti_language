% probtrack results folder
clear all
close all
probtrack_folder='/Users/eghbalhosseini/MyData/dti_language/';
analysis_path='/Users/eghbalhosseini/MyData/dti_language/analysis';

folders={'probtrackX_results_IFG_top_20-PostTemp_top_20_TO_IFG_top_20-PostTemp_top_20_EX_MFG_top_20';
    'probtrackX_results_IFG_top_10-PostTemp_top_10_TO_IFG_top_10-PostTemp_top_10_EX_MFG_top_10';
    'probtrackX_results_IFGorb_top_10-AntTemp_top_10_TO_IFGorb_top_10-AntTemp_top_10_EX_MFG_top_10';
    'probtrackX_results_IFGorb_top_20-AntTemp_top_20_TO_IFGorb_top_20-AntTemp_top_20_EX_MFG_top_20';
    'probtrackX_results_IFG_top_20-PostTemp_top_20_TO_IFG_top_20-PostTemp_top_20_EX_IFGorb_top_20';
    'probtrackX_results_IFGorb_top_20-AntTemp_top_20_TO_IFGorb_top_20-AntTemp_top_20_EX_IFG_top_20'
    }


%% 
all_unique_subs={};
for folder =folders'
    fdt_files=dir(fullfile(probtrack_folder,folder{1},'*fdt_network.mat'));
    sub_ids=regexp({fdt_files(:).name},'sub\d+','match');
    sub_ids=cellfun(@(x) x(1) , sub_ids);
    unique_subs=unique(sub_ids);
    all_unique_subs=[all_unique_subs;unique_subs];
    LH_cell={};
    RH_cell={};
    for id_sub=1:length(unique_subs)
        sub=unique_subs{id_sub};
        overlap=find(strcmp(sub_ids,sub));
        assert(length(overlap)==2)
        for file_id=overlap
            file_dat=load(fullfile(fdt_files(file_id).folder,fdt_files(file_id).name),'fdt_st');
            file_dat=file_dat.fdt_st;
            switch file_dat.hemi
                case 'LH'
                    LH_cell{id_sub,1}=file_dat.fdt_mat;
                    LH_cell{id_sub,2}=file_dat.targets;
                    LH_cell{id_sub,3}=file_dat.sub_id;
                case 'RH'
                    RH_cell{id_sub,1}=file_dat.fdt_mat;
                    RH_cell{id_sub,2}=file_dat.targets;
                    RH_cell{id_sub,3}=file_dat.sub_id;
            end
        end
    end
    % do some checks to make sure everything is properly aligned across subjects
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
    
    % LH
    % make symmetric by summing up upper and lower halves
    temp_fdt=cellfun(@(t) (triu(t)+transpose(tril(t)))/2, LH_fdt,'uni',false);
    temp_fdt=cellfun(@(t_sym) t_sym+transpose(triu(t_sym)), temp_fdt,'uni',false);
    temp_fdt_sum=temp_fdt;
    %for kk=1:length(temp_fdt)
    %    t=temp_fdt{kk};
    %    if sum(t)~=0, t=t./(.5*sum(sum(t)));else t=t;end ;
    %    temp_fdt_sum{kk,1}=t;
    %end 
    
    cellfun(@(x) assert(issymmetric(x)),temp_fdt_sum)
    LH_fdt_raw=LH_fdt;
    LH_fdt_sum=temp_fdt_sum;
    % RH
    temp_fdt=cellfun(@(t) (triu(t)+transpose(tril(t)))/2, RH_fdt,'uni',false);
    temp_fdt=cellfun(@(t_sym) t_sym+transpose(triu(t_sym)), temp_fdt,'uni',false);
    temp_fdt_sum=temp_fdt;
    %for kk=1:length(temp_fdt)
    %    t=temp_fdt{kk};
    %    if sum(t)~=0, t=t./(.5*sum(sum(t)));else t=t;end ;
    %    temp_fdt_sum{kk,1}=t;
    %end 
    cellfun(@(x) assert(issymmetric(x)),temp_fdt)
    cellfun(@(x) assert(issymmetric(x)),temp_fdt_sum)
    RH_fdt_raw=RH_fdt;
    RH_fdt_sum=temp_fdt_sum;
    assert(all(cellfun(@(x,y) strcmp(x,y),LH_subs,unique_subs')))
    assert(all(cellfun(@(x,y) strcmp(x,y),RH_subs,unique_subs')))
    
    unique_dti=struct;
    unique_dti.unique_subs=unique_subs;
    unique_dti.unique_LH_targets=LH_targets;
    unique_dti.unique_RH_targets=RH_targets;
    unique_dti.unique_LH_fdt_raw=LH_fdt_raw;
    unique_dti.unique_LH_fdt_sum=LH_fdt_sum;
    unique_dti.unique_RH_fdt_raw=RH_fdt_raw;
    unique_dti.unique_RH_fdt_sum=RH_fdt_sum;


    save(fullfile(probtrack_folder,folder{1},'unique_subjects_pkg'),'unique_dti');
    
    
end
for kk=1:size(all_unique_subs,2)
    assert(size(unique(all_unique_subs(:,kk)),1)==1)
end 
% get files both LH and RH 



%% hypothesis 1. 
threshold=20;
w_type='sum';
titles={'n.s.';'-->';'<--'};
folders={sprintf('probtrackX_results_IFG_top_%d-PostTemp_top_%d_TO_IFG_top_%d-PostTemp_top_%d_EX_MFG_top_%d',threshold,threshold,threshold,threshold,threshold);
    sprintf('probtrackX_results_IFGorb_top_%d-AntTemp_top_%d_TO_IFGorb_top_%d-AntTemp_top_%d_EX_MFG_top_%d',threshold,threshold,threshold,threshold,threshold)}; 
results={};
for idx=1:size(folders,1)
   results{idx}=load(fullfile(probtrack_folder,folders{idx},'unique_subjects_pkg'),'unique_dti').unique_dti;
end 
assert(all(cell2mat(cellfun(@(x,y) strcmp(x,y),results{1}.unique_subs,results{2}.unique_subs,'uni',false))))
unique_subs=results{1}.unique_subs;
% pick a random set of 60 subject 
rng(1)
% ids=randi(length(unique_subs),1,60);
% train_subs=unique_subs(ids);
num_subs=70;
[train_subs,ids]=datasample(unique_subs,70,'Replace',false);

IFG_Post=results{1}.unique_LH_targets(:,1);
IFGorb_Ant=results{2}.unique_LH_targets(:,1);
if strcmp(w_type,'sum')
    IFG_post_w=results{1}.unique_LH_fdt_sum(ids);
    IFGorb_Ant_w=results{2}.unique_LH_fdt_sum(ids);
else
    IFG_post_w=results{1}.unique_LH_fdt_raw(ids);
    IFGorb_Ant_w=results{2}.unique_LH_fdt_raw(ids);
end 
% 
ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 11 8]
ff.PaperOrientation='landscape';

ax=subplot(1,1,1)
x=cellfun(@(x) x(1,2), IFGorb_Ant_w);
y=cellfun(@(x) x(1,2), IFG_post_w);
[hscatter,hbar,ax,ahist]=scatterDiagHist(x,y);
hscatter.Marker='o'
hscatter.MarkerFaceColor='r'
hscatter.MarkerEdgeColor='k'
hbar.FaceColor='r';
ax.YLim=[0,1.1*max([x;y])]
ax.XLim=[0,1.1*max([x;y])]
hbar.LineWidth=2;
%[h,p]=ttest(x,y);
%ahist.Title.String=titles{h+1}
    [h1,p1]=ttest(x,y,'Tail','right');
    [h2,p2]=ttest(x,y,'Tail','left');
    if h1
        ahist.Title.String=titles{2};
    elseif h2
        ahist.Title.String=titles{3};
    else
        ahist.Title.String=titles{1};
    end
    

ahist.Title.Rotation=-45;
ahist.Title.FontSize=15

ahist.Title.Position=[0,max(ahist.YLim),0]
ax.YLabel.String=sprintf('%s --> \n %s',strrep(IFG_Post{1},'_',' '),strrep(IFG_Post{2},'_',' '));
ax.XLabel.String=sprintf('%s --> \n %s',strrep(IFGorb_Ant{1},'_',' '),strrep(IFGorb_Ant{2},'_',' '));
ax.FontSize=12;
%ylim([min([x;y]),max([x;y])])
%xlim([min([x;y]),max([x;y])])
print(ff,'-fillpage','-dpdf','-painters', strcat(analysis_path,'/','LH_select_tracts_temporal_to_frontal_',num2str(threshold),'_',w_type,'_subs_',num2str(num_subs),'.pdf'));


%% compare LH vs RH parcels 

rng(1)
% ids=randi(length(unique_subs),1,60);
% train_subs=unique_subs(ids);
num_subs=70;
[train_subs,ids]=datasample(unique_subs,70,'Replace',false);


LH_IFG_Post=results{1}.unique_LH_targets(:,1);
RH_IFG_Post=results{1}.unique_RH_targets(:,1);
LH_IFGorb_Ant=results{2}.unique_LH_targets(:,1);
RH_IFGorb_Ant=results{2}.unique_RH_targets(:,1);
if strcmp(w_type,'sum')
    LH_IFG_post_w=results{1}.unique_LH_fdt_sum(ids);
    LH_IFGorb_Ant_w=results{2}.unique_LH_fdt_sum(ids);
    RH_IFG_post_w=results{1}.unique_RH_fdt_sum(ids);
    RH_IFGorb_Ant_w=results{2}.unique_RH_fdt_sum(ids);
end 


ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 11 8]
ff.PaperOrientation='landscape';

ax=subplot(1,1,1)
x=cellfun(@(x) x(1,2), RH_IFG_post_w);
y=cellfun(@(x) x(1,2), LH_IFG_post_w);
[hscatter,hbar,ax,ahist]=scatterDiagHist(x,y);
hscatter.Marker='o'
hscatter.MarkerFaceColor='r'
hscatter.MarkerEdgeColor='k'
hbar.FaceColor='r';
ax.YLim=[0,1.1*max([x;y])]
ax.XLim=[0,1.1*max([x;y])]
hbar.LineWidth=2;
%[h,p]=ttest(x,y);
%ahist.Title.String=titles{h+1}
    [h1,p1]=ttest(x,y,'Tail','right');
    [h2,p2]=ttest(x,y,'Tail','left');
    if h1
        ahist.Title.String=titles{2};
    elseif h2
        ahist.Title.String=titles{3};
    else
        ahist.Title.String=titles{1};
    end
    

ahist.Title.Rotation=-45;
ahist.Title.FontSize=15

ahist.Title.Position=[0,max(ahist.YLim),0]
ax.XLabel.String=sprintf('%s --> \n %s',strrep(RH_IFG_Post{1},'_',' '),strrep(RH_IFG_Post{2},'_',' '));
ax.YLabel.String=sprintf('%s --> \n %s',strrep(LH_IFG_Post{1},'_',' '),strrep(LH_IFG_Post{2},'_',' '));
ax.FontSize=12;


print(ff,'-fillpage','-dpdf','-painters', strcat(analysis_path,'/','LH_vs_RH_select_tracts_PosTemp_to_IFG_',num2str(threshold),'_',w_type,'_subs_',num2str(num_subs),'.pdf'));


ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 11 8]
ff.PaperOrientation='landscape';
ax=subplot(1,1,1)
x=cellfun(@(x) x(1,2), RH_IFGorb_Ant_w);
y=cellfun(@(x) x(1,2), LH_IFGorb_Ant_w);
[hscatter,hbar,ax,ahist]=scatterDiagHist(x,y);
hscatter.Marker='o'
hscatter.MarkerFaceColor='r'
hscatter.MarkerEdgeColor='k'
hbar.FaceColor='r';
ax.YLim=[0,1.1*max([x;y])]
ax.XLim=[0,1.1*max([x;y])]
hbar.LineWidth=2;
%[h,p]=ttest(x,y);
%ahist.Title.String=titles{h+1}
    [h1,p1]=ttest(x,y,'Tail','right');
    [h2,p2]=ttest(x,y,'Tail','left');
    if h1
        ahist.Title.String=titles{2};
    elseif h2
        ahist.Title.String=titles{3};
    else
        ahist.Title.String=titles{1};
    end
    

ahist.Title.Rotation=-45;
ahist.Title.FontSize=15

ahist.Title.Position=[0,max(ahist.YLim),0]
ax.XLabel.String=sprintf('%s --> \n %s',strrep(RH_IFGorb_Ant{1},'_',' '),strrep(RH_IFGorb_Ant{2},'_',' '));
ax.YLabel.String=sprintf('%s --> \n %s',strrep(LH_IFGorb_Ant{1},'_',' '),strrep(LH_IFGorb_Ant{2},'_',' '));
ax.FontSize=12;

print(ff,'-fillpage','-dpdf','-painters', strcat(analysis_path,'/','LH_vs_RH_select_tracts_Anttemp_to_IFGorb_',num2str(threshold),'_',w_type,'_subs_',num2str(num_subs),'.pdf'));
%ylim([min([x;y]),max([x;y])])
%xlim([min([x;y]),max([x;y])])

%% 
threshold=20;
w_type='sum';
titles={'n.s.';'-->';'<--'};
folders={sprintf('probtrackX_results_IFG_top_%d-PostTemp_top_%d_TO_IFG_top_%d-PostTemp_top_%d_EX_IFGorb_top_%d',threshold,threshold,threshold,threshold,threshold);
    sprintf('probtrackX_results_IFGorb_top_%d-AntTemp_top_%d_TO_IFGorb_top_%d-AntTemp_top_%d_EX_IFG_top_%d',threshold,threshold,threshold,threshold,threshold)}; 
results={};
for idx=1:size(folders,1)
   results{idx}=load(fullfile(probtrack_folder,folders{idx},'unique_subjects_pkg'),'unique_dti').unique_dti;
end 
assert(all(cell2mat(cellfun(@(x,y) strcmp(x,y),results{1}.unique_subs,results{2}.unique_subs,'uni',false))))
unique_subs=results{1}.unique_subs;
% pick a random set of 60 subject 
rng(1)
% ids=randi(length(unique_subs),1,60);
% train_subs=unique_subs(ids);
num_subs=70;
[train_subs,ids]=datasample(unique_subs,70,'Replace',false);

IFG_Post=results{1}.unique_LH_targets(:,1);
IFGorb_Ant=results{2}.unique_LH_targets(:,1);
if strcmp(w_type,'sum')
    IFG_post_w=results{1}.unique_LH_fdt_sum(ids);
    IFGorb_Ant_w=results{2}.unique_LH_fdt_sum(ids);
else
    IFG_post_w=results{1}.unique_LH_fdt_raw(ids);
    IFGorb_Ant_w=results{2}.unique_LH_fdt_raw(ids);
end 
% 
ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 11 8]
ff.PaperOrientation='landscape';

ax=subplot(1,1,1)
x=cellfun(@(x) x(1,2), IFGorb_Ant_w);
y=cellfun(@(x) x(1,2), IFG_post_w);
[hscatter,hbar,ax,ahist]=scatterDiagHist(x,y);
hscatter.Marker='o'
hscatter.MarkerFaceColor='r'
hscatter.MarkerEdgeColor='k'
hbar.FaceColor='r';
ax.YLim=[0,1.1*max([x;y])]
ax.XLim=[0,1.1*max([x;y])]
hbar.LineWidth=2;
%[h,p]=ttest(x,y);
%ahist.Title.String=titles{h+1}
    [h1,p1]=ttest(x,y,'Tail','right');
    [h2,p2]=ttest(x,y,'Tail','left');
    if h1
        ahist.Title.String=titles{2};
    elseif h2
        ahist.Title.String=titles{3};
    else
        ahist.Title.String=titles{1};
    end
    

ahist.Title.Rotation=-45;
ahist.Title.FontSize=15

ahist.Title.Position=[0,max(ahist.YLim),0]
ax.YLabel.String=sprintf('%s --> \n %s',strrep(IFG_Post{1},'_',' '),strrep(IFG_Post{2},'_',' '));
ax.XLabel.String=sprintf('%s --> \n %s',strrep(IFGorb_Ant{1},'_',' '),strrep(IFGorb_Ant{2},'_',' '));
ax.FontSize=12;
%ylim([min([x;y]),max([x;y])])
%xlim([min([x;y]),max([x;y])])
print(ff,'-fillpage','-dpdf','-painters', strcat(analysis_path,'/','LH_select_tracts_temporal_to_frontal_',num2str(threshold),'_',w_type,'_subs_',num2str(num_subs),'mask_IFG_IFGorb','.pdf'));


