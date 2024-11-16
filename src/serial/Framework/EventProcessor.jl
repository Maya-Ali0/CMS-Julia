using .ESPluginFactory
using Dagger

struct EventProcessor
 
    numberOfStreams::Int
    source::Source
    event_setup::EventSetup
    registry::ProductRegistry
    schedules::Vector{StreamSchedule}

    # Constructor
    function EventProcessor(numOfStreams::Int,path::Vector{String},esproducers::Vector{String}, datadir::String)
        numberOfStreams = numOfStreams
        registry = ProductRegistry()
        source = Source(registry,datadir)
        # print(source.raw_events)
        event_setup = EventSetup()
        for name in esproducers
            esp = create_plugin(name,datadir)
            produce(esp,event_setup)
        end

        schedules = Vector{StreamSchedule}()
        for i in 1:numberOfStreams
            push!(schedules, StreamSchedule(registry, source, event_setup, i, path))
        end

        new(numOfStreams,source,event_setup,registry,schedules)
    end
end



function run_processor(ev::EventProcessor)
    # for i in 1:ev.numberOfStreams
    #     Dagger.@spawn run_stream(ev.schedules[i])
    # end
    tasks = [Dagger.@spawn run_stream(schedule) for schedule in ev.schedules]
    # print(length(tasks))
    for i in 1:ev.numberOfStreams
        # Dagger.@spawn run_stream(ev.schedules[i])
        fetch(tasks[i])
    end
    # Dagger.collect(tasks);  # This will execute all tasks and wait for them to finish
    print(tasks)
    # @info "All stream schedules have completed."

end