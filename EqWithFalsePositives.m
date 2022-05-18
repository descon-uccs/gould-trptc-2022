function [data, eqs, socialCosts, crashProbs, coverage] = EqWithFalsePositives(varargin)
    %% Parse inputs
    defaultGranularity = 100;
    defaultCrashProbFn = @(x) 0.8 .* x + 0.1;
    defaultTrueSignalProbFn = @(x) 0.7 .* x;
    defaultFalseSignalProbFn = @(x) 0.1 .* x;
    defaultSilent = false;
    
    p = inputParser;
    addParameter(p, 'granularity', defaultGranularity, @(x) isinteger(x) && (x > 0));
    addParameter(p, 'crashProbFn', defaultCrashProbFn);
    addParameter(p, 'trueSignalProbFn', defaultTrueSignalProbFn);
    addParameter(p, 'falseSignalProbFn', defaultFalseSignalProbFn);
    addParameter(p, 'silent', defaultSilent, @islogical);
    parse(p, varargin{:});

    %% Record Model Parameters
    data.granularity = p.Results.granularity;

    data.crashCosts = linspace(2, 100, data.granularity);
%     data.crashCosts = linspace(1.19, 1.2, data.granularity);
    data.crashProbFn = p.Results.crashProbFn;
    
    data.V2VMasses = linspace(0, 1, data.granularity);
%     data.V2VMasses = linspace(0.05, 0.15, data.granularity);
    data.trueSignalProbFn = p.Results.trueSignalProbFn;
    data.falseSignalProbFn = p.Results.falseSignalProbFn;

    [data.V2VMat, data.costMat] = meshgrid(data.V2VMasses, data.crashCosts);
    data.trueSignalProbMat = data.trueSignalProbFn(data.V2VMat);
    data.falseSignalProbMat = data.falseSignalProbFn(data.V2VMat);
    data.zeroMat = zeros(data.granularity);
    
    silent = p.Results.silent;

    %% Create Equilibria
    eqs = createEquilibria(data);
    
    % Check for overlap / gaps in coverage
    coverage.coveredIdxs = data.zeroMat;
    for eq = eqs
        coverage.coveredIdxs = coverage.coveredIdxs + eq.idx;
    end
    coverage.overlaps = coverage.coveredIdxs > 1;
    coverage.holes = coverage.coveredIdxs < 1;
    fprintf('Coverage Overlaps: %d\n', sum(coverage.overlaps, 'all'));
    fprintf('Coverage Holes: %d\n', sum(coverage.holes, 'all'));

    %% Consolidate Results
    % consolidate social costs
    socialCosts.careful = data.zeroMat;
    socialCosts.reckless = data.zeroMat;
    socialCosts.total = data.zeroMat;
    for eq = eqs
        socialCosts.careful(eq.idx) = eq.scc(eq.idx);
        socialCosts.reckless(eq.idx) = eq.scr(eq.idx);
        socialCosts.total(eq.idx) = eq.socialCost(eq.idx);
    end

    % consolidate crash probabilities
    crashProbs = data.zeroMat;
    for eq = eqs
        crashProbs(eq.idx) = eq.crashProb(eq.idx);
    end
    
    % save generated data so we do not have to recalculate it later
    save('fpeqs.mat', 'data', 'eqs', 'socialCosts', 'crashProbs', 'coverage');

    %% Final Graphs
    if (~silent)
        DispEqs(data, eqs, socialCosts, crashProbs);
    end
end

%% Helper Functions
function eqs = createEquilibria(data)
    % definitions we will not need outside function
    crashProbFn = data.crashProbFn;
    inverseCrashProbFn = matlabFunction(finverse(sym(crashProbFn)));
    trueSignalProbFn = data.trueSignalProbFn;
    falseSignalProbFn = data.falseSignalProbFn;
    
    minCrashProb = data.zeroMat + crashProbFn(0);
    signaledV2VCrashProbCritPoint = data.falseSignalProbMat ./ ...
        ((data.costMat - 1) .* data.trueSignalProbMat + data.falseSignalProbMat);
    nonV2VCrashProbCritPoint = 1 ./ data.costMat;
    unsignaledV2VCrashProbCritPoint = (1-data.falseSignalProbMat) ./ ...
        (data.costMat - (data.costMat - 1) .* data.trueSignalProbMat - data.falseSignalProbMat);
    maxCrashProb = data.zeroMat + crashProbFn(1); 
    
    % SC NC UC calculations
    scncucEq.name = 'Signaled V2V Careful, Non-V2V Careful, Unsignaled V2V Careful';
    scncucEq.crashProb = minCrashProb;
    scncucEq.signalProb = scncucEq.crashProb .* data.trueSignalProbMat + (1-scncucEq.crashProb) .* data.falseSignalProbMat;
    scncucEq.xvs = data.zeroMat;
    scncucEq.xn = data.zeroMat;
    scncucEq.xvu = data.zeroMat;

    scncucEq.loBound = unsignaledV2VCrashProbCritPoint;
    scncucEq.hiBound = maxCrashProb;
    scncucEq.idx = scncucEq.loBound < scncucEq.crashProb;

    [scncucEq.scc, scncucEq.scr, scncucEq.socialCost] = socialCost(scncucEq.xvs, scncucEq.xn, scncucEq.xvu, ...
        scncucEq.crashProb, scncucEq.signalProb, data);
    
    % SC NC UI calculations
    scncuiEq.name = 'Signaled V2V Careful, Non-V2V Careful, Unsignaled V2V Indifferent';
    scncuiEq.crashProb = unsignaledV2VCrashProbCritPoint;
    scncuiEq.signalProb = scncuiEq.crashProb .* data.trueSignalProbMat + (1-scncuiEq.crashProb) .* data.falseSignalProbMat;
    scncuiEq.xvs = data.zeroMat;
    scncuiEq.xn = data.zeroMat;
    scncuiEq.xvu = inverseCrashProbFn(scncuiEq.crashProb) ./ (1-scncuiEq.signalProb);

    scncuiEq.loBound = minCrashProb;
    scncuiEq.hiBound = crashProbFn((1-scncuiEq.signalProb) .* data.V2VMat);
    scncuiEq.idx = scncuiEq.loBound <= scncuiEq.crashProb & scncuiEq.crashProb <= scncuiEq.hiBound;

    [scncuiEq.scc, scncuiEq.scr, scncuiEq.socialCost] = socialCost(scncuiEq.xvs, scncuiEq.xn, scncuiEq.xvu, ...
        scncuiEq.crashProb, scncuiEq.signalProb, data);
    
    % SC NC UR calculations
    scncurEq.name = 'Signaled V2V Careful, Non-V2V Careful, Unsignaled V2V Reckless';
    syms A;
    scncurEq.crashProb = double(repmat(...
        arrayfun(@(y) vpasolve(A == crashProbFn((1-(A.*trueSignalProbFn(y) + (1-A).*falseSignalProbFn(y))) .* y), A), data.V2VMat(1, :)),...
        data.granularity, 1));
    scncurEq.signalProb = scncurEq.crashProb .* data.trueSignalProbMat + (1-scncurEq.crashProb) .* data.falseSignalProbMat;
    scncurEq.xvs = data.zeroMat;
    scncurEq.xn = data.zeroMat;
    scncurEq.xvu = data.V2VMat;

    scncurEq.loBound = nonV2VCrashProbCritPoint;
    scncurEq.hiBound = unsignaledV2VCrashProbCritPoint;
    scncurEq.idx = scncurEq.loBound < scncurEq.crashProb & scncurEq.crashProb < scncurEq.hiBound;

    [scncurEq.scc, scncurEq.scr, scncurEq.socialCost] = socialCost(scncurEq.xvs, scncurEq.xn, scncurEq.xvu, ...
        scncurEq.crashProb, scncurEq.signalProb, data);
    
    % SC NI UR calculations
    scniurEq.name = 'Signaled V2V Careful, Non-V2V Indifferent, Unsignaled V2V Reckless';
    scniurEq.crashProb = nonV2VCrashProbCritPoint;
    scniurEq.signalProb = scniurEq.crashProb .* data.trueSignalProbMat + (1-scniurEq.crashProb) .* data.falseSignalProbMat;
    scniurEq.xvs = data.zeroMat;
    scniurEq.xn = inverseCrashProbFn(scniurEq.crashProb) - (1-scniurEq.signalProb) .* data.V2VMat;
    scniurEq.xvu = data.V2VMat;

    scniurEq.loBound = crashProbFn((1-scniurEq.signalProb) .* data.V2VMat);
    scniurEq.hiBound = crashProbFn(1 - scniurEq.signalProb .* data.V2VMat);
    scniurEq.idx = scniurEq.loBound <= scniurEq.crashProb & scniurEq.crashProb < scniurEq.hiBound;

    [scniurEq.scc, scniurEq.scr, scniurEq.socialCost] = socialCost(scniurEq.xvs, scniurEq.xn, scniurEq.xvu, ...
        scniurEq.crashProb, scniurEq.signalProb, data);
    
    % SC NR UR calculations
    scnrurEq.name = 'Signaled V2V Careful, Non-V2V Reckless, Unsignaled V2V Reckless';
    scnrurEq.crashProb = double(repmat(...
        arrayfun(@(y) vpasolve(A == crashProbFn(1 - (A.*trueSignalProbFn(y) + (1-A).*falseSignalProbFn(y)) .* y), A), data.V2VMat(1, :)),...
        data.granularity, 1));
    scnrurEq.signalProb = scnrurEq.crashProb .* data.trueSignalProbMat + (1-scnrurEq.crashProb) .* data.falseSignalProbMat;
    scnrurEq.xvs = data.zeroMat;
    scnrurEq.xn = 1 - data.V2VMat;
    scnrurEq.xvu = data.V2VMat;

    scnrurEq.loBound = signaledV2VCrashProbCritPoint;
    scnrurEq.hiBound = nonV2VCrashProbCritPoint;
    scnrurEq.idx = scnrurEq.loBound < scnrurEq.crashProb & scnrurEq.crashProb < scnrurEq.hiBound;

    [scnrurEq.scc, scnrurEq.scr, scnrurEq.socialCost] = socialCost(scnrurEq.xvs, scnrurEq.xn, scnrurEq.xvu, ...
        scnrurEq.crashProb, scnrurEq.signalProb, data);
    
    % SI NR UR calculations
    sinrurEq.name = 'Signaled V2V Indifferent, Non-V2V Reckless, Unsignaled V2V Reckless';
    sinrurEq.crashProb = signaledV2VCrashProbCritPoint;
    sinrurEq.signalProb = sinrurEq.crashProb .* data.trueSignalProbMat + (1-sinrurEq.crashProb) .* data.falseSignalProbMat;
    sinrurEq.xvs = (inverseCrashProbFn(sinrurEq.crashProb) + data.V2VMat-1 - (1-sinrurEq.signalProb).*data.V2VMat) ./ ...
        sinrurEq.signalProb;
    sinrurEq.xn = 1 - data.V2VMat;
    sinrurEq.xvu = data.V2VMat;

    sinrurEq.loBound = crashProbFn(1 - sinrurEq.signalProb .* data.V2VMat);
    sinrurEq.hiBound = maxCrashProb;
    sinrurEq.idx = sinrurEq.loBound <= sinrurEq.crashProb & sinrurEq.crashProb <= sinrurEq.hiBound;

   [sinrurEq.scc, sinrurEq.scr, sinrurEq.socialCost] = socialCost(sinrurEq.xvs, sinrurEq.xn, sinrurEq.xvu, ...
        sinrurEq.crashProb, sinrurEq.signalProb, data);
    
    % SR NR UR calculations
    srnrurEq.name = 'Signaled V2V Reckless, Non-V2V Reckless, Unsignaled V2V Reckless';
    srnrurEq.crashProb = maxCrashProb;
    srnrurEq.signalProb = srnrurEq.crashProb .* data.trueSignalProbMat + (1-srnrurEq.crashProb) .* data.falseSignalProbMat;
    srnrurEq.xvs = data.V2VMat;
    srnrurEq.xn = 1 - data.V2VMat;
    srnrurEq.xvu = data.V2VMat;

    srnrurEq.loBound = minCrashProb;
    srnrurEq.hiBound = signaledV2VCrashProbCritPoint;
    srnrurEq.idx = srnrurEq.crashProb < srnrurEq.hiBound;

    [srnrurEq.scc, srnrurEq.scr, srnrurEq.socialCost] = socialCost(srnrurEq.xvs, srnrurEq.xn, srnrurEq.xvu, ...
        srnrurEq.crashProb, srnrurEq.signalProb, data);

    
    % Return List of Equilibria
    eqs = [scncucEq, scncuiEq, scncurEq, scniurEq, scnrurEq, sinrurEq, srnrurEq];
end

function [scc, scr, socialCost] = socialCost(xvs, xn, xvu, crashProb, signalProb, data)
    % TODO: this division causes some problems; consider rewriting w/
    % simplified expressions
    prAS = ((data.trueSignalProbMat) .* crashProb) ./ signalProb;
    prAnS = ((1 - data.trueSignalProbMat) .* crashProb) ./ (1-signalProb);
    
    scc = signalProb .* (data.V2VMat - xvs) + (1 - data.V2VMat-xn) + ...
        (1-signalProb) .* (data.V2VMat - xvu);
    scr = data.costMat .* (signalProb .* xvs .* prAS + ...
        xn .* crashProb + ...
        (1-signalProb) .* xvu .* prAnS);
    socialCost = scc + scr;
end
