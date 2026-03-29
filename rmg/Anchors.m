%kmeans 聚类中心作为anchors
function anchors=Anchors(X,m)
    maxIter = 120;
    numRep = 1;
    [~,anchors]=litekmeans(X,m,'MaxIter',maxIter,'Replicates',numRep);
end