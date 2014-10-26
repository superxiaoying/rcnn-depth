args = {};

if strcmp(jobName, 'region_write_window_file')
  p = get_paths(); c = benchmarkPaths();
  NYU_ROOT_DIR = c.dataDir; REGIONDIR = fullfile(p.output_dir, 'regions', 'release-gt-inst');
  SALT = 'region';
  MAX_BOXES = 2000;
  task = 'task-detection-with-cabinet';
  
  spdir = fullfile(p.detection_dir,  'sp');
  sp2regdir = fullfile(p.detection_dir,  'sp2reg')
  imexts = {'png', 'png', 'png'};
  imsets = {'train', 'val'}; 

  channels = 3;
  for i = 2,
    imset = imsets{i}; 
    imdb = imdb_from_nyud2(c.dataDir, imset, task, REGIONDIR, SALT, MAX_BOXES);
    imdb.roidb_func = @roidb_from_nyud2_region;
    roidb = imdb.roidb_func(imdb);
    % write_superpixels_sp2reg(imdb, roidb, spdir, sp2regdir);
    list = {}; 
    for i = 1:length(roidb.rois),
      roi = roidb.rois(i); [ov, label] = max(roi.overlap, [], 2);
      ov(ov < 1e-5) = 0; label(ov < 1e-5) = 0; list{i} = cat(2, label, ov, roi.boxes-1);
    end
    
    imlist = imdb.image_ids;
    imdirs = {p.ft_hha_dir, spdir, sp2regdir};
    window_file = fullfile(p.detection_dir, 'finetuning', 'v1', 'wf', sprintf('ft_hha_%s', imset)); 
    write_window_file(imdirs, imexts, imlist, channels, list, window_file);

    imdirs = {p.ft_image_dir, spdir, sp2regdir};
    window_file = fullfile(p.detection_dir, 'finetuning', 'v1', 'wf', sprintf('ft_rgb_%s', imset)); 
    write_window_file(imdirs, imexts, imlist, channels, list, window_file);
  end
end

if strcmp(jobName, 'vis_regions')
  p = get_paths(); c = benchmarkPaths();
  NYU_ROOT_DIR = c.dataDir; REGIONDIR = fullfile(p.output_dir, 'regions', 'release-gt-inst');
  SALT = 'release-regions';
  MAX_BOXES = 2000;
  task = 'task-detection-with-cabinet';

  trainset = 'img_6449';
  imdb = imdb_from_nyud2(c.dataDir, trainset, task, REGIONDIR, SALT, MAX_BOXES);
  imdb.roidb_func = @roidb_from_nyud2_region;

  roidb = imdb.roidb_func(imdb);
  roi = roidb.rois;
  clss = 5; %[1:20];
  I = getImage(imdb.image_ids{1}, 'images');
  figure(1); imagesc(I);
  for i = clss,
    figure(2);
    [~, ind] = sort(roi.overlap(:,i), 'descend');
    for j = 1:1:100,
      sp2regi = roi.sp2reg(ind(j),:);
      imagesc(sp2regi(roi.sp));
      title(sprintf('%s %0.3f', imdb.classes{i}, roi.overlap(ind(j),i)));
      pause;
    end
  end
end

if strcmp(jobName, 'check_boxes'),
  imset = 'train';
  imlist = getImageSet(imset);
  pt = load(['cache/release/detection/finetuning/v1/wf/ft_hha_' imset '.mat']);
  for i = 1:length(imlist),
    dt = load(fullfile_ext('cache/release/detection/feat_cache/hha_30000/nyud2_release/', imlist{i}, 'mat'), 'boxes');
    assert(isequal(dt.boxes, single(pt.list{i}(:, 3:6))+1));
  end
end

if strcmp(jobName, 'hha_cache_region_features')
  p = get_paths(); c = benchmarkPaths();
  NYU_ROOT_DIR = c.dataDir;
  REGIONDIR = fullfile(p.output_dir, 'regions', 'release-gt-inst');
  SALT = 'release'; MAX_BOXES = 2000;
  task = 'task-detection-with-cabinet';

  % imset = 'train';
  imdb = imdb_from_nyud2(NYU_ROOT_DIR, imset, task, REGIONDIR, SALT, MAX_BOXES);
  imdb.roidb_func = @roidb_from_nyud2_region;
    
  image_dir = fullfile(p.ft_hha_dir); hha_or_rgb = 'hha'; 
  
  image_ext = 'png'; snapshot = 30000;
  net_file = fullfile_ext(p.snapshot_dir, sprintf('nyud2_finetune_region_%s_iter_%d', hha_or_rgb, snapshot), 'caffemodel');
  feat_cache_dir = p.cnnF_cache_dir;
  net_def_file = fullfile('nyud2_finetuning', 'imagenet_hha_256_fc6.prototxt');
  mean_file = fullfile_ext(p.mean_file_hha, 'mat');
  cache_name = sprintf('hha_region_%d', snapshot);
  args = {};
  % st = 1; sp = 1; e = 0; gpu_id = 1;
  args{1} = {'start', st, 'step', sp, 'end', e, ...
    'image_dir', image_dir, 'image_ext', image_ext, ...
    'feat_cache_dir', feat_cache_dir, ...
    'net_def_file', net_def_file, 'net_file', net_file, 'mean_file', mean_file, ...
    'cache_name', cache_name, 'gpu_id', gpu_id};
  rcnn_cache_features(imdb, true, args{1}{:});
end

if strcmp(jobName, 'rgb_cache_region_features')
  p = get_paths(); c = benchmarkPaths();
  NYU_ROOT_DIR = c.dataDir;
  REGIONDIR = fullfile(p.output_dir, 'regions', 'release-gt-inst');
  SALT = 'release'; MAX_BOXES = 2000;
  task = 'task-detection-with-cabinet';

  % imset = 'train';
  imdb = imdb_from_nyud2(NYU_ROOT_DIR, imset, task, REGIONDIR, SALT, MAX_BOXES);
  imdb.roidb_func = @roidb_from_nyud2_region;
    
  image_dir = fullfile(p.ft_image_dir); hha_or_rgb = 'rgb'; 
  
  image_ext = 'png'; snapshot = 30000;
  net_file = fullfile_ext(p.snapshot_dir, sprintf('nyud2_finetune_region_%s_iter_%d', hha_or_rgb, snapshot), 'caffemodel');
  feat_cache_dir = p.cnnF_cache_dir;
  net_def_file = fullfile('nyud2_finetuning', 'imagenet_color_256_fc6.prototxt');
  mean_file = fullfile_ext(p.mean_file_color, 'mat');
  cache_name = sprintf('rgb_region_%d', snapshot);
  args = {};
  % st = 1; sp = 1; e = 0; gpu_id = 1;
  args{1} = {'start', st, 'step', sp, 'end', e, ...
    'image_dir', image_dir, 'image_ext', image_ext, ...
    'feat_cache_dir', feat_cache_dir, ...
    'net_def_file', net_def_file, 'net_file', net_file, 'mean_file', mean_file, ...
    'cache_name', cache_name, 'gpu_id', gpu_id};
  rcnn_cache_features(imdb, true, args{1}{:});
end

if strcmp(jobName, 'fe'),
  p = get_paths(); c = benchmarkPaths();
  NYU_ROOT_DIR = c.dataDir;
  REGIONDIR = fullfile(p.output_dir, 'regions', 'release-gt-inst');
  SALT = 'release'; MAX_BOXES = 2000;
  task = 'task-detection-with-cabinet';
  imsets = {'val', 'train'};
  for i = 1,
    imset = imsets{i};
    imdb = imdb_from_nyud2(NYU_ROOT_DIR, imset, task, REGIONDIR, SALT, MAX_BOXES);
    imdb.roidb_func = @roidb_from_nyud2_region;

    h5_file = sprintf('cache/release/detection/feat_cache/rgb_region_30000/%s.h5', imset);
    window_file = sprintf('cache/release/detection/finetuning/v1/wf/ft_rgb_%s.mat', imset);
    output_dir = 'cache/release/detection/feat_cache/rgb_region_30000/extract_features_fast/';
    h5_to_mat_fast(h5_file, imdb, window_file, output_dir);
  end 
end

% Check the extracted data..
if strcmp(jobName, 'feat_norm_diff')
  dbstop in rcnn_features at 32
  imset = 'img_5003';
  st = 1; sp = 1; e = 0; gpu_id = 0; jobName = 'rgb_cache_region_features'; script_region_detection
  a = read_h5_file('cache/release/detection/feat_cache/rgb_region_30000/data.h5', 'data-[0-9]*');

  batches{1} = batches{1}(:,:,:,1:128);
  for i = 1:128, 
    im1 = uint8(permute(a{1}(:,:,1:3,i)+128, [2 1 3]));
    im2 = uint8(permute(batches{1}(:,:,1:3,i)+128, [2 1 3]));
    figure(1); 
    subplot(1,3,1); imagesc(im1); subplot(1,3,2); imagesc(im2);
    subplot(1,3,3); imagesc(sqrt(sum((im1-im2).^2, 3))); colormap jet; colorbar; title(norm(double(im1(:))-double(im2(:)))./norm(double(im1(:))));
    pause; 
  end

  b1 = cat(4, batches{1}, batches{1}); f1 = caffe('forward', {b1}); 
  b2 = cat(4, a{1}, a{1}); f2 = caffe('forward', {b2}); 
  f1 = f1{1}(:); f2 = f2{1}(:);
  norm(f1-f2)./norm(f2);
end

if strcmp(jobName, 'box_train')
  res = rcnn_all('task-detection', 'hha', 1, 'train', 'val');
end

if strcmp(jobName, 'region_train')
  p = get_paths(); c = benchmarkPaths();
  NYU_ROOT_DIR = c.dataDir;
  REGIONDIR = fullfile(p.output_dir, 'regions', 'release-gt-inst');
  SALT = 'release'; MAX_BOXES = 2000;
  task = 'task-detection-with-cabinet';
  imset = 'train';
  
  imdb = imdb_from_nyud2(NYU_ROOT_DIR, imset, task, REGIONDIR, SALT, MAX_BOXES);
  imdb.roidb_func = @roidb_from_nyud2_region;


end