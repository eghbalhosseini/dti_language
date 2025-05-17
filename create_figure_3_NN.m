clear all;
close all;
threshold=20;
num_subs=125;
left_out=false;
w_type='sum';
probtrack_folder='/Users/eghbalhosseini/MyData/dti_language/';
analysis_path='/Users/eghbalhosseini/MyData/dti_language/analysis';
titles={'n.s.';'-->';'<--'};

sources_x={'AntTemp','PostTemp','AngG'};
%sources_x={'AntTemp','PostTemp'};
targets_y={'IFG','IFGorb','MFG'};
target='IFGorb';
folders={   
            sprintf('probtrackX_results_IFG_top_%d-AntTemp_top_%d_TO_IFG_top_%d-AntTemp_top_%d_EX_IFGorb_top_%d-MFG_top_%d',threshold,threshold,threshold,threshold,threshold,threshold);
            sprintf('probtrackX_results_IFG_top_%d-PostTemp_top_%d_TO_IFG_top_%d-PostTemp_top_%d_EX_IFGorb_top_%d-MFG_top_%d',threshold,threshold,threshold,threshold,threshold,threshold);
            sprintf('probtrackX_results_IFG_top_%d-AngG_top_%d_TO_IFG_top_%d-AngG_top_%d_EX_IFGorb_top_%d-MFG_top_%d',threshold,threshold,threshold,threshold,threshold,threshold);
            
            sprintf('probtrackX_results_IFGorb_top_%d-AntTemp_top_%d_TO_IFGorb_top_%d-AntTemp_top_%d_EX_IFG_top_%d-MFG_top_%d',threshold,threshold,threshold,threshold,threshold,threshold);
            sprintf('probtrackX_results_IFGorb_top_%d-PostTemp_top_%d_TO_IFGorb_top_%d-PostTemp_top_%d_EX_IFG_top_%d-MFG_top_%d',threshold,threshold,threshold,threshold,threshold,threshold);
            sprintf('probtrackX_results_IFGorb_top_%d-AngG_top_%d_TO_IFGorb_top_%d-AngG_top_%d_EX_IFG_top_%d-MFG_top_%d',threshold,threshold,threshold,threshold,threshold,threshold);
        
        sprintf('probtrackX_results_MFG_top_%d-AntTemp_top_%d_TO_MFG_top_%d-AntTemp_top_%d_EX_IFG_top_%d-IFGorb_top_%d',threshold,threshold,threshold,threshold,threshold,threshold);
        sprintf('probtrackX_results_MFG_top_%d-PostTemp_top_%d_TO_MFG_top_%d-PostTemp_top_%d_EX_IFG_top_%d-IFGorb_top_%d',threshold,threshold,threshold,threshold,threshold,threshold);
      sprintf('probtrackX_results_MFG_top_%d-AngG_top_%d_TO_MFG_top_%d-AngG_top_%d_EX_IFG_top_%d-IFGorb_top_%d',threshold,threshold,threshold,threshold,threshold,threshold);
        };

results={};
results_path={};
for idx=1:size(folders,1)
    A= load(fullfile(probtrack_folder,folders{idx},'unique_subjects_pkg_nov2024'),'unique_dti');
    B= load(fullfile(probtrack_folder,folders{idx},'unique_subjects_paths_nov2024.mat'));
   results{idx}=A.unique_dti;
   results_path{idx}=B.unique_paths;
end 
assert(all(cell2mat(cellfun(@(x,y) strcmp(x,y),results{1}.unique_subs,results{2}.unique_subs,'uni',false))))
assert(all(cell2mat(cellfun(@(x,y) strcmp(x,y),results_path{1}.unique_subjects,results_path{2}.unique_subjects,'uni',false))))

assert(all(cell2mat(cellfun(@(x,y) strcmp(x,y),results{1}.unique_subs,results_path{2}.unique_subjects,'uni',false))))
unique_subs=results{1}.unique_subs;
rng(1)
[train_subs,ids]=datasample(unique_subs,num_subs,'Replace',false);

if left_out
   leftout_subs=setdiff(unique_subs,train_subs);
   ids=cellfun(@(x) find(contains(unique_subs,x)), leftout_subs);
   train_subs=leftout_subs;
end 
seeds={sprintf('LH_AntTemp_top_%d',threshold),sprintf('LH_PostTemp_top_%d',threshold),sprintf('LH_AngG_top_%d',threshold)};
%seeds={sprintf('LH_AntTemp_top_%d',threshold),sprintf('LH_PostTemp_top_%d',threshold)};
targets={sprintf('LH_IFG_top_%d',threshold);sprintf('LH_IFGorb_top_%d',threshold);sprintf('LH_MFG_top_%d',threshold)};
%% load group tract results
group_folders={... % first 3 are how frontal are connected to temporal 
    'probtrackX_group_results_PostTemp_top_20-AntTemp_top_20-AngG_top_20-MFG_top_20_TO_PostTemp_top_20-AntTemp_top_20-AngG_top_20-MFG_top_20_EX_IFG_top_20-IFGorb_top_20';...
    'probtrackX_group_results_PostTemp_top_20-AntTemp_top_20-AngG_top_20-IFG_top_20_TO_PostTemp_top_20-AntTemp_top_20-AngG_top_20-IFG_top_20_EX_IFGorb_top_20-MFG_top_20';...
    'probtrackX_group_results_PostTemp_top_20-IFGorb_top_20-IFG_top_20-MFG_top_20_TO_PostTemp_top_20-IFGorb_top_20-IFG_top_20-MFG_top_20_EX_AntTemp_top_20-AngG_top_20';...
    
    'probtrackX_group_results_AntTemp_top_20-IFGorb_top_20-IFG_top_20-MFG_top_20_TO_AntTemp_top_20-IFGorb_top_20-IFG_top_20-MFG_top_20_EX_PostTemp_top_20-AngG_top_20';...
    'probtrackX_group_results_PostTemp_top_20-AntTemp_top_20-AngG_top_20-IFGorb_top_20_TO_PostTemp_top_20-AntTemp_top_20-AngG_top_20-IFGorb_top_20_EX_IFG_top_20-MFG_top_20';...
    'probtrackX_group_results_IFGorb_top_20-IFG_top_20-AngG_top_20-MFG_top_20_TO_AngG_top_20-IFGorb_top_20-IFG_top_20-MFG_top_20_EX_AntTemp_top_20-PostTemp_top_20'...
    };


group_results={};
for idx=1:size(group_folders,1)
   group_results{idx}=load(fullfile(probtrack_folder,group_folders{idx},'unique_subjects_pkg'),'unique_dti').unique_dti;
end 
assert(all(cell2mat(cellfun(@(x,y) strcmp(x,y),group_results{1}.unique_subs,results{2}.unique_subs,'uni',false))))

%% load language specific connectivty pattern 
unique_dti=load(fullfile(probtrack_folder,'probtrackX_lang_results_AntTemp_top_20-IFGorb_top_20-IFG_top_20-MFG_top_20-PostTemp_top_20-AngG_top_20','unique_subjects_pkg'));
unique_dti=unique_dti.unique_dti;

train_dti=struct;
train_dti.unique_subs=unique_dti.unique_subs(ids);
train_dti.unique_LH_fdt_raw=unique_dti.unique_LH_fdt_raw(ids);
train_dti.unique_LH_fdt_sum=unique_dti.unique_LH_fdt_sum(ids);

%train_dti.unique_RH_fdt_raw=unique_dti.unique_RH_fdt_raw(ids); 
%train_dti.unique_RH_fdt_sum=unique_dti.unique_RH_fdt_sum(ids);

train_dti.unique_LH_targets=unique_dti.unique_LH_targets(:,ids);
train_dti.unique_RH_targets=unique_dti.unique_RH_targets(:,ids);

%%  
ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 8 11];
ff.PaperOrientation='portrait';
pa_ratio=8/11;
edges=[.15,.45,.75];
ax_=[];
for k=1:length(seeds)
    ax=subplot('position',[edges(k),.5,.2,.15*pa_ratio]);
    s_t_weights=[];
    s_t_connectivity={}
    s_t_weight_all=[];
    % get all seed connections 
    [C,~,L_T]=intersect(seeds{k},train_dti.unique_LH_targets,'stable');
    [C,~,L_S]=intersect(targets,train_dti.unique_LH_targets,'stable');
    LH_fdt=train_dti.unique_LH_fdt_sum;
    % 
    target_fdt=cellfun(@(t) t(:,L_T),LH_fdt,'uni',false);
    source_target=cellfun(@(t) t(L_S,:),target_fdt,'uni',false);
    target_sum=cellfun(@sum,target_fdt);
    source_target_sum=cellfun(@sum,source_target);
    for kk=1:length(targets)
        
        t_idx=contains(folders,erase([targets{kk},'-',seeds{k}],'LH_'));
        remain=setdiff(seeds,seeds(k));
        grp_fold=cellfun(@(x) x(1:regexp(x,'_EX_')), group_folders,'uni',false);
        not_contains=~sum(cell2mat(cellfun(@(x) contains(grp_fold,erase(x,'LH_')),remain,'uni',false)),2);
        g_t_idx=find(contains(grp_fold,erase(seeds{k},'LH_')).*contains(grp_fold,erase(targets{kk},'LH_')).*not_contains);
        
        % find everything after ex and remove it 
        s_t_con=cat(3,results{t_idx}.unique_LH_fdt_sum{ids});
        s_t_connect=results_path{t_idx}.('LH_path');
        s_t_connect=cellfun(@(x) double(x./max(x)) ,s_t_connect(:,1),'uni',false);
        s_t_connectivity=[s_t_connectivity,s_t_connect];
        s_t_con_all=cat(3,group_results{g_t_idx}.unique_LH_fdt_sum{ids});
        assert(sum(sum(contains(results{t_idx}.unique_LH_targets(:,ids),targets{kk})))==size(s_t_con,3));
        assert(sum(sum(contains(results{t_idx}.unique_LH_targets(:,ids),seeds{k})))==size(s_t_con,3));
        
        s_t_weights=[s_t_weights,squeeze([s_t_con(1,2,:)])];
        s_t_weight_all=[s_t_weight_all,squeeze(sum(sum(s_t_con_all,1),2)/2)];
        
    end 
    X_total=sum(s_t_weights,2);
    non_zero_idx=find((X_total~=0));
    
    % drop zeros 
    X_non_zero_idx=X_total(non_zero_idx);
    s_t_connectivity=s_t_connectivity(non_zero_idx,:);
    s_t_nonzero=s_t_weights(non_zero_idx,:);
    
    target_sum_nonzero=target_sum(non_zero_idx);
    source_target_nonzero=source_target_sum(non_zero_idx);
    al_indx=find(~(X_non_zero_idx<=target_sum_nonzero));
    %al_t_indx=find(~(X_non_zero_idx<=source_target_sum));
    s_t_nonzero(al_indx,:)=[];
    target_sum_nonzero(al_indx)=[];
    %source_target_nonzero(al_t_indx)=[];
    
    s_t_nonzero=s_t_nonzero./(repmat(target_sum_nonzero,1,size(s_t_nonzero,2)));
    %s_t_nonzero=s_t_nonzero./(repmat(source_target_nonzero,1,size(s_t_nonzero,2)));
    s_t_nonzero_std=std(s_t_nonzero,[],1)./sqrt(length(s_t_nonzero));
    %b=bar(1:length(targets),cellfun(@mean,s_t_nonzero))
    b=barh(1:length(targets),mean(s_t_nonzero,1),'facecolor','flat','linestyle','none');
    b.BaseLine.LineStyle='none';
    hold on
    b.FaceColor='r';
    %errorbar(1:length(targets),cellfun(@mean,s_t_nonzero),s_t_nonzero_std,'vertical','linestyle','none','color','k','linewidth',2)
    errorbar(mean(s_t_nonzero,1),1:length(targets),s_t_nonzero_std,'horizontal','linestyle','none','color','k','linewidth',2,'capsize',0)
    ax.XLim=[0,0.01];
    ax.XAxis.FontSize=8;
    ax.YTickLabel=targets_y;
    ax.YAxis.FontSize=8;
    ax.YLim=[.5,3.5]
     
    
    ax.XTick=ax.XLim;
    
    ax.XLabel.String=["average weight" , "(mean / standard error)"];
    
    ax=makeaxis_eh(ax);
    %ax.Title.String=strcat(strrep(seeds{k},'_',' '),' #sub:',num2str(size(s_t_weights,1)));
    ax.Title.String=sources_x{k}
    ax.Title.FontSize=10;
    ax_=[ax_,ax];
    ax.Box='off';
end 
    


%ff=figure();
%ff.Units='Inches';
%ff.Position=[55.5139 10.6250 8 11];
%ff.PaperOrientation='portrait';
%pa_ratio=8/11;
edges=[.15,.45,.75];
ax_=[];

for k=1:length(targets)
    ax=subplot('position',[edges(k),.65,.2,.15*pa_ratio]);
    s_t_weights=[];
    [C,~,L_T]=intersect(targets{k},train_dti.unique_LH_targets,'stable');
    LH_fdt=train_dti.unique_LH_fdt_sum;
    % 
    target_fdt=cellfun(@(t) t(:,L_T),LH_fdt,'uni',false);
    target_sum=cellfun(@sum,target_fdt);
    for kk=1:length(seeds)
        t_idx=contains(folders,erase([targets{k},'-',seeds{kk}],'LH_'));
        s_t_con=cat(3,results{t_idx}.unique_LH_fdt_sum{ids});
        assert(sum(sum(contains(results{t_idx}.unique_LH_targets(:,ids),targets{k})))==size(s_t_con,3));
        assert(sum(sum(contains(results{t_idx}.unique_LH_targets(:,ids),seeds{kk})))==size(s_t_con,3));
        s_t_weights=[s_t_weights,squeeze([s_t_con(1,2,:)])];
        
        
    end
    X_total=sum(s_t_weights,2);
    
    non_zero_idx=find((X_total~=0));
   % non_zero_idx=1:length(X_total);
    
    % drop zeros 
    X_non_zero_idx=X_total(non_zero_idx);
    
    s_t_nonzero=s_t_weights(non_zero_idx,:);
    target_sum_nonzero=target_sum(non_zero_idx);
    al_indx=find(~(X_non_zero_idx<=target_sum_nonzero));
    disp(length(al_indx))
    s_t_nonzero(al_indx,:)=[];
    target_sum_nonzero(al_indx)=[];
    
    s_t_nonzero=s_t_nonzero./(repmat(target_sum_nonzero,1,size(s_t_nonzero,2)));
    s_t_nonzero_std=std(s_t_nonzero,[],1)./sqrt(length(s_t_nonzero));
    %b=bar(1:length(targets),cellfun(@mean,s_t_nonzero))
    b=barh(1:length(seeds),mean(s_t_nonzero,1),'facecolor','flat','linestyle','none');
    b.BaseLine.LineStyle='none';
    hold on;
    b.FaceColor='r';
    %errorbar(1:length(targets),cellfun(@mean,s_t_nonzero),s_t_nonzero_std,'vertical','linestyle','none','color','k','linewidth',2)
    errorbar(mean(s_t_nonzero,1),1:length(seeds),s_t_nonzero_std,'horizontal','linestyle','none','color','k','linewidth',2,'capsize',0);
    ax.XAxis.FontSize=8;
    
    ax.XTick=ax.XLim;
    
    ax.YTickLabel=sources_x;
    ax.YAxis.FontSize=8;
    
        
    %ax.XLabel.String=["average weight" , "(mean / standard error)"];
    ax=makeaxis_eh(ax);
    %ax.Title.String=strcat(strrep(seeds{k},'_',' '),' #sub:',num2str(size(s_t_weights,1)));
    ax.Title.String=targets_y{k};
    ax.Title.FontSize=10;
    ax_=[ax_,ax];
    ax.Box='off';
end 
%% 
print(ff,'-dpdf','-bestfit','-painters', strcat(analysis_path,'/','figure_3_LH_temporal_to_frontal_connectivity_pattern_thr_',num2str(threshold),'_',w_type,'_subs_',num2str(length(train_subs)),'.pdf'));
print(ff,'-painters','-dpng', strcat(analysis_path,'/','figure_3_LH_temporal_to_frontal_connectivity_pattern_thr_','_',num2str(threshold),'_',w_type,'_subs_',num2str(length(train_subs)),'.png'));
%% 
%%  

ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 8 11];
ff.PaperOrientation='portrait';
pa_ratio=8/11;
edges=[.15,.45,.75];
ax_=[];
for k=1:length(seeds)
    ax=subplot('position',[edges(k),.5,.2,.15*pa_ratio]);
    s_t_weights=[];
    s_t_weight_all=[];
    s_t_connectivity={};
    % get all seed connections 
    for kk=1:length(targets)
        disp([seeds{k},' to ',targets{kk}])
        t_idx=contains(folders,erase([targets{kk},'-',seeds{k}],'LH_'));
        remain=setdiff(seeds,seeds(k));
        grp_fold=cellfun(@(x) x(1:regexp(x,'_EX_')), group_folders,'uni',false);
        not_contains=~sum(cell2mat(cellfun(@(x) contains(grp_fold,erase(x,'LH_')),remain,'uni',false)),2);
        g_t_idx=find(contains(grp_fold,erase(seeds{k},'LH_')).*contains(grp_fold,erase(targets{kk},'LH_')).*not_contains);
        %disp(group_folders(g_t_idx))
        
        s_t_con=cat(3,results{t_idx}.unique_LH_fdt_sum{ids});
        [C,~,L_T]=intersect(seeds{k},group_results{g_t_idx}.unique_LH_targets,'stable');
        s_t_con_all=cat(3,group_results{g_t_idx}.unique_LH_fdt_sum{ids});
        assert(sum(sum(contains(results{t_idx}.unique_LH_targets(:,ids),targets{kk})))==size(s_t_con,3));
        assert(sum(sum(contains(results{t_idx}.unique_LH_targets(:,ids),seeds{k})))==size(s_t_con,3));
        s_t_connect=results_path{t_idx}.('LH_path');
        s_t_connect=cellfun(@(x) double(x./1) ,s_t_connect(:,1),'uni',false);
        s_t_connectivity=[s_t_connectivity,s_t_connect];
        s_t_weights=[s_t_weights,squeeze([s_t_con(1,2,:)])];
        s_t_weight_all=[s_t_weight_all,squeeze(sum(s_t_con_all(L_T,:,:),2))];
        
    end 
    X_total=mean(s_t_weight_all,2);
    non_zero_idx=find((X_total~=0));
    s_t_connectivity=s_t_connectivity(non_zero_idx,:);
    % drop zeros 
    X_non_zero=X_total(non_zero_idx);
    s_t_nonzero=s_t_weights(non_zero_idx,:);
    larger_idx=sum(s_t_nonzero>X_non_zero,2)>0;
    %larger_idx=0*sum(s_t_nonzero>X_non_zero,2)>0;
    fprintf('dropping %d subject because the values is bigger than sum \n',sum(larger_idx));
    s_t_nonzero=s_t_nonzero(find(~larger_idx),:);
    X_non_zero=X_non_zero(find(~larger_idx),:);
    s_t_connectivity_nonzero=s_t_connectivity(find(~larger_idx),:);
    s_t_connectivity_ave=arrayfun(@(x) nanmean(cat(4,s_t_connectivity_nonzero{:,x}),4), 1:size(s_t_connectivity_nonzero,2),'uni',false);
    s_t_connectivity_ave_nonnan={};
    for s_t_ =s_t_connectivity_ave
        s_t_=s_t_{1};
        s_t_(isnan(s_t_))=0;
        s_t_connectivity_ave_nonnan=[s_t_connectivity_ave_nonnan;s_t_];
    end 
    arrayfun(@(x) niftiwrite(s_t_connectivity_ave_nonnan{x},sprintf('~/desktop/%s_%s_',seeds{k},targets{x})),1:length(s_t_connectivity_ave_nonnan))
    assert(all(all(s_t_nonzero<=X_non_zero)));
    s_t_nonzero=s_t_nonzero./X_non_zero;
    %s_t_nonzero=s_t_nonzero./(repmat(source_target_nonzero,1,size(s_t_nonzero,2)));
    s_t_nonzero_std=std(s_t_nonzero,[],1)./sqrt(length(s_t_nonzero));
    %b=bar(1:length(targets),cellfun(@mean,s_t_nonzero))
    b=barh(1:length(targets),mean(s_t_nonzero,1),'facecolor','flat','linestyle','none');
    b.BaseLine.LineStyle='none';
    hold on
    b.FaceColor='r';
    %errorbar(1:length(targets),cellfun(@mean,s_t_nonzero),s_t_nonzero_std,'vertical','linestyle','none','color','k','linewidth',2)
    errorbar(mean(s_t_nonzero,1),1:length(targets),s_t_nonzero_std,'horizontal','linestyle','none','color','k','linewidth',2,'capsize',0)
    %ax.XLim=[0,1];
    ax.XAxis.FontSize=8;
    ax.YTickLabel=targets_y;
    ax.YAxis.FontSize=8;
    ax.YLim=[.5,3.5];
    ax.XLim=[0,.7];
    
    ax.XTick=ax.XLim;
    if k==length(seeds)
    ax.XLabel.String=["weight ratio (a.u.)" , "(mean / standard error)"];
    end 
    ax=makeaxis_eh(ax);
    %ax.Title.String=strcat(strrep(seeds{k},'_',' '),' #sub:',num2str(size(s_t_weights,1)));
    ax.Title.String=sources_x{k}
    ax.Title.FontSize=10;
    ax_=[ax_,ax];
    ax.Box='off';
end 

%% 
%pa_ratio=8/11;
edges=[.15,.45,.75];
ax_=[];

for k=1:length(targets)
    ax=subplot('position',[edges(k),.65,.2,.15*pa_ratio]);
    s_t_weights=[];
    s_t_weight_all=[];
    for kk=1:length(seeds)
        t_idx=contains(folders,erase([targets{k},'-',seeds{kk}],'LH_'));
        remain=setdiff(targets,targets(k))';
        grp_fold=cellfun(@(x) x(1:regexp(x,'_EX_')), group_folders,'uni',false);
        not_contains=~sum(cell2mat(cellfun(@(x) contains(grp_fold,erase(x,'LH_')),remain,'uni',false)),2);
        g_t_idx=find(contains(grp_fold,erase(seeds{kk},'LH_')).*contains(grp_fold,erase(targets{k},'LH_')).*not_contains);
        assert(length(g_t_idx)==1);
        disp(group_folders(g_t_idx))
        s_t_con=cat(3,results{t_idx}.unique_LH_fdt_sum{ids});
        [C,~,L_T]=intersect(targets{k},group_results{g_t_idx}.unique_LH_targets,'stable');
        assert(sum(sum(contains(results{t_idx}.unique_LH_targets(:,ids),targets{k})))==size(s_t_con,3));
        assert(sum(sum(contains(results{t_idx}.unique_LH_targets(:,ids),seeds{kk})))==size(s_t_con,3));
        s_t_weights=[s_t_weights,squeeze([s_t_con(1,2,:)])];
        s_t_weight_all=[s_t_weight_all,squeeze(sum(s_t_con_all(L_T,:,:),2))];
        
    end
    X_total=mean(s_t_weight_all,2);
    non_zero_idx=find((X_total~=0));
    % drop zeros 
    X_non_zero=X_total(non_zero_idx);
    s_t_nonzero=s_t_weights(non_zero_idx,:);
    larger_idx=sum(s_t_nonzero>X_non_zero,2)>0;
    %larger_idx=0*sum(s_t_nonzero>X_non_zero,2)>0;
    fprintf('dropping %d subject because the values is bigger than sum \n',sum(larger_idx));
    s_t_nonzero=s_t_nonzero(find(~larger_idx),:);
    X_non_zero=X_non_zero(find(~larger_idx),:);
    assert(all(all(s_t_nonzero<=X_non_zero)));
    s_t_nonzero=s_t_nonzero./X_non_zero;
    s_t_nonzero_std=std(s_t_nonzero,[],1)./sqrt(length(s_t_nonzero));
    b=barh(1:length(seeds),mean(s_t_nonzero,1),'facecolor','flat','linestyle','none');
    b.BaseLine.LineStyle='none';
    hold on;
    b.FaceColor='r';
    %errorbar(1:length(targets),cellfun(@mean,s_t_nonzero),s_t_nonzero_std,'vertical','linestyle','none','color','k','linewidth',2)
    errorbar(mean(s_t_nonzero,1),1:length(seeds),s_t_nonzero_std,'horizontal','linestyle','none','color','k','linewidth',2,'capsize',0);
    ax.XAxis.FontSize=8;
    ax.XLim=[0,.7];
    ax.XTick=ax.XLim;
    
    ax.YTickLabel=sources_x;
    ax.YAxis.FontSize=8;
    
        
    %ax.XLabel.String=["average weight" , "(mean / standard error)"];
    ax=makeaxis_eh(ax);
    %ax.Title.String=strcat(strrep(seeds{k},'_',' '),' #sub:',num2str(size(s_t_weights,1)));
    ax.Title.String=targets_y{k};
    ax.Title.FontSize=10;
    ax_=[ax_,ax];
    ax.Box='off';
end 
%% 
print(ff,'-dpdf','-bestfit','-painters', strcat(analysis_path,'/','figure_3_LH_temporal_to_frontal_con_ratio_thr_',num2str(threshold),'_',w_type,'_subs_',num2str(length(train_subs)),'.pdf'));
print(ff,'-painters','-dpng', strcat(analysis_path,'/','figure_3_LH_temporal_to_frontal_connectivity_ratio_thr_','_',num2str(threshold),'_',w_type,'_subs_',num2str(length(train_subs)),'.png'));
%% load indvidual paths 
all_unique_subs={};
for folder = folders'
    fdt_files=dir(fullfile(probtrack_folder,folder{1},'*fdt_paths.nii.gz'));
    
    sub_ids=regexp({fdt_files(:).name},'sub\d+','match');
    sub_ids=cellfun(@(x) x(1) , sub_ids);
    unique_subs=unique(sub_ids);
    all_unique_subs=[all_unique_subs;unique_subs];
    LH_path={};
    RH_path={};

    for id_sub=1:length(unique_subs)
        sub=unique_subs{id_sub};
        overlap=find(strcmp(sub_ids,sub));
        assert(length(overlap)==2)
        for file_id=overlap
            file_dat=niftiread(fullfile(fdt_files(file_id).folder,fdt_files(file_id).name));
            file_info=niftiinfo(fullfile(fdt_files(file_id).folder,fdt_files(file_id).name));
            if contains(fdt_files(file_id).name,'LH')
                LH_path{id_sub,1}=file_dat;
                LH_path{id_sub,2}=file_info;
                LH_path{id_sub,3}=sub;
            elseif contains(fdt_files(file_id).name,'RH')
                RH_path{id_sub,1}=file_dat;
                RH_path{id_sub,2}=file_info;
                RH_path{id_sub,3}=sub;
            end
        end
    end
    assert(all(cellfun(@(x,y) strcmp(x,y),LH_path(:,3),unique_subs')))
    assert(all(cellfun(@(x,y) strcmp(x,y),RH_path(:,3),unique_subs')))
    unique_paths=struct;
    unique_paths.LH_path=LH_path;
    unique_paths.RH_path=RH_path;
    unique_paths.unique_subjects=unique_subs;
    save(fullfile(probtrack_folder,folder{1},'unique_subjects_paths'),'unique_paths');
    
end 

%% plot average connectivity between regions 
%% plot average connectivity between regions 
ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 8 11];
ff.PaperOrientation='portrait';
pa_ratio=8/11;
edges=[.15,.45,.75];

all_targets=horzcat(seeds,targets');
all_labels={'AntTemp','PostTemp','AngG','IFG','IFGorb','MFG'};

[C,~,LT]=cellfun(@(x) intersect(x,train_dti.unique_LH_targets,'stable'),all_targets);
% reformat areas 
LH_fdt=train_dti.unique_LH_fdt_sum;
target_fdt=cellfun(@(t) t(:,LT),LH_fdt,'uni',false);
source_target_fdt=cellfun(@(t) t(LT,:),target_fdt,'uni',false);
source_target_fdt=cellfun(@(t) t./(sum(t(:))/2),source_target_fdt,'uni',false);

%cmap=gray(128);
cmap=brewermap(128 ,'Purples');
ax=subplot('position',[.2,.65,.3,.3*pa_ratio]);
x=[1:length(all_labels)];
C=mean(cat(3,source_target_fdt{:}),3);
nan_mask=tril(nan*C);
C=nan_mask+C;
C_percent=ceil(C*1000)/10;
imagesc(x,x,C_percent,[0,120]);
colormap((cmap));
hold on 
arrayfun(@(y) plot([y,y], ax.YLim,'k','linewidth',.5),x-.5)
arrayfun(@(y) plot([y,y], ax.YLim,'k','linewidth',1.5),x(4)-.5)

arrayfun(@(y) plot( ax.XLim,[y,y],'k','linewidth',.5),x-.5)
arrayfun(@(y) plot( ax.XLim,[y,y],'k','linewidth',1.5),x(4)-.5)
ax.XTick=x;
ax.XTickLabel=all_labels;ax.XTickLabelRotation=90;
ax.YTick=x;
ax.YTickLabel=all_labels;ax.YTickLabelRotation=0;

for k=x(1:end-1)
    for kk=k+1:max(x)
        if kk~=k
        text(kk,k,sprintf('%.1f',C_percent(k,kk)),'color','k','horizontalalignment','center','verticalalignment','middle','fontsize',8,'fontweight','bold');
        end 
    end 
end 

cb=colorbar;
cb.Position = [.52,.65,.02,.3*pa_ratio];
cb.Limits=[0,100];
cb.Label.String='weight ratio(%)';
cb.Label.FontWeight='bold';
%cb.Color=[51,153,255]/256;
cb.Ticks=[0,100];

cb.Box='off';
     
    
%print(ff,'-dpdf','-bestfit','-painters', strcat(analysis_path,'/','figure_3_all_lang_con_ratio_thr_',num2str(threshold),'_',w_type,'_subs_',num2str(length(train_subs)),'.pdf'));
%print(ff,'-painters','-dpng', strcat(analysis_path,'/','figure_3_all_lang_connectivity_ratio_thr_','_',num2str(threshold),'_',w_type,'_subs_',num2str(length(train_subs)),'.png'));
 

%% load connectivity between regions as a ratio for all brain 

unique_dti=load(fullfile(probtrack_folder,['probtrackX_results_lang_glasser_thr_',num2str(threshold)],'unique_subjects_pkg'));
unique_dti=unique_dti.unique_dti;

unique_subs=unique_dti.unique_subs;
% pick a random set of 60 subject 
train_dti=struct;
ids=1:124;
train_dti.unique_subs=unique_dti.unique_subs(ids);
train_dti.unique_LH_fdt_raw=unique_dti.unique_LH_fdt_raw(ids);
train_dti.unique_LH_fdt_sum=unique_dti.unique_LH_fdt_sum(ids);

train_dti.unique_RH_fdt_raw=unique_dti.unique_RH_fdt_raw(ids);
train_dti.unique_RH_fdt_sum=unique_dti.unique_RH_fdt_sum(ids);

train_dti.unique_LH_targets=unique_dti.unique_LH_targets(:,ids);
train_dti.unique_RH_targets=unique_dti.unique_RH_targets(:,ids);


ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 8 11];
ff.PaperOrientation='portrait';
pa_ratio=8/11;
edges=[.15,.45,.75];

all_targets=horzcat(seeds,targets');
all_labels={'AntTemp','PostTemp','AngG','IFG','IFGorb','MFG'};

[C,~,LT]=cellfun(@(x) intersect(x,train_dti.unique_LH_targets,'stable'),all_targets);
% reformat areas 
LH_fdt=train_dti.unique_LH_fdt_sum;
target_fdt=cellfun(@(t) t(:,LT),LH_fdt,'uni',false);
target_sum=cellfun(@(t) sum(t,1),target_fdt,'uni',false);
target_fdt=cellfun(@(t1,t2) t1./t2,target_fdt,target_sum,'uni',false);

source_target_fdt=cellfun(@(t) t(LT,:),target_fdt,'uni',false);


%cmap=gray(128);
cmap=brewermap(128 ,'Purples');
ax=subplot('position',[.2,.65,.3,.3*pa_ratio]);
x=[1:length(all_labels)];
C=mean(cat(3,source_target_fdt{:}),3);
nan_mask=tril(nan*C);
C=nan_mask+C;
C_percent=ceil(C*1000)/10;
imagesc(x,x,C_percent,[0,4]);
colormap((cmap));
hold on 
arrayfun(@(y) plot([y,y], ax.YLim,'k','linewidth',.5),x-.5)
arrayfun(@(y) plot([y,y], ax.YLim,'k','linewidth',1.5),x(4)-.5)

arrayfun(@(y) plot( ax.XLim,[y,y],'k','linewidth',.5),x-.5)
arrayfun(@(y) plot( ax.XLim,[y,y],'k','linewidth',1.5),x(4)-.5)
ax.XTick=x;
ax.XTickLabel=all_labels;ax.XTickLabelRotation=90;
ax.YTick=x;
ax.YTickLabel=all_labels;ax.YTickLabelRotation=0;

for k=x(1:end-1)
    for kk=k+1:max(x)
        if kk~=k
        text(kk,k,sprintf('%.1f',C_percent(k,kk)),'color','k','horizontalalignment','center','verticalalignment','middle','fontsize',8,'fontweight','bold');
        end 
    end 
end 

cb=colorbar;
cb.Position = [.52,.65,.02,.3*pa_ratio];
cb.Limits=ax.CLim;
cb.Label.String='weight ratio(%)';
cb.Label.FontWeight='bold';
%cb.Color=[51,153,255]/256;
cb.Ticks=ax.CLim;

cb.Box='off';
     
    
%print(ff,'-dpdf','-bestfit','-painters', strcat(analysis_path,'/','figure_3_global_lang_con_ratio_thr_',num2str(threshold),'_',w_type,'_subs_',num2str(length(train_subs)),'.pdf'));
%print(ff,'-painters','-dpng', strcat(analysis_path,'/','figure_3_global_lang_connectivity_ratio_thr_','_',num2str(threshold),'_',w_type,'_subs_',num2str(length(train_subs)),'.png'));
 

