module HypothesisTestsExtraDataFramesExt

using HypothesisTestsExtra
using DataFrames
using CategoricalArrays
using HypothesisTests
using Printf

import HypothesisTestsExtra: GroupTestToDataframe, CellTestToDataframe,
    PostHocPar, PostHocNonPar, PostHocContingencyRow, PostHocContingencyCell,
    WelchANOVATest, FisherExactTestRxC, JonckheereTerpstraTest,
    CochranArmitageTest, LinearByLinearTest

import HypothesisTests: ChisqTest, FisherExactTest, PowerDivergenceTest,
    OneWayANOVATest, KruskalWallisTest,
    LeveneTest, BrownForsytheTest, FlignerKilleenTest,
    EqualVarianceTTest, UnequalVarianceTTest, MannWhitneyUTest,
    VarianceFTest, ApproximateTwoSampleKSTest,
    OneSampleTTest, OneSampleZTest, SignTest, SignedRankTest, BinomialTest

include("helpers.jl")
include("formatters.jl")

include("DataFramesExt/dataframe/posthoc.jl")
include("DataFramesExt/dataframe/onesample.jl")
include("DataFramesExt/dataframe/twosample.jl")
include("DataFramesExt/dataframe/multisample.jl")
include("DataFramesExt/dataframe/contingency.jl")
include("DataFramesExt/dataframe/trends.jl")

include("DataFramesExt/grouped/posthoc.jl")
include("DataFramesExt/grouped/twosample.jl")
include("DataFramesExt/grouped/multisample.jl")
include("DataFramesExt/grouped/contingency.jl")
include("DataFramesExt/grouped/trends.jl")

end # module
