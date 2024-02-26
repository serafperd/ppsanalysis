import mne
import numpy as np
import pymatreader
import platform

def read(runs):
    pps = []
    ch_names = ['Fz',
                'FC3',
                'FC1',
                'FCz',
                'FC2',
                'FC4',
                'C3',
                'C1',
                'Cz',
                'C2',
                'C4',
                'CP3',
                'CP1',
                'CPz',
                'CP2',
                'CP4']

    ch_types = ["eeg"] * len(ch_names)
    info = mne.create_info(ch_names, ch_types=ch_types, sfreq=500)
    info.set_montage("standard_1020")



    for curIR, curR in enumerate(runs):
        data = pymatreader.read_mat(curR)
        data['RunOutput']['data']['clean'] = data['RunOutput']['data']['clean']*1e-6
        info = mne.create_info(ch_names, ch_types=ch_types, sfreq=data['RunOutput']['sfreq'])
        info.set_montage("standard_1020")
        events = np.column_stack(
            (
                np.arange(0, len(data['RunOutput']['labels']), 1),
                np.zeros(len(data['RunOutput']['labels']), dtype=int),
                np.array(data['RunOutput']['labels']),
            )
        )

        event_dict = dict(T=10, AC=21, AF=22, TAC=31, TAF=32)
        epochs = mne.EpochsArray(np.transpose(data['RunOutput']['data']['clean'],(0,2,1)), info, tmin=-1.0, events=events, event_id=event_dict)
        epochs.filter(l_freq=1, h_freq=20)
        epochs.crop(-0.5, 1)

        # epochs.apply_baseline((-0.5, 0))
        if platform.system() == 'Windows':
            epochs.info['subject_info'] = dict(name=runs[0].split('\\')[1])
            epochs.info['description'] = curR.split('\\')[-1]
        else:
            epochs.info['subject_info']=dict(name=runs[0].split('/')[-2])
            epochs.info['description']=curR.split('/')[-1]
        pps.append(epochs)

    return pps


