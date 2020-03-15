concatenate(v::Union{Tuple, NamedTuple}...) = map(concatenate, v...)
concatenate(v::AbstractArray...) = vcat(v...)

ncols(v::Tuple) = length(v)
ncols(v::AbstractVector) = 1

extract_view(v::Union{Tuple, NamedTuple}, idxs) = map(x -> extract_view(x, idxs), v)
extract_view(v::AbstractVector, idxs) = view(v, idxs)

function extract_view(v::Select, idxs)
    Select(
           map(x -> extract_view(x, idxs), v.args)...;
           map(x -> extract_view(x, idxs), v.kwargs)...
          )
end

extract_view(v::Union{Tuple, NamedTuple}, idxs, n) = extract_view(v[n], idxs)
extract_view(v::AbstractVector, idxs, n) = view(v, idxs)

function extract_view(v::Select, idxs, n)
    Select(
           map(x -> extract_view(x, idxs, n), v.args)...;
           map(x -> extract_view(x, idxs, n), v.kwargs)...
          )
end

extract_column(t, c::Union{Tuple, NamedTuple}) = map(x -> extract_column(t, x), c)
extract_column(t, col::AbstractVector) = col
extract_column(t, col::Symbol) = getproperty(t, col)
extract_column(t, col::Integer) = getindex(t, col)

_extract_columns(t, tup::Union{Tuple, NamedTuple}) = map(col -> extract_column(t, col), tup)

function _extract_columns(t, s::Select)
    Select(
           _extract_columns(t, select.args)...;
           _extract_columns(t, select.kwargs)...
          )
end

_extract_columns(t, grp::Group) = Group(; _extract_columns(t, grp.columns)...)

function extract_columns(d::Data, g)
    t = d.table
    t === nothing ? g : _extract_columns(t, g)
end

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

# NamedTuple utils

function keepvectors(n::NamedTuple{s, <:Tuple{AbstractVector, Vararg}}) where s
    l = keepvectors(NamedTuple{tail(s)}(n))
    fn, fs = first(n), first(s)
    f = NamedTuple{(fs,)}((fn,))
    return merge(f, l)
end

function keepvectors(n::NamedTuple{s}) where s
    return keepvectors(NamedTuple{tail(s)}(n))
end

keepvectors(::typeof(NamedTuple())) = NamedTuple()

