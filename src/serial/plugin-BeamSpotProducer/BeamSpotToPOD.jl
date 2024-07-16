<<<<<<< HEAD
=======
struct BeamSpotToPOD <: EDProducer
    bsPutToken_::EDPutTokenT{BeamSpotPOD}

    function BeamSpotToPOD(reg::ProductRegistry)
        new(produces(reg,BeamSpotPOD))
    end
end


function produce(bs::BeamSpotToPOD , iEvent::Event, iSetup::EventSetup)
    emplace(iEvent,bs.bsPutToken_,get(iSetup,BeamSpotPOD))
end



>>>>>>> 6b1107a5244da37532040fb8a7979f35c003b5ed
