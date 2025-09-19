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
for iFiberFile = 1:numel(fibers)
    thisFiberFile = fibers{iFiberFile};
    sim{1,iFiberFile} = cell(numel(thisFiberFile.Vertices),1);
    sim{2,iFiberFile} = cell(numel(thisFiberFile.Vertices),1);
end




%For each fiberbundle..
for iFiberFile = 1:numel(fibers)
    thisFiberFile = fibers{iFiberFile};
    
    %..for each Fiberstring in a bundle..
    for iFiberString = 1:numel(thisFiberFile.Vertices)
        disp([num2str(iFiberFile),'/',num2str(numel(fibers)),'  ',num2str(iFiberString),'/many'])

        

        FiberVertices = thisFiberFile.Vertices(iFiberString).Vectors; 

        %..for both recipes..
        for iRecipe = 1:2
            thisRecipe = NoodlesConfig.(['Recipe',num2str(iRecipe)]);
            
            
            %..for each patient in the recipe.. 
            for iPatient = 1:length(thisRecipe)
                impact = [];

                %.. for each E-field per patient
                for side = 1:numel(depth(thisRecipe))
                    Efield = thisRecipe.getVoxelDataAtPosition(iPatient,side);

                    %1. get the impact (sum of E-field values)
                    values = Efield.getValueAt(FiberVertices);
                    impact(side) = nansum(values);
                end

                %2. Add up left+right
                bilateralImpact = nansum(impact);

                %3. multiply it with the clinical weight
                similarity = bilateralImpact * thisRecipe.Weights(iFiberFile);

                %4. Store it (per 

                sim{iRecipe,iFiberFile}{iFiberString}= [sim{iRecipe,iFiberFile}{iFiberString},similarity];
            end
        end
    end
end

%statistics

for iFiberBundle = 1:size(sim,2)
    for iString = 1:numel(sim{1,iFiberBundle})

    
        [h,p,ci,stat] = ttest2(...
            sim{1,iFiberBundle}{iString},...
            sim{1,iFiberBundle}{iString});
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
