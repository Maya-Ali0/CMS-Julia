struct BeamSpotToPOD <: EDProducer
    bsPutToken_::EDPutTokenT<BeamSpotPOD>

    function BeamSpotToPOD(reg::ProductRegistry)
        new(produces(reg,BeamSpotPOD))
    end
end


function produce(iEvent::Event, iSetup::EventSetup)
    iEvent.emplace(bsPutToken_, iSetup.get<BeamSpotPOD>())
end



