function [outputArg1,outputArg2] = BrainlabExtractor_overwriteDICOM(menu,eventdata,scene)
%BRAINLABEXTRACTOR_OVERWRITEDICOM Summary of this function goes here
%   Detailed explanation goes here

actor = ArenaScene.getSelectedActors(scene);
dicom = menu.Parent.UserData;
switch class(actor.Data)
    case 'Slicei'
        vd = actor.Data.parent;
        dicom.overwriteWith(vd)
    case 'Mesh'
        vd = actor.Data.Source;
        if actor.Data.Settings.T > 0
            vd.Voxels = vd.Voxels>actor.Data.Settings.T;
        else
            vd.Voxels = vd.Voxels<actor.Data.Settings.T;
        end
            
        dicom.overwriteWith(vd);

end
end

