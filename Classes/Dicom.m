classdef Dicom < handle
    %DICOM Summary of this class goes here
    %   Detailed explanation goes here

    properties
        raw_Info
        raw_Files = {}
        raw_InstanceNumbers = []
        raw_class = '';
        T
        TtoRAS
        Tag
        Type
        Description
        VoxelData
        VoxelData_foreground
        VoxelData_background
        RAS_VoxelData
        RAS_VoxelData_foreground
        RAS_VoxelData_background
        Segmentation =0
        Dicomdir
        InstanceNumbers
        Parent

    end

    methods
        function obj = Dicom(input)
            switch class(input)
                case 'Dicomdir'
                    obj.Dicomdir = input;
                    obj.Tag = input.Tag;
            end

        end

        function recordSequence(obj,rec)
            switch rec.DirectoryRecordType
                case 'SERIES'
                    if isempty(obj.Description)
                        obj.Description = rec.SeriesDescription;
                    end
                case 'IMAGE'
                    referencedFile = strrep(rec.ReferencedFileID,'\',filesep);
                    fullFilePath = fullfile(fileparts(obj.Dicomdir.Info.Filename), referencedFile);
                    obj.raw_Files{end+1} = fullFilePath;
                    obj.raw_InstanceNumbers(end+1) = rec.InstanceNumber;
                    if isempty(obj.raw_Info)
                        obj.raw_Info = dicominfo(obj.raw_Files{end});
                        try
                            obj.Type = obj.raw_Info.DerivationDescription;
                        catch
                            obj.Type = '';
                        end
                        try
                            %This needs to be figured out properly.
                            %Sometimes the Z is Y*X, sometimes the Z is
                            %X*Y.

                            if  contains(obj.raw_Info.RequestedProcedureDescription,'CT')
                                %RAS:
                                obj.T = inv(...
                                [obj.raw_Info.ImageOrientationPatient(1:3),...
                                obj.raw_Info.ImageOrientationPatient(4:6),...
                                cross(obj.raw_Info.ImageOrientationPatient(1:3),...
                                obj.raw_Info.ImageOrientationPatient(4:6))]);
                            else

                            obj.T = inv(...
                                [obj.raw_Info.ImageOrientationPatient(1:3),...
                                obj.raw_Info.ImageOrientationPatient(4:6),...
                                cross(obj.raw_Info.ImageOrientationPatient(4:6),...
                                obj.raw_Info.ImageOrientationPatient(1:3))]);
                            end
                            obj.T(4,4)=1;
                        catch
                            obj.T = nan;
                        end
                    end


            end

        end

        function convertRawToVoxelData(obj)
            if length(obj.raw_Files)>1

                numImages = numel(obj.raw_Files);
                sampleImage = dicomread(obj.raw_Files{1});
                obj.raw_class = class(sampleImage);

                [rows, cols,rgb] = size(sampleImage);

                %make sure instances start at 1
                obj.InstanceNumbers = obj.raw_InstanceNumbers - min(obj.raw_InstanceNumbers)+1;

                %initiate volume
                imageVolume = zeros(rows, cols, rgb,max(obj.InstanceNumbers));

                for i = 1:numImages
                    try
                        imageVolume(:, :,:, obj.InstanceNumbers(i)) = double(dicomread(obj.raw_Files{i}));
                    catch
                        warning(['File has different dimensions: ',obj.Description,' (image index = ',num2str(i),')'])
                    end
                end

                %if it is a grayscale image
                if rgb==1
                    obj.VoxelData = VoxelData(squeeze(imageVolume));
                    obj.VoxelData.Tag = obj.Description;

                    %if there is rgb information run segmentation automatically
                elseif rgb ==3
                    r = VoxelData(squeeze(imageVolume(:,:,1,:)));
                    g = VoxelData(squeeze(imageVolume(:,:,2,:)));
                    b = VoxelData(squeeze(imageVolume(:,:,3,:)));

                    [foreground,background] = detectForeground({r,g,b});

                    segmentation = foreground-background;
                    segmentation.makeBinary(0.5)
                    segmentation.imclose(5);

                    segmentation.Tag = ['diff_',obj.Description];
                    background.Tag = ['bg_',obj.Description];
                    foreground.Tag = ['fg_',obj.Description];

                    obj.VoxelData = segmentation;
                    obj.VoxelData_background = background;
                    obj.VoxelData_foreground = foreground;

                    % in order to flag that the prime VoxelData has been
                    % processed:
                    obj.Segmentation = true;

                end
            end

            function [fg,bg] = detectForeground(volumes)
                totalvalues = cellfun(@total,volumes);
                [~,bg_index] = min(totalvalues);
                [~,fg_index] = max(totalvalues);
                fg = volumes{fg_index};
                bg = volumes{bg_index};
                %Not longer hard coded because brainlab is inconsistent
                %fg = volumes{2};
                %bg = volumes{1};

            end




        end

        function warpToRAS(obj)
            [~,Tvoxelsize] = obj.getVoxelSize();

            obj.TtoRAS = obj.T * diag([-1 -1 1 1]*Tvoxelsize);

                if not(isempty(obj.VoxelData))
                    obj.RAS_VoxelData = obj.VoxelData.imwarp(obj.TtoRAS);
                end
                if not(isempty(obj.VoxelData_foreground))
                    obj.RAS_VoxelData_foreground = obj.VoxelData_foreground.imwarp(obj.TtoRAS);
                end
                if not(isempty(obj.VoxelData_background))
                    obj.RAS_VoxelData_background = obj.VoxelData_background.imwarp(obj.TtoRAS);
                end
        end

        function warpToNative(obj)
            

                if not(isempty(obj.RAS_VoxelData))
                    obj.VoxelData = obj.RAS_VoxelData.imwarp(inv(obj.TtoRAS));
                end
                if not(isempty(obj.RAS_VoxelData_foreground))
                    obj.VoxelData_foreground = obj.RAS_VoxelData_foreground.imwarp(inv(obj.TtoRAS));
                end
                if not(isempty(obj.RAS_VoxelData_background))
                    obj.VoxelData_background = obj.RAS_VoxelData_background.imwarp(inv(obj.TtoRAS));
                end
                
        end

        function overwriteWith(obj,vd)
            obj.RAS_VoxelData = vd.warpto(obj.RAS_VoxelData);
           
        end

        function [voxelsize,Tvoxelsize] = getVoxelSize(obj)
            if not(isempty(obj.Parent))
                info = obj.Dicomdir.Dicoms(obj.Parent).raw_Info;
            else
                info = obj.raw_Info;
            end

            x = info.PixelSpacing(1);
            y = info.PixelSpacing(2);
            z = info.SliceThickness;
            
            voxelsize = [x,y,z]; %ASSUMING X, Y And Z are correct..
            Tvoxelsize = diag([voxelsize,1]);
            
        end


        function export(obj)
            [~,patient_name] = fileparts(fileparts(obj.Dicomdir.path));
            outputdir = obj.Dicomdir.path;
            outputdir = strrep(outputdir,patient_name,['ARENA EXPORT_', patient_name]);
            [~,~] = mkdir(outputdir);

            obj.warpToNative();

            modifiedVolume = obj.VoxelData.Voxels;
            if max (modifiedVolume(:)) < 2
                modifiedVolume = modifiedVolume * 100 / max(modifiedVolume(:));
            end

            if any(modifiedVolume(:)<0)
                lowest = min(modifiedVolume(:));
                modifiedVolume = modifiedVolume - lowest;
            end


            for i = 1:numel(obj.raw_InstanceNumbers)
                originalInfo = dicominfo(obj.raw_Files{i});
                originalInfo.Manufacturer = 'VisualDBSlab';
                original = dicomread(obj.raw_Files{i});
                outputImage = original;
                if size(original,3)==1
                    outputImage = cast(modifiedVolume(:,:,obj.InstanceNumbers(i)),obj.raw_class);
                elseif size(original,3)==3
                    %outputImage(:,:,1) = cast(modifiedVolume(:,:,obj.raw_InstanceNumbers(i)),obj.raw_class);
                    outputImage(:,:,2) = cast(modifiedVolume(:,:,obj.InstanceNumbers(i)),obj.raw_class);
                    %outputImage(:,:,3) = cast(modifiedVolume(:,:,obj.raw_InstanceNumbers(i)),obj.raw_class);
                end

                
                outputFilename = strrep(obj.raw_Files{i},patient_name,['ARENA EXPORT_', patient_name]);
                %originalInfo.Filename = strrep(originalInfo.Filename,patient_name,['ARENA EXPORT_', patient_name]);
                [~,~] = mkdir(fileparts(outputFilename));
            
                % write dicom image using original metadata
                dicomwrite(outputImage, outputFilename, originalInfo, 'CreateMode', 'Copy');
            end

            copyfile(obj.Dicomdir.path,outputdir)


        end

        function actor = see(obj,scene)
            if nargin==2
                if obj.Segmentation
                    actor = obj.RAS_VoxelData.getmesh().see(scene)
                else
                    actor = obj.RAS_VoxelData.getslice().see(scene)
                end
            else
                if obj.Segmentation
                    actor = obj.RAS_VoxelData.getmesh().see()
                else
                    actor = obj.RAS_VoxelData.getslice().see()
                end

            end

        end

    end

end
