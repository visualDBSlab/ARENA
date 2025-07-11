classdef PointCloud < ArenaActorRendering
    %POINTCLOUD Contains Vectors [Vector3D list] and Weights [scaler]  
    
    properties
        Vectors = Vector3D.empty;
        Weights = [];
    end

    properties(Hidden)
        labels = {}
    end
    
    methods
        function obj = PointCloud(vectors,weights)
            %POINTCLOUD Construct an instance of this class
            %   Detailed explanation goes here
            if nargin==0
                    return
            end
            
            nVectors = numel(obj.Vectors); %initial condition
            switch class(vectors)
                case 'PointCloud' %unintended use
                    obj.Vectors = vectors.Vectors;
                    obj.Weights = vectors.Weights;
                otherwise
                    obj.Vectors = vectors;
            end
            
            
            
            addedVectors = numel(obj.Vectors)-nVectors;
            if exist('weights','var')
                if numel(weights)==addedVectors
                    obj.Weights(end+1:end+numel(weights),1) = weights;
                else
                    obj.Vectors(end-addedVectors+1:end) = []; %error: delete the added vectors
                    error('number of weights does not correspond with number of vectors')
                end
            else
                obj.Weights(nVectors+1:nVectors+addedVectors,1) = 0;
            end
            
            
        end
        
        function obj = addVectors(obj,newVectors,newWeight,newLabel)
            n_before = obj.length();
            if isa(newVectors,'PointCloud')
                obj.Vectors = [obj.Vectors;newVectors.Vectors];
                obj.Weights = [obj.Weights;newVectors.Weights];
            else
                if not(isa(newVectors,'Vector3D'))
                    temp = Vector3D(newVectors);
                    newVectors = temp.Vectors;
                end
                    obj.Vectors = [obj.Vectors;newVectors];
                    if nargin==3
                        obj.Weights = [obj.Weights,newWeight];
                    else
                        obj.Weights = [obj.Weights;nan(1,numel(newVectors))];
                    end
            end
            n_after = obj.length();

            if nargin==4
                obj.labels{n_before+1:n_after} = newLabel;
            end
        
        end
        
        function out = length(obj)
            out = length(obj.Vectors);
        end
            
        
        function obj = saveToFolder(obj,outdir, tag)
            pointcloud = obj;
            save(fullfile(outdir,tag),'pointcloud')
        end

        function ttest2_CoordinatesAgainstOtherPointCloud(obj,other)
            a = obj.Vectors.getArray();
            b = other.Vectors.getArray();
            
            for d = 1:3
                [h,p,ci,stats] = ttest2(a(:,d),b(:,d));
                disp(['Dimension ',num2str(d)])
                disp('------------')
                disp(['Reject null hypothesis: ',num2str(h)])
                disp(['p: ',num2str(p)])
                disp(['t:', num2str(stats.tstat)])
                
            end
        end
        
        

        
        function obj = set.Vectors(obj,vectors)
            switch class(vectors)
                case 'Vector3D'
                    obj.Vectors = vectors;
                    
                case {'double', 'single'}
                    obj.Vectors = Vector3D.empty;
                    if size(vectors,1)>1 && size(vectors,2)==3 %list
                        Vectors = Vector3D.empty;
                        parfor i = 1:size(vectors,1)
                            Vectors(i,1) = Vector3D(vectors(i,1),vectors(i,2),vectors(i,3),'quick');
                        end
                        obj.Vectors = Vectors;
                    elseif size(vectors,1)==1 && size(vectors,2)==3 %single
                        obj.Vectors(end+1,1) = Vector3D(vectors(1),vectors(2),vectors(3));
                    else
                        error('Vectors should be nx3')
                    end
            end
        end
        
        function varargout = see(obj,sceneobj)
            %Find or instantiate Arena
            
            global arena
            if nargin==1
                if isempty(arena)
                    evalin('base','startArena');
                    thisScene = arena.sceneselect(1);
                else %arena is running
                    thisScene = arena.sceneselect();
                end
            else %nargin==2
                thisScene = sceneobj;
            end
            
            if isempty(thisScene);return;end %user cancels
            thisActor = thisScene.newActor(obj);
            thisActor.changeName(inputname(1))
            
            varargout{1} = thisActor;
            varargout{2} = thisScene;

            
        end
        
        function getStats(obj)
            disp(['Length: ',num2str(length(obj.Vectors))]);
            disp(['     X: ',num2str(mean([obj.Vectors.x])),' +/- ',num2str(std([obj.Vectors.x]))])
            disp(['     Y: ',num2str(mean([obj.Vectors.y])),' +/- ',num2str(std([obj.Vectors.y]))])
            disp(['     Z: ',num2str(mean([obj.Vectors.z])),' +/- ',num2str(std([obj.Vectors.z]))])
        end
        
        function newPC = select(obj,idcs)
            if length(idcs)==length(obj.Weights)
                if not(islogical(idcs))
                    try idcs = logical(idcs);
                    catch
                        error('indexing requires logicals')
                    end
                end
            else
                if not(and(max(idcs)<=length(obj.Weights),min(idcs>0)))
                    error('indexing is out of bounds')
                end
            end
            newPC = PointCloud(obj.Vectors(idcs),obj.Weights(idcs));

        end
        
        function COG = getCOG(obj)
            if numel(obj.Vectors)==1
                COG = obj.Vectors;
            else
                COG = Vector3D(mean(obj.Vectors.getArray));
            end
            
        end
        
        function balls = makeBallMesh(obj,radius)
            balls = {};
            for iVector = 1:numel(obj.Vectors)
                thisVector = obj.Vectors(iVector);
                [x,y,z] = sphere;
                x = x*radius+thisVector.x;
                y = y*radius+thisVector.y;
                z = z*radius+thisVector.z; 
                hSurface = surface(x,y,z);
                p = surf2patch(hSurface,'triangles');
                delete(hSurface);
                balls{iVector} = Mesh(p.faces,p.vertices);
                
            end
            
        end
        
        %--- mathematical things
        function vectorOut = getWeightedAverage(obj)
            multiplied = Vector3D.empty;
            for i = 1:numel(obj.Weights)
                multiplied(i) = obj.Vectors(i)*obj.Weights(i);
            end
            
            vectorOut = Vector3D(sum(multiplied.getArray)/sum(obj.Weights));

        end
        
        function distances = distanceTo(obj,point)
            array = obj.Vectors.getArray;
            if isa(point,'PointCloud')
                if length(point.Vectors)==length(obj.Vectors)
                    reference = point.Vectors.getArray;
                elseif length(point.Vectors)==1
                    reference = repmat(point.Vectors.getArray',length(array),1);
                else
                    error('Dimenioins should match or it should be 1 Vector3D')
                    
                end
            elseif isa(point,'Vector3D')
               reference = repmat(point.getArray',length(array),1);
            else 
                 error('input should be a Vector3D')
            end
            
            
            difference = array - reference;
            pc = PointCloud(difference);
            distances  = pc.Vectors.norm;
        end
        
        function obj = transform(obj,T)
            obj.Vectors = obj.Vectors.transform(T);
        end
        
        function out = minus(obj,term)
            v = obj.Vectors.getArray;
            if isa(term,'Vector3D')
                term = term.getArray';
            else
                error('add this option')
            end
            
            if numel(term)==3
                termrep = repmat(term,length(v),1);
                vnew = v-termrep;
            elseif numel(term)==1
                vnew = v-term;
            end
            
            if nargout==1
                out = PointCloud(vnew,obj.Weights);
            elseif nargout==0
                obj.Vectors = vnew;
                out = obj;
            end
        end
        
        function out = plus(obj,term)
            v = obj.Vectors.getArray;
            if isa(term,'Vector3D')
                term = term.getArray';
            else
                error('add this option')
            end
            
            if numel(term)==3
                termrep = repmat(term,length(v),1);
                vnew = v+termrep;
            elseif numel(term)==1
                vnew = v+term;
            end
            
            if nargout==1
                out = PointCloud(vnew,obj.Weights);
            elseif nargout==0
                obj.Vectors = vnew;
                out = obj;
            end
            
            
            
        end
       
    end
end

