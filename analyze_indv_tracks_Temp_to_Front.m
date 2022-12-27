clear all 
close all 
probtrack_folder='/Users/eghbalhosseini/MyData/dti_language/probtrackX_results';
analysis_path='/Users/eghbalhosseini/MyData/dti_language/analysis';
titles={'n.s.';'-->';'<--'};
train_dti=load(fullfile(probtrack_folder,'train_dti_analysis'));
train_dti=train_dti.train_dti;
LH_targets=train_dti.train_LH_targets;
RH_targets=train_dti.train_RH_targets;
%
LH_fdt_sum=train_dti.train_LH_fdt_sum;
LH_fdt_max=train_dti.train_LH_fdt_max;
LH_fdt_raw=train_dti.train_LH_fdt_raw;
% 
RH_fdt_sum=train_dti.train_RH_fdt_sum;
RH_fdt_max=train_dti.train_RH_fdt_max;
RH_fdt_raw=train_dti.train_RH_fdt_raw;

%% analyze LH Temporal to LH Frontal based on sum  
LH_front_lang_target=["LH_IFGorb_top_90";"LH_IFG_top_90";"LH_MFG_top_90"];
LH_front_ctrl_target=["LH_IFGorb_bottom_10";"LH_IFG_bottom_10";"LH_MFG_bottom_10"];
LH_temp_lang_target=["LH_AntTemp_top_90";"LH_PostTemp_top_90";"LH_AngG_top_90"];
LH_temp_ctrl_target=["LH_AntTemp_bottom_10";"LH_PostTemp_bottom_10";"LH_AngG_bottom_10"];
LH_PostTemp_glass_target=["LH_STSdp_ROI";"LH_A4_ROI";"LH_TPOJ1_ROI";"LH_STSvp_ROI"];
LH_AntTemp_glass_target=["LH_TE1a_ROI";"LH_STSva_ROI";"LH_STSda_ROI";"LH_TGd_ROI"];
% 
[C,~,L_F]=intersect(LH_front_lang_target,LH_targets,'stable');
[C,~,L_F_ctrl]=intersect(LH_front_ctrl_target,LH_targets,'stable'); 

[C,~,L_T_Lang]=intersect(LH_temp_lang_target,LH_targets,'stable');
[C,~,L_T_ctrl]=intersect(LH_temp_ctrl_target,LH_targets,'stable');
[C,~,L_postT_glass]=intersect(LH_PostTemp_glass_target,LH_targets,'stable');
[C,~,L_antT_glass]=intersect(LH_AntTemp_glass_target,LH_targets,'stable');

source_fdt=cellfun(@(t) t(L_T_Lang,:),LH_fdt_sum,'uni',false);
target_fdt=cellfun(@(t) t(:,L_F),source_fdt,'uni',false);

source_ctrl_fdt=cellfun(@(t) t(L_T_ctrl,:),LH_fdt_sum,'uni',false);
target_ctrl_fdt=cellfun(@(t) t(:,L_F),source_ctrl_fdt,'uni',false);

source_ctrl_ctrl_fdt=cellfun(@(t) t(L_T_ctrl,:),LH_fdt_sum,'uni',false);
target_ctrl_ctrl_fdt=cellfun(@(t) t(:,L_F_ctrl),source_ctrl_fdt,'uni',false);


source_postglass_fdt=cellfun(@(t) t(L_postT_glass,:),LH_fdt_sum,'uni',false);
target_postglass_fdt=cellfun(@(t) t(:,L_F),source_postglass_fdt,'uni',false);

source_antglass_fdt=cellfun(@(t) t(L_antT_glass,:),LH_fdt_sum,'uni',false);
target_antglass_fdt=cellfun(@(t) t(:,L_F),source_antglass_fdt,'uni',false);


%% Language connectivity 
for tmp_src=1:length(L_T_Lang)
    test=cell2mat(cellfun(@(t) t(tmp_src,:),target_fdt,'uni',false));
    flips=nchoosek(1:3,2);
    ff=figure;
    ff.Units='Inches';
    ff.Position=[55.5139 10.6250 11 8];
    ff.PaperOrientation='landscape';
    for kk=1:3
        subplot(2,2,kk);
        x=test(:,flips(kk,1));
        x_log=log(x);
        y=test(:,flips(kk,2));
        y_log=log(y);
        [hscatter,hbar,ax,ahist]=scatterDiagHist(x,y);
        hscatter.Marker='o';
        hscatter.MarkerFaceColor='r';
        hscatter.MarkerEdgeColor='k';
        hbar.FaceColor='r';
        hbar.LineWidth=2;
        ax.XLabel.String=sprintf('--> %s',strrep(LH_front_lang_target(flips(kk,1)),'_',' '));
        ax.YLabel.String=sprintf('--> %s',strrep(LH_front_lang_target(flips(kk,2)),'_',' '));
        ax.FontSize=12;
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
        ahist.Title.FontSize=15;
        ahist.Title.Position=[0,max(ahist.YLim),0];
    end
    
    dim = [.55 .1 .3 .2];
    str = sprintf('Connectivity between %s and \n frontal regions (SUM)',strrep(LH_temp_ctrl_target{tmp_src},'_',' '));
    a=annotation(ff,'textbox',dim,'String',str,'fontsize',14,'fontweight','bold');
    a.LineStyle='none'
    %print(ff,'-dpdf','-painters', strcat(analysis_path,'/',sprintf('%s_to_front_indv_sum.pdf',LH_temp_ctrl_target{tmp_src})));
    
end

%% do control regions 
for tmp_src=1:length(L_T_ctrl)
test=cell2mat(cellfun(@(t) t(tmp_src,:),target_ctrl_fdt,'uni',false));
flips=nchoosek(1:3,2);
ff=figure;
ff.Units='Inches';
ff.Position=[55.5139 10.6250 11 8];
ff.PaperOrientation='landscape';

for kk=1:3
    subplot(2,2,kk);
    x=test(:,flips(kk,1));
    x_log=log(x);
    y=test(:,flips(kk,2));
    y_log=log(y);
    [hscatter,hbar,ax,ahist]=scatterDiagHist(x,y);
    
    hscatter.Marker='o';
    hscatter.MarkerFaceColor='r';
    hscatter.MarkerEdgeColor='k';
    hbar.FaceColor='r';
    hbar.LineWidth=2;
    ax.XLabel.String=sprintf('--> %s',strrep(LH_front_lang_target(flips(kk,1)),'_',' '));
    ax.YLabel.String=sprintf('--> %s',strrep(LH_front_lang_target(flips(kk,2)),'_',' '));
    
    ax.FontSize=10;
    
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
    ahist.Title.FontSize=15;
    ahist.Title.Position=[0,max(ahist.YLim),0];
end
    dim = [.55 .1 .3 .2];
    str = sprintf('Connectivity between %s and \n frontal regions (SUM)',strrep(LH_temp_lang_target{tmp_src},'_',' '));
    a=annotation(ff,'textbox',dim,'String',str,'fontsize',14,'fontweight','bold');
    a.LineStyle='none'
    print(ff,'-dpdf','-painters', strcat(analysis_path,'/',sprintf('%s_to_front_indv_sum.pdf',LH_temp_lang_target{tmp_src})));
    
end

%% do Post glasser regions 
for tmp_src=1:length(L_postT_glass)
test=cell2mat(cellfun(@(t) t(tmp_src,:),target_postglass_fdt,'uni',false));
flips=nchoosek(1:3,2);
ff=figure;
ff.Units='Inches';
ff.Position=[55.5139 10.6250 11 8];
ff.PaperOrientation='landscape';

for kk=1:3
    subplot(2,2,kk);
    x=test(:,flips(kk,1));
    x_log=log(x);
    y=test(:,flips(kk,2));
    y_log=log(y);
    [hscatter,hbar,ax,ahist]=scatterDiagHist(x,y);
    
    hscatter.Marker='o';
    hscatter.MarkerFaceColor='r';
    hscatter.MarkerEdgeColor='k';
    hbar.FaceColor='r';
    hbar.LineWidth=2;
    ax.XLabel.String=sprintf('--> %s',strrep(LH_front_lang_target(flips(kk,1)),'_',' '));
    ax.YLabel.String=sprintf('--> %s',strrep(LH_front_lang_target(flips(kk,2)),'_',' '));
    
    ax.FontSize=10;
    
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
    ahist.Title.FontSize=15;
    ahist.Title.Position=[0,max(ahist.YLim),0];
end
    dim = [.55 .1 .3 .2];
    str = sprintf('Connectivity between %s and \n frontal regions (SUM)',strrep(LH_PostTemp_glass_target{tmp_src},'_',' '));
    a=annotation(ff,'textbox',dim,'String',str,'fontsize',14,'fontweight','bold');
    a.LineStyle='none';
    print(ff,'-dpdf','-painters', strcat(analysis_path,'/',sprintf('%s_to_front_indv_sum.pdf',LH_PostTemp_glass_target{tmp_src})));
    
end

%% do Ant glasser regions 
for tmp_src=1:length(L_antT_glass)
test=cell2mat(cellfun(@(t) t(tmp_src,:),target_antglass_fdt,'uni',false));
flips=nchoosek(1:3,2);
ff=figure;
ff.Units='Inches';
ff.Position=[55.5139 10.6250 11 8];
ff.PaperOrientation='landscape';

for kk=1:3
    subplot(2,2,kk);
    x=test(:,flips(kk,1));
    x_log=log(x);
    y=test(:,flips(kk,2));
    y_log=log(y);
    [hscatter,hbar,ax,ahist]=scatterDiagHist(x,y);
    
    hscatter.Marker='o';
    hscatter.MarkerFaceColor='r';
    hscatter.MarkerEdgeColor='k';
    hbar.FaceColor='r';
    hbar.LineWidth=2;
    ax.XLabel.String=sprintf('--> %s',strrep(LH_front_lang_target(flips(kk,1)),'_',' '));
    ax.YLabel.String=sprintf('--> %s',strrep(LH_front_lang_target(flips(kk,2)),'_',' '));
    
    ax.FontSize=10;
    
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
    ahist.Title.FontSize=15;
    ahist.Title.Position=[0,max(ahist.YLim),0];
end
    dim = [.55 .1 .3 .2];
    str = sprintf('Connectivity between %s and \n frontal regions (SUM)',strrep(LH_AntTemp_glass_target{tmp_src},'_',' '));
    a=annotation(ff,'textbox',dim,'String',str,'fontsize',14,'fontweight','bold');
    a.LineStyle='none';
    print(ff,'-dpdf','-painters', strcat(analysis_path,'/',sprintf('%s_to_front_indv_sum.pdf',LH_AntTemp_glass_target{tmp_src})));
    
end


%% 
%% do control to contrl regions 
for tmp_src=1:length(LH_temp_ctrl_target)
test=cell2mat(cellfun(@(t) t(tmp_src,:),target_ctrl_ctrl_fdt,'uni',false));
flips=nchoosek(1:3,2);
ff=figure;
ff.Units='Inches';
ff.Position=[55.5139 10.6250 11 8];
ff.PaperOrientation='landscape';

for kk=1:3
    subplot(2,2,kk);
    x=test(:,flips(kk,1));
    x_log=log(x);
    y=test(:,flips(kk,2));
    y_log=log(y);
    [hscatter,hbar,ax,ahist]=scatterDiagHist(x,y);
    
    hscatter.Marker='o';
    hscatter.MarkerFaceColor='r';
    hscatter.MarkerEdgeColor='k';
    hbar.FaceColor='r';
    hbar.LineWidth=2;
    ax.XLabel.String=sprintf('--> %s',strrep(LH_front_ctrl_target(flips(kk,1)),'_',' '));
    ax.YLabel.String=sprintf('--> %s',strrep(LH_front_ctrl_target(flips(kk,2)),'_',' '));
    
    ax.FontSize=10;
    
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
    ahist.Title.FontSize=15;
    ahist.Title.Position=[0,max(ahist.YLim),0];
end
    dim = [.55 .1 .3 .2];
    str = sprintf('Connectivity between %s and \n frontal regions (SUM)',strrep(LH_temp_ctrl_target{tmp_src},'_',' '));
    a=annotation(ff,'textbox',dim,'String',str,'fontsize',14,'fontweight','bold');
    a.LineStyle='none';
    print(ff,'-dpdf','-painters', strcat(analysis_path,'/',sprintf('%s_to_front_ctrl_indv_sum.pdf',LH_temp_ctrl_target{tmp_src})));
    
end


%% plot them all together 
lang_temp_front_ave=mean(cat(3,target_fdt{:}),3);
lang_ctrl_tmp_front_ave=mean(cat(3,target_ctrl_fdt{:}),3);

glass_ant_tmp_front_ave=mean(cat(3,target_antglass_fdt{:}),3);
glass_post_tmp_front_ave=mean(cat(3,target_postglass_fdt{:}),3);

PostTemp_res=[lang_temp_front_ave(2,:);lang_ctrl_tmp_front_ave(2,:);glass_post_tmp_front_ave];
PostTemp_ticks=[LH_temp_lang_target(2);LH_temp_ctrl_target(2);LH_PostTemp_glass_target];

AntTemp_res=[lang_temp_front_ave(1,:);lang_ctrl_tmp_front_ave(1,:);glass_ant_tmp_front_ave];
AntTemp_ticks=[LH_temp_lang_target(1);LH_temp_ctrl_target(1);LH_AntTemp_glass_target];
ff=figure;
ff.Units='Inches';
ff.Position=[55.5139 10.6250 11 8];
ff.PaperOrientation='landscape';
ax=subplot(1,2,1);
imagesc(PostTemp_res)
colormap('inferno')
daspect([1,1,1])
ax.XTick=[1,2,3];
ax.YTick=1:size(PostTemp_res,1);
ax.XTickLabel=strrep(LH_front_lang_target,'_',' ');
ax.XTickLabelRotation=45;

ax.YTickLabel=strrep(PostTemp_ticks,'_',' ');
ax.YTickLabelRotation=0;
ax.Title.String='Posterior regions';

ax=subplot(1,2,2);
imagesc(AntTemp_res)
colormap('inferno')
daspect([1,1,1])
ax.XTick=[1,2,3];
ax.YTick=1:size(AntTemp_res,1);
ax.XTickLabel=strrep(LH_front_lang_target,'_',' ');
ax.XTickLabelRotation=45;

ax.YTickLabel=strrep(AntTemp_ticks,'_',' ');
ax.YTickLabelRotation=0;
ax.Title.String='Anterior regions'
print(ff,'-dpdf','-painters', strcat(analysis_path,'/',sprintf('all_temp_to_front_sum.pdf')));

%% analyze LH Temporal to LH Frontal based on max  
LH_temp_lang_target=["LH_AntTemp_top_90";"LH_PostTemp_top_90";"LH_AngG_top_90"];
LH_front_lang_target=["LH_IFGorb_top_90";"LH_IFG_top_90";"LH_MFG_top_90"];
% 
RH_temporal_target=["RH_AntTemp_top_90";"RH_PostTemp_top_90";"RH_AngG_top_90"];
RH_frontal_target=["RH_IFGorb_top_90";"RH_IFG_top_90";"RH_MFG_top_90"];

[C,~,L_T_Lang]=intersect(LH_temp_lang_target,LH_targets,'stable');
[C,~,L_F]=intersect(LH_front_lang_target,LH_targets,'stable');

source_fdt=cellfun(@(t) t(L_T_Lang,:),LH_fdt_max,'uni',false);
target_fdt=cellfun(@(t) t(:,L_F),source_fdt,'uni',false);
LH_PostTemp_Frontal=cell2mat(cellfun(@(x) sum(x), target_fdt,'uni',false));


% first ant temp 
for tmp_src=1:3
test=cell2mat(cellfun(@(t) t(tmp_src,:),target_fdt,'uni',false));
flips=nchoosek(1:3,2);
ff=figure;
ff.Units='Inches';
ff.Position=[55.5139 10.6250 8 11];
ff.PaperOrientation='portrait';

for kk=1:3
    subplot(3,1,kk);
    x=test(:,flips(kk,1));
    x_log=log(x);
    y=test(:,flips(kk,2));
    y_log=log(y);
    [hscatter,hbar,ax,ahist]=scatterDiagHist(x,y);
    
    hscatter.Marker='o';
    hscatter.MarkerFaceColor='r';
    hscatter.MarkerEdgeColor='k';
    hbar.FaceColor='r';
    hbar.LineWidth=2;
    ax.XLabel.String=sprintf('--> %s',strrep(LH_front_lang_target(flips(kk,1)),'_',' '));
    ax.YLabel.String=sprintf('--> %s',strrep(LH_front_lang_target(flips(kk,2)),'_',' '));

    ax.FontSize=12;
    
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
    ahist.Title.FontSize=15;
    ahist.Title.Position=[0,max(ahist.YLim),0];
end 

dim = [.55 .1 .3 .2];
str = sprintf('Connectivity between %s and \n frontal regions (MAX)',strrep(LH_temp_lang_target{tmp_src},'_',' '));
a=annotation(ff,'textbox',dim,'String',str,'fontsize',14,'fontweight','bold');
print(ff,'-dpdf','-opengl', strcat(analysis_path,'/',sprintf('%s_to_front_indv_max.pdf',LH_temp_lang_target{tmp_src})));
end 