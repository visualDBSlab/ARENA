function [outputArg1,outputArg2] = Noodles_selectRecipe1(menu,eventdata,scene)

load('NoodlesConfig.mat')

Stack=VoxelDataStack;
Stack.construct();
nPatients = numel(Stack.Weights);


if nPatients
    NoodlesConfig.Recipe1 = Stack;
    set(NoodlesConfig.handles.recipe1,'Text',['Recipe: loaded (',num2str(nPatients),')'],'Checked','on')
end


%save selection
save(fullfile(NoodlesConfig.dir,'NoodlesConfig.mat'),'NoodlesConfig')

Noodles_checkifready('Recipe',scene)



end

