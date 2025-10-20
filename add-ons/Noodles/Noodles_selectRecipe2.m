function [outputArg1,outputArg2] = Noodles_selectRecipe2(menu,eventdata,scene)

load('NoodlesConfig.mat')


[file,path] = uigetfile('*.xlsx','Locate the recipe');

if file
    NoodlesConfig.Recipe2 = fullfile(path,file);
    set(NoodlesConfig.handles.recipe2,'Text',['Recipe: loaded (',file,')'],'Checked','on')
end


%save selection
save(fullfile(NoodlesConfig.dir,'NoodlesConfig.mat'),'NoodlesConfig')

Noodles_checkifready('Recipe',scene)



end

