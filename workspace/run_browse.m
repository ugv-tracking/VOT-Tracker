% This script can be used to interactively inspect the results

addpath('/home/zhizhen/Academic/I-DeepTracking/Benchmark/VOT2016/vot-toolkit'); toolkit_path; % Make sure that VOT toolkit is in the path

[sequences, experiments] = workspace_load();

trackers = tracker_load('DNT');

workspace_browse(trackers, sequences, experiments);

