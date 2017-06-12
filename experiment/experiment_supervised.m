function [files, metadata] = experiment_supervised(tracker, sequence, directory, parameters, scan)

files = {};
metadata.completed = true;
cache = get_global_variable('experiment_cache', true);
silent = get_global_variable('experiment_silent', false);

defaults = struct('repetitions', 15, 'skip_tags', {{}}, 'skip_initialize', 0, 'failure_overlap', 0);
context = struct_merge(parameters, defaults);
metadata.deterministic = false;

if context.failure_overlap < 0
    error('Illegal failure overlap');
end;

time_file = fullfile(directory, sprintf('%s_time.txt', sequence.name));

times = zeros(sequence.length, context.repetitions);

if ~scan && cache && exist(time_file, 'file')
    times = csvread(time_file);
end;

r = context.repetitions;

if isfield(tracker, 'metadata') && isfield(tracker.metadata, 'deterministic') && tracker.metadata.deterministic
    r = 1;
end

check_deterministic = ~(scan && nargout < 2); % Ensure faster execution when we only want a list of files by ommiting determinisim check.

for i = 1:r

    result_file = fullfile(directory, sprintf('%s_%03d.txt', sequence.name, i));

    if cache && exist(result_file, 'file')
        files{end+1} = result_file; %#ok<AGROW>
        continue;
    end;

    if check_deterministic && i == 4 && is_deterministic(sequence, 3, directory)
        if ~silent
            print_debug('Detected a deterministic tracker, skipping remaining trials.');
        end;
        metadata.deterministic = true;
        break;
    end;

    if scan
        metadata.completed = false;
        continue;
    end;

    print_indent(1);

    print_text('Repetition %d', i);

    context.repetition = i;

    data.sequence = sequence;
    data.index = 1;
    data.context = context;
    data.result = repmat({0}, sequence.length, 1);
    data.timing = nan(sequence.length, 1);
    data.initialized = false;

    data = tracker_run(tracker, @callback, data);

    times(:, i) = data.timing;
    write_trajectory(result_file, data.result);
    csvwrite(time_file, times);

    print_indent(-1);
end;

if exist(time_file, 'file')
    files{end+1} = time_file;
else
    metadata.completed = false;
end;

end

function [image, region, properties, data] = callback(state, data)

region = [];
image = [];
properties = struct();

% Handle initial frame (initialize for the first time)
if isempty(state.region)
    region = data.sequence.initialize(data.sequence, data.index, data.context);
    image = get_image(data.sequence, data.index);
    return;
end;
o = region_overlap(state.region, get_region(data.sequence, data.index));

% Handle tracker failure
if o(1) <= data.context.failure_overlap
    data.result{data.index} = 2;
    data.timing(data.index) = state.time;

    start = data.index + data.context.skip_initialize;

    if ~isempty(data.context.skip_tags)
	    data.index = data.sequence.length + 1; % Set to terminate position
        for i = start:data.sequence.length
            if isempty(intersect(get_tags(data.sequence, i), data.context.skip_tags))
                data.index = i; % Frame is valid, can be used for initializaiton
                break;
            end;
        end;
	else
		data.index = start;
    end;

    if data.index > data.sequence.length
        return;
    end

    region = data.sequence.initialize(data.sequence, data.index, data.context);
    image = get_image(data.sequence, data.index);
    data.initialized = false;
    return;
end;

% Store initialization
if ~data.initialized
    data.result{data.index} = 1;
    data.initialized = true;
else
    data.result{data.index} = state.region;
end;
data.timing(data.index) = state.time;

data.index = data.index + 1;

% End of sequence
if data.index > data.sequence.length
    return;
end

image = get_image(data.sequence, data.index);

end

