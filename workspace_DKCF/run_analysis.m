% This script can be used to perform a comparative analyis of the experiments
% in the same manner as for the VOT challenge
% You can copy and modify it to create a different analyis

addpath('/raid/hustxly/VOT/VOT-Tracker'); toolkit_path; % Make sure that VOT toolkit is in the path

[sequences, experiments] = workspace_load();

trackers = tracker_list('DeepKCF', 'TODO'); % TODO: add more trackers here

context = create_report_context('report_vot2016_DeepKCF');

report_article(context, experiments, trackers, sequences, 'spotlight', 'DeepKCF'); % This report is more suitable for results included in a paper

% report_challenge(context, experiments, trackers, sequences); % Use this report for official challenge report
% report_visualization(context, experiments, trackers, sequences);  % Use this report to generate images of visual (bounding box) results of trackers