# HypothesisTestsExtra.jl
module HypothesisTestsExtra

using Reexport
@reexport using HypothesisTests
using Distributions
using Statistics
using LinearAlgebra
using Printf
using Rmath
using DataFrames
using NamedArrays
using FreqTables
using PrettyTables
import StatsAPI
using StatsAPI
using StatsAPI: HypothesisTest
using Random
using SpecialFunctions: logabsgamma

# ==============================================================================
# Import functions to extend them
# ==============================================================================
# Base utility
import HypothesisTests: pvalue

# Categorical / Contingency Tests (Added based on dataframe_ext.jl)
import HypothesisTests: ChisqTest, FisherExactTest, PowerDivergenceTest

# K-Sample Tests (ANOVA & Non-parametric)
import HypothesisTests: OneWayANOVATest, KruskalWallisTest

# Variance / Homogeneity Tests (Added based on dataframe_ext.jl)
import HypothesisTests: LeveneTest, BrownForsytheTest, FlignerKilleenTest

# 2-Sample Tests (Parametric & Non-parametric)
import HypothesisTests: EqualVarianceTTest, UnequalVarianceTTest, MannWhitneyUTest
import HypothesisTests: VarianceFTest, ApproximateTwoSampleKSTest

# ==============================================================================
# Include source files
# ==============================================================================
include("welch.jl")
include("fisherrxc.jl")
include("PostHoc/posthoc_structures.jl")
include("PostHoc/utils_cld.jl")
include("PostHoc/posthoc_parametric.jl")
include("PostHoc/posthoc_nonparametric.jl")
include("PostHoc/posthoc_contingency.jl")
include("dataframe_ext.jl")

# ==============================================================================
# Export new types and functions
# ==============================================================================
# Note: Functions extended from HypothesisTests (like ChisqTest) are already 
# exported by @reexport using HypothesisTests. We only export *new* functions here.

# New test functions
export WelchANOVATest
export FisherExactTestMC, FisherExactTestRxC

# PostHoc Related Export
export PostHocTest, PostHocNonPar, PostHocContingencyRow, PostHocContingencyCell
export PostHocTestResult, PostHocComparison, ContingencyCellTestResult
export GroupTestToDataframe, CellTestToDataframe

end # module
