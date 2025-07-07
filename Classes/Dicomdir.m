classdef Dicomdir < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here

    properties
        path
        Info
        Dicoms = Dicom.empty()
        Tag
    end

    methods
        function obj = Dicomdir(path)
            if nargin==1
                obj.path = obj.checkPath(path);
                obj.load()
            end
        end

        function load(obj,path)
            if nargin==1
                if isempty(obj.path)
                    error('path is required input')
                end
            else
                obj.path = obj.checkPath(path);
            end

            [~,obj.Tag,~] = fileparts(fileparts(obj.path));

            %load dicomdir-info
            obj.Info = dicominfo(obj.path);
            D = Dicom(obj);

            for item = 1:length(fieldnames(obj.Info.DirectoryRecordSequence))
                rec = obj.Info.DirectoryRecordSequence.(sprintf('Item_%d', item));
                if strcmp(rec.DirectoryRecordType,'SERIES')
                    % declare new Dicom
                    D = Dicom(obj);
                    obj.Dicoms(end+1)  = D;
                end
                D.recordSequence(rec)
            end

            for iD = 1:numel(obj.Dicoms)
                obj.Dicoms(iD).convertRawToVoxelData();
            end

            obj.clean();
            obj.segmentAll();
            obj.getTforAll();
            obj.warpAllToRAS();
        end

        function clean(obj)
            keep = [];
            for D = obj.Dicoms
                if not(isempty(D.VoxelData))
                    keep(end+1) = 1;
                else
                    keep(end+1) = 0;
                end
            end
            obj.Dicoms(not(keep)) = [];
        end

        function segmentAll(obj)
            for D = obj.Dicoms
                if strcmp(D.Type,'Burned-In')
                    if isempty(D.VoxelData_background)
                        D.VoxelData_foreground = D.VoxelData;
                        D.VoxelData_background = obj.findBackground();
                        D.VoxelData = obj.extractSegmentation(D);
                        D.Segmentation = 1;
                    end
                end
            end
        end

        function checkCorrelationWithParent(obj,D,Parent)
            bestflip = obj.findBestFlip(D.RAS_VoxelData_background,Parent.RAS_VoxelData);
            T = diag(bestflip*-2+1);
            T(4,4) = 1;
            D.TtoRAS = D.TtoRAS*T;
            
            
            applyBestFlip(obj,D.RAS_VoxelData,bestflip)
            applyBestFlip(obj,D.RAS_VoxelData_foreground,bestflip)
            applyBestFlip(obj,D.RAS_VoxelData_background,bestflip)
            

        end

        function bestflip = findBestFlip(obj,im1,im2)
            bestscore = 0;
            bestflip = [0 0 0];
            for x = 0:1
                for y = 0:1
                    for z = 0:1
                        bg_copy = im1.Voxels;
                        if x
                            bg_copy_out = flip(bg_copy,1);
                            bg_copy = bg_copy_out;
                        end
                        if y
                            bg_copy_out = flip(bg_copy,2);
                            bg_copy = bg_copy_out;
                        end
                        if z
                            bg_copy_out = flip(bg_copy,3);
                            bg_copy = bg_copy_out;
                        end

                        score = corr(bg_copy(:),im2.Voxels(:));
                        if score > bestscore
                            bestscore = score;
                            bestflip = [x y z];
                        end
                    end
                end
            end
        end
        function applyBestFlip(obj,slave,bestflip)
            %apply the best flip
            if bestflip(1); slave.Voxels = flip(slave.Voxels,1);end
            if bestflip(2); slave.Voxels = flip(slave.Voxels,2);end
            if bestflip(3); slave.Voxels = flip(slave.Voxels,3);end

        end


        function seg = extractSegmentation(obj,D)
            slave  = D.VoxelData_background;
            master = D.VoxelData;

            bestflip = obj.findBestFlip(slave,master);
            obj.applyBestFlip(slave,bestflip)

            seg = D.VoxelData - D.VoxelData_background;


        end


        function  getTforAll(obj)

            for D = obj.Dicoms
                if isnan(D.T)
                    [D.T,D.Parent] = obj.findTforDicom(D);
                end
            end
        end

        function warpAllToRAS(obj)
            for D = obj.Dicoms
                D.warpToRAS()
            end
            for D = obj.Dicoms
                if D.Parent
                    obj.checkCorrelationWithParent(D,obj.Dicoms(D.Parent))
                end
            end
        end

        function bg = findBackground(obj)
            for D = obj.Dicoms
                if not(strcmp(D.Type,'Burned-In'))
                    bg = D.VoxelData;
                end
            end

        end

        function [T,i] = findTforDicom(obj,dcm)
            dim = size(dcm.VoxelData);
            i = 0;

            for D = obj.Dicoms
                i = i+1;
                if D == dcm
                    continue
                end
                if not(isempty(D.Parent))
                    continue
                end
                if not(isempty(D.VoxelData))
                    if dim==size(D.VoxelData)
                        if not(isempty(D.T))
                            if not(isnan(D.T))
                                T = D.T;
                                return
                            end
                        end
                    end
                end
            end
        end

        function path = checkPath(obj,p)
            [~,~,dcmdir] = fileparts(p);
            if isempty(dcmdir)
                path = fullfile(p,'DICOMDIR');
            end
        end

        function export(obj)
            for D = obj.Dicoms
                D.export()
            end
        end


    end
end

