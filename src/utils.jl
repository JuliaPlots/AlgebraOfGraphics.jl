const Tup = Union{Tuple, NamedTuple, MixedTuple}

extract_view(v::Tup, idxs) = map(x -> extract_view(x, idxs), v)
extract_view(v::AbstractVector, idxs) = view(v, idxs)

extract_column(t, c::Tup) = map(x -> extract_column(t, x), c)
extract_column(t, col::AbstractArray) = col
extract_column(t, col::Symbol) = getproperty(t, col)
extract_column(t, col::Integer) = getindex(t, col)

# show utils

function _show(io::IO, args...; kwargs...)
    print(io, "(")
    kwargs = values(kwargs)
    na, nk = length(args), length(kwargs)
    for i in 1:na
        show(io, args[i])
        if i < na + nk
            print(io, ", ")
        end
    end
    for i in 1:nk
        print(io, keys(kwargs)[i])
        print(io, " = ")
        show(io, kwargs[i])
        if i < nk
            print(io, ", ")
        end
    end
    print(io, ")")
end

# PooledArrays utils

function pool(v)
    s = refarray(v)
    pv = PooledArray(s)
    map(pv) do el
        refvalue(v, el)
    end
end

pool(v::PooledVector) = v

pool(v::AbstractVector{<:Integer}) = v

# function consistent(nt1::NamedTuple, nt2::NamedTuple)
#     all(((key, val),) -> val == get(nt2, key, val), pairs(nt1))
# end
# consistent(mt1::MixedTuple, mt2::MixedTuple) = consistent(mt1.kwargs, mt2.kwargs)

# ranking

jointable(ts) = jointable(ts, foldl(merge, ts))

function jointable(tables, ::NamedTuple{names}) where names
    vals = map(names) do name
        vcat((get(table, name, Union{}[]) for table in tables)...)
    end
    NamedTuple{names}(vals)
end

rankdict(d) = Dict(val => i for (i, val) in enumerate(uniquesorted(d)))

function rankdicts(ts::AbstractTraceList)
    tables = map(t -> primary(group(t)).kwargs, ts) |> jointable
    return map(rankdict, tables)
end

# StructArray utils

function soa(m)
    args = isempty(m[1].args) ? () : columntable(map(t -> t.args, m))
    kwargs = isempty(m[1].kwargs) ? NamedTuple() : columntable(map(t -> t.kwargs, m))
    return MixedTuple(Tuple(args), kwargs)
end

aos(m::MixedTuple) = isempty(m) ? Union{}[] : [_rename(el, m) for el in zip(m.args..., m.kwargs...)]

function keyvalue(p::MixedTuple, d::MixedTuple)
    isempty(p) && isempty(d) && error("Both arguments are empty")
    isempty(p) && return ((mixedtuple(), el) for el in aos(d))
    isempty(d) && return ((el, mixedtuple()) for el in aos(p))
    return zip(aos(p), aos(d))
end
