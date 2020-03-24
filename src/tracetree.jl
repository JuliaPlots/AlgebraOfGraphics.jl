# Combine different `Trace`s in a `TraceTree` object

struct TraceTree
    list::LinkedList
end
TraceTree(s::TraceTree) = s
TraceTree(t::Trace) = TraceTree(list(t => list()))

function Base.show(io::IO, s::TraceTree)
    print(io, "TraceTree")
end

function Base.:+(a::Union{Trace, TraceTree}, b::Union{Trace, TraceTree})
    a = TraceTree(a)
    b = TraceTree(b)
    return TraceTree(cat(a.list, b.list))
end

function leafconcat(l1::LinkedList, l2::LinkedList)
    isempty(l1) && return list()
    trace, ll = first(l1)
    t = isempty(ll) ? l2 : leafconcat(ll, l2)
    return cons(trace => t, leafconcat(tail(l1), l2))
end

function Base.:*(a::Union{Trace, TraceTree}, b::Union{Trace, TraceTree})
    a = TraceTree(a)
    b = TraceTree(b)
    return TraceTree(leafconcat(a.list, b.list))
end

function applylist(l::LinkedList, x)
    isempty(l) && return list()
    trace, ll = first(l)
    t = isempty(ll) ? list(trace(x)) : applylist(ll, trace(x))
    return cat(t, applylist(tail(l), x))
end

(t::TraceTree)(x) = applylist(t.list, x)

# ranking

jointable(ts) = jointable(ts, foldl(merge, ts))

function jointable(ts, ::NamedTuple{names}) where names
    vals = map(names) do name
        vcat((get(table, name, Union{}[]) for table in ts)...)
    end
    NamedTuple{names}(vals)
end

primarytable(t::AbstractTrace) = fieldarrays(StructArray(p for (p, _) in pairs(t)))
primarytable(series::LinkedList) = jointable(map(primarytable, series))

rankdict(d) = Dict(val => i for (i, val) in enumerate(uniquesorted(vec(d))))

rankdicts(ts) = map(rankdict, primarytable(ts))
