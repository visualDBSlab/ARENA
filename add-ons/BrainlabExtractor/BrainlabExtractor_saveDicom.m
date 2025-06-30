function [outputArg1,outputArg2] = BrainlabExtractor_saveDicom(menu,eventdata,scene)
%BRAINLABEXTRACTOR_SEEDICOM Summary of this function goes here
%   Detailed explanation goes here

if not(isempty(menu.UserData))
    switch class(menu.UserData)
        case 'ArenaActor'
            %---
            
            menu.UserData.export()
    end
else
    menu.Parent.UserData.export()





end

