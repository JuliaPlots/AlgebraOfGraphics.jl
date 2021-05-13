## Grouping machinery

fast_hashed(v::AbstractVector) = isbitstype(eltype(v)) ? PooledArray(v) : v

function indices_iterator(cols)
    isempty(cols) && return Ref(Colon())
    grouping_sa = StructArray(map(refarray∘fast_hashed, cols))
    gp = GroupPerm(grouping_sa)
    return (sortperm(gp)[rg] for rg in gp)
end

function subselect(arr, idxs, c′::CartesianIndex)
    c = Broadcast.newindex(CartesianIndices(tail(axes(arr))), c′)
    return view(arr, idxs, Tuple(c)...)
end

nested_map(f, (a, b)::Tuple) = map(f, a), map(f, b)

splitapply(entry::Entry) = splitapply(identity, entry)

function splitapply(f, entry::Entry)
    primary, positional, named = entry.primary, entry.positional, entry.named
    axs = Broadcast.combine_axes(primary..., positional..., named...)
    grouping = filter(v -> isa(v, AbstractVector), Tuple(primary))
    list = Entry[]
    foreach(indices_iterator(grouping)) do idxs
        for c in CartesianIndices(tail(axs))
            subpositional, subnamed = nested_map((positional, named)) do arr
                return subselect(arr, idxs, c)
            end

            subprimary = map(primary) do arr
                i = idxs === Colon() || size(arr, 1) == 1 ? firstindex(arr, 1) : first(idxs)
                return subselect(arr, i, c)
            end

            sublabels = copy(entry.labels)
            map!(values(sublabels)) do l
                w = maybewrap(l)
                return w[Broadcast.newindex(w, c)]
            end

            input = Entry(entry.plottype, subprimary, subpositional, subnamed, sublabels; entry.attributes...)
            append!(list, maybewrap(f(input)))
        end
    end
    return list
end

## Transform `Layers` into list of `Entry`

function unnest(arr::AbstractArray{<:AbstractArray})
    inner_size = mapreduce(size, assert_equal, arr)
    outer_size = size(arr)
    flattened = reduce(vcat, map(vec, vec(arr)))
    return reshape(flattened, inner_size..., outer_size...)
end

unnest(arr::NTuple{<:Any, <:AbstractArray}) = unnest(collect(arr))

function process_data(data, positional′, named′)
    axs = Broadcast.combine_axes(positional′..., named′...)
    labels = Dict{KeyType, Any}()
    primary, positional, named = [], [], []
    for c in (positional′, named′)
        for (key, val) in pairs(c)
            ntls = map(y -> NameTransformationLabel(data, y), val)
            labels[key] = map(ntl -> ntl.label, ntls)
            nested = map(ntls) do ntl
                cols = apply_context(data, axs, maybewrap(ntl.name))
                return map(ntl.transformation, cols...)
            end
            v = unnest(nested)
            if key isa Int
                push!(positional, v)
            elseif any(ntl -> ntl.name isa DimsSelector, ntls) || !iscontinuous(v)
                push!(primary, key => v)
            else
                push!(named, key => v)
            end
        end
    end
    return Entry(Any, (; primary...), Tuple(positional), (; named...), labels)
end

function process_data(layer::Layer)
    positional, named = map(maybewrap, layer.positional), map(maybewrap, layer.named)
    return process_data(layer.data, positional, named)
end

function process_transformations(layer::Layer)
    init = process_data(layer)
    res = foldl(process_transformations, layer.transformations; init)
    return res isa Entry ? splitapply(res) : res
end

process_transformations(v::AbstractArray{Entry}, f) = map(f, v)

process_transformations(le::Entry, f) = f(le)
