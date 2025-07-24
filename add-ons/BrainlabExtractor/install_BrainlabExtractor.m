function install_BrainlabExtractor(menuhandle,eventdata,scene)

scene.addon_addmenuitem('BrainlabExtractor','Master: [none]',str2func('@BrainlabExtractor_AssignMaster'))
scene.addon_addmenuitem('BrainlabExtractor','Burned-in: [none]',str2func('@BrainlabExtractor_AssignBI'))
scene.addon_addmenuitem('BrainlabExtractor','Other: [none]',str2func('@BrainlabExtractor_AssignOther'))
scene.addon_addmenuitem('BrainlabExtractor','Electrodes by coordinates: [none]',str2func('@BrainlabExtractor_DefineElectrodes'))
scene.addon_addmenuitem('BrainlabExtractor','post-op CT: [none]',str2func('@BrainlabExtractor_CT'))
scene.addon_addmenuitem('BrainlabExtractor','run batch call',str2func('@Batch_Brainlab'))
%------
sephere = scene.addon_addmenuitem('BrainlabExtractor','Segment only',str2func('@BrainlabExtractor_SegmentOnly'));
scene.addon_addmenuitem('BrainlabExtractor','Segment and normalize (SPM)',str2func('@BrainlabExtractor_SegmentNormalize'))
scene.addon_addmenuitem('BrainlabExtractor','normalize (SPM)',str2func('@BrainlabExtractor_normalize'))
scene.addon_addmenuitem('BrainlabExtractor','Import previously processed files',str2func('@BrainlabExtractor_see'))
scene.addon_addmenuitem('BrainlabExtractor','Import elecrtrodes from Excel (no normalization)',str2func('@BrainlabExtractor_LeadsFromExcel'))
%-----
sephere2 = scene.addon_addmenuitem('BrainlabExtractor','Normative to native', str2func('@BrainlabExtractor_updateNativeMenu'));
scene.addon_addmenuitem('BrainlabExtractor','+ new native link',str2func('@BrainlabExtractor_newNative'),sephere2)
dcmdirmenu = scene.addon_addmenuitem('BrainlabExtractor','DICOMDIR', str2func('@BrainlabExtractor_updateDICOMDIRMenu'));
scene.addon_addmenuitem('BrainlabExtractor','+ new DICOMDIR',str2func('@BrainlabExtractor_newDICOMDIR'),dcmdirmenu)
%---
sephere3 = scene.addon_addmenuitem('BrainlabExtractor','Preprocessing');
scene.addon_addmenuitem('BrainlabExtractor','Reconnect nii to header',str2func('@BrainlabExtractor_reconnectToHeader'),sephere3)
scene.addon_addmenuitem('BrainlabExtractor','Cut out a box around the electrodes',str2func('@BrainlabExtractor_saveBoxAroundElectrodes'))



%add separator
m = handle(sephere);
m.Separator = 'on';

m = handle(sephere2);
m.Separator = 'on';


%change menu title
menuhandle.Text = menuhandle.Text(6:end);

%init userdata
menuhandle.UserData.master = [];
menuhandle.UserData.BIfilename = [];
menuhandle.UserData.BIfoldername = [];
menuhandle.UserData.CTfilename = [];
menuhandle.UserData.CTfoldername = [];
menuhandle.UserData.electrodes = nan;
menuhandle.UserData.nativepair.main = sephere2;
menuhandle.UserData.nativepair.link = [];

%hack SPM so that it exports the inverse warp
BrainlabExtractor_hackSPM()


disp('Docking complete')



end