classdef PredictionModel < handle
    %PREDICTIONMODEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Heatmap
        SamplingMethod = @A_15bins;
        TrainingLinearModel
        TrainigLinearModel_cov
        Tag
        Path
        %Description
    end
    
    properties (Hidden)
        
        B
        B_cov
    end
    
    methods
        function obj = PredictionModel(inputArg1,inputArg2)
        end
        
        function bool = isTrained(obj)
            bool = ~isempty(obj.B);
        end
        
        function obj = trainOnVoxelDataStack(obj,VDS,customMethod)
            if nargin==3
                obj.SamplingMethod = customMethod;
            end
            
            %get required info from the SamplingMethod
            samplingMethod = feval(obj.SamplingMethod);
            requiredMaps = samplingMethod.RequiredHeatmaps;
            
            %Make a Heatmap including all data.
            disp('Making a heatmap based on all data')
            heatmap=Heatmap(); %#ok<CPROPLC>
            try
                [~,foldername] = fileparts(fileparts(VDS.RecipePath));
                propertyname = VDS.ScoreLabel;
                nameSuggestion = [foldername,' ',propertyname];
                description = [];
            catch
                disp('name suggestion failed..')
                nameSuggestion = [];
                description = [];
            end
                
            heatmap.fromVoxelDataStack(VDS,nameSuggestion,description,requiredMaps);
            obj.Heatmap = heatmap;
           
            
            %Run a Leave one out training routine
            TrainingModule = LOORoutine();
            TrainingModule.SamplingMethod = obj.SamplingMethod; %pass on
            TrainingModule.VDS = VDS;
            TrainingModule.LOOregression();
            
            obj.TrainingLinearModel = TrainingModule.LOOmdl;
            obj.B = TrainingModule.LOOmdl.Coefficients.Estimate;
            obj.Tag = obj.Heatmap.Tag;
            obj.Path = TrainingModule.VDS.RecipePath;
            
            obj.printTrainingDetails
            
        end
        
        function printTrainingDetails(obj)
            obj.TrainingLinearModel
        end
        

        function fig = plotTraining(obj)
            % fig = figure;
            %  set(fig,'defaultTextInterpreter','none')
            % if isempty(obj.TrainingLinearModel);return;end
            % scatter(obj.TrainingLinearModel.Variables.y,...
            %     obj.TrainingLinearModel.predict);
            % hold on;
            % line(xlim,xlim,'Color','red','LineStyle','--')
            % xlabel(obj.Heatmap.Tag)
            % ylabel('Model prediction')
            % title({'LOO training model',['Rsquared:', num2str(obj.TrainingLinearModel.Rsquared.Ordinary)]})



            %%

            fig = figure; 
            obj.TrainingLinearModel.plot


            x_text = 'Model score';%; %
            tag = strsplit(obj.Tag,' ');
            y_text = tag{2};
            t_text = ['Leave one out ',y_text];%
            p = obj.TrainingLinearModel.ModelFitVsNullModel.Pvalue;
            r2 = obj.TrainingLinearModel.Rsquared.Ordinary;
            xlabel(x_text);
            ylabel(y_text,'Interpreter','tex');
            if p < 0.01
                title({['\bf ',t_text];['\rm \fontsize{12} r^2 = ',num2str(r2),', p <0.01 \rm']},'Interpreter','tex')
            elseif p < 0.05
                title({['\bf ',t_text];['\rm \fontsize{12} r^2 = ',num2str(r2),', p <0.05 \rm']},'Interpreter','tex')
            else
                p = round(p,2);
                title({['\bf ',t_text];['\rm \fontsize{12} r^2 = ',num2str(r2),', p = ',num2str(p),' \rm']},'Interpreter','tex')
            end

            PredictionModel.styleFig(fig)



            
        end

        function f= plotLOOCV_cov(obj)
            mdl = obj.LOOCV_cov('this string avoids that the plotting is triggered twice');
            f = obj.plotmdl(mdl,'LOOCV with covariates');
        end

        function vif_on_covariates(obj)
            if isempty(obj.TrainigLinearModel_cov)
                disp('No covariate model was trained')
            end

            data = table2array(obj.TrainigLinearModel_cov.Variables);
            R0 = corrcoef(data);
            vif = diag(inv(R0))';
            names = obj.TrainigLinearModel_cov.VariableNames;
            for i = 1:length(names)
                fprintf('%s: %.3f\n', names{i}, vif(i));
            end



        end
        
        function f = plotLOOCV(obj)
            mdl = obj.LOOCV();

            f = obj.plotmdl(mdl,'LOOCV ');
        end
        function fig = plotmdl(obj,mdl,txt)

            fig = figure;
            mdl.plot;
            

            x_text = 'Prediction';%; %
            tag = strsplit(obj.Tag,' ');
            y_text = tag{2};
            t_text = [txt,' ',y_text];%
            p = mdl.ModelFitVsNullModel.Pvalue;
            r2 = mdl.Rsquared.Ordinary;
                
            q2 = A_q2(mdl.Variables.x1,mdl.Variables.y);
            disp(['The exact prediction quality q^2: ',num2str(q2)])
            if q2>0
                q2_text = [', q^2 = ',num2str(round(q2,2))];
            else
                q2_text = '';
            end


            xlabel(x_text);
            ylabel(y_text,'Interpreter','tex');
            if p < 0.01
                title({['\bf ',t_text];['\rm \fontsize{12} r^2 = ',num2str(round(r2,2)),', p <0.01',q2_text,'\rm']},'Interpreter','tex')
            elseif p < 0.05
                title({['\bf ',t_text];['\rm \fontsize{12} r^2 = ',num2str(round(r2,2)),', p <0.05',q2_text,' \rm']},'Interpreter','tex')
            else
                p = round(p,2);
                title({['\bf ',t_text];['\rm \fontsize{12} r^2 = ',num2str(round(r2,2)),', p = ',num2str(p),' \rm']},'Interpreter','tex')
            end

            PredictionModel.styleFig(fig)


        end


        
        function [prediction,predictors] = predictVoxelData(obj,VD)
           
           
            ba = BiteAnalysis(obj.Heatmap,VD,obj.SamplingMethod);
            predictors = ba.Predictors;
            
            %apply B
            try
            prediction = [1,predictors]*obj.B;
            catch
                if isnan(predictors)
                    prediction = nan;
                else % no B
                    error('please train model before applying prediction');
                end
            end
        end
        
        function mdl = validateOnVoxelDataStack(obj,VDS)
            n = length(VDS);
            predictorslist = {};
            predictions = [];
            for i= 1:n
                [prediction,predictors] = predictVoxelData(obj,VDS.getVoxelDataAtPosition(i));
                predictorslist{i} = predictors;
                predictions(i) = prediction;
            end
            
            mdl= fitlm(VDS.Weights,predictions);
            
        end
        
        function save(obj)
            global arena
            root = arena.getrootdir;
            modelFolder = fullfile(root,'UserData','PredictionModels');
            if ~exist(modelFolder,'dir')
                mkdir(modelFolder)
            end
            mdl = obj;
            formatOut = 'yyyy_mm_dd';
            disp(['saving as: ',datestr(now,formatOut),'_',obj.Heatmap.Tag,'_',func2str(obj.SamplingMethod),' in ../ArenaToolbox/UserData/PredictionModels'])
            save(fullfile(modelFolder,[datestr(now,formatOut),'_',obj.Heatmap.Tag,'_',func2str(obj.SamplingMethod)]),'mdl','-v7.3')
            disp('Saving complete')
        end
        
        
        function obj = load(obj)
            global arena
            root = arena.getrootdir;
            modelFolder = fullfile(root,'UserData','PredictionModels');
            strmessage=['from Arena Rootdirectory: ',modelFolder];
            answer=questdlg('how would you like to load the prediction model?','',...
               strmessage,...
                'select from other directory',strmessage);
            
            switch answer
                case strmessage
                     mdlpath = uigetfile(fullfile(modelFolder,'*.mat'),'select file');
                     loaded = load(fullfile(modelFolder,mdlpath));
                case 'select from other directory'
                   [mdlpath,modelFolder] = uigetfile('*.mat','select file');
                    loaded = load(fullfile(modelFolder,mdlpath));
            end
                
          

            disp('Loading...')
             
          
            
            obj.Heatmap = loaded.mdl.Heatmap;
            obj.SamplingMethod = loaded.mdl.SamplingMethod;
            obj.TrainingLinearModel = loaded.mdl.TrainingLinearModel;
            obj.B = loaded.mdl.B;
            obj.Tag = loaded.mdl.Tag;
        end
        
        function mdl = LOOCV(obj)
            
            if ~isempty(obj.TrainingLinearModel)
                tbl  = obj.TrainingLinearModel.Variables;
                mtrx = table2array(tbl);
                predictors = mtrx(:,1:end-1);
                truth = mtrx(:,end);
                mdl = LOORoutine.quickLOOCV(predictors,truth');
            end
            
        end

        function mdl = LOOCV_cov(obj,internalcall)

            %load excel sheet
            tableRecipe = readtable(obj.Path);

            %select covariates
            options = tableRecipe.Properties.VariableNames(4:end);
            choice = listdlg('ListString',options,'PromptString','Select a label:','SelectionMode','multiple');
            scoreTag = options(choice);
            
            %spatial output
            spatial = obj.TrainingLinearModel.predict;
            covariates = array2table(spatial);


            %get additional covariate data
            for iTag = 1:numel(scoreTag)
                covariates.(scoreTag{iTag}) = tableRecipe.(scoreTag{iTag});
            end


            

            %truth
            mtrx  = table2array(obj.TrainingLinearModel.Variables);
            truth = mtrx(:,end);
            

            %LOOCV
            disp('')
            disp('-----------------')
            disp('LOOCV with covariates')
            disp('----------------')
            mdl = LOORoutine.quickLOOCV(table2array(covariates),truth')
            disp('LOOCV model is accessible as mdlLOOCV in workspace')
            assignin("base",'mdlLOOCV',mdl)

            %LOO for predictions later on.
            disp('')
            disp('-----------------')
            disp('LOO with covariates for future predictions')
            disp('----------------')
            covariates.truth = truth;
            covmdl = fitlm(covariates,'truth')
            obj.TrainigLinearModel_cov = covmdl;
            obj.save
            disp('LOO model is accessible as mdlCOV in workspace')
            assignin("base",'mdlCOV',covmdl)

            if nargin==1
                obj.plotmdl(mdl,'LOOCV with covariates');
            end
            

        end
        
        function spearman(obj)
            
            if ~isempty(obj.TrainingLinearModel)
                tbl  = obj.TrainingLinearModel.Variables;
                mtrx = table2array(tbl);
                predictors = obj.TrainingLinearModel.predict;
                truth = mtrx(:,end);
                [rho, pval] = corr(predictors,truth,'Type','Spearman')
                
            end
        end
    end
    methods (Static)
        function styleFig(fig)

            %axis and figure:
hold on
legend off
fig.CurrentAxes.Box = 'off';
fig.CurrentAxes.XLabel.FontSize=14;
fig.CurrentAxes.YLabel.FontSize=14;
fig.CurrentAxes.TitleFontSizeMultiplier = 1.5;


%data
h_data = findobj(fig.CurrentAxes,'DisplayName','Data','-or','Tag','data');
h_data.MarkerSize = 15;
h_data.Marker = '.';
h_data.Color = [0 0 0];

%fit
h_fit = findobj(fig.CurrentAxes,'DisplayName','Fit','-or','Tag','fit');
h_fit.LineStyle = '--';
h_fit.Color = [0 0 0];

%confidence
h_dashedline = findobj(fig.CurrentAxes,'LineStyle',':');
if numel(h_dashedline)==2
    x1 = h_dashedline(1).XData;
    y1 = h_dashedline(1).YData;
    x2 = h_dashedline(2).XData;
    y2 = h_dashedline(2).YData;
    x = [x1,fliplr(x2)];
    y = [y1,fliplr(y2)];
    delete(h_dashedline)
else
    x = h_dashedline.XData;
    y = h_dashedline.YData;
    middle = find(isnan(x));
    x = [x(1:middle-1),fliplr(x(middle+1:end))];
    y = [y(1:middle-1),fliplr(y(middle+1:end))];
    delete(h_dashedline) 
end
h_confidence = fill(fig.CurrentAxes,x,y,[0.85 0.85 0.85]);
h_confidence.LineStyle = 'none';
set(gca, 'Children', flipud(get(gca, 'Children')) )

%legend
legend({'95% confidence','trend','data'})
fig.CurrentAxes.Legend.Location = 'SouthEast';

        end
    end

end

