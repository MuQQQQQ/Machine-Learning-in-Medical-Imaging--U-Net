function [net, info] = unet()

run /home/qwertzuiopu/.matconvnet-1.0-beta20/matlab/vl_setupnn

net = unet_init()
opts.expDir = fullfile(pwd,'data');
net.meta.trainOpts.learningRate = [0.05*ones(1,2)];
net.meta.trainOpts.weightDecay = 1.0000e-04;
net.meta.trainOpts.batchSize = 1;
net.meta.trainOpts.numEpochs = 2;
opts.train.gpus = []

data = zeros(572,572,1,30);
for i = 1:30
    im = imread('train-volume.tif',i);
    pad = (572 - size(im,1))/2;
    im = padarray(im,[pad pad],'symmetric');
    data(:,:,:,i) = im;
end
data = single(data);

labels = zeros(388,388,2,30);
for i = 1:30
    im = imread('train-labels.tif',i)/255;
    crop = (512 - 388)/2;
    l = im(crop:end-crop,crop:end-crop);
    labels(:,:,1,i) = im(crop+1:end-crop,crop+1:end-crop);
    labels(:,:,2,i) = ~im(crop+1:end-crop,crop+1:end-crop);
end
labels = single(labels);

imdb.images.data = data;
imdb.images.labels = labels;
imdb.images.set = single(ones(1,30));
imdb.meta.sets = {'train', 'val', 'test'}
imdb.meta.classes = {'positive', 'negative'}

[net, info] = cnn_train_dag(net, imdb, getBatch(opts), ...
  'expDir', opts.expDir, ...
  net.meta.trainOpts, ...
  opts.train) ;

function fn = getBatch(opts)
bopts = struct('numGpus', numel(opts.train.gpus)) ;
fn = @(x,y) getDagNNBatch(bopts,x,y) ;

function inputs = getDagNNBatch(opts, imdb, batch)
images = imdb.images.data(:,:,:,batch) ;
labels = imdb.images.labels(1,batch) ;
if rand > 0.5, images=fliplr(images) ; end
if opts.numGpus > 0
    images = gpuArray(images) ;
end
inputs = {'input', images, 'label', labels} ;