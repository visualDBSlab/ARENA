function results = HeatmapMaker_testOtherOutcome(varargin)
%HEATMAPMAKER_TESTOTHEROUTCOME Test a trained heatmap against another
%clinical outcome, optionally adjusting for covariates.
%
%   The trained PredictionModel is NOT retrained. For every patient its
%   leave-one-out cross-validated prediction (PredictionModel.LOOCV) is
%   taken and used as a predictor of a new outcome:
%
%       m0:  outcome ~ covariates                      (covariates only)
%       m1:  outcome ~ covariates + heatmap_pred       (+ heatmap)
%
%   Reported: heatmap coefficient and p-value in m1, in-sample delta R^2
%   with nested F-test, and cross-validated (leave-one-out) q^2 of both
%   models with a permutation p-value for the gain in q^2.
%
%   GUI use (ARENA > HeatmapMaker > Advanced pipeline (LOO)):
%       you are asked for the trained model (.mat), a clinical table
%       (.xlsx/.csv with a 'fileID' column matching the training recipe),
%       the outcome column and the covariate columns.
%
%   Script use:
%       results = HeatmapMaker_testOtherOutcome( ...
%           'model',      '/path/to/PredictionModel.mat', ...
%           'table',      '/path/to/clinical.xlsx',  ... (or a MATLAB table)
%           'outcome',    'updrsiii%_zscored', ...
%           'covariates', {'age','disease_duration','baseline_updrs'}, ...
%           'trainingRecipe', '/path/to/recipe.xlsx', ... (optional)
%           'nPerm', 1000, 'plot', true, 'save', true);
%
%   Text covariates (e.g. sex) are treated as categorical. Patients with a
%   missing value in the outcome or any covariate are excluded from BOTH
%   models so that m0 and m1 are compared on the same patients.

%% ---- parse input ------------------------------------------------------
global arena
opts = struct('model',[],'table',[],'outcome',[],'covariates',[], ...
    'trainingRecipe',[],'nPerm',1000,'plot',true,'save',true);
guiMode = isempty(varargin) || ~ischar(varargin{1}) && ~isstring(varargin{1});
if ~guiMode
    for k = 1:2:numel(varargin)
        opts.(lower(char(varargin{k}))) = varargin{k+1};
    end
    % fieldnames are case-sensitive; map the lower-cased ones back
    if isfield(opts,'trainingrecipe'); opts.trainingRecipe = opts.trainingrecipe; end
    if isfield(opts,'nperm'); opts.nPerm = opts.nperm; end
end

%% ---- 1. trained model -------------------------------------------------
if isempty(opts.model)
    waitfor(msgbox(['Select the trained prediction model you want to test ', ...
        'against another clinical outcome.'],'Test heatmap on another outcome'))
    startFolder = pwd;
    try
        startFolder = fullfile(arena.getrootdir,'UserData','PredictionModels');
    catch
    end
    [f,p] = uigetfile(fullfile(startFolder,'*.mat'),'Select trained prediction model');
    if isequal(f,0); results = []; return; end
    opts.model = fullfile(p,f);
end
if ischar(opts.model) || isstring(opts.model)
    loaded = load(opts.model,'mdl');
    PM = loaded.mdl;
    modelFile = char(opts.model);
else
    PM = opts.model;
    modelFile = '';
end
if ~isa(PM,'PredictionModel') || isempty(PM.TrainingLinearModel)
    error('The selected file does not contain a trained PredictionModel.')
end

%% ---- 2. held-out predictions of the trained model ----------------------
disp('Computing leave-one-out predictions of the trained model...')
ws = warning('off','stats:regress:RankDefDesignMat');
wsr = warning('off','MATLAB:rankDeficientMatrix');
cvMdl = PM.LOOCV();
warning(ws); warning(wsr);
heatmapPred = cvMdl.Variables.x1(:);
trainY = cvMdl.Variables.y(:);
nTrain = numel(heatmapPred);

% IDs of the training patients, in training order
trainIDs = [];
recipePath = opts.trainingRecipe;
if isempty(recipePath); recipePath = PM.Path; end
if ~isempty(recipePath) && isfile(recipePath)
    R = readtable(recipePath,'VariableNamingRule','preserve');
    if height(R)==nTrain && any(strcmp(R.Properties.VariableNames,'fileID'))
        trainIDs = string(R.fileID);
        % sanity check: scores in the recipe must equal the training scores
        sc = R{:,4};
        if isnumeric(sc) && max(abs(sc(:)-trainY)) > 1e-6
            warning(['Scores in the training recipe do not match the scores ', ...
                'stored in the model. Check that this is the right recipe.'])
        end
    end
end
if isempty(trainIDs)
    if guiMode
        waitfor(msgbox(['The training recipe could not be found at:' newline ...
            char(string(PM.Path)) newline 'Please select it, so patients can be matched by fileID.']))
        [f,p] = uigetfile({'*.xlsx;*.xls;*.csv'},'Select the TRAINING recipe');
        if ~isequal(f,0)
            R = readtable(fullfile(p,f),'VariableNamingRule','preserve');
            trainIDs = string(R.fileID);
        end
    end
end

%% ---- 3. clinical table -----------------------------------------------
if isempty(opts.table)
    [f,p] = uigetfile({'*.xlsx;*.xls;*.csv'}, ...
        'Select table with the outcome and covariates (needs a fileID column)');
    if isequal(f,0); results = []; return; end
    opts.table = fullfile(p,f);
end
if istable(opts.table)
    C = opts.table;
    tableFile = '';
else
    tableFile = char(opts.table);
    C = readtable(tableFile,'VariableNamingRule','preserve');
end

% match patients
if ~isempty(trainIDs) && any(strcmp(C.Properties.VariableNames,'fileID'))
    [found,loc] = ismember(string(C.fileID),trainIDs);
    if ~all(found)
        warning('%d patient(s) in the clinical table are not in the training data and are skipped.',sum(~found))
    end
    C = C(found,:);
    heatmapPredMatched = heatmapPred(loc(found));
    if sum(found) < nTrain
        fprintf('%d of %d training patients found in the clinical table.\n',sum(found),nTrain);
    end
elseif height(C)==nTrain
    warning(['Patients could not be matched by fileID; assuming the clinical ', ...
        'table has the same row order as the training recipe.'])
    heatmapPredMatched = heatmapPred;
else
    error(['Cannot match patients: provide a fileID column (as in the ', ...
        'training recipe) or a table with exactly %d rows in training order.'],nTrain)
end

% choose columns
skip = {'fileID','fullpath','Move_or_keep_left'};
candidates = setdiff(C.Properties.VariableNames,skip,'stable');
if isempty(opts.outcome)
    [i,ok] = listdlg('ListString',candidates,'SelectionMode','single', ...
        'PromptString','Select the OUTCOME to test:','ListSize',[300 250]);
    if ~ok; results = []; return; end
    opts.outcome = candidates{i};
end
if isempty(opts.covariates) && guiMode
    rest = setdiff(candidates,{opts.outcome},'stable');
    [i,ok] = listdlg('ListString',rest,'SelectionMode','multiple', ...
        'PromptString',{'Select COVARIATES (optional).','Cancel = no covariates.'}, ...
        'ListSize',[300 250]);
    if ok; opts.covariates = rest(i); else; opts.covariates = {}; end
end
if isempty(opts.covariates); opts.covariates = {}; end
covNames = cellstr(opts.covariates);
covNames = covNames(~cellfun(@isempty,covNames));
if ~ismember(opts.outcome,C.Properties.VariableNames)
    error('Outcome column "%s" not found.',opts.outcome)
end
missingCov = setdiff(covNames,C.Properties.VariableNames);
if ~isempty(missingCov)
    error('Covariate column(s) not found: %s',strjoin(missingCov,', '))
end

%% ---- 4. analysis table (valid names, complete cases) -----------------
origNames = [{opts.outcome}, covNames];
validNames = matlab.lang.makeValidName(origNames);
validNames = matlab.lang.makeUniqueStrings(validNames,{'heatmap_pred'});
T = table();
for k = 1:numel(origNames)
    v = C.(origNames{k});
    if iscell(v) || isstring(v) || ischar(v)
        v = categorical(string(v));
        v(ismember(string(v),["","NaN","NA","nan"])) = categorical(missing);
    end
    T.(validNames{k}) = v;
end
T.heatmap_pred = heatmapPredMatched(:);
yName = validNames{1};
cName = validNames(2:end);
if ~isnumeric(T.(yName))
    error('The outcome must be numeric.')
end

complete = ~any(ismissing(T),2);
nDropped = sum(~complete);
if nDropped>0
    fprintf('%d patient(s) excluded because of missing values.\n',nDropped);
end
T = T(complete,:);
n = height(T);
if n < numel(cName)+5
    error('Too few complete patients (%d) for %d covariates.',n,numel(cName))
end
if numel(cName) > n/10
    warning(['%d covariates for %d patients (fewer than 10 patients per covariate). ', ...
        'Estimates may be unstable.'],numel(cName),n)
end

%% ---- 5. in-sample models ---------------------------------------------
if isempty(cName)
    f0 = sprintf('%s ~ 1',yName);
else
    f0 = sprintf('%s ~ %s',yName,strjoin(cName,' + '));
end
f1 = [f0 ' + heatmap_pred'];
if isempty(cName); f1 = sprintf('%s ~ heatmap_pred',yName); end

m0 = fitlm(T,f0);
m1 = fitlm(T,f1);
idx = strcmp(m1.CoefficientNames,'heatmap_pred');
[pF,Fstat] = coefTest(m1,double(idx));
dR2 = m1.Rsquared.Ordinary - m0.Rsquared.Ordinary;
beta = m1.Coefficients.Estimate(idx);
betaSE = m1.Coefficients.SE(idx);
pBeta = m1.Coefficients.pValue(idx);
ci = coefCI(m1); ci = ci(idx,:);
% partial correlation of heatmap prediction with outcome, given covariates
partialR = sign(beta)*sqrt(Fstat/(Fstat + m1.DFE));

%% ---- 6. cross-validated comparison -----------------------------------
X0 = designMatrix(T,cName);
X1 = [X0, T.heatmap_pred];
y = T.(yName);
[q2_0,pred0] = looQ2(X0,y);
[q2_1,pred1] = looQ2(X1,y);
dq2 = q2_1 - q2_0;

% permutation test: shuffle the heatmap prediction across patients
nPerm = opts.nPerm;
pPerm = NaN;
if nPerm > 0
    fprintf('Permutation test (%d permutations)...\n',nPerm);
    rng(0,'twister');
    nullDq2 = zeros(nPerm,1);
    for k = 1:nPerm
        nullDq2(k) = looQ2([X0, T.heatmap_pred(randperm(n))],y) - q2_0;
    end
    pPerm = (sum(nullDq2 >= dq2) + 1)/(nPerm + 1);
end

%% ---- 7. report -------------------------------------------------------
outcomeLabel = opts.outcome;
fprintf('\n=====================================================\n');
fprintf(' Heatmap tested on: %s\n',outcomeLabel);
fprintf(' Model: %s\n',PM.Tag);
if isempty(covNames)
    fprintf(' Covariates: none\n');
else
    fprintf(' Covariates: %s\n',strjoin(covNames,', '));
end
fprintf(' Patients: %d\n',n);
fprintf('-----------------------------------------------------\n');
fprintf(' Heatmap coefficient: %.3f (95%% CI %.3f to %.3f), SE %.3f, p = %.3g\n',beta,ci(1),ci(2),betaSE,pBeta);
fprintf(' Partial r (given covariates): %.3f\n',partialR);
fprintf(' R^2 covariates only: %.3f | + heatmap: %.3f | delta R^2 = %.3f\n', ...
    m0.Rsquared.Ordinary,m1.Rsquared.Ordinary,dR2);
fprintf(' Nested F-test: F(1,%d) = %.2f, p = %.3g\n',m1.DFE,Fstat,pF);
fprintf(' Cross-validated q^2 covariates only: %.3f | + heatmap: %.3f | delta q^2 = %.3f\n',q2_0,q2_1,dq2);
if ~isnan(pPerm)
    fprintf(' Permutation p for delta q^2: %.3g (%d permutations)\n',pPerm,nPerm);
end
fprintf('=====================================================\n');
disp('Full model:'); disp(m1)

results = struct();
results.outcome = outcomeLabel;
results.covariates = covNames;
results.n = n;
results.nExcludedMissing = nDropped;
results.beta = beta; results.betaCI = ci; results.betaSE = betaSE; results.pBeta = pBeta;
results.partialR = partialR;
results.R2_covariates = m0.Rsquared.Ordinary;
results.R2_full = m1.Rsquared.Ordinary;
results.deltaR2 = dR2;
results.F = Fstat; results.pF = pF;
results.q2_covariates = q2_0; results.q2_full = q2_1; results.deltaQ2 = dq2;
results.pPermutation = pPerm; results.nPerm = nPerm;
results.mdlCovariates = m0;
results.mdlFull = m1;
results.data = T;
results.looPredCovariates = pred0;
results.looPredFull = pred1;
results.modelFile = modelFile;
results.tableFile = tableFile;

assignin('base','heatmapTest',results);
disp('Results are available in the workspace as "heatmapTest".')

%% ---- 8. figure -------------------------------------------------------
if opts.plot
    fig = figure('Name',['Heatmap vs ' outcomeLabel],'Color','w','Position',[100 100 1000 420]);
    subplot(1,2,1)
    scatter(T.heatmap_pred,y,40,'k','filled','MarkerFaceAlpha',0.6); hold on
    lr = fitlm(T.heatmap_pred,y);
    xl = xlim; xx = linspace(xl(1),xl(2),50)';
    [yy,yci] = predict(lr,xx);
    fill([xx;flipud(xx)],[yci(:,1);flipud(yci(:,2))],[0.85 0.85 0.85],'LineStyle','none');
    plot(xx,yy,'k--','LineWidth',1.5);
    uistack(findobj(gca,'Type','scatter'),'top');
    [rr,pr] = corr(T.heatmap_pred,y);
    xlabel('Heatmap prediction (LOOCV)'); ylabel(outcomeLabel,'Interpreter','none');
    title({'Unadjusted',sprintf('r = %.2f, p = %.2g',rr,pr)});
    box off; set(gca,'FontSize',12)

    subplot(1,2,2)
    if isempty(cName)
        bar([q2_0 q2_1],'FaceColor',[0.6 0.6 0.6]); set(gca,'XTickLabel',{'intercept only','+ heatmap'})
        ylabel('Cross-validated q^2'); title('Cross-validated')
    else
        plotAdded(m1,'heatmap_pred'); legend off
        h = findobj(gca,'Type','line');
        set(h(end),'Marker','.','MarkerSize',15,'Color','k')
        xlabel('Heatmap prediction | covariates'); ylabel([outcomeLabel ' | covariates'],'Interpreter','none');
        title({'Adjusted for covariates', ...
            sprintf('\\beta = %.2f, p = %.2g, \\Deltaq^2 = %.2f',beta,pBeta,dq2)},'Interpreter','tex');
        h = findobj(gca,'Type','line');
        set(h(1:end-1),'Color','k')
    end
    box off; set(gca,'FontSize',12)
    results.figure = fig;
    assignin('base','heatmapTest',results);
end

%% ---- 9. save ---------------------------------------------------------
if opts.save && ~isempty(tableFile)
    [p,base] = fileparts(tableFile);
    outFile = fullfile(p,sprintf('%s_heatmapTest_%s.xlsx',base, ...
        matlab.lang.makeValidName(outcomeLabel)));
    summary = table( ...
        string(outcomeLabel),string(PM.Tag),string(strjoin(covNames,', ')),n,beta,ci(1),ci(2),pBeta, ...
        partialR,m0.Rsquared.Ordinary,m1.Rsquared.Ordinary,dR2,Fstat,pF,q2_0,q2_1,dq2,pPerm, ...
        'VariableNames',{'outcome','model','covariates','n','beta_heatmap','CI_low','CI_high', ...
        'p_heatmap','partial_r','R2_covariates','R2_full','delta_R2','F','p_F', ...
        'q2_covariates','q2_full','delta_q2','p_permutation'});
    coefs = m1.Coefficients;
    coefs = addvars(coefs,string(coefs.Properties.RowNames),'Before',1,'NewVariableNames','term');
    try
        writetable(summary,outFile,'Sheet','summary');
        writetable(coefs,outFile,'Sheet','full_model');
        fprintf('Results saved to %s\n',outFile);
        results.outFile = outFile;
        assignin('base','heatmapTest',results);
    catch err
        warning('HeatmapMaker:saveFailed','Could not save results: %s',err.message)
    end
end

end

%% ======================================================================
function X = designMatrix(T,names)
% numeric design matrix (without intercept); categoricals dummy-coded
X = zeros(height(T),0);
for k = 1:numel(names)
    v = T.(names{k});
    if iscategorical(v)
        v = removecats(v);
        D = dummyvar(v);
        X = [X, D(:,2:end)]; %#ok<AGROW>
    else
        X = [X, double(v)]; %#ok<AGROW>
    end
end
end

function [q2,pred] = looQ2(X,y)
% leave-one-out cross-validated q^2 = 1 - PRESS/SS_total
n = numel(y);
Xi = [ones(n,1), X];
pred = zeros(n,1);
for i = 1:n
    tr = true(n,1); tr(i) = false;
    b = pinv(Xi(tr,:))*y(tr);
    pred(i) = Xi(i,:)*b;
end
q2 = 1 - sum((y-pred).^2)/sum((y-mean(y)).^2);
end
