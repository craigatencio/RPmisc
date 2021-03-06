#
#-----------------------------------------------------------------------
#
# Note : I chose to implement the model in R instead of Python. While I 
# know the R packages to implement statistical models, I don't know the 
# models in Python.
#
# I do know that sci-kit learn has the tools to perform the analysis, 
# though I am not familiar with them yet.
#
# I am currently working through the book 
# "Machine Learning in Python: Essential Techniques for Predictive Analysis"
# by Mike Bowles, which describes penalized regression and tree ensemble 
# techniques. Given my current time constraints, however, I would need a
# few more days to fully implement them.
#
#-----------------------------------------------------------------------
#
#
# Questions:
#
# Question 1. Describe your methodology. Why did you pick it? 
#
# For this analysis, the predicted output is continuous, so this is a
# regression problem, not a classification problem.
#
# I chose multiple regression since it is the simplest initial approach. It
# is also the most straightforward to implement and interpret, and it is also the
# fastest to estimate.
#
# I also considered Ridge Regression and LASSO. However, I found that the
# performance of multiple regression was very good. Also, there are not many
# variables, and thus the automatic feature selection aspect of LASSO is
# not really needed.
#
# I did try Ridge and LASSO, but they did not perform better than multiple 
# regression.
#
# I also found that the features I chose to include were relatively independent.
# There was little collinearity between the features as shown by the
# variance inflation factor for each feature.
#
# After choosing my approach, I estimated the model parameters using best subset 
# selection. This required estimating the best model for a given set of parameters.
# Then, I estimated the performance of each set.
#
# Once the models from best subset selection were estimated, I then chose the 
# overall best model using cross-validation by predicting on a test set.
#
#
# Question 2. How well would you do if you included the List Price.
#
# I made an initial comparison between models with and without ListPrice. I compared
# the models using an ANOVA, and found that the model without ListPrice was
# significantly better. The comparison is coded below.
#
#
# Question 3. What is the performance of you model? What error metrics did you choose?
#
# My model performs very well. It has very high adjusted R2 value. On a test set,
# the predicitons of the test set were similar to the actual test set values. 
# A plot of the values revealed a unity relationship. The code at the bottom of 
# this page produces this plot.
#
# To estimate general model performance, I examined the residual sum of squares,
# Adjuested R2, Cp, and BIC. To choose the final model using cross-validation, 
# I used the mean squared error on a test validation set.
#
#
# Question 4. How would you improve your model?
#
# This model only includes a small subset of a much larger housing database.
# To make a reasonable prediction, different subsets of the data need to be
# extracted and modeled.
#
# For the housing market, the location needs to be included in the analysis.
# To do this, I would consider translating the geographical coordinates into
# a zip code, a neighborhood variable, or a school district variable, or all. 
# Then, I would estimate regression coefficients for each location, using the
# chosen features.
#
# There are a few other aspects that need to be considered.
#
# 1. The market changes with time. Thus, the regression coefficients need to be updated
# every week or two. 
#
# 2. For the predicted house value, the prediction of the value over
# time needs to be estimated, and shown. This could be done using a sliding
# temporal window. This would allow the market trend to influence the decision 
# of the seller/buyer.
# 
# 3. For the house value with time trend, the slope and acceleration of the house
# price could also be shown, using a sliding temporal window. Then, how fast the
# market is changing, and if it is nearing a reversal, could be taken into
# consideration. You could even predict what the housing price will be in the
# near future if the trends are taken into consideration.
#
#
# Question 5. How would you deploy your model to predict in real-time?
#
# First, the the regression model needs to be estimated for each location/district.
# This would produce regression coefficients that could be extracted, and then
# used to quickly estimate a housing price for any location. The model would need to 
# be updated behind the scenes so that only data within a chosen time window would
# be used to predict house prices at the current time. Second, the coefficients
# need to be stored on disk, using a database of some sort. This would necessitate
# estimating and storing coefficients for each time period. Third, I could imagine having a 
# web page, where the house location is entered. This would then be translated 
# behind the scenes to a zip code/neighborhood/district. Then, the regresssion
# coefficients would be extracted from the database for the current time, and 
# the housing features would be used to predict a houseing price.
#


# The features/variables in the data are:
# 
# "ListingId"       | Did not use - just an index
# "LivingArea"      | Did use - house size is important
# "NumBedrooms"     | number of rooms is important
# "NumBaths"        | number of baths is important
# "Pool"            | used
# "ExteriorStories" | used
# "ListDate"        | Did not use. Could be used to assess time on market, implying over/under priced
# "ListPrice"       | used
# "GeoLat"          | did not use. Should be used for neighborhood/school district category
# "GeoLon"          | same as previous
# "PublicRemarks"   | didn't use - just text
# "CloseDate"       | didn't use; might be interesting to examine CloseDate - ListDate
# "ListingStatus"   | did not used - if it has a closing price, the status is determined
# "DwellingType"    | used
#
# "ClosePrice"      | to be predicted


library(MASS) # general regression
library(car) # for variance inflation
library(leaps) # for cross validation


# Data source
file = "data_sci_snippet.csv"


# read data into data frame
data = read.csv(file, header=TRUE, sep=",")


# All variable/features names
allatt = c("ListingId",       "LivingArea","NumBedrooms","NumBaths",     "Pool",         
           "ExteriorStories", "ListDate",  "ListPrice",  "GeoLat",       "GeoLon",  
           "PublicRemarks",   "CloseDate", "ClosePrice", "ListingStatus","DwellingType")   


# Subset of features to used
goodatt = c("LivingArea","NumBedrooms","NumBaths", "Pool", 
            "ExteriorStories", "ListPrice", "ClosePrice", "DwellingType")   


# Data without remarks, etc.
data = data[,goodatt]



# determine if there's missing data
nNA = apply(data, 2, function(x) sum(is.na(x)))
nNA


# There's a lot, so get cases with complete data
index = complete.cases(data)


# complete data set without NA
dataComplete = data[index,]


# First pass: perform a simple multiple regression, without feature selection

# Regression with ListPrice
lm.fit.LP = lm(ClosePrice ~ . , data=dataComplete)
vif(lm.fit.LP) # inflation factors are small (all < 2.2), so model is well-behaved


# Regression without ListPrice
lm.fit.noLP = lm(ClosePrice ~ . - ListPrice , data=dataComplete)
vif(lm.fit.noLP) # inflation factors are small (all < 2.2)


# Plot fit object to see quality metrics

# Model with List Price
par(mfrow=c(2,2))
plot(lm.fit.LP)


# Model without List Price
par(mfrow=c(2,2))
plot(lm.fit.noLP)



# Perform ANOVA to compare the two models
anova(lm.fit.noLP, lm.fit.LP) # model w/o ListPrice is better



# Construct training and test set indices for estimation/validation data
set.seed(1)
train = sample(c(TRUE,FALSE),nrow(dataComplete),rep=TRUE)
test = (!train)



# Get a sense of how the full model performs. 
# Use best subset selection on the training set.
nVars = length(coef(lm.fit.LP)) - 1 # number of variables to assess with cross-validation
regfit.best = regsubsets(ClosePrice ~ .,data=dataComplete[train,],nvmax=nVars)
reg.summary = summary(regfit.best)



# Plot error metrics to identify possible number of variables
# and get a sense of the model performance
par(mfrow=c(2,2))

# Residual sum of squares
plot(reg.summary$rss, xlab="#VArs", ylab="RSS", type="l")

# Adjusted R square
plot(reg.summary$adjr2, xlab="#VArs", ylab="Adj R2", type="l")
index = which.max(reg.summary$adjr2)
points(index, reg.summary$adjr2[index],col="red",cex=2, pch=20)

# Cp
plot(reg.summary$cp, xlab="#VArs", ylab="Cp", type="l")
index = which.min(reg.summary$cp)
points(index, reg.summary$cp[index],col="red",cex=2, pch=20)

# BIC
plot(reg.summary$bic, xlab="#VArs", ylab="BIC", type="l")
index = which.min(reg.summary$bic)
points(index, reg.summary$bic[index],col="red",cex=2, pch=20)





# Construct test design matrix to predict prices
# This matrix will contain multiple values for DwellingType and Pool
# since these are categorical variables. They will be represented
# by dummy variables. Then, from the dummy variables, contrasts will
# be constructed. 
test.mat = model.matrix(ClosePrice ~ .,data=dataComplete[test,])


# Calculate validation set errors - MSE
val.errors = rep(NA,nVars)
for (i in 1:nVars){
  coefi = coef(regfit.best,id=i)
  pred = test.mat[,names(coefi)] %*% coefi
  val.errors[i] = mean((dataComplete$ClosePrice[test]-pred)^2)
}


# How many variables does the best model contain?
index = which.min(val.errors)


# Make function to get predictions 
predict.regsubsets = function(object ,newdata,id ,...){
   form = as.formula(object$call [[2]])
   mat = model.matrix(form ,newdata )
   coefi = coef(object,id=id)
   xvars = names (coefi)
   mat[,xvars ] %*% coefi
   }


# Get test set values, and predictions for test set using best model
test_val = dataComplete$ClosePrice[test]
test_pred = predict.regsubsets(regfit.best, dataComplete[test,],index)


# Plot test set vs. predictions.
# The predictions and values have a unity relationship - the model
# predicts the values very well.
par(mfrow=c(1,1))
plot(test_val, test_pred, pch=1, 
     xlab="Test Validation Set - House Price ($)", 
     ylab="Predicted Validation Set - House Price ($)", 
     main="Prediction of Test Validation Set")
abline(0,1)




















