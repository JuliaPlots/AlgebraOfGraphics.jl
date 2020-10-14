struct NamedSparseArray{S<:Tuple, V<:AbstractVector}
    keys::S
    values::V
    function NamedSparseArray(args::AbstractVector...)
        keys = Base.front(args)
        values = last(args)
        return new{typeof(keys), typeof(values)}(keys, values)
    end
end

# Turn named sparse array into a dense one, while remembering the labels.
function dense(kv::NamedSparseArray)
    keys, values = kv.keys, kv.values
    labels = map(collect∘uniquesorted, keys)
    indices = map(Base.OneTo∘length, labels)
    converter = map((k, v) -> Dict(zip(k, v)), labels, indices)
    d = zeros(eltype(values), indices)
    for (k, v) in zip(StructArray(keys), values)
        I = map(getindex, converter, k)
        d[I...] = v
    end
    return labels, d
end

function _frequency(args...)
    gp = GroupPerm(fast_sortable(args))
    itr = (s[sp[first(range)]] => length(range) for range in gp)
    keys, values = fieldarrays(StructArray(itr, unwrap = t -> t <: Tuple))
    namedarray =  NamedSparseArray(fieldarrays(keys)..., values)
    labels, values = dense(namedarray)
    plottypes = [:BarPlot, :Heatmap, :Volume]
    return mapping(labels..., values) * visual(plottypes[length(labels)])
end

"""
    frequency(data...)

Compute a frequency table of the arguments.
"""
const frequency = Analysis(_frequency)
