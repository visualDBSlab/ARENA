%In this example we demonstrate how to load:
% - a .nii image, 
% - electrodes,
% - VTAs.


%% First make an empty scene
scene = newScene();
 
%In order to organize your work the scene can be named. 


%% Loading an image via code
%For obvious reasons no patient scan is provided.
%The following script copies a t1.nii from lead-dbs
borrowT1FromLeadDBS()

% The image can be loaded in two ways:
%via code, or simply by the UI in this example we are going to explore the 
% code.

%--- CODE
%1. make an empty instance of the VoxelData class.
vd = VoxelData(); 

%2. load a nii from a path, or leave it empty to get a file selector ui.
vd.loadnii('t1.nii') 

%3. by default the image is resliced on a orthogonal grid. The header
%information can store various transformations, these are alle applied
%during the reslicing. If reslicing has to be avoided you can do this:
vd_no_reslice = VoxelData().loadnii('t1.nii',true);

%4. Most data objects can be visualised with '.see()'. However VoxelData
%can be visualised as a slice or as a mesh. A anatomical scan is preferably
%shown as a slice. 
slice = vd.getslice();
actor = slice.see(scene);

%5. Since we have a reference to actor (the 3D representation of our data)
%we can use that to modify it. For starters, let's change the name:
actor.changeName('t1 in MNI space')

%Summary:
%The power of ARENA is that all these functions can be written in one line:
VoxelData().loadnii('t1.nii').getslice().see(scene).changeName('t1 in MNI SPACE')



%% Make en electrode with code.
% Electrodes are a central object for DBS analysis. There are several
% pipelines where electrodes are detected or created for patient data. In
% this example we show how to create an electrode instance.

%1. Create an empty instance
e = Electrode();

%2. let's say we know where the lowest contact is in MNI space. We can
%write that as a 3 number array. Or we can convert it to a Vector3D which
%is the ARENA way of of describing a point in 3D space.
c0 = [-19.12,-8.46,-4.65]; 
c0_v3d = Vector3D(c0)

%either of those can be used the set the C0 property.
e.C0 = c0;

%3. let's visualise it now in Arena. You will notice it will point straight
%up along the z-axis. This is the default position of an electrode.
e.see(scene)

%4. in order to set the angle we need either another point on the lead, or
%we need to set the direction if we already know it. Let's say we know the
%electrode also crosses the coordinate: [-20.28, -0.79, 8.18].

POL = [-20.28, -0.79, 8.18];
e.PointOnLead(POL)


%or if we want to set the normalized direction directly:

POL_v3d = Vector3D(POL);
difference = POL_v3d - c0_v3d;
disp(['distance between the two points: ',num2str(difference.norm),' mm.'])
e.Direction = difference.unit();

%5. since we know the electrode coordinates are in MNI space, it is good
%practice to provide this information.

e.Space = Space.MNI2009b;
e.see(scene)

%.6 If you want to get the locations of all the contacts you can do the
%following:
contacts = e.getLocationOfContacts();

%7. These contacts can be shown as dots in the scene. For this you use the
%PointCloud class:
pc = PointCloud(contacts);


%8. imagine these contacts have different scores associated to them. Then
%these can be addded as 'weights'.
pc.Weights = [5,3,1,4]; %C0, C1, C2, C3

%8. You can show this again using .see()
actor = pc.see(scene);

%9. the colors can be set so that a low weight is green. 
actor.changeSetting('colorLow',[0,1,0],'colorHigh',[1,0,0])


%% Show a VTA
%VTAs are volumes within the electrical signal of the electrode is assumed
%to have some impact on the neurons. In this example we load a VTA and
%explore some of the options.

%1. load the data
load('example1.mat');
vtaleft = data.VTAs.left;

%2. we can immediately visualise this:
vtaleft.see(scene);

%3. let's get some details
vtaleft.getCubicMM()
vtaleft.getCOG()

%4. previously we created a pointcloud with the contact centers. Let's see
%which contact center is inside or covered by the VTA:
vtaleft.isinside(pc)

























