#################################################
###  Optimal Transport Methods in  Economics  ###
#################################################
##########       Alfred Galichon       ##########
#################################################
##########  Princeton University Press ##########
#################################################
#
#
#################################################
###           PE 8.1: Shortest path           ###
###           via linear programming          ###
#################################################
library('gurobi')
library('Matrix')

# for Paris:
city = 'Paris'
originNode <- 84 #saint-germain des pres
destinationNode<- 116 #trocadero
themargin=-c(1.1,.6,.6,1.1)

# for NYC
# city = 'NYC'
# originNode = 446 # Union Sq.
# destinationNode = 465 # 59th St in Brooklyn
# themargin=-c(1,1,.5,0.2)

sep=";"
header=FALSE

if (city == 'NYC') {
    sep=","
    header=TRUE
}

thepath = getwd()
arcs = as.matrix(read.csv(paste0(thepath,"/", city, "/arcs.csv"),sep=sep, header=header)) # loads the data
nodes = as.matrix(read.csv(paste0(thepath,"/", city,"/nodes.csv"),sep=sep, header=header)) # loads the data

namesNodes = nodes[,1]

if (city == 'NYC') {
    arcs <- matrix(as.numeric(arcs[,c(1,2,3)]),ncol=3)
    namesNodes = paste(nodes[,1],nodes[,7])
}

nbNodes = max(arcs[,1])
nbArcs = dim(arcs)[1]

n = rep(0,nbNodes) # construct vector of exiting flow
n[c(originNode,destinationNode)]=c(-1,1)

# construct node-incidence matrix:
Nabla =  sparseMatrix(i=1:nbArcs,j=arcs[,1],dims=c(nbArcs,nbNodes),x=-1) + sparseMatrix(i=1:nbArcs,j=arcs[,2],
                                                                                        dims=c(nbArcs,nbNodes),x=1)
#A = sparseMatrix(i=arcs[,1],j=1:nbArcs,dims=c(nbNodes,nbArcs),x=-1) + sparseMatrix(i=arcs[,2],j=1:nbArcs, dims=c(nbNodes,nbArcs),x=1)


Cost <- arcs[,3] # construct (minus) distance matrix

# solve LP via Gurobi
result = gurobi ( list(A=t(Nabla),obj=Cost,modelsense='min',rhs=n,sense='=',start=matrix(0,nbArcs,1)), params=NULL)
pi = result$x
distance = result$objval


# deduce minimal distance path:
cont = TRUE
i = originNode
writeLines(paste0(namesNodes[i]," (#", i,")"))
eqpath = which(pi>0)
rank = 0
while(cont)
{ 
  rank = rank+1
  leavingi = which(Nabla[,i]==-1)
  a = intersect(eqpath,leavingi)[1]
  j = which(Nabla[a,]==1)[1]
  writeLines(paste0(rank,": ", namesNodes[j]," (#", j,")"))
  i = j
  if(j==destinationNode) {cont<-FALSE}  
}

# plotting the path
require('igraph')
geoCoordinates = nodes[,3:4]
class(geoCoordinates)="numeric"
# mapCoordinates = nodes[,5:6]
# class(mapCoordinates)="numeric"
nbNodes = max(arcs[,1])
nbArcs = dim(arcs)[1]

plotCurrentNetwork = function (network,curNode)
{
  sizeNodes= rep(1,nbNodes)
  sizeNodes[originNode]=4
  sizeNodes[destinationNode]=4
  sizeNodes[curNode]=4
  labelNodes = rep(NA,nbNodes)
  labelNodes[originNode]=namesNodes[originNode]
  labelNodes[destinationNode]=namesNodes[destinationNode]
  labelNodes[curNode]=namesNodes[curNode]
  plot.igraph(network,vertex.label=labelNodes, vertex.label.cex=1,vertex.size=sizeNodes, edge.arrow.size=0, layout = geoCoordinates, margin=themargin)
  
}

thegraph=graph_from_edgelist(arcs[,1:2])

labelColors=rep("SkyBlue2",nbNodes)
labelColors[originNode]="firebrick2"
labelColors[destinationNode]="forestgreen"


sizeNodes= rep(1,nbNodes)
sizeNodes[originNode]=4
sizeNodes[destinationNode]=4

nbNodesSoFar = 1
curpoint=originNode

cont = TRUE
i = originNode
writeLines(paste0(namesNodes[i]," (#", i,")"))
eqpath = which(pi>0)
rank = 0
plotCurrentNetwork(thegraph,i)

while(cont)
{ 
  rank = rank+1
  leavingi = which(Nabla[,i]==-1)
  a = intersect(eqpath,leavingi)[1]
  j = which(Nabla[a,]==1)[1]
  plotCurrentNetwork(thegraph,j)
  writeLines(paste0(rank,": ", namesNodes[j]," (#", j,")"))
  i = j
  if(j==destinationNode) {cont<-FALSE}  
  Sys.sleep(0.5)
}
