
clear all;clc
addpath(genpath('dataset'))
addpath(genpath('utils'))
addpath(genpath('util'))
addpath(genpath('rmg'))
addpath(genpath('nmfLS2'))
load('Indian_pines_corrected.mat');
load('Indian_pines_gt.mat');
Data = data;
groundT = groundT;
[row,col,num_feature] = size(Data);

Label = reshape(double(groundT),row*col,1);
num_class = max(Label(:));
clear a;
iternum=1100;%1100
tic
[row,col,num_feature] = size(Data);
Data1=normalize(reshape(Data, row*col, num_feature));
Data1=reshape(Data1, [row,col,num_feature]);
        
num_PC =7;
bandNum = 3;r = 3;  nr = 8;
X = reshape(Data1, row*col, num_feature);
Psi = PCA_Train(X', bandNum);
X = X*Psi;
DataTmp = reshape(X, row, col,size(Psi,2)); 
mapping = getmapping(nr,'u2'); 
fprintf(' ... ... LBP feature extraction begin ... ...\n');
Feature_P = LBP_feature_global(DataTmp, r, nr, mapping,11, groundT);
lbp_dim = size(Feature_P, 3);
% spatial  data
DataSpat = NewScale(reshape(Feature_P, row*col, lbp_dim));
% spectral data
DataSpec = NewScale(reshape(Data, row*col, num_feature));
% spatial and spectral data combination
DataSpec = DataSpec(:,1:140);
Data_spec_spat = [DataSpat, DataSpec];

train_num_array = 5.*ones(1,16);
train_num_all = sum(train_num_array);

Layernum = 7;%或者，IP：(Layernum = 7,w=29,K=21,epsilon=0.01)

w=29;%29,33
win_inter = (w-1)/2;
epsilon = 0.01;
K=21;%21，70;
num=20;%实验次数
StackFeature= cell(Layernum,1);
for j=1:num
for l=1:Layernum
   
    randidx = randperm(row*col);
    %StackFeature{l}.centroids = zeros(w*w*num_PC,K);
    disp(['Extracting the features of the ',num2str(l),'th layer...']);
    if l==1
        XPCA = PCANorm(reshape(Data, row * col, num_feature),num_PC);
        XPCAvector = XPCA;
        minZ = min(XPCAvector);
        maxZ = max(XPCAvector);
        XPCAvector = bsxfun(@minus, XPCAvector, minZ);
        XPCAvector = bsxfun(@rdivide, XPCAvector, maxZ-minZ);
        XPCA_cov = cov(XPCA);
        [U S V] = svd(XPCA_cov);
        whiten_matrix = U * diag(sqrt(1./(diag(S) + epsilon))) * U';
        XPCA = XPCA * whiten_matrix;
        XPCA = bsxfun(@rdivide,bsxfun(@minus,XPCA,mean(XPCA,1)),std(XPCA,0,1)+epsilon);
         XPCA = reshape(XPCA,row,col,num_PC);
        X_extension = MirrowCut(XPCA,win_inter);
        image_patch=Image_patch(reshape(XPCA, [row,col, num_PC]),w,w);
        [W1,H1]=threeDNMF(image_patch,K,iternum);
        H1=permute(H1,[2 3 1]);
        disp(['H1维度: ', num2str(size(H1))]);

        StackFeature{l}.centroids=reshape(H1,[size(H1,1)*size(H1,2),size(H1,3)]);%randn(w*w*num_PC,K);%
        disp(['X_extension维度: ', num2str(size(X_extension))]);
        StackFeature{l}.feature = extract_features(X_extension,StackFeature{l}.centroids);
        
        XPCAvector = PCANorm([StackFeature{l}.feature],num_PC);
        minZ = min(XPCAvector);
        maxZ = max(XPCAvector);
        XPCAvector = bsxfun(@minus, XPCAvector, minZ);
        XPCAvector = bsxfun(@rdivide, XPCAvector, maxZ-minZ);
        
        clear StackFeature{l}.centroids;
    else
        XPCA = PCANorm(StackFeature{l-1}.feature,num_PC);
        
        XPCA_cov = cov(XPCA);
        [U S V] = svd(XPCA_cov);
        whiten_matrix = U * diag(sqrt(1./(diag(S) + epsilon))) * U';
        
        
        XPCA = XPCA * whiten_matrix;
        XPCA = bsxfun(@rdivide,bsxfun(@minus,XPCA,mean(XPCA,1)),std(XPCA,0,1)+epsilon);
        
        XPCA = reshape(XPCA,row,col,num_PC);
        X_extension = MirrowCut(XPCA,win_inter);
        
       image_patch=Image_patch(reshape(XPCA, [row,col, num_PC]),w,w);
        [W1,H1]=threeDNMF(image_patch,K,iternum);
        H1=permute(H1,[2 3 1]);
        StackFeature{l}.centroids=reshape(H1,[w*w*num_PC,K]);%randn(w*w*num_PC,K);%
        StackFeature{l}.feature = extract_features(X_extension,StackFeature{l}.centroids);
        
        StackFeature{l}.feature = extract_features(X_extension,StackFeature{l}.centroids);
        
        XPCAvector = PCANorm(StackFeature{l}.feature,num_PC);
        minZ = min(XPCAvector);
        maxZ = max(XPCAvector);
        XPCAvector = bsxfun(@minus, XPCAvector, minZ);
        XPCAvector = bsxfun(@rdivide, XPCAvector, maxZ-minZ);
        
        clear StackFeature{l}.centroids;
    end
    
    clear X_extension;
end

% for layernum=1:Layernum
for layernum=Layernum
    
    X_joint = [];
    for i=1:layernum
        X_joint = [X_joint StackFeature{i}.feature];
    end
    X_joint = [X_joint reshape(Data,row*col,num_feature) Data_spec_spat];
    X_joint=normalize(X_joint);

    randomLabel = cell(num_class,1);
    for i=1:num_class
        index = find(Label==i);
        randomLabel{i}.array = randperm(size(index,1));
    end
    X_train = [];
    X_test = [];
    y_train = [];
    y_test = [];
    
    train_indexes = [];
    test_indexes = [];

    for i=1:num_class
        index = find(Label==i);
        randomX = randomLabel{i,1}.array;
        train_num = train_num_array(i);
        randomX_index =index(randomX(1:train_num));
        X_train = [X_train;X_joint(randomX_index,:)];
        y_train = [y_train;Label(randomX_index,1)];
        randomX_tindex=index(randomX(train_num+1:end));
        X_test = [X_test;X_joint(randomX_tindex,:)];
        y_test = [y_test;Label(randomX_tindex,1)];
        train_indexes   = [train_indexes; randomX_index];
        test_indexes    = [test_indexes; randomX_tindex];
        
    end
    
    X=[X_train;X_test];
    labels = [y_train;y_test]; 
       X_train = [];
    X_test = [];
    y_train = [];
    y_test = [];
    
    for i=1:num_class
        index = find(Label==i);
        randomX = randomLabel{i,1}.array;
        train_num = train_num_array(i);
        X_train = [X_train;X_joint(index(randomX(1:train_num)),:)];
        y_train = [y_train;Label(index(randomX(1:train_num)),1)];
        
        X_test = [X_test;X_joint(index(randomX(train_num+1:end)),:)];
        y_test = [y_test;Label(index(randomX(train_num+1:end)),1)];
        
    end
    
    
    [N,Dim] = size(X);
    kf = floor(Dim/4);kg = 4;%4
    label_index = find(y_train~=0);
    [G,F]  = MultiGraphs(X,labels,label_index,kg,kf);
    
    [val, predict_res]=max(F,[],2);
    [Pr, ConfMat] = GetAccuracy(predict_res(length(label_index)+1:end), ...
                            labels(length(label_index)+1:end));
     OA=Pr.OA;
     Kappa=Pr.Kappa;
    


end
 OA1(j)=OA;Kappa1(j)=Kappa;
end
OAm=mean(OA1);Kappam=mean(Kappa1);
