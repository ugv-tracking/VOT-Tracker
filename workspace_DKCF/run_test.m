% This script can be used to test the integration of a tracker to the
% framework.

addpath('/raid/hustxly/VOT/VOT-Tracker'); toolkit_path; % Make sure that VOT toolkit is in the path

[sequences, experiments] = workspace_load();

tracker = tracker_load('DeepKCF');

workspace_test(tracker, sequences);

