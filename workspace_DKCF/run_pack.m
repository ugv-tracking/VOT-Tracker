% This script can be used to pack the results and submit them to a challenge.

addpath('/raid/hustxly/VOT/VOT-Tracker'); toolkit_path; % Make sure that VOT toolkit is in the path

[sequences, experiments] = workspace_load();

tracker = tracker_load('DeepKCF');

workspace_submit(tracker, sequences, experiments);

