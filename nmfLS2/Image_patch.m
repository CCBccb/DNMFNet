function image_patch=Image_patch(input,M,N)
%M=5;N=5;%M、N选择image_patch
% rgb=imread('下载 (1).jpg');
% [m,n,c]=size(rgb);
[m,n,c]=size(input);
xb=round(m/M)*M;yb=round(n/N)*N;%找到能被整除的M,N
rgb=imresize(input,[xb,yb]);
[m,n,c]=size(rgb);
count =1;
imagepatch=cell(M,N);
for i=1:M
    for j=1:N
        % 1） 分块
        block = rgb((i-1)*m/M+1:m/M*i,(j-1)*n/N+1:j*n/N,:); % 图像分成块
        imagepatch{i,j}=block;
   %写上要对每一块的操作
%      subplot（M,N,count）；
%      imshow（block）；
%         count = count+1;
    end
end

for i=1:M 
    for j=1:N 
        temp=imagepatch{i,j}(:,:,1);
        image_patch1(:,(i-1)*N+j)=temp(:);
    end
end
for i=1:M
    for j=1:N
        temp=imagepatch{i,j}(:,:,2);
        image_patch2(:,(i-1)*N+j)=temp(:);
    end
end
for i=1:M
    for j=1:N
        temp=imagepatch{i,j}(:,:,3);
        image_patch3(:,(i-1)*N+j)=temp(:);
    end
end
image_patch=cat(3,image_patch1,image_patch2,image_patch3);
