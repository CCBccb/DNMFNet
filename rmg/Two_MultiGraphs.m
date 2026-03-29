

%construct multi-graphs
%kg---number of graphs
%kf---number of features used by every graph

function [G,F1,F2]=Two_MultiGraphs(X1,X2,labels1,labels2,label_index1,label_index2,kg,kf1,kf2)

  n1=size(X1,1);
  k1=length(unique(labels1));
  G=cell(kg,1);
  F1=zeros(n1,k1);
  
  n2=size(X2,1);
  k2=length(unique(labels2));
  G=cell(kg,1);
  F2=zeros(n2,k2);
  parfor i=1:kg
      fprintf('... ... the %dth graph computation ... ...\n', i);
      X11=SelectFeatures(X1, kf1, i);
      X22=SelectFeatures(X2, kf2, i);
      % gaofeng revised code
      % 修改为和训练样本一样多
      % m=floor(n*0.1);
      m1 = length(label_index1);
      A1=Anchors(X11,m1);
      A1=[A1;X11(label_index1,:)];
      s = 3;
      cn = 10;
      [Z1,rL1] = AnchorGraph(X11', A1', s, 0, cn); % 1代表使用LAE求解Z
      
      F11 = AnchorGraphReg(Z1, rL1, labels1', label_index1, 0.01);
      m2 = length(label_index2);
      A2=Anchors(X22,m2);
      A2=[A2;X22(label_index2,:)];
      [Z2,rL2] = AnchorGraph(X22', A2', s, 0, cn); % 1代表使用LAE求解Z
      
      F22 = AnchorGraphReg(Z2, rL2, labels2', label_index2, 0.01);
      G{i}=F11;
      F1=F1+F11;
      F2=F2+F22;
  end
  F1=F1/kg;F2=F2/kg;
end



