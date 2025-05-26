using CUDA
struct Point 
    x::Int32
    y::Int32
end

function test()
    points = @cuStaticSharedMem(Point,10)
    points[1] = Point(3,2)
    points[2].x = 2
    return
end


@cuda test()