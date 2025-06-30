function [outputArg1,outputArg2] = BrainlabExtractor_seeDicom(menu,eventdata,scene)
%BRAINLABEXTRACTOR_SEEDICOM Summary of this function goes here
%   Detailed explanation goes here

actor = menu.Parent.UserData.see(scene);

set(menu,'UserData',actor)





end

