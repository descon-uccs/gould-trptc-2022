function DispEqs(data, eqs, socialCosts, crashProbs)
     figure('Name', 'Results', 'NumberTitle', 'off', 'WindowState', 'maximized');

    % Show where each type of equilibrium occurs
    subplot(2, 2, 1);
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
    legend();
    
    FormatPlot(gca);
    
    % show social cost at equilibrium
    subplot(2, 2, 2);
    hold on;
    surf(data.V2VMat, data.costMat, socialCosts.careful, 'FaceColor', 'Blue', 'EdgeColor', 'none');
    surf(data.V2VMat, data.costMat, socialCosts.reckless, 'FaceColor', 'Red', 'EdgeColor', 'none');
    surf(data.V2VMat, data.costMat, socialCosts.total, 'EdgeColor', 'none');
    zlim([0, 1]); % I don't think we are guaranteed that costs will be less than 1...

    xlabel('V2V Mass');
    ylabel('Crash Cost');
    title('Social Cost at Equilibrium');
    legend('Regret Cost', 'Crash Cost', 'Total Cost');
    view(20, 30);
    
    FormatPlot(gca);
    
    % show crash probability at equilibrium
    subplot(2, 2, 3);
    surf(data.V2VMat, data.costMat, crashProbs, 'EdgeColor', 'None');
    
    xlabel('V2V Mass');
    ylabel('Crash Cost');
    title('Crash Probability at Equilibrium');
    view(20, 30);
    
    FormatPlot(gca);
    
    showUI(data, eqs);
end

function showUI(data, eqs)
    % Main figure and layout
    uifig = uifigure('Name', 'View Eq. Details');
    uifig.Position(3:4) = [450, 250];
    movegui(uifig, 'northwest');

    g = uigridlayout(uifig, [3, 2]);
    g.RowHeight = {30, '1x', 30};
    g.ColumnWidth = {'1x', '1x'};

    % Label + dropdown to select type of equilibrium
    eqLbl = uilabel(g, 'Text', 'Equilibrium Type:');
    eqLbl.Layout.Row = 1;
    eqLbl.Layout.Column = 1;
    eqLbl.FontSize = 20;

    eqDD = uidropdown(g, 'Items', arrayfun(@(eq) eq.name, eqs, 'UniformOutput', false));
    eqDD.Layout.Row = 1;
    eqDD.Layout.Column = 2;
    eqDD.ItemsData = eqs;

    % Panel to select options about how to view
    viewOptionsPanel = uipanel(g, 'Title', 'View Options');
    viewOptionsPanel.FontSize = 15;
    viewOptionsPanel.Layout.Row = 2;
    viewOptionsPanel.Layout.Column = [1, 2];

    vopg = uigridlayout(viewOptionsPanel, [1, 2]);
    vopg.ColumnWidth = {'1x', '1x'};

    % Panel for options on crash prob graph
    crashProbOptionsPanel = uipanel(vopg, 'Title', 'Crash Prob. Options');
    crashProbOptionsPanel.FontSize = 15;

    cpopg = uigridlayout(crashProbOptionsPanel, [3, 1]);
    cpopg.RowHeight = {'1x', '1x', '1x'};

    cpLoBoundCbx = uicheckbox(cpopg, 'Text', 'Crash Prob. Lo Bound');
    cpHiBoundCbx = uicheckbox(cpopg, 'Text', 'Crash Prob. Hi Bound');
    spCbx = uicheckbox(cpopg, 'Text', 'Signal Probability');

    % Panel for options on social cost graph
    socialCostOptionsPanel = uipanel(vopg, 'Title', 'Social Cost Options');
    socialCostOptionsPanel.FontSize = 15;

    scopg = uigridlayout(socialCostOptionsPanel, [2, 1]);
    scopg.RowHeight = {'1x', '1x'};

    scCarefulCbx = uicheckbox(scopg, 'Text', 'Social Cost due to Careful');
    scRecklessCbx = uicheckbox(scopg, 'Text', 'Social Cost due to Reckless');

    % Button to generate equilibrium graphs
    eqBtn = uibutton(g);
    eqBtn.Layout.Row = 3;
    eqBtn.Layout.Column = 2;
    eqBtn.Text = 'View';
    eqBtn.ButtonPushedFcn = @(btn, event) showEq(data, eqDD.Value, ...
        cpLoBoundCbx.Value, cpHiBoundCbx.Value, spCbx.Value, ...
        scCarefulCbx.Value, scRecklessCbx.Value);
end 

function showEq(data, eq, showCrashProbLoBound, showCrashProbHiBound, showSignalProb, ...
    showCarefulSC, showRecklessSC)
    figure('Name', eq.name, 'NumberTitle', 'off');
    
    % show info about what drivers are doing
    subplot(2, 2, 1);
    hold on;
    surf(data.V2VMat, data.costMat, eq.xvs, 'FaceColor', 'Blue', 'EdgeColor', 'none');
    surf(data.V2VMat, data.costMat, eq.xn, 'FaceColor', 'Yellow', 'EdgeColor', 'none');
    surf(data.V2VMat, data.costMat, eq.xvu, 'FaceColor', 'Red', 'EdgeColor', 'none');
%     surf(data.V2VMat, data.costMat, V2VMat, 'FaceColor', 'Yellow', 'EdgeColor', 'none');
    
    xlabel('V2V Mass');
    ylabel('Crash Cost');
    title('Reckless Drivers');

    legend('Signaled V2V', 'Non-V2V', 'Unsignaled V2V');
    view(-40, 30);
    
    FormatPlot(gca);
    
    % show info about accident / signal probabilities
    subplot(2, 2, 2);
    hold on;
    crashProbLegendLabels = ["Crash Prob"];
    
    surf(data.V2VMat, data.costMat, eq.crashProb, 'FaceColor', 'Red', 'EdgeColor', 'none');
    if(showCrashProbLoBound)
        surf(data.V2VMat, data.costMat, eq.loBound, 'FaceColor', 'Green', 'EdgeColor', 'none');
        crashProbLegendLabels(end+1) = "Lo Bound";
    end
    if(showCrashProbHiBound)
        surf(data.V2VMat, data.costMat, eq.hiBound, 'FaceColor', 'Yellow', 'EdgeColor', 'none');
        crashProbLegendLabels(end+1) = "Hi Bound";
    end
    if(showSignalProb)
        surf(data.V2VMat, data.costMat, eq.signalProb, 'FaceColor', 'Blue', 'EdgeColor', 'none');
        crashProbLegendLabels(end+1) = "Signal Prob";
    end
    
    xlabel('V2V Mass');
    ylabel('Crash Cost');
    title('Event Probability');

    legend(crashProbLegendLabels);
    view(-40, 30);
    
    FormatPlot(gca);
    
    % show equilibrium's social cost
    subplot(2, 2, 3);
    socialCostLegendLabels = ["Social Cost"];
    
    hold on;
    surf(data.V2VMat, data.costMat, eq.socialCost, 'EdgeColor', 'none');
    if (showCarefulSC)
        surf(data.V2VMat, data.costMat, eq.scc, 'FaceColor', 'Blue', 'EdgeColor', 'none');
        socialCostLegendLabels(end+1) = "Regret Cost";
    end
    if (showRecklessSC)
        surf(data.V2VMat, data.costMat, eq.scr, 'FaceColor', 'Red', 'EdgeColor', 'none');
        socialCostLegendLabels(end+1) = "Crash Cost";
    end

    xlabel('V2V Mass');
    ylabel('Crash Cost');
    title('Social Cost');
    
    legend(socialCostLegendLabels);
    view(-40, 30);
    
    FormatPlot(gca);
    
    % show info about when the equilibrium is valid
    subplot(2, 2, 4);
    surf(data.V2VMat, data.costMat, double(eq.idx), 'EdgeColor', 'none');
    
    xlabel('V2V Mass');
    ylabel('Crash Cost');
    title('Exists?');
    
    view(2);
    
    FormatPlot(gca);
end
