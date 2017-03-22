
# Principles of a bootstrap analysis of stable clusters
This tutorial illustrates the basic principles behind the "Bootstrap Analysis of Stable Clusters (BASC)" algorithm, using basic simulations.
  * **More documentation**: You can check the following [video](https://www.youtube.com/watch?v=4yAUB-FHyv0&t=751s) for a presentation of the algorithm, as well as applications to resting-state and task-based fMRI.
  * **.m script**: The script of the tutorial can be downloaded [here](https://raw.githubusercontent.com/SIMEXP/niak_tutorials/master/niak_tutorial_basc_principles.m) and the notebook is available [here](https://nbviewer.jupyter.org/github/SIMEXP/niak_tutorials/blob/master/niak_tutorial_basc_principles.ipynb).
  * **Time for completion**: this tutorial will take 5-10 minutes to complete.

We are going to simulate data with a cluster structure. Let's assume we have 100 subjects, 300 brain regions and 3 clusters. The `alpha` parameter will control for the strength of the clustering.


```octave
nb_subject = 100; % # of subjects
nb_roi = 300;     % # of regions
nb_cluster = 3;   % # of clusters
alpha = 0.3;      % this parameter controls the "strength" of the clustering.
```

The simulations just consist of random gaussian noise. We add a single (random) single signal to all regions within a cluster. All clusters are set to have the same size.


```octave
y = randn(nb_subject,nb_roi);
ind = floor(linspace(1,nb_roi,nb_cluster+1));
for cc = 1:nb_cluster
    cluster = ind(cc):ind(cc+1);
    y(:,cluster) = y(:,cluster) + alpha*repmat(randn(nb_subject,1),[1 length(cluster)]);
end
```

We compute the spatial correlation matrix (across subjects) to see how the cluster structure looks.  


```octave
R = corr(y);
title('Spatial correlation matrix')
imagesc(R), axis square, colormap(jet), colorbar
```


![png](niak_tutorial_basc_principles/_6_0.png)


the cluster structure is clear, but noisy. Let's run a hierarchical clustering and see if we can recover it.


```octave
hier = niak_hierarchical_clustering(R); % The similarity-based hierarchical clustering
part = niak_threshold_hierarchy(hier,struct('thresh',3)); % threshold the hierarchy to get 3 clusters
niak_visu_part(part) % visualize the partition
```

         Percentage done : 0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 Done !



![png](niak_tutorial_basc_principles/_8_1.png)


In this representation, if a pair of region is in cluster `I`, a `I` is shown in the matrix. If the clustering had done a perfect job, we would have squares on the diagonal. Note that the adjacency matrix representation of the clustering is the same as this representation, but with all non-zero entries coded as 1 (we don't care about the actual label of clusters, as these are arbitrary). It looks like the hierarchical clustering did an OK job here.

A small aside note here. Note that we simulated the data with a simple order (cluster 1, then cluster 2, etc). In real life we don't know the order. We can use the hierarchical clustering to estimate it though:


```octave
order = niak_hier2order(hier); % order the regions based on the hierarchy
subplot(1,2,1)
% Re-order the correlation matrix
title('re-ordered correlation matrix')
imagesc(R(order,order)), axis square, colorbar
subplot(1,2,2)
% Show the re-ordered partition
title('re-ordered partition')
niak_visu_part(part(order)), axis square
```


![png](niak_tutorial_basc_principles/_11_0.png)


with that ordering, by construction the solution of the hierarchical clustering are squares on the diagonal. If you are lucky, the similarity matrix will also look like it has squares on the diagonal.  

Now it is time to implement a boostrap analysis of stable clusters. The steps of the algorithm are as follows:
 * Let's start by resample the data many times
 * re-run the clustering on each replication
 * represent each cluster solution as an adjacency matrix
 * compute the average of the adjacency matrix. This matrix, called stability or co-occurence, tells you the frequency at which a pair of regions fall into the same cluster.


```octave
nb_samp = 30;
opt_b.block_length = 1; % That's a parameter for the bootstrap. We treat the subjects as independent observations.
for ss = 1:nb_samp
    niak_progress(ss,nb_samp)
    y_s = niak_bootstrap_tseries(y,opt_b); % Bootstrap the subjects
    R_s = corr(y_s); % compute the correlation matrix for the bootstrap sample
    hier = niak_hierarchical_clustering(R_s,struct('flag_verbose',false)); % replication the hierarchical clustering
    part = niak_threshold_hierarchy(hier,struct('thresh',nb_cluster)); % Cut the hierarchy to get clusters
    mat = niak_part2mat(part,true); % convert the partition into an adjacency matrix
    if ss == 1; stab = mat; else stab = stab+mat; end; % Add all adjacency matrices
end
stab = stab / nb_samp; % Divide by the number of replications to get the stability matrix
```

        Percentage done: 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100


Let's have a look at the stability matrix:


```octave
imagesc(stab), axis square, colormap(jet), colorbar
```


![png](niak_tutorial_basc_principles/_16_0.png)


Looks like the clusters are pretty stable. Also note that the stability matrix ressembles a lot the original similarity matrix, except that the cluster structure is much cleaner. So let's use this stability matrix as the input of a new clustering! We are now looking for clusters of regions which have a high probability of falling into the same clusters. This step is called consensus clustering.


```octave
hier_consensus = niak_hierarchical_clustering(stab); % run a hierarchical clustering on the stability matrix
part_consensus = niak_threshold_hierarchy(hier_consensus,struct('thresh',nb_cluster)); % cut the consensus hierarchy
niak_visu_part(part_consensus), axis square, colormap(jet) % visualize the consensus partition
```

         Percentage done : 0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 Done !



![png](niak_tutorial_basc_principles/_18_1.png)


Still not perfect but a bit better... In general the consensus cluster has better performance than the individual cluster solution. This is a general machine learning approach called bagging (for bootstrap aggregation).

One last question. Which region in the consensus cluster #1 (for example) are actually stable? We can combine the sability matrix and the consensus clusters to answer this question.


```octave
map = mean(stab(:,part_consensus==1),2); % Stability "map" of the first consensus cluster
plot(map)
```


![png](niak_tutorial_basc_principles/_21_0.png)


For each region, we have the average stability between this region and all regions in consensus cluster #1 (which happen to be very close to our simulated cluster #1, but it could be any other cluster). For regions in the true cluster, the stability is about 0.6, while in other regions, it is about 0.25. Not bad. An ideal situation would be 1 within cluster, and 0 between cluster. We can also see each region happen to be less stable in that cluster. If each region corresponded to a parcel in the brain, we could represent this vector as a brain map.
