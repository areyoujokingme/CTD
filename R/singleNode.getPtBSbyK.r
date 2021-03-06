#' Generate patient-specific bitstrings from the fixed, single-node network walker.
#'
#' This function calculates the bitstrings (1 is a hit; 0 is a miss) associated with the fixed, single-node network walker
#' trying to find the variables in the encoded subset, given the background knowledge graph.
#' @param S - A character vector of node names describing the node subset to be encoded.
#' @param ranks - The list of node ranks calculated over all possible nodes, starting with each node in subset of interest.
#' @param num.misses - The number of misses tolerated by the network walker before path truncation occurs.
#' @return pt.byK - a list of bitstrings, with the names of the list elements the node names of the encoded nodes
#' @export singleNode.getPtBSbyK
#' @examples
#' # Load in your profiling data (rows are compounds, columns are samples)
#' data_mx = read.table("your_profiling_data.txt", sep="\t", header=TRUE)
#' # Get bitstrings associated with each patient's top kmx variable subsets
#' kmx = 15
#' ptBSbyK = list()
#' for (pt in 1:ncol(data_mx)) {
#'   S = data_mx[order(abs(data_mx[,pt]), decreasing=TRUE),pt][1:kmx]
#'   ptBSbyK[[ptID]] = singleNode.getPtBSbyK(S, ranks)
#' }
singleNode.getPtBSbyK = function(S, ranks, num.misses=NULL) {
  if (is.null(num.misses)) { num.misses = log2(length(ranks)) }
  ranks2 = ranks[which(names(ranks) %in% S)]
  pt.bitString = list()
  for (p in 1:length(S)) {
    miss = 0
    thresh = length(ranks2[[S[p]]])
    for (ii in 1:length(ranks2[[S[p]]])) {
      ind_t = as.numeric(ranks2[[S[p]]][ii] %in% S)
      if (ind_t==0) {
        miss = miss + 1
        if (miss >= num.misses) {
          thresh = ii
          break;
        }
      } else { miss = 0 }
      pt.bitString[[S[p]]][ii] = ind_t
    }
    pt.bitString[[S[p]]] = pt.bitString[[S[p]]][1:thresh]
    names(pt.bitString[[S[p]]]) = ranks2[[S[p]]][1:thresh]
    ind = which(pt.bitString[[S[p]]] == 1)
    pt.bitString[[S[p]]] = pt.bitString[[S[p]]][1:ind[length(ind)]]
  }

  # For each k, find the ranks that found at least k in S. Which found the first k soonest?
  pt.byK = list()
  for (k in 1:length(S)) {
    pt.byK_tmp = pt.bitString
    # Which found at least k nodes
    bestInd = vector("numeric", length(S))
    for (p in 1:length(S)) {
      bestInd[p] = sum(pt.bitString[[p]])
    }
    if (length(which(bestInd>=k))>0) {
      pt.byK_tmp = pt.byK_tmp[which(bestInd>=k)]
      # Which found the most nodes soonest
      bestInd = vector("numeric", length(pt.byK_tmp))
      for (p in 1:length(pt.byK_tmp)) {
        bestInd[p] = sum(which(pt.byK_tmp[[p]] == 1)[1:k])
      }
      maxInd = max(which(pt.byK_tmp[[which.min(bestInd)]] == 1)[1:k])
      pt.byK[[k]] = pt.byK_tmp[[which.min(bestInd)]][1:maxInd]
    } else {
      pt.byK[[k]] = pt.byK_tmp[[which.max(bestInd)]]
    }
  }

  return(pt.byK)
}

