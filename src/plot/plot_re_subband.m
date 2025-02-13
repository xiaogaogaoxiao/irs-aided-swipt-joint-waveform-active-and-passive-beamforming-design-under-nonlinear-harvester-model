clear; clc; close all; config_re_subband;

%% * Load batch data
indexSet = 1 : nBatches;
reSet = cell(nBatches, length(Variable.nSubbands));
infoAmplitudeSet = cell(nBatches, length(Variable.nSubbands));
powerAmplitudeSet = cell(nBatches, length(Variable.nSubbands));
for iBatch = 1 : nBatches
    try
        load(sprintf('../data/re_subband/re_subband_%d.mat', iBatch), 'reAoInstance', 'reAoSolution');
		reSet(iBatch, :) = reAoInstance;
		for iSubband = 1 : length(Variable.nSubbands)
			infoAmplitudeSet{iBatch, iSubband} = sort(reAoSolution{iSubband}{end}.infoAmplitude);
			powerAmplitudeSet{iBatch, iSubband} = sort(reAoSolution{iSubband}{end}.powerAmplitude);
		end
    catch
		indexSet(indexSet == iBatch) = [];
        disp(iBatch);
    end
end

%% * Average over batches
reSubband = cell(1, length(Variable.nSubbands));
infoAmplitude = cell(1, length(Variable.nSubbands));
powerAmplitude = cell(1, length(Variable.nSubbands));
for iSubband = 1 : length(Variable.nSubbands)
	reSubband{iSubband} = mean(cat(3, reSet{indexSet, iSubband}), 3);
	infoAmplitude{iSubband} = mean(cat(3, infoAmplitudeSet{indexSet, iSubband}), 3);
	powerAmplitude{iSubband} = mean(cat(3, powerAmplitudeSet{indexSet, iSubband}), 3);
end
save('../data/re_subband.mat');

%% * R-E plots
figure('name', 'R-E region vs number of subbands', 'position', [0, 0, 500, 400]);
legendString = cell(1, length(Variable.nSubbands) + 2);
plotHandle = gobjects(1, length(Variable.nSubbands) + 2);
hold all;
for iSubband = 1 : length(Variable.nSubbands)
    plotHandle(iSubband) = plot(reSubband{iSubband}(1, :) / Variable.nSubbands(iSubband), 1e6 * reSubband{iSubband}(2, :));
    legendString{iSubband} = sprintf('PS: $N = %d$', Variable.nSubbands(iSubband));
end

% * Optimal strategy for medium number of subbands (TS + PS)
subbandIndex = 4;
optIndex = convhull(transpose([0, reSubband{subbandIndex}(1, :) / Variable.nSubbands(subbandIndex); 0, 1e6 * reSubband{subbandIndex}(2, :)])) - 1;
optIndex = optIndex(2 : end - 1);
plotHandle(iSubband + 1) = plot(reSubband{subbandIndex}(1, optIndex) / Variable.nSubbands(subbandIndex), 1e6 * reSubband{subbandIndex}(2, optIndex), 'r');
legendString{iSubband + 1} = sprintf('TS + PS: $N = %d$', Variable.nSubbands(subbandIndex));

% * Optimal strategy for large number of subbands (TS)
subbandIndex = 5;
plotHandle(iSubband + 2) = plot([reSubband{subbandIndex}(1, end) / Variable.nSubbands(subbandIndex), reSubband{subbandIndex}(1, 1) / Variable.nSubbands(subbandIndex)], [1e6 * reSubband{iSubband}(2, end), 1e6 * reSubband{iSubband}(2, 1)], 'k');
legendString{iSubband + 2} = sprintf('TS: $N = %d$', Variable.nSubbands(subbandIndex));
hold off;
grid on;
legend(legendString);
xlabel('Per-subband rate [bps/Hz]');
ylabel('DC current [$\mu$A]');
xlim([0 inf]);
ylim([0 inf]);
box on;
apply_style(plotHandle);

savefig('../figures/re_subband.fig');
matlab2tikz('../../assets/re_subband.tex', 'extraaxisoptions', ['title style={font=\huge}, ' 'label style={font=\huge}, ' 'ticklabel style={font=\LARGE}, ' 'legend style={font=\LARGE}']);
close;

%% * Waveform amplitude
figure('name', 'Sorted waveform amplitude vs number of subbands', 'position', [0, 0, 500, 400]);
waveformPlot = tiledlayout(length(Variable.nSubbands), 1, 'tilespacing', 'compact');
for iSubband = 1 : length(Variable.nSubbands)
	nexttile;
	hold all;
	stem(1 : Variable.nSubbands(iSubband), infoAmplitude{iSubband}, 'marker', 'o');
    stem(1 : Variable.nSubbands(iSubband), powerAmplitude{iSubband}, 'marker', 'x');
	xlim([0 Variable.nSubbands(iSubband) + 1]);
	ylim([0 inf]);
    xticks(1 : Variable.nSubbands(iSubband));
	hold off;
	grid on;
    if iSubband == 1
		legend('{\boldmath${s}$}$_{\mathrm{I}}$', '{\boldmath${s}$}$_{\mathrm{P}}$', 'location', 'northoutside', 'orientation', 'horizontal');
	elseif iSubband == 3
		ylabel('Waveform amplitude');
	elseif iSubband == 4
        yticks([0 1]);
	elseif iSubband == 5
        yticks([0 1]);
    end
    box on;
end
xlabel('Sorted subband index');

savefig('../figures/waveform_subband.fig');
matlab2tikz('../../assets/waveform_subband.tex', 'extraaxisoptions', ['title style={font=\huge}, ' 'label style={font=\huge}, ' 'ticklabel style={font=\LARGE}, ' 'legend style={font=\LARGE}']);
