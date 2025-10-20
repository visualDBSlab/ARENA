function [outputArg1,outputArg2] = Noodles_runbasic(menu,eventdata,scene)
%NOODLES_RUNBASIC() Summary of this function goes here
%   Detailed explanation goes here


    fibers = {};

    
    load('NoodlesConfig')
    %Load Fibers
    for iFiber = 1:numel(NoodlesConfig.fibers)
        f = Fibers();
        
        [~,~, ext] = fileparts(NoodlesConfig.fibers{iFiber});
        switch ext
            case '.vtk'
                fname = fullfile(NoodlesConfig.fibersfolder,NoodlesConfig.fibers{iFiber});
                f.loadvtk(fname)
            case '.mat'
                fname = fullfile(NoodlesConfig.fibersfolder,NoodlesConfig.fibers{iFiber});
                f.loadleadDBSfibers(fname)
            otherwise
                error('Fiber file extension not yet supported.')
        end
        fibers{iFiber}=f;
    end

    %Load VoxelDataStack
    rcp1 = NoodlesConfig.Recipe1;
    rcp2 = NoodlesConfig.Recipe2;
 
    NoodlesConfig.Recipe1 = VoxelDataStack().loadStudyDataFromRecipe(rcp1);
    NoodlesConfig.Recipe2 = VoxelDataStack().loadStudyDataFromRecipe(rcp2);

    

%initialize data tree (each fiberbundle might have different N)
sim = cell(2,numel(fibers)); %recipe - bundle - string




% %..for each Fiberstring in a bundle..
%     for iFiberString = 1:numel(thisFiberFile.Vertices)
%         disp([num2str(iFiberFile),'/',num2str(numel(fibers)),'  ',num2str(iFiberString),'/many'])
% 
% 
% 
%         FiberVertices = thisFiberFile.Vertices(iFiberString).Vectors; 






for iRecipe = 1:2
    thisRecipe = NoodlesConfig.(['Recipe',num2str(iRecipe)]);

    nPatients = length(thisRecipe);
    for iPatient = 1:nPatients


        for side = 1:numel(depth(thisRecipe))
            %This takes some time
            Efield = thisRecipe.getVoxelDataAtPosition(iPatient,side);
            
           

            for iFiberFile = 1:numel(fibers)
                disp(['recipe: ',num2str(iRecipe),' - patient: ',num2str(iPatient),' - fibers: ', num2str(iFiberFile)])

                thisFiberFile = fibers{iFiberFile};


                %initialize array
                if isempty(sim{iRecipe,iFiberFile})
                    nFibersInBundle = numel(thisFiberFile.Vertices);
                    sim{iRecipe,iFiberFile} = nan([nPatients,nFibersInBundle]);
                end

                
                %0. serialize
                [fiberVertices,indcs] = thisFiberFile.serialize();

                %1. get values
                values = Efield.getValueAt(fiberVertices);

                %2. unserialize
                valuesPerFiber = thisFiberFile.deserializeValues(values,indcs);

                %3. get impact
                sim{iRecipe,iFiberFile}(iPatient,:) = cellfun(@nansum, valuesPerFiber) * thisRecipe.Weights(iPatient);
            end
        end
    end
end

   

%statistics

for iFiberBundle = 1:size(sim,2)
    for iString = 1:size(sim{1,iFiberBundle},2)

    
        [h,p,ci,stat] = ttest2(...
            sim{1,iFiberBundle}(:,iString),...
            sim{2,iFiberBundle}(:,iString));
        t = stat.tstat;
        
        fibers{iFiberBundle}.Weight(iString) = t;
    end
    fibers{iFiberBundle}.see(scene)

end

end



function out = remaining(all,i)
    out = 1:all;
    out(out==i) = [];
end
