# ARENA User Manual

Welcome to the official documentation for ARENA (Advanced Research Environment for Neurological Analysis), a MATLAB-based platform for performing interactive 3D analysis of deep brain stimulation (DBS) data. ARENA offers a powerful 3D viewport user interface, advanced interaction tools, and modular support for data workflows through plug-in add-ons. This page will walk you through the installation, usage, and core components of the system. 

## Features
* MATLAB-based 3D viewport
* Support for multiple actor layers (volumes, point clouds, electrodes, fibers, etc.)
* Interactive visualization configuration tools
* Built-in and add-on analysis workflows
* Flexible data import/export pipelines

## Getting Started
ARENA is designed for researchers working with deep brain stimulation data, particularly those who need to visualize and analyze spatial 3D information, predict outcomes, or process data from commercial neuroimaging tools.

### Installation

**Prerequisites**
* MATLAB (R2019b until R2025a)
  * Image Processing toolbox
  * Statistics toolbox
* Git (for cloning the repository)
* [lead-dbs.org](https://www.lead-dbs.org/)
* [SuretuneSDK](https://github.com/JonasRoothans/SuretuneSDK)

> [!Note]
> Functionality from SuretuneSDK and lead-dbs is used in several functions. For a smooth run, it is strongly recommended to download both toolboxes.


**Step-by-step Installation**
1. Clone the ARENA repository
2. Download and install dependencies
   * Download and install Lead-DBS by following instructions at [lead-dbs.org](https://www.lead-dbs.org/)
   * Clone or download [SuretuneSDK](https://github.com/JonasRoothans/SuretuneSDK) into a known directory.
3. Navigate to ARENA path inside MATLAB.
   > Use the "Current Folder" window in MATLAB to find the ARENA folder on your computer.
4. Run the setup
   >`startArena`
   >During this step, you will be prompted to locate the directories of Lead-DBS and SuresuiteSDK. These locations will be stored and not    asked again. (Delete config.mat to trigger the set-up procedure again) 
5. Launch ARENA
   > `startArena` or to directly open a 3D viewport `newScene`.


# User Interface Overview

Once launched, ARENA displays the 3D viewport, where different actors (data layers) can be added, manipulated, and analyzed. Each actor type supports dynamic visual options such as transparency and color.

## Actor Types
ARENA visualizes data through actors—modular components that represent a specific object in 3D space. Actor types are highly flexible and support interaction, transformation, and analysis.

Actors are generally divided into two categories:
* Basic Actors: Represent low-level geometric or imaging data
* Composit Actors: Aggregate multiple components for higher-level interpretation

### Basic Actors:
* VoxelData: 3D volumetric dataset
* VoxelDataStack: a set of VoxelData objects and their weights.
* Fibers: Tractography streamlines
* Electrode: DBS electrodes with contacts
* PointCloud, VectorCloud: Geometric data visualization
* Mesh: 3D shape often based on volumetric data
* ObjFile: 3D shape based on an imported .obj file
* DICOM: Holds original raw files and related ARENA compatible representations of the data.
* Scene: 3D viewport

All these actors can be individually manipulated, visualized, and used in spatial analysis.

### Composite Actor Types

ARENA also supports composite actors that integrate multiple data types into a unified structure. These are particularly valuable for advanced research workflows.

_VTA (Volume of Tissue Activated)_
> TheVTA class models the region of brain tissue affected by a DBS setup. As it is often the core of a research question The VTA class will hold references to all relevant aspects related to the VTA for contextual metadata.

_Heatmap_
> TheVTA class models the region of brain tissue affected by a DBS setup. As it is often the core of a research question The VTA class will hold references to all relevant aspects related to the VTA for contextual metadata.

_LOORoutine_
> This composites the input data (VoxelDataStack) and analysis method (BiteAnalysis) and is able to perform leave-one-out analysis with the specified method on the provided data.

_Prediction_
> PredictionModels are final products of studies. The prediction class allows to load these models and a VTA, and predict the outcome for the VTA.

_BiteAnalysis_
> There are various ways how a VTA can interact with a heatmap to produce a prediction. The BiteAnalysis class provides the framework for a modular design of the tools.


## Keyboard shortcuts
* `.`: center the camera on the active layer
* `arrow keys`: move the camera or zoom
* `b`: invert background colo
* `o`: center the origin
* `cmd+i` / `ctrl+i`: import actor
* `return`: change layer name
* `shift+1`: axial view
* `shift+2`: sagittal view
* `shift+3`: coronal view
* `h`: hide or show the layer
* `s`: allow selecting layer in the 3D viewport.

# Demo 

Do you want to get started right away? Good idea! Demo data for two example use cases is provided.

_Let's go_
 > Browse to the ARENA > Examples folder to find data and scripts.

_Find example 1_
> type `edit example1` to find the first script. It is not recommended to run the entire script at once. Use it to copy lines of code to the command window or use it in your own script. The examples simply provide ideas.





