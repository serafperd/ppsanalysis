import read
import classify
import platform
import glob
import copy
import numpy as np
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

def main():
    if platform.system() == 'Windows':
        # dataFolder = 'F:/UniBox/Box/myBox/data/pps/Processed/Processed'
        dataFolder = 'C:/Users/shalder/Box/myBox/data/pps/Processed/Processed'
    else:
        dataFolder = '/Users/shalder/Library/CloudStorage/Box-Box/myBox/data/pps/Processed/Processed'

    patients = glob.glob(dataFolder + '/' + '*')
    # patients = patients[0:1]
    dfAccs = pd.DataFrame(columns=['Patient', 'Run', 'Mode', 'Accuracy'])
    dfCM = pd.DataFrame(columns=['Patient', 'Run', 'Mode', 'Row', 'Column', 'Accuracy'])

    modes = ["TACvsTAF", "ACvsAF", "TACACvsTAFAF", "All"]
    classifiers = ['LDA', 'Ridge', 'Logistic', 'LogisticXDawn', 'Riemann']
    classifierID = 4
    for curI, curP in enumerate(patients):
        runs = glob.glob(curP + '/*.mat')
        mnePD = read.read(runs)
        if mnePD == []:
            continue
        for curMI, curM in enumerate(modes):
            accs, cm = classify.classify(copy.deepcopy(mnePD), curM, classifiers[classifierID])
            if platform.system() == 'Windows':
                for curIR, curR in enumerate(accs):
                    dfAccs = pd.concat([dfAccs, pd.DataFrame([{'Patient': curP.split('\\')[-1], 'Run': curIR, 'Mode': curM, 'Accuracy': accs[curIR]}])], ignore_index=True)
                    for curCMIR in range(cm.shape[0]):
                        for curCMIC in range(cm.shape[1]):
                            dfCM = pd.concat([dfCM, pd.DataFrame([{'Patient': curP.split('\\')[-1], 'Run': curIR, 'Mode': curM, 'Row': curCMIR, 'Column': curCMIC, 'Accuracy': cm[curCMIR][curCMIC]}])], ignore_index=True)
            else:
                for curIR, curR in enumerate(accs):
                    dfAccs = pd.concat([dfAccs, pd.DataFrame([{'Patient': curP.split('/')[-1], 'Run': curIR, 'Mode': curM, 'Accuracy': accs[curIR]}])], ignore_index=True)
                    for curCMIR in range(cm.shape[0]):
                        for curCMIC in range(cm.shape[1]):
                            dfCM = pd.concat([dfCM, pd.DataFrame([{'Patient': curP.split('/')[-1], 'Run': curIR, 'Mode': curM, 'Row': curCMIR, 'Column': curCMIC, 'Accuracy': cm[curCMIR][curCMIC]}])], ignore_index=True)
                    # dfAccs.append()
                    # dfAccs.loc[curI+curIR] = [curP.split('\\')[-1], curIR, accs[curIR]]

    dfAccs.to_pickle("PPSaccs" + classifiers[classifierID] + ".pkl")
    sns.set_context("paper")
    fig = plt.figure(tight_layout=True, figsize=(20, 4))
    sns.boxplot(x='Patient', y='Accuracy', hue='Mode', data=dfAccs)
    sns.despine(offset=10, trim=True)
    fig.savefig("figures//figSummary_" + classifiers[classifierID] + ".png", bbox_inches='tight')

if __name__ == '__main__':
    main()