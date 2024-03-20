#remove.packages("phenoptrReports")
devtools::install_github("christianrickert/phenoptrReports")
#devtools::install_local("C:/Users/Christian Rickert/Documents/GitHub/phenoptrReports")

library(testthat)
library(phenoptrReports)
library(rstudioapi)

# set path to current script directory
setwd(dirname(getSourceEditorContext()$path))

# run test script with test data
test_check("phenoptrReports")