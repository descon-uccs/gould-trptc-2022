% Note: this script with throw several "Warning: Attempting to format a
% nonexistent legend". These warnings can be safely ignored. They simply
% mean that the current plot does not have a legend.
%
% Additionally, each plot depicting the ranges of equilibria will print
% coverage information about the number of indices checked that either do
% not satisfy any equilibrium, or satisfy multiple. In our paper, we claim
% that every parameter combination has an essentially unique signaling
% equilibrium, and this is true. However, due to floating-point arithmatic,
% this script will not always correctly detect this equilibrium. This
% information is printed as a summary of how accurate the computed
% equilibria can be expected to be. 
% 
% Finally, the legend on the equilibrium range plot is not exactly the one
% seen in the paper, but has exactly the same meaning. The one used in the 
% paper was custom made in a vector graphics tool, and is difficult to 
% replicate exactly in matlab. 

clear;

%% Plots showing families of signaling equilibria 
% Low recklessness 
[data, eqs, ~, ~, ~] = EqWithFalsePositives('silent', true);
DispEqRanges(data, eqs); % Set parameter 'serialize' to true to save fig to disk
% Mid recklessness
[data, eqs, ~, ~, ~] = EqWithFalsePositives('silent', true, ...
    'crashProbFn', @(x) 0.1 .* x, 'trueSignalProbFn', @(x) 0.95 .* x, ...
    'falseSignalProbFn', @(x) 0.3 .* x);
DispEqRanges(data, eqs, "lgd", true);
% High recklessness
[data, eqs, ~, ~, ~] = EqWithFalsePositives('silent', true, ...
    'crashProbFn', @(x) 0.03 .* x, 'trueSignalProbFn', @(x) 0.95 .* x, ...
    'falseSignalProbFn', @(x) 0.5 .* x);
DispEqRanges(data, eqs); 

%% Plots showing accident probability paradox
[data, eqTypes] = GetEqTypes('V2VMass', 0.9, 'crashCost', 3, ...
    'trueSignalProbFn', @(y) 0.8.*y, 'falseSignalProbFn', @(y) 0.1.*y, ...
    'crashProbFn', @(x) 0.3 .* x + 0.1, 'granularity', int16(1000));
DispCrashProb(data, eqTypes); % Set parameter 'serialize' to true to save fig to disk

%% Plots showing social cost paradoxes
[data, eqTypes] = GetEqTypes('V2VMass', 0.066, 'crashCost', 1.001, ...
    'trueSignalProbFn', @(y) 0.9.*y, 'falseSignalProbFn', @(y) 0.1.*y, ...
    'crashProbFn', @(x) x.^(1/4), 'granularity', int16(1000));
crashProbs = DispCrashProb(data, eqTypes, 'display', false);
DispSocialCost(data, eqTypes, crashProbs); % Set parameter 'serialize' to true to save fig to disk

[data, eqTypes] = GetEqTypes('V2VMass', 0.4, 'crashCost', 20, ...
    'trueSignalProbFn', @(y) 0.95.*y, 'falseSignalProbFn', @(y) 0.5.*y, ...
    'crashProbFn', @(x) 0.03.*x, 'granularity', int16(1000));
crashProbs = DispCrashProb(data, eqTypes, 'display', false);
DispSocialCost(data, eqTypes, crashProbs);

[data, eqTypes] = GetEqTypes('V2VMass', 0.8, 'crashCost', 5, ...
    'trueSignalProbFn', @(y) 0.8.*y, 'falseSignalProbFn', @(y) 0.1.*y, ...
    'crashProbFn', @(x) 0.8 .* x + 0.1, 'granularity', int16(1000));
crashProbs = DispCrashProb(data, eqTypes, 'display', false);
socialCosts = DispSocialCost(data, eqTypes, crashProbs, 'display', false); 
DispCrashProbSocialCost(data, crashProbs, socialCosts, false); % Set last argument to true to save fig to disk

%% Helper functions
function DispEqRanges(varargin)
    % Parse inputs
    p = inputParser;
    addRequired(p, 'data');
    addRequired(p, 'eqs');
    addParameter(p, 'lgd', false, @islogical);
    addParameter(p, 'serialize', false, @islogical);
    parse(p, varargin{:});

    data = p.Results.data;
    eqs = p.Results.eqs;
    lgd = p.Results.lgd;
    serialize = p.Results.serialize;

    % Create figure
    fig = figure();

    hold on;
    colors = ["#7703fc", "#0000ff", "#00ff00", "#ffff00", "#fcad03", "#ff0000", "#f403fc"];
    i = 1;
    for eq = eqs
        surf(data.V2VMat, data.costMat, double(eq.idx), 'FaceColor', colors(i), 'EdgeColor', 'none', ...
            'DisplayName', eq.name);
        i=i+1;
    end

    xlabel('V2V Mass');
    ylabel('Crash Cost');
    title('Choices at Equilibrium');
    if (lgd)
        fig.Position(4) = 600; % Add extra height to accomodate legend
        legend("Location", 'southoutside');
    end
    FormatPlot(gca);

    if (serialize)
        saveName = "EqPlot_" + datestr(now,'dd-mm-yy_HH:MM:SS');
        saveas(fig, saveName, 'epsc');
    end
end

function [data, eqTypes] = GetEqTypes(varargin)
    % Parse inputs
    defaultV2VMass = 0.5;
    defaultCrashCost = 10;
    defaultGranularity = 100;
    defaultCrashProbFn = @(x) 0.8 .* x + 0.1;
    defaultTrueSignalProbFn = @(x) 0.7 .* x;
    defaultFalseSignalProbFn = @(x) 0.1 .* x;
    
    p = inputParser;
    addParameter(p, 'V2VMass', defaultV2VMass, @(x) 0 <= x && x <= 1);
    addParameter(p, 'crashCost', defaultCrashCost, @(x) 1 < x);
    addParameter(p, 'granularity', defaultGranularity, @(x) isinteger(x) && (x > 0));
    addParameter(p, 'crashProbFn', defaultCrashProbFn);
    addParameter(p, 'trueSignalProbFn', defaultTrueSignalProbFn);
    addParameter(p, 'falseSignalProbFn', defaultFalseSignalProbFn);
    parse(p, varargin{:});

    V2VMass = p.Results.V2VMass;
    crashCost = p.Results.crashCost;
    granularity = p.Results.granularity;
    crashProbFn = p.Results.crashProbFn;
    trueSignalProbFn = p.Results.trueSignalProbFn;
    falseSignalProbFn = p.Results.falseSignalProbFn;

    beta = linspace(0, 1, granularity);

    % Calculate critical points where equilibrium type changes
    Pvs = falseSignalProbFn(V2VMass) ./ (crashCost * trueSignalProbFn(V2VMass) + falseSignalProbFn(V2VMass));
    Pn = 1 / (1 + crashCost);
    Pvu = (1 - beta .* falseSignalProbFn(V2VMass)) ./ ...
        (1 + crashCost * (1 - beta * trueSignalProbFn(V2VMass)) - beta * falseSignalProbFn(V2VMass));
    Qvs = beta .* Pvs * (trueSignalProbFn(V2VMass) - falseSignalProbFn(V2VMass)) ...
        + beta .* falseSignalProbFn(V2VMass);
    Qn = beta .* Pn * (trueSignalProbFn(V2VMass) - falseSignalProbFn(V2VMass)) ...
        + beta .* falseSignalProbFn(V2VMass);
    Qvu = beta .* Pvu * (trueSignalProbFn(V2VMass) - falseSignalProbFn(V2VMass)) ...
        + beta .* falseSignalProbFn(V2VMass);

    border1 = crashProbFn(0);
    border2 = crashProbFn(V2VMass - Qvu * V2VMass);
    border3 = crashProbFn(V2VMass - Qn * V2VMass);
    border4 = crashProbFn(1 - Qn * V2VMass);
    border5 = crashProbFn(1 - Qvs * V2VMass);
    border6 = crashProbFn(1);

    % Calculate equilibrium type valid for each value of beta
    eqTypes.SCNCUC = Pvu < border1;
    eqTypes.SCNCUI = border1 <= Pvu & Pvu <= border2;
    eqTypes.SCNCUR = border2 < Pvu & Pn < border3;
    eqTypes.SCNIUR = border3 <= Pn & Pn <= border4;
    eqTypes.SCNRUR = border4 < Pn & Pvs < border5;
    eqTypes.SINRUR = border5 <= Pvs & Pvs <= border6;
    eqTypes.SRNRUR = border6 < Pvs;

    eqTypes.all = zeros(1, granularity);
    eqTypes.all(eqTypes.SCNCUC) = 1;
    eqTypes.all(eqTypes.SCNCUI) = 2;
    eqTypes.all(eqTypes.SCNCUR) = 3;
    eqTypes.all(eqTypes.SCNIUR) = 4;
    eqTypes.all(eqTypes.SCNRUR) = 5;
    eqTypes.all(eqTypes.SINRUR) = 6;
    eqTypes.all(eqTypes.SRNRUR) = 7;

    % Save data used to generate equilibrium types
    data.V2VMass = V2VMass;
    data.crashCost = crashCost;
    data.granularity = granularity;
    data.crashProbFn = crashProbFn;
    data.trueSignalProbFn = trueSignalProbFn;
    data.falseSignalProbFn = falseSignalProbFn;
    data.beta = beta;

    data.Pvs = Pvs;
    data.Pn = Pn;
    data.Pvu = Pvu;
end

function crashProbs = DispCrashProb(varargin)
    % Parse inputs
    p = inputParser;
    addRequired(p, 'data');
    addRequired(p, 'eqTypes');
    addParameter(p, 'display', true, @islogical);
    addParameter(p, 'serialize', false, @islogical);
    parse(p, varargin{:});

    data = p.Results.data;
    eqTypes = p.Results.eqTypes;
    display = p.Results.display;
    serialize = p.Results.serialize;

    % Calculate crash prob at each value of beta
    crashProbs = zeros(1, data.granularity);
    syms P;

    crashProbs(eqTypes.SCNCUC) = data.crashProbFn(0);
    crashProbs(eqTypes.SCNCUI) = data.Pvu(eqTypes.SCNCUI);
    crashProbs(eqTypes.SCNCUR) = arrayfun(@(b) ...
        double(...
            vpasolve(P == data.crashProbFn((1 - ...
                b*P*(data.trueSignalProbFn(data.V2VMass) - data.falseSignalProbFn(data.V2VMass)) - ...
                b*data.falseSignalProbFn(data.V2VMass)) * data.V2VMass))...
            ), ...
        data.beta(eqTypes.SCNCUR));
    crashProbs(eqTypes.SCNIUR) = data.Pn;
    crashProbs(eqTypes.SCNRUR) = arrayfun(@(b) ...
        double(...
            vpasolve(P == data.crashProbFn(1 - ...
                (b*P*(data.trueSignalProbFn(data.V2VMass) - data.falseSignalProbFn(data.V2VMass)) - ...
                b*data.falseSignalProbFn(data.V2VMass)) * data.V2VMass))...
            ), ...
        data.beta(eqTypes.SCNRUR));
    crashProbs(eqTypes.SINRUR) = data.Pvs;
    crashProbs(eqTypes.SRNRUR) = data.crashProbFn(1);

    % Display calculated crash probs
    if (display)
        figure();
        plot(data.beta, crashProbs, 'LineWidth', 2);
        title("Accident Probability as a Function of $\beta$");
        xlabel("$\beta$");
        ylabel("$P(G)$");
    
        FormatPlot(gca);
    
        if (serialize)
            saveas(gcf, 'CrashProbParadox', 'epsc');
        end
    end
end

function socialCosts = DispSocialCost(varargin)
    % Parse inputs
    p = inputParser;
    addRequired(p, 'data');
    addRequired(p, 'eqTypes');
    addRequired(p, 'crashProbs')
    addParameter(p, 'display', true, @islogical);
    addParameter(p, 'serialize', false, @islogical);
    parse(p, varargin{:});

    data = p.Results.data;
    eqTypes = p.Results.eqTypes;
    crashProbs = p.Results.crashProbs;
    display = p.Results.display;
    serialize = p.Results.serialize;

    % Calculate social cost at each value of beta
    socialCosts = zeros(1, data.granularity);
    falseSignalProb = data.falseSignalProbFn(data.V2VMass);
    trueSignalProb = data.trueSignalProbFn(data.V2VMass);

    socialCosts(eqTypes.SCNCUC) = 1 - crashProbs(eqTypes.SCNCUC);
    temp = data.crashCost.*(1-data.beta.*trueSignalProb) ./ ...
        (1 + data.crashCost.*(1-data.beta.*trueSignalProb) - data.beta.*falseSignalProb);
    socialCosts(eqTypes.SCNCUI) = temp(eqTypes.SCNCUI);
    temp = 1 - data.V2VMass - crashProbs*...
        (1-data.V2VMass-data.crashCost*data.V2VMass) + data.beta.*data.V2VMass.*...
        (falseSignalProb - crashProbs.*...
        (falseSignalProb + data.crashCost.*trueSignalProb));
    socialCosts(eqTypes.SCNCUR) = temp(eqTypes.SCNCUR);
    temp = data.crashCost.*...
        (1 - data.V2VMass.*data.beta.*(trueSignalProb-falseSignalProb)).*...
        data.Pn;
    socialCosts(eqTypes.SCNIUR) = temp(eqTypes.SCNIUR);
    temp = data.crashCost.*crashProbs + data.beta.*data.V2VMass.*...
        (falseSignalProb - crashProbs.*...
        (falseSignalProb + data.crashCost.*trueSignalProb));
    socialCosts(eqTypes.SCNRUR) = temp(eqTypes.SCNRUR);
    socialCosts(eqTypes.SINRUR) = data.crashCost.*falseSignalProb ./ ...
        (falseSignalProb + data.crashCost.*trueSignalProb);
    socialCosts(eqTypes.SRNRUR) = data.crashCost * data.crashProbFn(1);

    % Display social cost
    if (display)
        fig = figure();
        plot(data.beta, socialCosts, 'LineWidth', 2);
        FormatPlot(gca);
        
        title("Social Cost as a Function of $\beta$");
        xlabel("$\beta$");
        ylabel("$S(G)$");

        if (serialize)
            saveName = "SCPeak" + datestr(now,'dd-mm-yy_HH:MM:SS');
            saveas(fig, saveName, 'epsc');
        end
    end
end

function DispCrashProbSocialCost(data, crashProbs, socialCosts, serialize)
    figure();

    yyaxis left;
    plot(data.beta, socialCosts, 'LineWidth', 2);
    ylabel("Social Cost");
    yyaxis right;
    plot(data.beta, crashProbs, 'LineWidth', 2, 'LineStyle', '--');
    ylabel("Accident Probability");
    
    title("Social Cost / Accident Probability Conflict");
    xlabel("$\beta$");
    legend("$S(G)$", "$P(G)$");
    
    FormatPlot(gca);
    yyaxis left;
    FormatPlot(gca);
    
    if (serialize)
        saveas(gcf, 'SocialCostConflict', 'epsc');
    end
end
