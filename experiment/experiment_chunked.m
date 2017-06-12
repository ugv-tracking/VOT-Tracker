function [files, metadata] = experiment_chunked(tracker, sequence, directory, parameters, scan)

    scan = false;
    files = {};
    metadata.completed = true;
    cache = get_global_variable('experiment.cache', 0);
    silent = get_global_variable('experiment.silent', 0);

    defaults = struct('repetitions', 15, 'failure_overlap',  -1, 'chunk_length', 50);
    context = struct_merge(parameters, defaults);
    metadata.deterministic = false;

    [chunks, chunk_offset] = sequence_fragment(sequence, context.chunk_length);

    time_file = fullfile(directory, sprintf('%s_time.txt', sequence.name));

    times = zeros(sequence.length, context.repetitions);

    if ~scan && cache && exist(time_file, 'file')
        times = csvread(time_file);
    end;

	r = context.repetitions;

	if isfield(tracker, 'metadata') && isfield(tracker.metadata, 'deterministic') && tracker.metadata.deterministic
		r = 1;
	end

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

        trajectory = cell(sequence.length, 1);
        time = zeros(sequence.length, 1);

        for c = 1:numel(chunks)

			data.sequence = chunks{c};
			data.index = 1;
			data.context = context;
			data.result = repmat({0}, chunks{c}.length, 1);
			data.timing = nan(chunks{c}.length, 1);

			data = tracker_run(tracker, @callback, data);

            [chunk_trajectory, chunk_time] = tracker.run(tracker, chunks{c}, context);

            trajectory(chunk_offset(c):chunk_offset(c)+numel(chunk_trajectory)-1) = data.result;
            time(chunk_offset(c):chunk_offset(c)+numel(chunk_trajectory)-1) = data.timing;

        end;

		times(:, i) = time;
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
	if isempty(state.region))
		region = data.sequence.initialize(data.sequence, data.index, data.context);
		image = get_image(data.sequence, data.index);
		return;
	end;

	% Handle tracker failure
	if region_overlap(state.region, get_region(data.sequence, data.index) <= data.context.failure_overlap
		return;
	end;

	% Store initialization
	if data.index == 1
		data.result{data.index} = 1;
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

