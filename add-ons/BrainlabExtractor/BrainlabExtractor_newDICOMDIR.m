function [outputArg1,outputArg2] = BrainlabExtractor_newDICOMDIR(menu,eventdata,scene)

ddpath = uigetdir('');
dd = Dicomdir(ddpath);
if isempty(menu.Parent.UserData)
    menu.Parent.UserData = Dicomdir.empty();
end
menu.Parent.UserData(end+1) = dd;

end