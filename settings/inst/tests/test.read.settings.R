#----------------------------------------------------------------------------

## Copyright (c) 2012 University of Illinois, NCSA.
## All rights reserved. This program and the accompanying materials
## are made available under the terms of the 
## University of Illinois/NCSA Open Source License
## which accompanies this distribution, and is available at
## http://opensource.ncsa.illinois.edu/license.html
## #-------------------------------------------------------------------------------
logger.setQuitOnSevere(FALSE)
logger.setLevel("OFF")
context("tests for read.settings and related functions")

settings <- read.settings(system.file("tests/testinput.xml",
                                      package = "PEcAn.settings"))    

test_that("read.settings returned correctly", {
	expect_true(file.exists(settings$outdir))
	expect_true(file.info(settings$outdir)$isdir)
	expect_true(file.exists(file.path(settings$outdir, "pecan.xml")))
})

test_that("read settings returns error if no settings file found (issue #1124)",{
	expect_error(read.settings("nofile.xml"), "Could not find a pecan.xml file")
})

test_that("check.settings throws error if required content not there", {

  s <- settings
  s[['pfts']] <- NULL
  expect_error(check.settings(s))  
  s <- settings
  s[['run']] <- NULL
  expect_error(check.settings(s))  

  for(date in c("start.date", "end.date")){
    s <- settings
    s$run[[date]] <- NULL
    expect_error(check.settings(s))
  }

})

test_that("check.settings gives sensible defaults",{
  ## This provides the minimum inputs 
  s <- settings
  s1 <- list(pfts = list(pft = list(name = "test", outdir = "testdir")), 
             database = NULL, 
             run = list(start.date = now(), end.date = days(1) + now()))
  s2 <- check.settings(s1)
  expect_is(s2$database, "NULL")
  
  s1$database <- settings$database
  s2 <- check.settings(s1)
  #expect_equal(s2$database$driver, "MySQL")

  ## dir. paths, with default localhost
  expect_equal(s2$run$host$name, "localhost")
  
  ## outdirs
  expect_equal(s2$outdir, tempdir())
  expect_equal(s2$modeloutdir, file.path(tempdir(), "out"))  
  expect_equal(s2$run$host$outdir, file.path(s2$outdir, "out"))

  ## rundir
  expect_equal(s2$rundir, file.path(tempdir(), "run"))  
  expect_equal(s2$rundir, s2$run$host$rundir)
  
  expect_true(s2$bety$write)
  expect_true(s2$meta.analysis$iter > 1000)
  expect_false(s2$meta.analysis$random.effects)
})

test_that("check.settings uses run dates if dates not given in ensemble or sensitivity analysis", {
  s <- settings
  
  for(node in c("ensemble", "sensitivity.analysis")) {
    s1 <- list(pfts = s$pfts, database = s$database, run = s$run)
    s1[[node]] <- list(variable = "FOO")
    s2 <- check.settings(s1)
    expect_equivalent(s2[[node]]$start.year, year(s2$run$start.date))
    expect_equivalent(s2[[node]]$end.year, year(s2$run$end.date))
    
    s1 <- list(pfts = s$pfts, database = s$database, run = NA)
    s1[[node]] <- list(variable = "FOO", start.year = 1000, end.year = 1000)

    expect_error(check.settings(s1))    
  }
})

test_that("sensitivity.analysis and ensemble use other's settings if null",{
  s <- settings
  s1 <- list(pfts = s$pfts, database = s$database, run = s$run)
  nodes <- c("sensitivity.analysis", "ensemble")
  for(node1 in nodes) {
    node2 <- nodes[nodes != node1]
    s1 <- list(pfts = s$pfts, database = s$database, run = s$run)
    s1[[node1]] <- list(variable = "FOO", start.year = 2003, end.year = 2004)
    s1[[node2]] <- list()
    s2 <- check.settings(s1)
    for(setting in c("variable", "start.year", "end.year")){
      expect_equal(s2[[node1]][[setting]], s2[[node2]][[setting]])        
    }
    expect_equal(s2$ensemble$size, 1)
  }
})

test_that("workflow id is numeric if settings$bety$write = TRUE", {
  s <- settings
  s1 <- check.settings(s)
  expect_is(s1$workflow$id, c("integer", "numeric"))
  
  s$workflow <- NULL
  s1 <- check.settings(s)
  expect_is(s1$workflow$id, c("integer", "numeric"))
})

test_that("check.settings will fail if db does not exist",{

  s <- settings
  expect_true(db.exists(s$database))
  s$database$dbname <- "blabla"
  expect_false(db.exists(s$database))

  expect_error(check.settings(s$database))

})



test_that("check.settings handles userid and username properly", {

  s1 <- settings
  s1$database[["userid"]] <- "bety"
  s1$database[["user"]] <- NULL
  s2 <- check.settings(s1)
  expect_true("user" %in% names(s2$database))  
  expect_true(!"userid" %in% names(s2$database))
  
  s1 <- settings
  s1$database[["username"]] <- "bety"
  s1$database[["user"]] <- NULL
  s2 <- check.settings(s1)
  expect_true("user" %in% names(s2$database))  
  expect_true(!"username" %in% names(s2$database))
  
  s1 <- settings
  s1$database[["userid"]] <- "bety"
  s2 <- check.settings(s1)
  expect_true("user" %in% names(s2$database))  
  expect_true(!"userid" %in% names(s2$database))
  
  s1 <- settings
  s1$database[["username"]] <- "bety"
  s2 <- check.settings(s1)
  expect_true("user" %in% names(s2$database))  
  expect_true(!"username" %in% names(s2$database))
  
})

test_that("check settings runs with only model$name and no database", {
  s <- settings
  s$model <- list(name = "foo")
  s$database <- NULL
  s1 <- check.settings(s)
  expect_identical(s$model$name, s1$model$name)
  s1$model$name <- NULL
  s2 <- check.settings(s1)
})