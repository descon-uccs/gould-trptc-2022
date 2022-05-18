function FormatPlot(ax)
%FormatPlot Formats a plot with LaTeX interpreters
ax.XLabel.Interpreter = "latex";
ax.XLabel.FontSize = 12;
ax.XAxis.TickLabelInterpreter = "latex";
ax.XAxis.FontSize = 15;

ax.YLabel.Interpreter = "latex";
ax.YLabel.FontSize = 12;
[ax.YAxis(:).TickLabelInterpreter] = deal("latex");
[ax.YAxis(:).FontSize] = deal(15);

ax.Title.Interpreter = "latex";
ax.Title.FontSize = 18;

try
    ax.Legend.Interpreter = "latex";
catch
    warning('Attempting to format a nonexistent legend');
end

ax.Parent.Color = [1, 1, 1];
end
