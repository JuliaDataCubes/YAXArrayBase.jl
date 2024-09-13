using YAXArrayBase
using Test, TestItemRunner

@testset "Datasets" begin
    include("datasets.jl")
end

@run_package_tests

#@testset "Arrays" begin
#  include("arrays.jl")
#end