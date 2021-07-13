increment!(idx::Ref) = (idx[] += 1; idx[])

function apply_palette(p::AbstractVector, uv)
    values = filter(x -> !isa(x, Pair), p)
    pairs = Dict(filter(x -> isa(x, Pair), p))
    idx = Ref(0)
    return [get(() -> cycle(values, increment!(idx)), pairs, v) for v in uv]
end

apply_palette(::Automatic, uv) = eachindex(uv)
apply_palette(p, uv) = map(p, eachindex(uv)) # FIXME: maybe apply to values instead?

# TODO: add more customizations?
struct Wrap end

const wrap = Wrap()

function apply_palette(::Wrap, uv)
    ncols = ceil(Int, sqrt(length(uv)))
    return [fldmod1(idx, ncols) for idx in eachindex(uv)]
end

struct CategoricalScale{S, T, U}
    data::S
    plot::T
    palette::U
    label::Union{String, Nothing}
end
function CategoricalScale(data, palette, label::Union{String, Nothing})
    return CategoricalScale(data, nothing, palette, label)
end

# Final processing step of a categorical scale
function fitscale(c::CategoricalScale)
    data = c.data
    palette = c.palette
    plot = apply_palette(c.palette, c.data)
    label = something(c.label, "")
    return CategoricalScale(data, plot, palette, label)
end

datavalues(c::CategoricalScale) = c.data
plotvalues(c::CategoricalScale) = c.plot

rescale(values, ::Nothing) = values

# recentering hack to avoid Float32 conversion errors on recent dates
# TODO: remove once Makie supports dates
const time_offset = let startingdate = Date(2020, 01, 01)
    ms:: Millisecond = DateTime(startingdate)
    ms / Millisecond(1)
end

function rescale(values::AbstractArray{T}, ::Nothing) where T<:Union{Date, DateTime}
    return map(values) do val
        ms::Millisecond = DateTime(val)
        return ms / Millisecond(1) - time_offset
    end
end

# Do not rescale continuous data with categorical scale
rescale(values::AbstractArray{<:Number}, ::CategoricalScale) = values

function rescale(values, c::CategoricalScale)
    idxs = indexin(values, datavalues(c))
    return plotvalues(c)[idxs]
end

Base.length(c::CategoricalScale) = length(datavalues(c))

function mergelabels(label1, label2)
    return if isnothing(label1)
        nothing
    elseif isequal(label1, label2)
        label1
    elseif isempty(label1)
        label2
    elseif isempty(label2)
        label1
    else
        nothing # no reasonable label found
    end
end

function compute_label(entries, key)
    label = ""
    for entry in entries
        label = mergelabels(label, get(entry.labels, key, ""))
    end
    return something(label, "")
end

function mergescales(c1::CategoricalScale, c2::CategoricalScale)
    data = mergesorted(c1.data, c2.data)
    palette = assert_equal(c1.palette, c2.palette)
    label = mergelabels(c1.label, c2.label)
    return CategoricalScale(data, palette, label)
end

# Logic to create ticks from a scale
# Should take current tick to incorporate information
function ticks(scale::CategoricalScale)
    u = map(string, datavalues(scale))
    return (axes(u, 1), u)
end

ticks((min, max)::NTuple{2, Any}) = automatic

function ticks((min, max)::NTuple{2, T}) where T<:Union{Date, DateTime}
    min_ms::Millisecond, max_ms::Millisecond = DateTime(min), DateTime(max)
    min_pure, max_pure = min_ms / Millisecond(1), max_ms / Millisecond(1)
    dates, labels = optimize_datetime_ticks(min_pure, max_pure)
    return (dates .- time_offset, labels)
end

## Scale helpers

const ArrayLike = Union{AbstractArray, Tuple}
const StringLike = Union{AbstractString, Symbol}

function cycle(v::AbstractVector, i::Int)
    ax = axes(v, 1)
    return v[first(ax) + mod(i - first(ax), length(ax))]
end

"""
    iscontinuous(v)

Determine whether `v` should be treated as a continuous or categorical vector.
"""
function iscontinuous(u)
    v = Broadcast.broadcastable(u)
    return !haszerodims(v) && eltype(v) <: Union{Number, Date, DateTime, Makie.StaticVector} && !(eltype(v) <: Bool)
end

isgeometry(::AbstractArray{<:Point}) = true
isgeometry(::AbstractArray{<:AbstractGeometry}) = true
isgeometry(::AbstractArray{T}) where {T} = eltype(T) <: Union{Point, AbstractGeometry}

extend_extrema((l1, u1), (l2, u2)) = min(l1, l2), max(u1, u2)
extend_extrema(::Nothing, (l2, u2)) = (l2, u2)

function compute_extrema(entries, key)
    acc = nothing
    for entry in entries
        col = get(entry, key, nothing)
        if !isnothing(col) && !isgeometry(col)
            acc = extend_extrema(acc, Makie.extrema_nan(col))
        end
    end
    return acc
end

push_different!(v, val) = !isempty(v) && isequal(last(v), val) || push!(v, val)

function mergesorted(v1, v2)
    issorted(v1) && issorted(v2) || throw(ArgumentError("arguments must be sorted"))
    T = promote_type(eltype(v1), eltype(v2))
    v = sizehint!(T[], length(v1) + length(v2))
    i1, i2 = 1, 1
    while i2 ≤ length(v2)
        while i1 ≤ length(v1) && isless(v1[i1], v2[i2])
            push_different!(v, v1[i1])
            i1 += 1
        end
        push_different!(v, v2[i2])
        i2 += 1
    end
    while i1 ≤ length(v1)
        push_different!(v, v1[i1])
        i1 += 1
    end
    return v
end
