require(caret)
library(DMwR)
library(e1071)
library(mda)
#set.seed(1234)
dataset <- read.csv("data/spambase/data.csv",header=FALSE,sep=";")
names <- read.csv("data/spambase/names.csv",header=FALSE,sep=";")
names(dataset) <- sapply((1:nrow(names)),function(i) toString(names[i,1]))
dataset$y <- as.factor(dataset$y)
#sample <- dataset[sample(nrow(dataset), 4000),]
trainIndex <- createDataPartition(dataset$y, p = .95, list = FALSE, times = 1)
dataTrain <- dataset[ trainIndex,]
dataTest  <- dataset[-trainIndex,]


# Naive Bayes
nb <- naiveBayes(y ~ ., dataTrain)
confusion(predict(nb,dataTest),dataTest$y)

# Self Train using Bayes
trST <- dataTrain
nas <- createDataPartition(dataTrain$y, p = 0.95, list = FALSE, times = 1)
trST[nas,'y'] <- NA
func <- function(m,d) {
  p <- predict(m,d,type='raw')
  data.frame(cl=colnames(p)[apply(p,1,which.max)],p=apply(p,1,max))
}
nbSTbase <- naiveBayes(y ~ .,trST[-nas,])
confusion(predict(nbSTbase,dataTest),dataTest$y)
nbST <- SelfTrain(y ~ .,trST,learner('naiveBayes',list()),'func')
confusion(predict(nbST,dataTest),dataTest$y)


# Decision tree
stdTree <- rpartXse(y ~ .,dataTrain,se=0.5)
confusion(predict(stdTree,dataTest,type='class'),dataTest$y)

# Self Train using Decision tree
trSelfT <- dataTrain
nas <- createDataPartition(dataTrain$y, p = 0.9, list = FALSE, times = 1)
trSelfT[nas,'y'] <- NA
## Learn a tree using only the labelled cases and test it
baseTree <- rpartXse(y~ .,trSelfT[-nas,],se=0.5)
confusion(predict(baseTree,dataTest,type='class'),dataTest$y)
confusion(predict(baseTree,trSelfT[nas,-58],type='class'),dataTrain[nas,]$y)
## The user-defined function that will be used in the self-training process

f <- function(m,d) {
  l <- predict(m,d,type='class')
  c <- apply(predict(m,d),1,max)
  data.frame(cl=l,p=c)
}
## Self train the same model using the semi-superside data and test the
## resulting model
treeSelfT <- SelfTrain(y~ .,trSelfT,learner('rpartXse',list(se=0.5)),'f')
confusion(predict(treeSelfT,dataTest,type='class'),dataTest$y)

confusion(predict(treeSelfT,trSelfT[nas,-58],type='class'),dataTrain[nas,]$y)
