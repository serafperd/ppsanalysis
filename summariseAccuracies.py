import platform
import glob
import copy
import numpy as np
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt


accuracies = glob.glob('./' + 'PPS*.pkl')
dfAccs = pd.DataFrame(columns=['Patient', 'Run', 'Mode', 'Accuracy', 'Classifier'])
for curAI, curA in enumerate(accuracies):
    dfCur = pd.read_pickle(curA)
    dfCur = dfCur.assign(Classifier=[curA.split("PPSaccs")[1][:-4]]*dfCur.shape[0])
    dfAccs = pd.concat([dfAccs, dfCur])

    sns.set_context("paper")
    fig = plt.figure(tight_layout=True, figsize=(4, 8))
    sns.boxplot(x='Classifier', y='Accuracy', hue='Mode', data=dfAccs)
    sns.despine(offset=10, trim=True)
    fig.savefig("figures//figSummaryAllAccs.png", bbox_inches='tight')
