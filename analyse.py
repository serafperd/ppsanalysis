import mne
import numpy as np
import pymatreader
import platform
import read
import glob
import classify
import copy
import matplotlib.pyplot as plt
import seaborn as sns

if platform.system() == 'Windows':
    # dataFolder = 'F:/UniBox/Box/myBox/data/pps/Processed/Processed'
    dataFolder = 'C:/Users/shalder/Box/myBox/data/pps/Processed/Processed'
else:
    dataFolder = '/Users/shalder/Library/CloudStorage/Box-Box/myBox/data/pps/Processed/Processed'

curP = 'DD'
runs = glob.glob(dataFolder + '/' + curP + '/*.mat')
mnePD = read.read(runs)

epochs = mne.concatenate_epochs(mnePD)

evokedsA = dict(
    AC=list(epochs["AC"].iter_evoked()),
    AF=list(epochs["AF"].iter_evoked()),
)

evokedsT = dict(
    TAC=list(epochs["TAC"].iter_evoked()),
    TAF=list(epochs["TAF"].iter_evoked()),
)

sns.set_context("paper")
fig, axes = plt.subplots(
    nrows=2, ncols=2, figsize=(15.0, 5), gridspec_kw=dict(height_ratios=[3, 4])
)
mne.viz.plot_compare_evokeds(evokedsA, combine="median", axes=axes[0,0])
mne.viz.plot_compare_evokeds(evokedsA, combine="gfp", axes=axes[0,1])

mne.viz.plot_compare_evokeds(evokedsT, combine="median", axes=axes[1,0])
mne.viz.plot_compare_evokeds(evokedsT, combine="gfp", axes=axes[1,1])

# add subplot labels
for sax, slab in zip(axes,["AB", "CD"]):
    for ax, label in zip(sax, slab):
        ax.text(
            ax.get_position().xmin-0.05,
            ax.get_position().ymax,
            label,
            transform=fig.transFigure,
            fontsize=16,
            fontweight="bold",
            va="top",
            ha="left",
        )
sns.despine(offset=5, trim=True)
fig.savefig("figures//figERP" + curP + ".png", bbox_inches='tight')

modes = ["TACvsTAF", "ACvsAF", "TACACvsTAFAF", "All"]
classifiers = ['LDA', 'Ridge', 'Logistic', 'LogisticXDawn', 'Riemann']
accs, cm = classify.classify(copy.deepcopy(mnePD), modes[3], classifiers[3], [0.0, 0.8])