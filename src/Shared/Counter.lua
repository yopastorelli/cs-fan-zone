local Counter = {}

export type State = {
    goal: number,
    count: number,
    seen: { [string]: boolean },
}

function Counter.new(goal: number): State
    return {
        goal = goal,
        count = 0,
        seen = {},
    }
end

function Counter.collect(state: State, id: string): boolean
    if state.seen[id] then
        return false
    end

    state.seen[id] = true
    state.count += 1
    return true
end

function Counter.has(state: State, id: string): boolean
    return state.seen[id] == true
end

function Counter.isComplete(state: State): boolean
    return state.count >= state.goal
end

function Counter.ids(state: State): { string }
    local ids = {}

    for id in pairs(state.seen) do
        ids[#ids + 1] = id
    end

    table.sort(ids)
    return ids
end

return Counter
