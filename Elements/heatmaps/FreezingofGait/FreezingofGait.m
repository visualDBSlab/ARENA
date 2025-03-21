classdef FreezingofGait < HeatmapModelSupport & handle
    %Some functions are required. Others are specific to this heatmap.
    % Essential functions and paramters are labeled with *REQ*
    % 
    events
      callonHeatmapfilter
    end
    properties
        Tag = 'FreezingofGait [beta]' %*REQ*
        HeatmapModel %*REQ*
%         b=[-0.634200000000000;0.144400000000000;...
%             -1.07900000000000;0.960900000000000;-0.0974000000000000;0.783700000000000;...
%             0.722300000000000;-0.627400000000000;-0.327400000000000;-1.98830000000000;0.831400000000000;-0.531100000000000;...
%             0;1.80780000000000;-1.18860000000000;1.37500000000000];
b=[ 0;2.4908;0.7444;-1.2646;-2.9704;-4.0697;-1.9006;0;-0.7328;-1.3470;-2.6856;-2.9568;-2.0681;-2.9058;-1.7828;-0.6680;-0.8519];% removed first b value with zero
        edges = -1:0.13333333333:1;
    end
    
     methods
            
        function obj = FreezingofGait() %*REQ*
            addpath(fileparts(mfilename('fullpath'))); %adds the path including the sweetspotfiles
        end
       
        
        function obj = load(obj) %*REQ*
            map  = load('FreezingofGait_heatmap.heatmap','-mat');
            map=map.heatmap.Signedpmap;
            obj.HeatmapModel = map;
            
        end
        
        function [prediction, confidence comments] = predictionForVTAs(obj,VTAlist) %*REQ*
            sample = [];
            comments = {};
            confidence = [];
            for iVTA = 1:numel(VTAlist)
                lastwarn('');
                thisVTA = VTAlist(iVTA);
                [newSample,newConfidence] = obj.sampleWithVTA(thisVTA);
                sample = [sample,newSample'];
                confidence(iVTA) = newConfidence;
                comments{iVTA} = lastwarn;
            end
            prediction = obj.predictForSample(sample);
        end
        
        function [sample,confidence] = sampleWithVTA(obj,VTA)
            comment = '';
            %load the model
            if isempty(obj.HeatmapModel)
                obj = obj.load();
            end
            
            %get the voxeldata of the VTA
            switch class(VTA.Volume)
                case 'VoxelData'
                    VTA_voxelData = VoxelData(double(VTA.Volume.Voxels > 0.5),VTA.Volume.R);
                case 'Mesh'
                     VTA_voxelData = VoxelData(double(VTA.Volume.Source.Voxels > VTA.Volume.Settings.T),VTA.Volume.Source.R);
            end
            
            %check the space and fix if it's not matching.
            if VTA.Space~=Space.MNI2009b
                VTA_voxelData = FreezingofGait.fixSpace(VTA.Space,VTA_voxelData);
            end
            

            %warp to heatmap space
            VTA_voxelData.warpto(obj.HeatmapModel);
            
            %make sure to mirror VTAs if heatmap unilateral
            CoG_map=obj.HeatmapModel.getcog;
            CoG_VTA=VTA_voxelData.getcog;
            if sign(CoG_map.x)~=sign(CoG_VTA.x)
               VTA_voxelData=VTA_voxelData.mirror;
            end
            
            %sample map to see if it's overlapping enough with the model!
            allvoxels = obj.HeatmapModel.Voxels(VTA_voxelData.Voxels>0.5);
            outofmodel = sum(allvoxels==0);
            if outofmodel/numel(allvoxels)>0.3
                warning(['VTA (',VTA.Tag,') is partly outside the model! (',num2str(outofmodel/numel(allvoxels)*100),'%)']);
                
            end
            confidence = 1-outofmodel/numel(allvoxels);
            
            %sample those voxels where VTA and model both are.
            sample = allvoxels;
        end
        
        function y = predictForSample(obj,sample)
            h = histogram(sample,obj.edges);
            X = [1,1,zscore(h.Values)];
            y = X*obj.b;
            delete(h)
        end
        end
        
        



methods(Static)
     

    function out = fixSpace(oldspace,voxeldata) 
    switch oldspace
        case Space.Legacy
            T = [-1 0 0 0;0 -1 0 0;0 0 1 0;0 -37.5 0 1];
            out = voxeldata.imwarp(T);
        case Space.Unknown
            error('wrong space')
        case Space.PatientNative
            error('wrong space')
    end
    end
    
    function  [filtersettings,cancelled] = definePostProcessingSettings(obj) %*REQ*
        
        %default
        filtersettings.confidence = 0.45;
        filtersettings.useSecondaryMap = 'Y';
        filtersettings.secondaryMap = '';
        filtersettings.sort = 'descending';
        filtersettings.filter = '';
        
        
%--- pop-up 1
        prompt = {'Minimum confidence:','Use secondary map for filtering? [Y/N]'};
        dlgtitle = 'Post Processing settings';
        dims = [1 35];
        definput = {num2str(filtersettings.confidence),filtersettings.useSecondaryMap};
        answer = inputdlg(prompt,dlgtitle,dims,definput);
        
        filtersettings.confidence = str2num(answer{1});
        filtersettings.useSecondaryMap = answer{2};
        
    %--- pop-up 2
        askForMap = strcmpi(filtersettings.useSecondaryMap,'Y');
        while askForMap
           
          
                [filename,pathname] = uigetfile('*.m', 'get the heatmap class');
                addpath(pathname)
                heatmappath = fullfile(pathname,filename);
                
                try
                    [~,fn]= fileparts(filename);
                    testrun = eval(fn);
                    filtersettings.secondaryMap = heatmappath;
                    askForMap = 0;
                catch
                   answer = questdlg('Looks like the heatmap is invalid','Oops','Try again','Abort','Try again');
                   switch answer
                       case 'Try again'
                           askForMap = 1;
                       case 'abort'
                           error('aborted by user');
                           
                           
                   end
                end
        end
        
%--- pop-up 3
        if ~isempty(filtersettings.secondaryMap)
            options = {'Method 1: Same UPDRS as pre-op. (So 0% improvement)',...
                        'Method 2a: Same as post-op (Using model score)',...
                        'Method 2b: Same as post-op (Using clinical value, requires manual input)'};
            [indx] = listdlg('PromptString',{'Select postprocessing routine'},...
                                'SelectionMode','single',...
                            'ListString',options,...
                            'ListSize',[400,50]);
                        filtersettings.filter = options{indx};
        end
                
        
        
%         Prompt = {};
%         DefAns = struct([]);
%        formats = struct('type', {}, 'style', {}, 'items', {}, ...
%             'format', {}, 'limits', {}, 'size', {});
% 
% 
% 
%         Options.Resize = 'on';
%         Options.Interpreter = 'tex';
%         Options.CancelButton = 'on';
%         Options.ApplyButton = 'on';
%         Options.ButtonNames = {'Continue','Cancel'}; %<- default names, included here just for illustration
%         Options.Dim = 4; % Horizontal dimension in fields
% 
% Title='filter sets window, to be applied after monopolar review';
%    
%       
%         
%         
%         Prompt(1,:) = {'Minimal confidence of the heatmap [0-1]', 'minimal',[]};
% 
%         formats(1,1).type   = 'edit';
%         formats(1,1).format = 'float';
%         formats(1,1).limits = [0 1];
%         DefAns(1).minimal=0.85;
%         
%         Prompt(end+1,:)={'Amplitude optimization based on  n = ', 'Amplitude',[]};
%         formats(2,1).type   = 'edit';
%         formats(2,1).format = 'float';
%         formats(2,1).limits = [0 5];
%         DefAns.Amplitude=2;
%         
%         
%         Prompt(end+1,:)={'Use a secondary map for filtering', 'Sigma',[]};
%         formats(3,1).type   = 'edit';
%         formats(3,1).format = 'integer';
%         formats(3,1).limits = [0 4];
%         DefAns.Sigma= 3;
%         
%         Prompt(end+1,:)={'filtering based on secondary heatmap', 'heatmap',[]};
%         formats(4,1).type = 'edit';
%         formats(4,1).format = 'file';
%         formats(4,1).items = {'*.m'};% was: {'*.swtspt';'*.mat';'*.heatmap';'*.nii'};
%         formats(4,1).limits = [0 1]; % single file get
%         formats(4,1).size = [-1 0];
%          DefAns.heatmap= pwd;
%         
%    
%         Prompt(end+1,:)={'select heatmap', 'heatmapchoice',[]};
%         formats(5,1).type = 'list';
%         formats(5,1).style = 'listbox';
%         formats(5,1).format = 'text'; % Answer will give value shown in items, disable to get integer
%         formats(5,1).items = {'positive (improvement)';'negative (worsening)';'no change '};
%         formats(5,1).limits = [0 4]; % multi-select
%         formats(5,1).size = [140 80];
%         
%         
%         Prompt(end+1,:)={'select filtering heatmap', 'secondaryheatmapchoice',[]};
%         formats(6,1).type = 'list';
%         formats(6,1).style = 'listbox';
%         formats(6,1).format = 'text'; % Answer will give value shown in items, disable to get integer
%         formats(6,1).items = {'positive (improvement)';'negative (worsening)';'no change '};
%         formats(6,1).limits = [0 4]; % multi-select
%         formats(6,1).size = [140 80];
%         
%        
%         DefAns.heatmapchoice = {'positive (improvement)'};
%         DefAns.secondaryheatmapchoice = {'positive (improvement)'};
% 
%         
%         [filtersettings, cancelled] = inputsdlg(Prompt, Title, formats, DefAns,Options);
%         
%         if ~isempty(filtersettings)
%             disp('not empty')
%         end
%         
%         %test to expedite crashed
%             [folder,heatmapname,ext] = fileparts(filtersettings.heatmap);
%             try
%             testrun = eval(heatmapname);
%             catch
%                 error('Seems like an invalid heatmapfile was selected')
%             end

      

      
    end
    
    function performReviewPostProcessing(tag,predictionList,filterSettings,pairs) %*REQ*
    
    %rename variable    
    predictionlist_fog = predictionList;
    clear predictionlist;
    
    %get functionname for heatmap
    [folder,heatmapname,ext] = fileparts(filterSettings.secondaryMap);
    secondaryHeatmap = eval(heatmapname);
    
    %set up Optional Input in order skip UI dialog boxes
    OptionalInput =[];
    OptionalInput.heatmap = secondaryHeatmap;
    OptionalInput.VTAset = filterSettings.UserInput.VTAset;
    OptionalInput.PostSettings.FOGroutineFilteringRoutine = 1;
    
    %%%% Again run the review. Based on PostopSettings as defined earlier
    therapy_object = filterSettings.Therapy.executeReview(OptionalInput);
    predictionlist_secondary = therapy_object.ReviewData.predictionList;
    %%%%
    
    
    
    switch filterSettings.filter
        case 'Method 1: Same UPDRS as pre-op. (So 0% improvement)'
            %settings
            lower_UPDRS = -40;
            upper_UPDRS = 40;
   %----- gate 1: confidence check
            confidence_primary = arrayfun(@(x) x.Confidence, predictionlist_fog,'UniformOutput',false);
            PassedConfideceCheck_primary = all(cell2mat(confidence_primary')>filterSettings.confidence,2);
            confidence_secondary = arrayfun(@(x) x.Confidence, predictionlist_fog,'UniformOutput',false);
            PassedConfideceCheck_secondary = all(cell2mat(confidence_secondary')>filterSettings.confidence,2);
            
            PassedConfidence = and(PassedConfideceCheck_primary,PassedConfideceCheck_secondary);
   %---- gate 2: same UPDRS
            scores_secondary = arrayfun(@(x) x.Output, predictionlist_secondary);
            PassedUPDRS = and(scores_secondary >= lower_UPDRS, scores_secondary <= upper_UPDRS);
            
   %--- gate 3: high FoG improvement
            PassedFilters = and(PassedConfidence,PassedUPDRS);
            
            confidence = PassedConfidence;
            Global_UPDRS_change=scores_secondary';
            nochangeUPDRS = PassedUPDRS';
            score_primary = arrayfun(@(x) x.Output, predictionlist_fog)';
            
            Amplitude_1 = arrayfun(@(x) x.Input.VTAs(1).Settings.amplitude,predictionlist_fog)';
            Contact_1 = arrayfun(@(x) x.Input.VTAs(1).Settings.activecontact,predictionlist_fog)';
            Amplitude_2 = arrayfun(@(x) x.Input.VTAs(2).Settings.amplitude,predictionlist_fog)';
            Contact_2 = arrayfun(@(x) x.Input.VTAs(2).Settings.activecontact,predictionlist_fog)';
            
            t = table(score_primary,confidence,Global_UPDRS_change,nochangeUPDRS,Contact_1,Amplitude_1,Contact_2,Amplitude_2);
            t_sorted = sortrows(t,'score_primary','descend');
            pathname=mfilename('fullpath');
            ArenaRoot=strfind(pathname,'ArenaToolbox');
            savepath=pathname(1:ArenaRoot+11);
            writetable(t_sorted,[savepath,filesep,'UserData',filesep,'Monpolar Review',filesep,'Electrode 1',...
                predictionlist_fog(1).Input.VTAs(1).ActorElectrode.Tag,' Electrode 2:',predictionlist_fog(1).Input.VTAs(2).ActorElectrode.Tag,'.xlsx']);
            
            disp(['Electrode 1: ',predictionlist_fog(1).Input.VTAs(1).ActorElectrode.Tag])
            disp(['Electrode 2: ',predictionlist_fog(1).Input.VTAs(2).ActorElectrode.Tag])
            

            %make a table,
            %add settigns left, right, score and filters
            %sort
            %print
        case 'Method 2a: Same as post-op (Using model score)'
            %--- settings:
            margin = 10;%
            
      %----- gate 1: confidence check
            confidence_primary = arrayfun(@(x) x.Confidence, predictionlist_fog,'UniformOutput',false);
            PassedConfideceCheck_primary = all(cell2mat(confidence_primary')>filterSettings.confidence,2);
            confidence_secondary = arrayfun(@(x) x.Confidence, predictionlist_fog,'UniformOutput',false);
            PassedConfideceCheck_secondary = all(cell2mat(confidence_secondary')>filterSettings.confidence,2);
            
            PassedConfidence = and(PassedConfideceCheck_primary,PassedConfideceCheck_secondary);
   %---- gate 2: same UPDRS
            clinicalTherapy = filterSettings.Therapy;
            [~, secondaryModelName] = fileparts(filterSettings.secondaryMap);
            secondaryModel = eval(secondaryModelName);
            disp('running clinical VTA through secondary model')
            prediction = clinicalTherapy.executePrediction(secondaryModel);
            
            lower_UPDRS = prediction.Output - margin;
            upper_UPDRS = prediction.Output + margin;
            
            
            scores_secondary = arrayfun(@(x) x.Output, predictionlist_secondary);
            PassedUPDRS = and(scores_secondary >= lower_UPDRS, scores_secondary <= upper_UPDRS);
            
        case 'Method 2b: Same as post-op (Using clinical value, requires manual input)'
            %--- settings:
            margin = 10;%
            
      %----- gate 1: confidence check
            confidence_primary = arrayfun(@(x) x.Confidence, predictionlist_fog,'UniformOutput',false);
            PassedConfideceCheck_primary = all(cell2mat(confidence_primary')>filterSettings.confidence,2);
            confidence_secondary = arrayfun(@(x) x.Confidence, predictionlist_fog,'UniformOutput',false);
            PassedConfideceCheck_secondary = all(cell2mat(confidence_secondary')>filterSettings.confidence,2);
            
            PassedConfidence = and(PassedConfideceCheck_primary,PassedConfideceCheck_secondary);
   %---- gate 2: same UPDRS
            prompt = {'Reference value:','Margin +/-: '};
        dlgtitle = 'Add reference';
        dims = [1 35];
        definput = {'0','40'};
        answer = inputdlg(prompt,dlgtitle,dims,definput);
            
            lower_UPDRS = str2num(answer{1}) - str2num(answer{2});
            upper_UPDRS = str2num(answer{1}) + str2num(answer{2});
            
            
            scores_secondary = arrayfun(@(x) x.Output, predictionlist_secondary);
            PassedUPDRS = and(scores_secondary >= lower_UPDRS, scores_secondary <= upper_UPDRS);
            
    end
    % predictionlist_fog for the FOG map
    % predictionlist_secondary for the secondary map. (probably UPDRS)
    %example:  
    % scores_a = arrayfun(@(x) x.Output, predictionlist_fog)
    % scores_b = arrayfun(@(x) x.Output, predictionlist_secondary)
    % etc.
    

    
    HeatmapModelSupport.printPredictionList(tag,predictionList,pairs);
    
    
    end
    
    
    function VTA_voxelData = mirror(VTA_voxelData)
    T = load('Tapproved.mat');
    Tvta = T.mni2rightgpi*T.leftgpi2mni;
    VTA_voxelData = VTA_voxelData.imwarp(Tvta);
    end
    end

end
