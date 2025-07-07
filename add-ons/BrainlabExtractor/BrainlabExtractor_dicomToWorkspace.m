function BrainlabExtractor_dicomToWorkspace(menu,eventdata,scene)
    dcm = menu.Parent.UserData;
    assignin('base','dcm',dcm)
    disp('Dicom image is now available in workspace as ''dcm''')

end