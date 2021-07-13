struct Layers
    layers::Vector{Layer}
end

Base.convert(::Type{Layers}, s::Layer) = Layers([s])
Base.convert(::Type{Layers}, s::Layers) = s

Base.getindex(v::Layers, i::Int) = v.layers[i]
Base.length(v::Layers) = length(v.layers)
Base.eltype(::Type{Layers}) = Layer
Base.iterate(v::Layers, args...) = iterate(v.layers, args...)

const OneOrMoreLayers = Union{Layers, Layer}

function Base.:+(s1::OneOrMoreLayers, s2::OneOrMoreLayers)
    l1::Layers, l2::Layers = s1, s2
    return Layers(vcat(l1.layers, l2.layers))
end

function Base.:*(s1::OneOrMoreLayers, s2::OneOrMoreLayers)
    l1::Layers, l2::Layers = s1, s2
    return Layers([el1 * el2 for el1 in l1 for el2 in l2])
end

uniquevalues(v::ArrayLike) = collect(uniquesorted(vec(v)))

to_label(label::AbstractString) = label
to_label(labels::ArrayLike) = reduce(mergelabels, labels)

function categoricalscales(e::Entry, palettes)
    cs = Dict{KeyType, Any}()
    for (key, val) in pairs(e.primary)
        palette = get(palettes, key, automatic)
        label = to_label(get(e.labels, key, ""))
        cs[key] = CategoricalScale(uniquevalues(val), palette, label)
    end
    for (key, val) in pairs(e.positional)
        all(iscontinuous, val) && continue
        all(isgeometry, val) && continue
        palette = automatic
        label = to_label(get(e.labels, key, ""))
        cs[key] = CategoricalScale(mapreduce(uniquevalues, mergesorted, val), palette, label)
    end
    return cs
end

function compute_grid_positions(scales, primary=(;))
    return map((:row, :col), (first, last)) do sym, f
        scale = get(scales, sym, nothing)
        lscale = get(scales, :layout, nothing)
        return if !isnothing(scale)
            rg = Base.OneTo(maximum(plotvalues(scale)))
            haskey(primary, sym) ? rescale(fill(primary[sym]), scale) : rg
        elseif !isnothing(lscale)
            rg = Base.OneTo(maximum(f, plotvalues(lscale)))
            haskey(primary, :layout) ? map(f, rescale(fill(primary[:layout]), lscale)) : rg
        else
            Base.OneTo(1)
        end
    end
end

function compute_axes_grid(fig, s::OneOrMoreLayers;
                           axis=NamedTuple(), palettes=NamedTuple())
    layers::Layers = s
    entries = map(process, layers)

    theme_palettes = NamedTuple(Makie.current_default_theme()[:palette])
    palettes = merge((layout=wrap,), map(to_value, theme_palettes), palettes)

    scales = mapreduce(mergewith!(mergescales), entries) do entry
        return categoricalscales(entry, palettes)
    end
    # fit scales (compute plot values using all data values)
    map!(fitscale, values(scales))


    function create_axis(fig, c)
        type = get(axis, :type, Axis)
        options = Base.structdiff(axis, (; type))
        ax = type(fig[Tuple(c)...]; options...)
        return AxisEntries(ax, Entry[], scales)
    end
    function create_axis(f::Axis, c)
        if !isempty(axis)
            @warn("Axis got passed, but also axis attributes. Ignoring axis attributes: $(axis)")
        end
        return AxisEntries(fig, Entry[], scales)
    end
    axs = compute_grid_positions(scales)
    sizes = length.(axs)

    if sizes !== (1, 1) && fig isa Axis
        error("You can only pass an Axis to draw!, if the calculated layout only contains one element. Elements: $(sizes)")
    end
    axes_grid = map(CartesianIndices(axs)) do c
        return create_axis(fig, c)
    end

    for e in entries
        for c in CartesianIndices(shape(e))
            primary, positional, named = map((e.primary, e.positional, e.named)) do tup
                return map(v -> getnewindex(v, c), tup)
            end
            rows, cols = compute_grid_positions(scales, primary)
            labels = copy(e.labels)
            map!(l -> getnewindex(l, c), values(labels))
            entry = Entry(e; primary, positional, named, labels)
            for i in rows, j in cols
                ae = axes_grid[i, j]
                push!(ae.entries, entry)
            end
        end
    end

    # Link colors
    labeledcolorrange = getlabeledcolorrange(axes_grid)
    if !isnothing(labeledcolorrange)
        _, colorrange = labeledcolorrange
        for entry in AlgebraOfGraphics.entries(axes_grid)
            entry.attributes[:colorrange] = colorrange
        end
    end

    # Axis labels and ticks
    for ae in axes_grid
        ndims = isaxis2d(ae) ? 2 : 3
        for (i, var) in zip(1:ndims, (:x, :y, :z))
            scale = get(scales, i) do
                return compute_extrema(AlgebraOfGraphics.entries(axes_grid), i)
            end
            isnothing(scale) && continue
            label = compute_label(ae.entries, i)
            for (k′, v) in pairs((label=string(label), ticks=ticks(scale)))
                k = Symbol(var, k′)
                k in keys(axis) || (getproperty(Axis(ae), k)[] = v)
            end
        end
    end
    return axes_grid
end

function Makie.plot!(fig, s::OneOrMoreLayers;
                     axis=NamedTuple(), palettes=NamedTuple())
    grid = compute_axes_grid(fig, s; axis, palettes)
    foreach(plot!, grid)
    return grid
end

function Makie.plot(s::OneOrMoreLayers;
                    axis=NamedTuple(), figure=NamedTuple(), palettes=NamedTuple())
    fig = Figure(; figure...)
    grid = plot!(fig, s; axis, palettes)
    return FigureGrid(fig, grid)
end

# Convenience function, which may become superfluous if `plot` also calls `facet!`
function draw(s::OneOrMoreLayers;
              axis = NamedTuple(), figure=NamedTuple(), palettes=NamedTuple())
    fg = plot(s; axis, figure, palettes)
    facet!(fg)
    Legend(fg)
    resizetocontent!(fg)
    return fg
end

function draw!(fig, s::OneOrMoreLayers;
               axis=NamedTuple(), palettes=NamedTuple())
    ag = plot!(fig, s; axis, palettes)
    facet!(fig, ag)
    return ag
end
