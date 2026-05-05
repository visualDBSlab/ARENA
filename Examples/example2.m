%In this example we demonstrate how to process 3D data, specifically:
% - Pointclouds


%% first make an empty scene
scene = newScene();

%% and let's load the data
load('example2.mat')

%% visualize Cohort1 to see what we have.
data.Cohort1.see(scene)

%this shows the 3D points of the pointloud in a scene. Because each point
%had a weight, the colors vary between colorLow and colorHigh. By default
%the first layer will have blue and red. 

%it would be nice to see where this (fictional!) data is located with an
%atlas.

%% Show the GPi atlas
% press: Atlas > From lead-dbs  and choose the distal atlas. (Depending on
% your lead-dbs version, one or many atlases are shown here).
% - select GPi.nii.gz and GPe.nii.gz for this exxample.
% - press 'h' on the keyboard to hide or unhide layers.
% - Only layers of the same type can be selected at the same time.

%% Add cohort 2
% before we add another cohort, let's change the name:
% - select the layer, hit [enter], and set the layer name: 'Cohort 1'

cohort2 = data.Cohort2.see(scene);
cohort2.changeName('cohort 2')

%% change color:
% we do not care about the weights in this example. you can do that via
% code:
cohort2.changeSetting('colorLow',[1 0 0])
cohort2.changeSetting('colorHigh',[1 0 0])

%because the first cohort was the first actor in the scene:
cohort1 = scene.Actors(1);
cohort1.changeSetting('colorLow',[1 0 0])
cohort1.changeSetting('colorHigh',[1 0 0])

%% change backrgoundcolor:
% shortcut 'b' or go to view > background color

%% Let's see which pointcloud is where.
% - select a pointcloud to enable the pointcloud menu.
% - Select  --> Pointcloud >  Analyse > Pointcloud: is point inside mesh?
% - select BOTH pointclouds
% - select GPi left and GPi left.
% - choose side-by-side or stacked.

%% Inspect the distributions in 3D
% select 'cohort 1' and go to --> Pointcloud > Analyse > Show Distribution
% repeat the same for cohort 2.
% Hide cohort 1 and cohort 2 for calarity. (shortcut 'h')

%% Set the GPi as a camera origin
% - select GPi.nii.gz left
% - then press '.' This will center the object.

%% Move the camera to orthogonal positions to examine differences.
% Shift+1, Shift+2 and shift+3 will move the camera to the closest
% orthogonal point.  (If the camera is already looking down a little, it
% will move to a top view. If the camera is looking up, it will move to a
% bottom view)

% Alternatively choose View > Camera > Orthogonal

%% Let's Quantify the differences.
% Select both Pointclouds
% --> Pointcloud > Analyse > Pointcloud: two sample t-test

%This will show all axes with  significant differences.
%X, Y and Z are in MNI space.
% PCA1 and PCA2 are along the dominant and subdominant axes of all data.
% proj 1 is the direction between the centers of the cohorts.










