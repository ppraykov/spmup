function spmup_BIDS(folder,options)

% routine to read and unpack BIDS fMRI
% does all the preprocessing with 'options'
% and run the 1st level analyses with 'options'
%
% options.outdir = where th write the data
% options.preprocess = a structure with preprocessing options
% options.preprocess.despiking
% options.preprocess.despiking.window
% options.preprocess.drifter
% options.preprocess.drifter

if nargin == 0
    BIDS_dir= uigetdir(pwd,'select BIDS directory');
    if BIDS_dir == 0
        return
    end
end

if nargin == 0 || nargin == 1
    options = get_all_options(BIDS_dir);
end

%% get the data info
% -------------------------------------------------------------------------
BIDS = spm_BIDS(BIDS_dir);

%% unpack data
% -------------------------------------------------------------------------
if ~isfield(options,'outdir')
    options.outdir = [BIDS_dir filesep 'spmup_BIDS_processed'];
end

mkdir(options.outdir);
disp('unpacking anatomical data')
parfor s=1:size(BIDS.subjects,2)
    % when encountering longitinal dataset this needs updated for 'session'
    in = [BIDS.dir filesep BIDS.subjects(s).name filesep 'anat' filesep BIDS.subjects(s).anat(run).filename];
    out = [options.outdir filesep BIDS.subjects(s).name filesep 'anat' filesep BIDS.subjects(s).anat(run).filename(1:end-3)];
    gunzip(in, out);
end

disp('unpacking functional data')
parfor s=1:size(BIDS.subjects,2)
    for run = 1:size(BIDS.subjects(s).func,2)
        in = [BIDS.dir filesep BIDS.subjects(s).name filesep 'func' filesep BIDS.subjects(s).func(run).filename];
        out = [options.outdir filesep BIDS.subjects(s).name filesep 'run' num2str(run) filesep BIDS.subjects(s).func(run).filename(1:end-3)];
        gunzip(in, out);
    end
end

if ~isempty(BIDS.subjects(1).fmap)
    disp('unpacking field maps')
end

parfor s=1:size(BIDS.subjects,2)
    % once encountering longitinal dataset this needs update for 'session'
    for run = 1:size(BIDS.subjects(s).fmap,2)
        for f=1:size(BIDS.subjects(s).fmap(run).filenames,1)
            in = [BIDS.dir filesep BIDS.subjects(s).name filesep 'fmap' filesep BIDS.subjects(s).fmap(run).filenames{f}];
            out = [options.outdir filesep BIDS.subjects(s).name filesep 'run' num2str(run) filesep 'fieldmaps' filesep BIDS.subjects(s).fmap(run).filenames{f}(1:end-3)];
            gunzip(in, out);
        end
    end
end

%% run preprocessing using options
% -------------------------------------------------------------------------
global defaults
defaults = spm_get_defaults;

if isfield(options.preprocess,'despiking')
    if isfield(options.preprocess.despiking,'window')
        window_size = options.preprocess.despiking.window;
    else
        window_size = [];
    end
    
    flags = struct('auto_mask','on','method','median','window',window_size);
    for s=1:size(BIDS.subjects,2)
        for run = 1:size(BIDS.subjects(s).func,2)
            [~,file,ext]=fileparts(BIDS.subjects(s).func(run).filename);
            pth = [options.outdir filesep BIDS.subjects(s).name filesep 'run' num2str(run) filesep file];
            in = [pth filesep file];
            cd(pth); spmup_despike(in,[],flags);
            delete(in); cd(BIDS_dir);
        end
    end
end




end

%% helper functions
% -------------------------------------------------------------------------
function options = get_all_options(BIDS_dir)
% routine that returns all available options

% despiking
preprocess_options.despiking.window = [];
preprocess_options.drifter = [];

options = struct('outdir',[BIDS_dir filesep 'spmup_BIDS_processed'], ...
    'preprocess',preprocess_options);
end


