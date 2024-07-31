struct M
end
Base.ndims(::M) = 2
YAXArrayBase.getdata(::M)  = reshape(1:12,3,4)
YAXArrayBase.dimname(::M,i) = i==1 ? :x : :y
YAXArrayBase.dimvals(::M,i) = i==1 ? (0.5:1.0:2.5) : (1.5:0.5:3.0)
YAXArrayBase.getattributes(::M) = Dict{String,Any}("a1"=>5, "a2"=>"att")