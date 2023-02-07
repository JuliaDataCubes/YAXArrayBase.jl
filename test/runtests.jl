using YAXArrayBase
using Test, TestItemRunner

@run_package_tests
@testset "Datasets" begin
    include("datasets.jl")
end
#@testset "Arrays" begin
#  include("arrays.jl")
#end