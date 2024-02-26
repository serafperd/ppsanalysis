import matplotlib.pyplot as plt
import numpy as np
from sklearn.discriminant_analysis import LinearDiscriminantAnalysis
from sklearn.linear_model import RidgeClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, confusion_matrix
from sklearn.model_selection import StratifiedKFold
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import MinMaxScaler
from sklearn.decomposition import PCA


from mne.decoding import Vectorizer
from mne.preprocessing import Xdawn
from mne.decoding import UnsupervisedSpatialFilter
import mne


from pyriemann.estimation import XdawnCovariances
from pyriemann.tangentspace import TangentSpace
from pyriemann.classification import MDM, TSclassifier
from pyriemann.estimation import Covariances

def classify(data, mode, classifier, time):

    if classifier=='LDA':
        clf = make_pipeline(
            Vectorizer(),
            MinMaxScaler(),
            LinearDiscriminantAnalysis(solver="lsqr", shrinkage='auto')
        )
    elif classifier=='Ridge':
        clf = make_pipeline(
            Vectorizer(),
            MinMaxScaler(),
            RidgeClassifier(alpha=1.0, max_iter=1000, solver='auto', tol=1e-3)
        )
    elif classifier=="Logistic":
        clf = make_pipeline(
            # Xdawn(n_components=3),
            Vectorizer(),
            MinMaxScaler(),
            LogisticRegression(penalty="l1", solver="liblinear", multi_class="auto"),
        )
    elif classifier=="LogisticXDawn":
        clf = make_pipeline(
            UnsupervisedSpatialFilter(PCA(8), average=False),
            XdawnCovariances(3),
            Vectorizer(),
            MinMaxScaler(),
            LogisticRegression(penalty="l1", solver="liblinear", multi_class="auto"),
        )
    elif classifier == 'Riemann':
        clf = make_pipeline(
            UnsupervisedSpatialFilter(PCA(8), average=False),
            XdawnCovariances(3, estimator='oas'),
            TangentSpace(metric="riemann"),
            LogisticRegression(penalty='l1', solver='liblinear',
                               multi_class='auto')
        )



    if mode=="All":
        myScores = np.empty((len(data), 5, 5))
    else:
        myScores = np.empty((len(data), 2, 2))
    accs = np.empty(len(data))

    # event_dict = dict(T=10, AC=21, AF=22, TAC=31, TAF=32)
    # modes = ["TACvsTAF", "ACvsAF", "TACACvsTAFAF", "All"]

    for curI, epochs in enumerate(data):
        epochs.crop(time[0], time[1])
        epochs.resample(10)
        if mode=="TACvsTAF":
            epochs = epochs['TAC','TAF']
        elif mode=="ACvsAF":
            epochs = epochs['AC','AF']
        elif mode=="TACACvsTAFAF":
            epochs.events = mne.merge_events(epochs.events, [31,21], 2)
            epochs.events = mne.merge_events(epochs.events, [32,22], 3)
            epochs.event_id = dict(T=10, TACAC=2, TAFAF=3)
            epochs = epochs['TACAC', 'TAFAF']

        labels = epochs.events[:, -1]
        classes = epochs.event_id.keys()
        name = epochs.info['subject_info']['name']
        title = 'Classification ' + classifier + ' ' + name
        if classifier == "LogisticXDawn" or classifier == "Riemann":
           epochs = epochs.get_data()
        # Cross validator
        cv = StratifiedKFold(n_splits=10, shuffle=True, random_state=42)

        # Do cross-validation
        preds = np.empty(len(labels))
        for train, test in cv.split(epochs, labels):
            clf.fit(epochs[train], labels[train])
            preds[test] = clf.predict(epochs[test])

        accs[int(curI)] = np.sum(labels==preds)/len(labels)
        cm = confusion_matrix(labels, preds)
        cm = cm.astype(float) / cm.sum(axis=1)[:, np.newaxis]
        myScores[int(curI), :, :] = cm


    cm = np.mean(myScores, axis=0)
    fig = plt.figure(figsize=(8, 8), dpi=500)

    plt.rcParams.update({'font.size': 11})
    cmap = plt.cm.Blues

    # ax = fig.add_subplot(myRows, myCols, iF+1)
    im = plt.imshow(cm, interpolation='nearest', cmap=cmap, clim=(0,1))


    ax = fig.axes[0]

    # ax.figure.colorbar(im, ax=ax)
    # We want to show all ticks...
    ax.set(xticks=np.arange(cm.shape[1]),
           yticks=np.arange(cm.shape[0]),
           # ... and label them with the respective list entries
           xticklabels=classes, yticklabels=classes,
           title=title,
           ylabel='True label',
           xlabel='Classified label')

    # Rotate the tick labels and set their alignment.
    # ax.set(ax.get_xticklabels(), rotation=0, ha="right",
    #          rotation_mode="anchor")

    # Loop over data dimensions and create text annotations.
    fmt = '.2f'
    thresh = cm.max() / 2.
    for i in range(cm.shape[0]):
        for j in range(cm.shape[1]):
            ax.text(j, i, format(cm[i, j], fmt),
                    ha="center", va="center",
                    color="white" if cm[i, j] > thresh else "black")
    plt.savefig('figures/figClassification_' + classifier + '_' + name + '_' + mode + '.png')
    plt.close('all')
    return accs, cm