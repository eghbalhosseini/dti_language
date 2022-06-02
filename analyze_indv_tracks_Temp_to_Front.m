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
LH_temp_lang_target=["LH_AntTemp_top_90";"LH_PostTemp_top_90";"LH_AngG_top_90"];
LH_front_lang_target=["LH_IFGorb_top_90";"LH_IFG_top_90";"LH_MFG_top_90"];

LH_temp_ctrl_target=["LH_AntTemp_bottom_10";"LH_PostTemp_bottom_10";"LH_AngG_bottom_10"];
LH_front_ctrl_target=["LH_IFGorb_bottom_10";"LH_IFG_bottom_10";"LH_MFG_bottom_10"];

% 

[C,~,L_T_Lang]=intersect(LH_temp_lang_target,LH_targets,'stable');
[C,~,L_F]=intersect(LH_front_lang_target,LH_targets,'stable');
source_fdt=cellfun(@(t) t(L_T_Lang,:),LH_fdt_sum,'uni',false);
target_fdt=cellfun(@(t) t(:,L_F),source_fdt,'uni',false);


[C,~,L_T_ctrl]=intersect(LH_temp_ctrl_target,LH_targets,'stable');
[C,~,L_F_ctrl]=intersect(LH_front_ctrl_target,LH_targets,'stable');
source_ctrl_fdt=cellfun(@(t) t(L_T_ctrl,:),LH_fdt_sum,'uni',false);
target_ctrl_fdt=cellfun(@(t) t(:,L_F),source_ctrl_fdt,'uni',false);


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
    str = sprintf('Connectivity between %s and \n frontal regions (SUM)',strrep(LH_temp_lang_target{tmp_src},'_',' '));
    a=annotation(ff,'textbox',dim,'String',str,'fontsize',14,'fontweight','bold');
    print(ff,'-dpdf','-opengl', strcat(analysis_path,'/',sprintf('%s_to_front_indv_sum.pdf',LH_temp_lang_target{tmp_src})));
    
end

tmp_src=2;
test=cell2mat(cellfun(@(t) t(tmp_src,:),target_fdt,'uni',false));
flips=nchoosek(1:3,2);
ff=figure;
ff.Units='Inches';
ff.Position=[55.5139 10.6250 8 11];
ff.PaperOrientation='portrait';

for kk=1:3
    subplot(3,1,kk);
    x=test(:,flips(kk,1));
    y=test(:,flips(kk,2));
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
str = sprintf('Connectivity between %s and \n frontal regions (SUM)',strrep(LH_temp_lang_target{tmp_src},'_',' '));
a=annotation(ff,'textbox',dim,'String',str,'fontsize',14,'fontweight','bold');
print(ff,'-dpdf','-opengl', strcat(analysis_path,'/',sprintf('%s_to_front_indv_sum.pdf',LH_temp_lang_target{tmp_src})));
% 
tmp_src=3;
test=cell2mat(cellfun(@(t) t(tmp_src,:),target_fdt,'uni',false));
flips=nchoosek(1:3,2);
ff=figure;
ff.Units='Inches';
ff.Position=[55.5139 10.6250 8 11];
ff.PaperOrientation='portrait';

for kk=1:3
    ax=subplot(3,1,kk);
    x=test(:,flips(kk,1));
    y=test(:,flips(kk,2));
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
str = sprintf('Connectivity between %s and \n frontal regions (SUM)',strrep(LH_temp_lang_target{tmp_src},'_',' '));
a=annotation(ff,'textbox',dim,'String',str,'fontsize',14,'fontweight','bold');
print(ff,'-dpdf','-opengl', strcat(analysis_path,'/',sprintf('%s_to_front_indv_sum.pdf',LH_temp_lang_target{tmp_src})));
%% do control regions 
tmp_src=1;
test=cell2mat(cellfun(@(t) t(tmp_src,:),target_ctrl_fdt,'uni',false));
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


tmp_src=2;
test=cell2mat(cellfun(@(t) t(tmp_src,:),target_ctrl_fdt,'uni',false));
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
tmp_src=1;
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


tmp_src=2;
test=cell2mat(cellfun(@(t) t(tmp_src,:),target_fdt,'uni',false));
flips=nchoosek(1:3,2);
ff=figure;
ff.Units='Inches';
ff.Position=[55.5139 10.6250 8 11];
ff.PaperOrientation='portrait';

for kk=1:3
    subplot(3,1,kk);
    x=test(:,flips(kk,1));
    y=test(:,flips(kk,2));
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
% 
tmp_src=3;
test=cell2mat(cellfun(@(t) t(tmp_src,:),target_fdt,'uni',false));
flips=nchoosek(1:3,2);
ff=figure;
ff.Units='Inches';
ff.Position=[55.5139 10.6250 8 11];
ff.PaperOrientation='portrait';

for kk=1:3
    ax=subplot(3,1,kk);
    x=test(:,flips(kk,1));
    y=test(:,flips(kk,2));
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