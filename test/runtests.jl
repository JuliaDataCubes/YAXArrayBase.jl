using YAXArrayBase
using Test

@testset "Datasets" begin
    include("datasets.jl")
end
@testset "Arrays" begin
  include("arrays.jl")
end