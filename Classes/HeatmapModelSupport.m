
classdef HeatmapModelSupport < handle
    %HEATMAP Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = HeatmapModelSupport()
            %HEATMAP Construct an instance of this class
            %   Detailed explanation goes here
            
        end
        
    end
    
    methods (Static)
        function fileID = printPredictionList(Tag,predictionList,pairs,blackOrRed,order)
            
            if nargin<4
                order = 'descend';
            end
                
                fileID = HeatmapModelSupport.makeFile(Tag,'RankedScores.txt');
                
                HeatmapModelSupport.loopPrint(fileID,predictionList,pairs,order)
               
        end
        
        
        function printtext(fid,varargin)
                fprintf(fid,varargin{:});
                fprintf(varargin{:});
            end
        function fileID = makeFile(Tag,name)
            %make export directory
            p = mfilename('fullpath');
            arenaDir= fileparts(fileparts(p));
            currentDir = fullfile(arenaDir,'UserData','Monpolar Review',Tag);
            [~,msg] = mkdir(currentDir);
            counter = 1;
            while strcmp(msg,'Directory already exists.')
                currentDir = fullfile(arenaDir,'UserData','Monpolar Review',[Tag,' (',num2str(counter),')']);
                [~,msg] = mkdir(currentDir);
                counter = counter+1;
            end
            
            %open file
            fileID = fopen(fullfile(currentDir,name),'w');
        end
        function printReco(fileID,predictionList,pairs)
            
          
                
             
                if ischar(predictionList)
                    
                     HeatmapModelSupport.printtext(fileID,'\n')
                     HeatmapModelSupport.printtext(fileID,'No settings found')
                     
                else
                    
                    HeatmapModelSupport.loopPrint(fileID,predictionList,pairs)
                    
                end
          
            
         
                
          
            
            
           

        end
        
        function loopPrint(fileID,predictionList,pairs,printOrder)

                if nargin==3
                    printOrder = 'descend';
                end
              [sorted,order] = sort(vertcat(predictionList.Output),printOrder);
                        
        %----two leads
            if length(pairs)~=numel(pairs)
                
                leadname1 = findLeadDescription(predictionList(1).Input.VTAs(1));
                leadname2 = findLeadDescription(predictionList(1).Input.VTAs(2));
                
                HeatmapModelSupport.printtext(fileID,'\t\t\t%s\t%s\n',leadname1,leadname2);
                HeatmapModelSupport.printtext(fileID,'-------------------------------------------\n')
                for iShortlist = 1:length(order)
                    item = order(iShortlist);
                    Improv = predictionList(item).Output;
                    c_e1 = predictionList(item).Input.VTAs(1).Settings.activecontact;
                    c_e2 = predictionList(item).Input.VTAs(2).Settings.activecontact;
                    a_e1 = predictionList(item).Input.VTAs(1).Settings.amplitude;
                    a_e2 = predictionList(item).Input.VTAs(2).Settings.amplitude;
                    conf_e1 = predictionList(item).Confidence(1);
                    conf_e2 = predictionList(item).Confidence(2);
                   
                    HeatmapModelSupport.printtext(fileID,'%i.\t %2.2f \t C%i - %2.1f mA\t C%i - %2.1f mA \t (%2.2f / %2.2f) \n',iShortlist,Improv, c_e1,a_e1,c_e2,a_e2,conf_e1,conf_e2);

                end
            else
                
    %----one lead
                for iShortlist = 1:length(order)
                    %                 thisPair = ReviewData.pairs(order(iShortlist),:);
                    item = order(iShortlist);
                    Improv = predictionList(item).Output;
                    c_e1 = predictionList(item).Input.VTAs(1).Settings.activecontact;
                    a_e1 = predictionList(item).Input.VTAs(1).Settings.amplitude;
                    conf_e1 = predictionList(item).Confidence(1);
                    
                    HeatmapModelSupport.printtext(fileID,'%i.\t %2.1f \t C%i - %2.1f mA\t (%2.2f) \n',iShortlist,Improv, c_e1,a_e1,conf_e1);


                end
            end
            
            function leadname = findLeadDescription(VTA)
                if not(isempty(VTA.ActorElectrode))
                    leadname = VTA.ActorElectrode.Tag;
                    return
                end
                
                try
                    filename = VTA.Electrode.VTA(1).Source;
                    [folder,filename,extension] = fileparts(filename);
                    leadname = filename;
                    return
                catch
                    leadname = '[leadname]';
                    %try smth else
                end
            end

        end
        
        function printList(therapy,pairs)
            
            fileID = HeatmapModelSupport.printPredictionList(therapy.Tag,therapy.ReviewData.predictionList,pairs);
                    
                    HeatmapModelSupport.printtext(fileID,'\n')
                    HeatmapModelSupport.printtext(fileID,'Therapy Recommendations - First choice and alternative:')
                    HeatmapModelSupport.printtext(fileID,'\n')
                    
                    HeatmapModelSupport.printReco(fileID,therapy.RecommendedSettings,pairs)
                    HeatmapModelSupport.printReco(fileID,therapy.AlternativeSettings,pairs)
                    
                    fclose(fileID);
                    
         end

        
            
end
        

end
        
        
        
    


