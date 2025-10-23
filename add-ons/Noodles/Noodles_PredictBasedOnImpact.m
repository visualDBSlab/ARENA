function [model1,model2] = Noodles_PredictBasedOnImpact (Bundle,procedure)

%the stacks

 load('NoodlesConfig')

 %Load VoxelDataStack

    rcp1 = NoodlesConfig.Recipe1;
    rcp2 = NoodlesConfig.Recipe2;
 
    NoodlesConfig.Recipe1 = VoxelDataStack().loadStudyDataFromRecipe(rcp1);
    NoodlesConfig.Recipe2 = VoxelDataStack().loadStudyDataFromRecipe(rcp2);



[fiberVertices,indcs] = Bundle.serialize();

 % get the magnitude sums along the whole  bundle for each recipe

 X = [size(NoodlesConfig.Recipe1.Voxels,2),2];
 Y = [size(NoodlesConfig.Recipe2.Voxels,2),2];

 impacts{1} = zeros(X);
 impacts{2} = zeros(Y);

    for iRecipe = 1:2

        thisRecipe = NoodlesConfig.(['Recipe',num2str(iRecipe)]);

            for iPatient = 1:size (thisRecipe.Voxels,2)

                for iSide = 1:2

                     Efield = thisRecipe.getVoxelDataAtPosition(iPatient,iSide);
                     values = Efield.getValueAt(fiberVertices);
            
                     impacts{iRecipe}(iPatient,iSide) = sum (values,'all');

                end

            end

    end


if nargin == 1

model1 = fitlm (sum(impacts{1},2),NoodlesConfig.Recipe1.Weights') % take the sum of both sides as a pridictor
model2 = fitlm (sum(impacts{2},2),NoodlesConfig.Recipe2.Weights')



end

if nargin > 1

    if procedure == 'Spearman'

        [rho1,p1] = corr (sum(impacts{1},2),NoodlesConfig.Recipe1.Weights','Type', 'Spearman')
        [rho2,p2] = corr (sum(impacts{2},2),NoodlesConfig.Recipe2.Weights','Type', 'Spearman')

    end

    model1 = [rho1,p1]
    model2 = [rho2,p2]

end


end
