function BrainlabExtractor_updateDICOMDIRMenu(menu,eventdata,scene)

% 
children = menu.Children;

%remove all children
for iChild = 1:numel(children)
    thisChild = children(iChild);
    if strcmp(thisChild.Text,'+ new DICOMDIR')
        continue
    end
    delete(thisChild)
end

%add all new children
for iDD = 1:numel(menu.UserData)
    for D = menu.UserData(iDD).Dicoms
        parent = scene.addon_addmenuitem('BrainlabExtractor',[D.Tag,' // ',D.Description], str2func('@BrainlabExtractor_dummyCallback'),menu);
        scene.addon_addmenuitem('BrainlabExtractor','see',str2func('@BrainlabExtractor_seeDicom'),parent)
        scene.addon_addmenuitem('BrainlabExtractor','overwrite voxelvalues with selected actor',str2func('@BrainlabExtractor_overwriteDICOM'),parent)
        scene.addon_addmenuitem('BrainlabExtractor','save',str2func('@BrainlabExtractor_saveDicom'),parent)
        scene.addon_addmenuitem('BrainlabExtractor','export to workspace',str2func('@BrainlabExtractor_dicomToWorkspace'),parent)
        
        set(parent,'UserData',D);
    end
end



end

