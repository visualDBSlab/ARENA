function  [output1, output2] = Noodles_PredictOutcomes (menu,eventdata,scene)
% this will predict outcomes based on estimated activation of selected
% fiber bundles (sums of Efield magnitudes along the bundles)


% get selected fibres and merge them
Actors = ArenaScene.getSelectedActors(scene);

Bundle = Fibers();

for iActor = 1:numel(Actors)

    if ~isa(Actors(iActor).Data,'Fibers')

        error ('Please select only fiberbundles')

    end

    Bundle = Bundle.merge (Actors(iActor).Data);

end



 load('NoodlesConfig')

 %Load VoxelDataStack

    rcp1 = NoodlesConfig.Recipe1;
    rcp2 = NoodlesConfig.Recipe2;

    if isa(rcp2,'char') %make it possible also for a single recipe

        numberOfRecipes = 2;

    else

        numberOfRecipes = 1;

    end
 
    NoodlesConfig.Recipe1 = VoxelDataStack().loadStudyDataFromRecipe(rcp1);

    if numberOfRecipes == 2

    NoodlesConfig.Recipe2 = VoxelDataStack().loadStudyDataFromRecipe(rcp2);

    end



[fiberVertices] = Bundle.serialize();

 % get the magnitude sums along the whole  bundle for each recipe

 X = [size(NoodlesConfig.Recipe1.Voxels,2),2];
 impacts{1} = zeros(X);

 if numberOfRecipes == 2

 Y = [size(NoodlesConfig.Recipe2.Voxels,2),2];
 impacts{2} = zeros(Y);

 end



    for iRecipe = 1:numberOfRecipes

        thisRecipe = NoodlesConfig.(['Recipe',num2str(iRecipe)]);

            for iPatient = 1:size (thisRecipe.Voxels,2)

                for iSide = 1:2

                     Efield = thisRecipe.getVoxelDataAtPosition(iPatient,iSide);
                     values = Efield.getValueAt(fiberVertices);
            
                     impacts{iRecipe}(iPatient,iSide) = sum (values,'all');

                end

            end

    end


fprintf('\n\n\n\n\n\n\n\n\n\n') % create some space

disp ('Recipe 1')   
disp ('Fitting a simple univariate linear model')

model1 = fitlm (sum(impacts{1},2),NoodlesConfig.Recipe1.Weights') %simple model
f1 = figure('Name', 'Recipe 1 linear model');
figure(f1)
model1.plot

fprintf('\n\n\n\n\n\n')


disp ('Spearman´s rank correlation')

[rho1,p1] = corr (sum(impacts{1},2),NoodlesConfig.Recipe1.Weights','Type', 'Spearman') %Spearman

fprintf('\n\n\n\n\n\n')

disp ('Fitting a linear model with logarithimic input') %Log
LogModel1 = fitlm (log(sum(impacts{1},2)),NoodlesConfig.Recipe1.Weights') 
f2 = figure('Name', 'Recipe 1 log input');
figure(f2)
LogModel1.plot




if numberOfRecipes == 2

fprintf('\n\n\n\n\n\n\n\n\n\n')    

disp ('Recipe 2')
disp ('Fitting a simple univariate linear model')

model2 = fitlm (sum(impacts{2},2),NoodlesConfig.Recipe2.Weights')
f3 = figure('Name', 'Recipe 2 linear model');
figure(f3)
model2.plot

fprintf('\n\n\n\n\n\n')

disp ('Spearman´s rank correlation')

[rho2,p2] = corr (sum(impacts{2},2),NoodlesConfig.Recipe2.Weights','Type', 'Spearman')

fprintf('\n\n\n\n\n\n')

disp ('Fitting a linear model with logarithimic input')

LogModel2 = fitlm (log(sum(impacts{2},2)),NoodlesConfig.Recipe2.Weights')

f4 = figure('Name', 'Recipe 2 log input');

figure (f4)
LogModel2.plot

end

fprintf('\n\n\n\n\n\n')

input('Type OK and press Enter when you are ready to continue: ', 's');



options = {'model1'...
    'model2' ... 
    'LogModel1'...
    'LogModel2'...
    'Don´t bother'};

[selection, ok] = listdlg('PromptString', 'Do you wish to save any of those models? :', ...
                          'SelectionMode', 'multiple', ...
                          'ListString', options, ...
                          'Name', 'Select models', ...
                          'ListSize', [300 120]);


Models = {};

        if ok

            chosen = options(selection);

            if ismember ('model1', chosen)

                Models{end+1}= model1;

            end

            if ismember ('model2', chosen)

                Models{end+1}= model2;

            end

            if ismember ('LogModel1', chosen)

                Models{end+1}= LogModel1;

            end

            if ismember ('LoModel2', chosen)

                Models{end+1}= LogModel2;

            end

        end

assignin ('base','Models', Models)




    end

   

