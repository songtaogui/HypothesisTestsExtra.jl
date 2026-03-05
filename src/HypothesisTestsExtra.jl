# src/HypothesisTestsExtra.jl

module HypothesisTestsExtra

using Reexport
@reexport using HypothesisTests
using Distributions
using Statistics
using LinearAlgebra
using Printf
using Rmath
using PrettyTables
import StatsAPI
using StatsAPI
using StatsAPI: HypothesisTest
using StatsBase
using Random
using SpecialFunctions: logabsgamma

# ==============================================================================
# Import functions to extend them
# ==============================================================================
# Base utility
import HypothesisTests: pvalue

# ==============================================================================
# Include source files
# ==============================================================================
include("NewTests/welchanova.jl")
include("NewTests/fisherrxc.jl")
include("NewTests/trends.jl")
include("PostHoc/posthoc.jl")

# ==============================================================================
# Export new types and functions
# ==============================================================================
# Note: Functions extended from HypothesisTests (like ChisqTest) are already 
# exported by @reexport using HypothesisTests. We only export *new* functions here.

# New test functions
export WelchANOVATest
export FisherExactTestRxC, mc_result, FisherMCSummary
export CochranArmitageTest, JonckheereTerpstraTest, LinearByLinearTest

# PostHoc Related Export
export PostHocPar, PostHocNonPar, PostHocContingencyRow, PostHocContingencyCell
export PostHocTestResult, PostHocComparison, ContingencyCellTestResult
export GroupTestToDataframe, CellTestToDataframe

end # module
